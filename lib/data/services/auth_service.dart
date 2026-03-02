import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _role;
  String? _classId;
  bool _isApproved = false;
  Map<String, dynamic>? _userData;

  User? get user => _user;
  String? get role => _role;
  String? get classId => _classId;
  bool get isApproved => _isApproved;
  Map<String, dynamic>? get currentUserData => _userData;

  // Helper to get name from Auth or potentially cached firestore data (if we added it).
  // For now, let's rely on Auth. If Auth name is null, we can return "User".
  String get userName => _user?.displayName ?? "User";
  String get currentUserId => _user?.uid ?? "";

  bool get isLoading => _user == null && _auth.currentUser != null && _role == null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserRole(user.uid);
      } else {
        _role = null;
        _classId = null;
        _isApproved = false; // Reset on sign out
        _userData = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userData = doc.data() as Map<String, dynamic>?;
        _role = doc['role'];
        _classId = doc['classId']; // Fetch classId
        _isApproved = doc['isApproved'] ?? false; // Fetch isApproved status
        
        // Ensure name is up to date if missing in Auth (for old users)
        if (_user != null && (_user!.displayName == null || _user!.displayName!.isEmpty)) {
           String? name = doc['name'];
           if (name != null && name.isNotEmpty) {
             // We can't await updateDisplayName here easily without triggering more loops or async complexity in this flow,
             // but we can at least know it's there. 
             // Actually, simplest is to just expose a 'userName' getter that checks both.
           }
        }

        // Save FCM Token and Listen for Firestore changes
        NotificationService().saveTokenToUser(uid);
        NotificationService().listenToNotifications(uid);
      } else {
        _role = 'pending'; // Default fallback
        _classId = null;
        _isApproved = false; // Default fallback
      }
      notifyListeners();
    } catch (e) {
      print("Error fetching role: $e");
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred";
    }
  }

  Future<String?> register(String email, String password, String name, String role, Map<String, dynamic> additionalData) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Create user record in Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'role': role, // 'pending' usually
        'createdAt': FieldValue.serverTimestamp(),
        ...additionalData, // Merge additional fields (phone, age, gender, address)
      });
      
      await cred.user!.updateDisplayName(name);
      await cred.user!.reload(); // Reload to reflect changes
      _user = _auth.currentUser; // Update local user object
      
      // Start listening
      NotificationService().listenToNotifications(cred.user!.uid);

      notifyListeners();
      
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred";
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred";
    }
  }

  Future<void> signOut() async {
    NotificationService().stopListening();
    await _auth.signOut();
  }
}
