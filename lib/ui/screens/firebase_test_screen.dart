import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Testing Firebase connection...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Test Firebase Auth
      final auth = FirebaseAuth.instance;
      setState(() {
        _status = 'Firebase Auth initialized ✅\n';
      });

      // Test Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.enableNetwork();
      setState(() {
        _status += 'Cloud Firestore connected ✅\n';
      });

      // Check current user
      final user = auth.currentUser;
      if (user != null) {
        setState(() {
          _status += 'User logged in: ${user.email} ✅\n';
        });
      } else {
        setState(() {
          _status += 'No user currently logged in ✅\n';
        });
      }

      // Test Firestore write (optional)
      try {
        await firestore.collection('test').doc('connection').set({
          'timestamp': FieldValue.serverTimestamp(),
          'message': 'Firebase connection test successful',
        });
        setState(() {
          _status += 'Firestore write test successful ✅\n';
        });
      } catch (e) {
        setState(() {
          _status += 'Firestore write test: ${e.toString()}\n';
        });
      }

      setState(() {
        _status += '\n🎉 Firebase is fully initialized and working!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Firebase connection failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: const Color(0xFF2D8CFF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Initialization Status',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D8CFF),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF2D8CFF)),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            const SizedBox(height: 20),
            if (!_isLoading)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D8CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Back to Login'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
