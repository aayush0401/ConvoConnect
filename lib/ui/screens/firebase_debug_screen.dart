import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({super.key});

  @override
  State<FirebaseDebugScreen> createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _status = 'Ready to test Firebase Auth';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  void _checkFirebaseStatus() {
    setState(() {
      _status = 'Firebase Apps: ${Firebase.apps.length}\n';
      _status +=
          'Current User: ${FirebaseAuth.instance.currentUser?.email ?? 'None'}\n';
      _status += 'Auth Domain: ${Firebase.app().options.authDomain}\n';
      _status += 'Project ID: ${Firebase.app().options.projectId}';
    });
  }

  Future<void> _testRegister() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _status = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Attempting to register...';
    });

    try {
      UserCredential result = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      setState(() {
        _status =
            'Registration SUCCESS!\nUser: ${result.user?.email}\nUID: ${result.user?.uid}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Registration FAILED:\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _status = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Attempting to sign in...';
    });

    try {
      UserCredential result = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      setState(() {
        _status =
            'Sign In SUCCESS!\nUser: ${result.user?.email}\nUID: ${result.user?.uid}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Sign In FAILED:\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      setState(() {
        _status = 'Signed out successfully';
      });
      _checkFirebaseStatus();
    } catch (e) {
      setState(() {
        _status = 'Sign out failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Debug'),
        backgroundColor: const Color(0xFF2D8CFF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _testRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test Register'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D8CFF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test Sign In'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _checkFirebaseStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Refresh Status'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
