import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:flutter/foundation.dart';

class JitsiService {
  static final JitsiMeet _jitsiMeetPlugin = JitsiMeet();
  
  /// Join a meeting with the specified room name and user details
  static Future<void> joinMeeting({
    required String roomName,
    required String userDisplayName,
    String? userEmail,
    String? userAvatarURL,
    bool isAudioMuted = false,
    bool isVideoMuted = false,
  }) async {
    try {
      // Configure meeting options
      var options = JitsiMeetConferenceOptions(
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": isAudioMuted,
          "startWithVideoMuted": isVideoMuted,
          "subject": "Zoom Clone Meeting",
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "prejoinpage.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: userDisplayName,
          email: userEmail,
          avatar: userAvatarURL,
        ),
      );

      // Join the meeting
      await _jitsiMeetPlugin.join(options);
      debugPrint('🎥 Joining Jitsi meeting: $roomName');
      
    } catch (e) {
      debugPrint('❌ Error joining Jitsi meeting: $e');
      rethrow;
    }
  }
  
  /// Create a new meeting with a generated room name
  static Future<String> createMeeting({
    required String userDisplayName,
    String? userEmail,
    String? userAvatarURL,
  }) async {
    try {
      // Generate a unique room name
      final roomName = _generateRoomName();
      
      // Join the newly created meeting
      await joinMeeting(
        roomName: roomName,
        userDisplayName: userDisplayName,
        userEmail: userEmail,
        userAvatarURL: userAvatarURL,
      );
      
      debugPrint('🆕 Created new Jitsi meeting: $roomName');
      return roomName;
      
    } catch (e) {
      debugPrint('❌ Error creating Jitsi meeting: $e');
      rethrow;
    }
  }
  
  /// Leave the current meeting
  static Future<void> leaveMeeting() async {
    try {
      await _jitsiMeetPlugin.hangUp();
      debugPrint('👋 Left Jitsi meeting');
    } catch (e) {
      debugPrint('❌ Error leaving Jitsi meeting: $e');
    }
  }
  
  /// Set audio mute state
  static Future<void> setAudioMuted(bool muted) async {
    try {
      await _jitsiMeetPlugin.setAudioMuted(muted);
      debugPrint('🔊 Audio muted: $muted');
    } catch (e) {
      debugPrint('❌ Error setting audio mute: $e');
    }
  }
  
  /// Set video mute state
  static Future<void> setVideoMuted(bool muted) async {
    try {
      await _jitsiMeetPlugin.setVideoMuted(muted);
      debugPrint('📹 Video muted: $muted');
    } catch (e) {
      debugPrint('❌ Error setting video mute: $e');
    }
  }
  
  /// Send a chat message
  static Future<void> sendChatMessage(String message) async {
    try {
      await _jitsiMeetPlugin.sendChatMessage(message: message);
      debugPrint('💬 Chat message sent: $message');
    } catch (e) {
      debugPrint('❌ Error sending chat message: $e');
    }
  }
  
  /// Toggle screen sharing
  static Future<void> toggleScreenShare() async {
    try {
      await _jitsiMeetPlugin.toggleScreenShare(true);
      debugPrint('🖥️ Screen share toggled');
    } catch (e) {
      debugPrint('❌ Error toggling screen share: $e');
    }
  }
  
  /// Generate a unique room name
  static String _generateRoomName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'zoom-clone-$random';
  }
  
  /// Generate a meeting ID from room name (for display purposes)
  static String getMeetingIdFromRoom(String roomName) {
    if (roomName.startsWith('zoom-clone-')) {
      return roomName.replaceFirst('zoom-clone-', '');
    }
    return roomName;
  }
  
  /// Generate room name from meeting ID
  static String getRoomFromMeetingId(String meetingId) {
    if (meetingId.length == 4 && int.tryParse(meetingId) != null) {
      return 'zoom-clone-$meetingId';
    }
    return meetingId;
  }
  
  /// Validate meeting ID format
  static bool isValidMeetingId(String meetingId) {
    // Accept 4-digit codes or any string
    return meetingId.isNotEmpty && meetingId.length >= 3;
  }
}
