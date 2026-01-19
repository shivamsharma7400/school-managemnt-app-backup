import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/auth_service.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}


class _NotificationScreenState extends State<NotificationScreen> {
  late Stream<List<Map<String, dynamic>>> _notificationStream;

  @override
  void initState() {
    super.initState();
    // Initialize stream once
    final user = Provider.of<AuthService>(context, listen: false).user;
    if (user != null) {
      _notificationStream = Provider.of<NotificationService>(context, listen: false)
          .getUserNotifications(user.uid);
    } else {
      _notificationStream = Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    if (user == null) return Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No notifications yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          // Group notifications by date
          final groupedNotifications = <String, List<Map<String, dynamic>>>{};
          for (var notification in notifications) {
            final Timestamp? timestamp = notification['date'] as Timestamp?;
            final dateStr = timestamp != null 
                ? _getDateHeader(timestamp.toDate()) 
                : 'Recent';
            if (groupedNotifications[dateStr] == null) {
              groupedNotifications[dateStr] = [];
            }
            groupedNotifications[dateStr]!.add(notification);
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: groupedNotifications.length,
            itemBuilder: (context, index) {
              String header = groupedNotifications.keys.elementAt(index);
              List<Map<String, dynamic>> items = groupedNotifications[header]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                    child: Text(
                      header,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                  ),
                  ...items.map((notification) {
                    final bool isRead = notification['read'] ?? false;
                    final String id = notification['id'];
                    
                    // Mark as read immediately when rendering (or could use VisibilityDetector)
                    if (!isRead) {
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                           Provider.of<NotificationService>(context, listen: false).markAsRead(id);
                       });
                    }

                    return Card(
                      elevation: isRead ? 0 : 2,
                      color: isRead ? Colors.white : Colors.blue[50],
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRead ? Colors.grey[200] : Colors.blue,
                          child: Icon(Icons.notifications, color: isRead ? Colors.grey : Colors.white),
                        ),
                        title: Text(
                          notification['title'] ?? 'No Title', 
                          style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)
                        ),
                        subtitle: Text(notification['body'] ?? ''),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return 'Today';
    if (dateToCheck == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}
