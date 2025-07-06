import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/firebase_service.dart';
import 'core/services/meeting_service.dart';
import 'core/models/meeting_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseService.initializeFirebase();
    print('🚀 Firebase initialized successfully');
    
    // Test meeting service
    await testMeetingService();
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> testMeetingService() async {
  print('\n🧪 Testing Meeting Service...');
  
  try {
    // Test getUserMeetings
    print('📝 Testing getUserMeetings...');
    final meetings = await MeetingService.getUserMeetings();
    print('✅ Found ${meetings.length} meetings');
    for (final meeting in meetings) {
      print('   - ${meeting.meetingId}: ${meeting.status} (${meeting.participants.length} participants)');
    }
    
    // Test watchUserMeetings stream
    print('\n📡 Testing watchUserMeetings stream...');
    final stream = MeetingService.watchUserMeetings();
    await for (final streamMeetings in stream.take(1)) {
      print('✅ Stream returned ${streamMeetings.length} meetings');
      for (final meeting in streamMeetings) {
        print('   - ${meeting.meetingId}: ${meeting.status} (created: ${meeting.createdAt})');
      }
      break; // Just test one iteration
    }
    
    // Test stats
    print('\n📊 Testing meeting stats...');
    final stats = await MeetingService.getMeetingStats();
    print('✅ Stats: $stats');
    
  } catch (e, stack) {
    print('❌ Error testing meeting service: $e');
    print('Stack trace: $stack');
  }
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Meeting Service Test')),
        body: const Center(
          child: Text('Check console for test results'),
        ),
      ),
    );
  }
}
