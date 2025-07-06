// lib/main_complete_test.dart
// Complete test of Firebase integration with your npm config

import 'package:flutter/material.dart';
import 'core/services/firebase_service.dart';
import 'core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await FirebaseService.initializeFirebase();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
  
  runApp(CompleteTestApp());
}

class CompleteTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complete Firebase Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: CompleteTestScreen(),
    );
  }
}

class CompleteTestScreen extends StatefulWidget {
  @override
  _CompleteTestScreenState createState() => _CompleteTestScreenState();
}

class _CompleteTestScreenState extends State<CompleteTestScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'test123456');
  
  String _status = 'Ready for testing';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Firebase Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Firebase Status Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔥 Firebase Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (FirebaseService.isInitialized) ...[
                      Text('✅ Status: Connected'),
                      Text('📱 Project: ${FirebaseService.app.options.projectId}'),
                      Text('🔗 Auth Domain: ${FirebaseService.app.options.authDomain}'),
                      Text('👤 Current User: ${_authService.currentUser?.email ?? "Not signed in"}'),
                    ] else
                      Text('❌ Firebase not initialized'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Test Controls
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Authentication Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testRegister,
                            icon: Icon(Icons.person_add),
                            label: Text('Test Register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testLogin,
                            icon: Icon(Icons.login),
                            label: Text('Test Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_authService.currentUser != null) ...[
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testSignOut,
                        icon: Icon(Icons.logout),
                        label: Text('Test Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Status Display
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Test Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_isLoading)
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Testing...'),
                        ],
                      )
                    else
                      Text(_status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testRegister() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing registration...';
    });

    try {
      final result = await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        'Test User',
      );
      
      setState(() {
        if (result != null) {
          _status = '✅ Registration successful!\nUser: ${result.user?.email}';
        } else {
          _status = '❌ Registration failed';
        }
      });
    } catch (e) {
      setState(() {
        _status = '❌ Registration error: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing login...';
    });

    try {
      final result = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      setState(() {
        if (result != null) {
          _status = '✅ Login successful!\nUser: ${result.user?.email}';
        } else {
          _status = '❌ Login failed';
        }
      });
    } catch (e) {
      setState(() {
        _status = '❌ Login error: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testSignOut() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing sign out...';
    });

    try {
      await _authService.signOut();
      setState(() {
        _status = '✅ Sign out successful!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Sign out error: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
