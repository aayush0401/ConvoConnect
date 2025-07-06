// lib/core/services/firebase_service.dart
// Flutter equivalent of your npm Firebase initialization

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../firebase_options.dart';

class FirebaseService {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;

  /// Initialize Firebase (equivalent to initializeApp from npm)
  static Future<void> initializeFirebase() async {
    try {
      _app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase services
      _auth = FirebaseAuth.instanceFor(app: _app!);
      _firestore = FirebaseFirestore.instanceFor(app: _app!);

      print('🔥 Firebase initialized successfully');
      print('📱 Project ID: ${_app!.options.projectId}');
      print('🔑 API Key: ${_app!.options.apiKey.substring(0, 10)}...');
    } catch (e) {
      print('❌ Firebase initialization error: $e');
      rethrow;
    }
  }

  /// Get Firebase App instance
  static FirebaseApp get app {
    if (_app == null) {
      throw Exception(
        'Firebase not initialized. Call initializeFirebase() first.',
      );
    }
    return _app!;
  }

  /// Get Firebase Auth instance (equivalent to getAuth from npm)
  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception(
        'Firebase Auth not initialized. Call initializeFirebase() first.',
      );
    }
    return _auth!;
  }

  /// Get Firestore instance (equivalent to getFirestore from npm)
  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception(
        'Firestore not initialized. Call initializeFirebase() first.',
      );
    }
    return _firestore!;
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _app != null;

  /// Get current user
  static User? get currentUser => _auth?.currentUser;

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('❌ Sign in error: $e');
      rethrow;
    }
  }

  /// Create user with email and password
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('❌ Create user error: $e');
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow;
    }
  }

  /// Listen to auth state changes
  static Stream<User?> get authStateChanges => auth.authStateChanges();
}
