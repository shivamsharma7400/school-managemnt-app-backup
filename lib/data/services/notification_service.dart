import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: \${message.messageId}");

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  // Show the notification when app is in background
  if (notification != null && android != null) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: android.smallIcon,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: message.data.toString(),
    );
  }
}

class NotificationService extends ChangeNotifier {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // 2. Setup Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          // Add Darwin/iOS/MacOS and Linux/Web if needed
        );

    if (!kIsWeb) {
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          print("Notification Clicked: ${details.payload}");
        },
      );

      // 3. Create Channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 4. Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Foreground Handler (FCM)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        showLocalNotification(
          notification.hashCode,
          notification.title ?? "",
          notification.body ?? "",
          payload: message.data.toString(),
        );
      }
    });

    // 6. Get Token
    await getToken();

    // 7. Subscribe to General Topic
    if (!kIsWeb) {
      await _firebaseMessaging.subscribeToTopic('announcements');
      print("Subscribed to 'announcements' topic");
    }
  }

  // Sync Firestore Notifications to Local Popups
  void listenToNotifications(String userId) {
    _notificationSubscription?.cancel();
    
    // Listen for NEW notifications added to Firestore
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThan: Timestamp.now()) // Only new ones
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          showLocalNotification(
            change.doc.id.hashCode,
            data['title'] ?? "New Notification",
            data['body'] ?? "",
            payload: change.doc.id,
          );
        }
      }
    });
  }

  Future<void> showLocalNotification(int id, String title, String body, {String? payload}) async {
    if (kIsWeb) {
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF4F46E5),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (!kIsWeb) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    }
  }

  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  Future<String?> getToken() async {
    _fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $_fcmToken");
    notifyListeners();
    return _fcmToken;
  }

  Future<void> saveTokenToUser(String userId) async {
    if (_fcmToken == null) await getToken();

    if (_fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'fcmToken': _fcmToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          })
          .catchError((e) => print("Error saving token: $e"));
    }
  }

  Future<void> sendNotificationToUser(
    String userId,
    String title,
    String body, {
    String? type,
    Map<String, dynamic>? data,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'date': FieldValue.serverTimestamp(),
      'read': false,
      'type': type,
      'data': data,
    });
  }

  Future<void> sendNotificationToClass(
    String classId,
    String title,
    String body, {
    String? type,
    Map<String, dynamic>? data,
  }) async {
    // In a real backend, we'd trigger a Cloud Function.
    // Here, we can iterate users (inefficient but works for MVP) or just create a 'class_broadcast' collection
    // Let's create individual notifications for now so they appear in user's inbox

    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('classId', isEqualTo: classId)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in usersSnapshot.docs) {
      final ref = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(ref, {
        'userId': doc.id,
        'title': title,
        'body': body,
        'date': FieldValue.serverTimestamp(),
        'read': false,
        'type': type,
        'data': data,
      });
    }

    await batch.commit();
  }

  Future<void> sendBroadcastNotification(
    String title,
    String body, {
    String? targetRole,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    // Simulating broadcast by sending to all users (inefficient for large scale, ok for MVP)
    // or better, sending to a 'topic' if using FCM directly.
    // For this MVP, we will iterate users collection.

    Query query = FirebaseFirestore.instance.collection('users');
    if (targetRole != null && targetRole != 'all') {
      query = query.where('role', isEqualTo: targetRole);
    }

    final usersSnapshot = await query.get();
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in usersSnapshot.docs) {
      final ref = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(ref, {
        'userId': doc.id,
        'title': title,
        'body': body,
        'date': FieldValue.serverTimestamp(),
        'read': false,
        'type': type,
        'data': data,
      });
    }
    await batch.commit();
  }

  Stream<int> getUnreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          // Client-side sorting
          docs.sort((a, b) {
            final Timestamp? tA = a['date'];
            final Timestamp? tB = b['date'];
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA); // Descending
          });

          return docs;
        });
  }
}
