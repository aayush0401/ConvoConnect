import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';
import 'firebase_service.dart';

class MeetingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _meetingsCollection = 'meetings';
  static const String _userMeetingsCollection = 'user_meetings';

  /// Create a new meeting in Firebase
  static Future<String> createMeeting({
    required String meetingId,
    required String roomName,
    required String hostName,
    String? title,
  }) async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final meetingDocId = _firestore.collection(_meetingsCollection).doc().id;
      
      final meeting = MeetingModel(
        id: meetingDocId,
        meetingId: meetingId,
        roomName: roomName,
        hostId: currentUser.uid,
        hostName: hostName,
        createdAt: DateTime.now(),
        participants: [currentUser.uid],
        status: 'active',
        title: title,
      );

      // Save meeting to meetings collection with Firestore timestamp
      final meetingData = meeting.toMap();
      meetingData['createdAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(_meetingsCollection)
          .doc(meetingDocId)
          .set(meetingData);

      // Add to user's meetings collection
      await _addToUserMeetings(currentUser.uid, meetingDocId, 'created');

      print('✅ Meeting created in Firebase: $meetingId');
      return meetingDocId;
    } catch (e) {
      print('❌ Error creating meeting: $e');
      rethrow;
    }
  }

  /// Join an existing meeting
  static Future<void> joinMeeting({
    required String meetingId,
    required String userName,
  }) async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find meeting by meetingId
      final querySnapshot = await _firestore
          .collection(_meetingsCollection)
          .where('meetingId', isEqualTo: meetingId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Meeting not found or has ended');
      }

      final meetingDoc = querySnapshot.docs.first;
      final meetingData = meetingDoc.data();
      final participants = List<String>.from(meetingData['participants'] ?? []);

      // Add user to participants if not already present
      if (!participants.contains(currentUser.uid)) {
        participants.add(currentUser.uid);

        await meetingDoc.reference.update({
          'participants': participants,
        });

        // Add to user's meetings collection
        await _addToUserMeetings(currentUser.uid, meetingDoc.id, 'joined');
      }

      print('✅ User joined meeting: $meetingId');
    } catch (e) {
      print('❌ Error joining meeting: $e');
      rethrow;
    }
  }

  /// End a meeting
  static Future<void> endMeeting({
    required String meetingId,
    required int duration,
  }) async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find meeting by meetingId
      final querySnapshot = await _firestore
          .collection(_meetingsCollection)
          .where('meetingId', isEqualTo: meetingId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final meetingDoc = querySnapshot.docs.first;
        
        await meetingDoc.reference.update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
          'duration': duration,
        });

        print('✅ Meeting ended: $meetingId');
      }
    } catch (e) {
      print('❌ Error ending meeting: $e');
      rethrow;
    }
  }

  /// Get user's meeting history
  static Future<List<MeetingModel>> getUserMeetings({
    String? userId,
    int limit = 20,
  }) async {
    try {
      final currentUser = FirebaseService.currentUser;
      final targetUserId = userId ?? currentUser?.uid;
      
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get meetings where user is host or participant
      final querySnapshot = await _firestore
          .collection(_meetingsCollection)
          .where('participants', arrayContains: targetUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting user meetings: $e');
      return [];
    }
  }

  /// Get active meetings
  static Future<List<MeetingModel>> getActiveMeetings() async {
    try {
      final querySnapshot = await _firestore
          .collection(_meetingsCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting active meetings: $e');
      return [];
    }
  }

  /// Get meeting by ID
  static Future<MeetingModel?> getMeetingById(String meetingId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_meetingsCollection)
          .where('meetingId', isEqualTo: meetingId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return MeetingModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Error getting meeting: $e');
      return null;
    }
  }

  /// Remove user from meeting (when they leave)
  static Future<void> leaveMeeting({
    required String meetingId,
  }) async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find meeting by meetingId
      final querySnapshot = await _firestore
          .collection(_meetingsCollection)
          .where('meetingId', isEqualTo: meetingId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final meetingDoc = querySnapshot.docs.first;
        final meetingData = meetingDoc.data();
        final participants = List<String>.from(meetingData['participants'] ?? []);

        // Remove user from participants
        participants.remove(currentUser.uid);

        await meetingDoc.reference.update({
          'participants': participants,
        });

        // If no participants left and user was host, end the meeting
        if (participants.isEmpty && meetingData['hostId'] == currentUser.uid) {
          await meetingDoc.reference.update({
            'status': 'ended',
            'endedAt': FieldValue.serverTimestamp(),
          });
        }

        print('✅ User left meeting: $meetingId');
      }
    } catch (e) {
      print('❌ Error leaving meeting: $e');
      rethrow;
    }
  }

  /// Add meeting to user's personal collection
  static Future<void> _addToUserMeetings(
    String userId,
    String meetingDocId,
    String action,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_userMeetingsCollection)
          .doc(meetingDocId)
          .set({
        'meetingDocId': meetingDocId,
        'action': action, // 'created' or 'joined'
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error adding to user meetings: $e');
    }
  }

  /// Get meeting statistics for user
  static Future<Map<String, int>> getMeetingStats({String? userId}) async {
    try {
      final currentUser = FirebaseService.currentUser;
      final targetUserId = userId ?? currentUser?.uid;
      
      if (targetUserId == null) {
        return {'created': 0, 'joined': 0, 'total': 0};
      }

      final meetings = await getUserMeetings(userId: targetUserId, limit: 1000);
      
      int created = 0;
      int joined = 0;
      
      for (final meeting in meetings) {
        if (meeting.hostId == targetUserId) {
          created++;
        } else {
          joined++;
        }
      }

      return {
        'created': created,
        'joined': joined,
        'total': meetings.length,
      };
    } catch (e) {
      print('❌ Error getting meeting stats: $e');
      return {'created': 0, 'joined': 0, 'total': 0};
    }
  }

  /// Listen to real-time meeting updates
  static Stream<List<MeetingModel>> watchUserMeetings({String? userId}) {
    try {
      final currentUser = FirebaseService.currentUser;
      final targetUserId = userId ?? currentUser?.uid;
      
      if (targetUserId == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection(_meetingsCollection)
          .where('participants', arrayContains: targetUserId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => MeetingModel.fromMap(doc.data()))
              .toList());
    } catch (e) {
      print('❌ Error watching meetings: $e');
      return Stream.value([]);
    }
  }

  /// Update meeting status and duration when meeting ends
  static Future<void> updateMeetingStatus(
    String meetingId,
    String status,
    Duration? duration,
  ) async {
    try {
      // Find the meeting by meetingId
      final querySnapshot = await _firestore
          .collection(_meetingsCollection)
          .where('meetingId', isEqualTo: meetingId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('⚠️ Meeting not found: $meetingId');
        return;
      }

      final docId = querySnapshot.docs.first.id;
      final updateData = <String, dynamic>{
        'status': status,
        'endedAt': FieldValue.serverTimestamp(),
      };

      if (duration != null) {
        updateData['duration'] = duration.inSeconds;
      }

      await _firestore
          .collection(_meetingsCollection)
          .doc(docId)
          .update(updateData);

      print('✅ Meeting status updated: $meetingId -> $status');
    } catch (e) {
      print('❌ Error updating meeting status: $e');
      rethrow;
    }
  }
}
