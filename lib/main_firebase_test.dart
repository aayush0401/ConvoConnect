import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_web_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseWebOptions);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            child: Text("Test Sign In"),
            onPressed: () async {
              try {
                await _auth.signInWithEmailAndPassword(
                  email: "testuser@gmail.com",
                  password: "testpass123",
                );
                print("✅ Login Success!");
              } catch (e) {
                print("❌ Sign in error: $e");
              }
            },
          ),
        ),
      ),
    );
  }
}
