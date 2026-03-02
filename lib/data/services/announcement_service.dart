import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';

class AnnouncementService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Announcement>> getAnnouncements(String userRole) {
    Query query = _firestore.collection('announcements');

    // Filter based on role
    if (userRole == 'student') {
      query = query.where('targetAudience', whereIn: ['student', 'all']);
    } else if (userRole == 'teacher') {
      query = query.where('targetAudience', whereIn: ['teacher', 'all']);
    } else if (userRole == 'driver') {
      // Driver sees student and teacher announcements + all
      query = query.where('targetAudience', whereIn: ['student', 'teacher', 'all']);
    }
    // Principal and Management see all

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .toList();
      // Client-side sorting to avoid Firestore Composite Index issues
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addAnnouncement(String title, String content, String type, String targetAudience) async {
    await _firestore.collection('announcements').add({
      'title': title,
      'content': content,
      'date': FieldValue.serverTimestamp(),
      'type': type,
      'targetAudience': targetAudience,
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
  }
}
