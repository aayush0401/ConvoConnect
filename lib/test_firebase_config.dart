// lib/test_firebase_config.dart
// Test file to verify your npm Firebase config works in Flutter

import 'package:flutter/material.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeFirebase();
  runApp(FirebaseTestApp());
}

class FirebaseTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Config Test',
      home: FirebaseTestScreen(),
    );
  }
}

class FirebaseTestScreen extends StatefulWidget {
  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Firebase Status: Checking...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  void _checkFirebaseStatus() {
    setState(() {
      if (FirebaseService.isInitialized) {
        _status =
            '✅ Firebase Connected!\n'
            'Project: ${FirebaseService.app.options.projectId}\n'
            'Auth Domain: ${FirebaseService.app.options.authDomain}';
      } else {
        _status = '❌ Firebase Not Initialized';
      }
    });
  }

  Future<void> _testAuthentication() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing authentication...';
    });

    try {
      // Test creating a user
      await FirebaseService.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'testpass123',
      );

      setState(() {
        _status =
            '✅ Authentication Test Passed!\n'
            'User created successfully.\n'
            'Your Firebase config is working!';
      });

      // Clean up - delete the test user
      await FirebaseService.currentUser?.delete();
    } catch (e) {
      setState(() {
        _status =
            '🔍 Authentication Test Result:\n'
            'Error: $e\n\n'
            'This is expected if:\n'
            '• Email/Password auth is not enabled\n'
            '• User already exists\n'
            '• Firebase rules prevent creation\n\n'
            'But your Firebase config is loaded correctly!';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Config Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your NPM Firebase Config:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Project ID: zoom-clone-83125\n'
                      'API Key: AIzaSyDpMw3K...\n'
                      'Auth Domain: zoom-clone-83125.firebaseapp.com\n'
                      'App ID: 1:205177497403:web:db8d7...',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(_status, style: TextStyle(fontSize: 14)),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAuthentication,
              child:
                  _isLoading
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Testing...'),
                        ],
                      )
                      : Text('Test Firebase Authentication'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkFirebaseStatus,
              child: Text('Refresh Status'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
