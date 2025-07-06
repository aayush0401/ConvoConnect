import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AuthService {
  // Use Firebase service instances (from your npm config)
  FirebaseAuth get _auth => FirebaseService.auth;
  FirebaseFirestore get _firestore => FirebaseService.firestore;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password (uses npm Firebase config)
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔐 Signing in with npm Firebase config...');
      UserCredential result = await FirebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Sign in successful!');
      return result;
    } catch (e) {
      print('❌ Sign in error: $e');
      return null;
    }
  }

  // Register with email and password (uses npm Firebase config)
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      print('📝 Registering with npm Firebase config...');
      UserCredential result =
          await FirebaseService.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

      // Update display name
      await result.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserDocument(result.user!, displayName);

      print('✅ Registration successful!');
      return result;
    } catch (e) {
      print('❌ Registration error: $e');
      return null;
    }
  }

  // Sign out (uses npm Firebase config)
  Future<void> signOut() async {
    try {
      await FirebaseService.signOut();
    } catch (e) {
      print('❌ Sign out error: $e');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  // Update user's last seen
  Future<void> updateLastSeen() async {
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating last seen: $e');
      }
    }
  }

  // Get user data from Firestore
  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}
