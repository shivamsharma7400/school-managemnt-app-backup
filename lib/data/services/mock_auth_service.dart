
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Keep for type compatibility if needed, though we won't use it directly in mock
import 'auth_service.dart';

// We'll extend or implement a similar interface. 
// For simplicity in this rapid prototype, I'll modify existing AuthService 
// to handle mock logic if firebase is not initialized, 
// BUT creating a clean separate MockService is better.

class MockAuthService extends ChangeNotifier implements AuthService {
  String? _userId;
  String? _role;
  bool _isLoading = false;

  @override
  User? get user => _userId != null ? MockUser(_userId!) : null;

  @override
  String? get role => _role;

  @override
  bool get isLoading => _isLoading;

  MockAuthService() {
    // Simulate auto-login check
    _checkMockSession();
  }

  void _checkMockSession() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(Duration(seconds: 1)); // Simulate network
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(Duration(seconds: 1));
    _isLoading = false;

    // Hardcoded mock credentials for testing
    if (email.contains('student')) {
      _userId = 'student_123';
      _role = 'student';
    } else if (email.contains('teacher')) {
      _userId = 'teacher_123';
      _role = 'teacher';
    } else if (email.contains('principal')) {
      _userId = 'principal_123';
      _role = 'principal';
    } else if (email.contains('new')) {
       _userId = 'new_123';
      _role = 'pending';
    } else {
      // Default fallback
       _userId = 'user_123';
       _role = 'student';
    }
    
    notifyListeners();
    return null;
  }

  @override
  Future<String?> register(String email, String password, String name, String role) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(Duration(seconds: 1));
    _isLoading = false;

    _userId = 'new_user_${DateTime.now().millisecondsSinceEpoch}';
    _role = 'pending'; // New users are always pending
    notifyListeners();
    return null;
  }

  @override
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 500));
    _userId = null;
    _role = null;
    _isLoading = false;
    notifyListeners();
  }
}

// Simple Mock User to satisfy type requirements if possible, 
// but FirebaseAuth User is a complex object. 
// We might need to change the AuthService interface to expose a generic User model 
// instead of FirebaseAuth user.
// For now, let's just make AuthService fields nullable or generic.
// Actually, since Dart is sound null safe, we can't easily fake `User`.
// STRATEGY CHANGE: The UI depends on `AuthService`. 
// I will modify `AuthService` to NOT return `User?` object from Firebase directly,
// but just a boolean `isAuthenticated` or a simple custom User model.

class MockUser implements User {
  @override
  final String uid;
  MockUser(this.uid);
  
  // Implement other required overrides with dummy data
  @override String? get email => 'test@example.com';
  @override String? get displayName => 'Test User';
  @override bool get emailVerified => true;
  @override bool get isAnonymous => false;
  @override String? get phoneNumber => null;
  @override String? get photoURL => null;
  @override List<UserInfo> get providerData => [];
  @override String? get refreshToken => null;
  @override String get tenantId => throw UnimplementedError();
  @override Future<void> delete() async {}
  @override Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token';
  @override Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async => throw UnimplementedError();
  @override Future<User> linkWithCredential(AuthCredential credential) async => this;
  @override Future<User> linkWithProvider(AuthProvider provider) async => this;
  @override Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async => throw UnimplementedError();
  @override Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) async => throw UnimplementedError();
  @override Future<void> reload() async {}
  @override Future<void> sendEmailVerification({ActionCodeSettings? actionCodeSettings}) async {}
  @override Future<User> unlink(String providerId) async => this;
  @override Future<void> updateDisplayName(String? displayName) async {}
  @override Future<void> updateEmail(String newEmail) async {}
  @override Future<void> updatePassword(String newPassword) async {}
  @override Future<void> updatePhoneNumber(PhoneAuthCredential credential) async {}
  @override Future<void> updatePhotoURL(String? photoURL) async {}
  @override Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async {}
  @override dynamic get metadata => throw UnimplementedError();
}
