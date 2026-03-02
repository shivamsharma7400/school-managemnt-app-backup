import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class SchoolConfigService extends ChangeNotifier {
  String _schoolName = AppStrings.appName;
  String _schoolLogoUrl = ''; // Empty string means use default asset
  String _aiAgentName = 'Veena AI Assist'; // Default
  
  String get schoolName => _schoolName;
  String get schoolLogoUrl => _schoolLogoUrl;
  String get aiAgentName => _aiAgentName;

  final CollectionReference _settingsCollection = 
      FirebaseFirestore.instance.collection('settings');

  SchoolConfigService() {
    _init();
  }

  void _init() {
    _settingsCollection.doc('config').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _schoolName = data['schoolName'] ?? AppStrings.appName;
        _schoolLogoUrl = data['schoolLogoUrl'] ?? '';
        _aiAgentName = data['aiAgentName'] ?? 'Veena AI Assist';
        notifyListeners();
      } else {
        // Create default config if it doesn't exist
        _settingsCollection.doc('config').set({
          'schoolName': AppStrings.appName,
          'schoolLogoUrl': '',
          'aiAgentName': 'Veena AI Assist',
        });
      }
    });
  }

  Future<void> updateConfig({
    required String schoolName,
    required String schoolLogoUrl,
    required String aiAgentName,
  }) async {
    await _settingsCollection.doc('config').update({
      'schoolName': schoolName,
      'schoolLogoUrl': schoolLogoUrl,
      'aiAgentName': aiAgentName,
    });
    // Local update happens via listener, but we can do it optimistically too if needed
  }
}
