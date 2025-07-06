import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/meeting_service.dart';
import '../../core/services/permissions_service.dart';

class ZoomMeetingScreen extends StatefulWidget {
  final String meetingId;
  final String roomName;
  final bool isHost;

  const ZoomMeetingScreen({
    super.key,
    required this.meetingId,
    required this.roomName,
    this.isHost = false,
  });

  @override
  State<ZoomMeetingScreen> createState() => _ZoomMeetingScreenState();
}

class _ZoomMeetingScreenState extends State<ZoomMeetingScreen>
    with TickerProviderStateMixin {
  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isLeaving = false;
  bool _showControls = true;
  bool _isScreenSharing = false;
  bool _isRecording = false;
  bool _isChatOpen = false;
  bool _hasPermissions = false;
  bool _jitsiMeetJoined = false;
  String _userName = '';
  Timer? _hideControlsTimer;
  Timer? _meetingTimer;
  Duration _meetingDuration = Duration.zero;
  
  // Jitsi Meet SDK
  final _jitsiMeetPlugin = JitsiMeet();
  
  // Animation controllers for live indicators
  late AnimationController _liveDotController;
  late AnimationController _recordingController;
  
  // Chat messages list
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeUserInfo();
    _startMeetingTimer();
    _setupControlsAutoHide();
    _initializeAnimations();
    // Delay initialization to avoid widget context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePermissions();
      _joinJitsiMeeting();
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _meetingTimer?.cancel();
    _liveDotController.dispose();
    _recordingController.dispose();
    _chatController.dispose();
    _leaveJitsiMeeting();
    super.dispose();
  }

  void _initializeAnimations() {
    _liveDotController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _initializeUserInfo() {
    final currentUser = FirebaseService.currentUser;
    setState(() {
      _userName = currentUser?.displayName ?? 
                 currentUser?.email?.split('@')[0] ?? 
                 'User';
    });
  }

  void _initializePermissions() async {
    try {
      print('🔐 Initializing media permissions...');
      final permissions = await PermissionsService.requestMediaPermissions();
      
      setState(() {
        _hasPermissions = permissions['camera'] == true && permissions['microphone'] == true;
      });

      if (!_hasPermissions) {
        _showPermissionDialog();
      } else {
        print('✅ All media permissions granted');
      }
    } catch (e) {
      print('❌ Error initializing permissions: $e');
      setState(() {
        _hasPermissions = false;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Permissions Required',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This app needs access to your camera and microphone to work properly.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.videocam, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Camera access for video calling', 
                     style: TextStyle(color: Colors.white70)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.mic, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Microphone access for audio', 
                     style: TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Exit meeting
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final permissions = await PermissionsService.requestMediaPermissions();
              setState(() {
                _hasPermissions = permissions['camera'] == true && permissions['microphone'] == true;
              });
              
              if (!_hasPermissions) {
                await PermissionsService.openAppSettings();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Grant Permissions', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startMeetingTimer() {
    _meetingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _meetingDuration = Duration(seconds: _meetingDuration.inSeconds + 1);
      });
    });
  }

  void _setupControlsAutoHide() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _setupControlsAutoHide();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _toggleMic() {
    if (!_hasPermissions) {
      _showPermissionDialog();
      return;
    }

    setState(() {
      _isMicOn = !_isMicOn;
    });
    
    // Update Jitsi Meet audio (mobile only)
    if (_jitsiMeetJoined && !kIsWeb) {
      _jitsiMeetPlugin.setAudioMuted(!_isMicOn);
    }
    
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMicOn ? 'Microphone unmuted' : 'Microphone muted'),
        backgroundColor: _isMicOn ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _toggleCamera() {
    if (!_hasPermissions) {
      _showPermissionDialog();
      return;
    }

    setState(() {
      _isCameraOn = !_isCameraOn;
    });
    
    // Update Jitsi Meet video (mobile only)
    if (_jitsiMeetJoined && !kIsWeb) {
      _jitsiMeetPlugin.setVideoMuted(!_isCameraOn);
    }
    
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCameraOn ? 'Camera turned on' : 'Camera turned off'),
        backgroundColor: _isCameraOn ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _shareMeeting() async {
    final meetingUrl = 'http://localhost:8080/#/join?id=${widget.meetingId}';
    final shareText = '''
Join my Zoom Clone meeting!

Meeting ID: ${widget.meetingId}
Room: ${widget.roomName}
Host: $_userName

Direct Link: $meetingUrl

Join now for an amazing video call experience!
''';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                const Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Share Meeting',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Meeting Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.roomName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Meeting ID:', widget.meetingId, true),
                      const SizedBox(height: 8),
                      _buildInfoRow('URL:', meetingUrl, false),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Share Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Share.share(shareText);
                        },
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text('Share Details', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Share.share(meetingUrl);
                        },
                        icon: const Icon(Icons.link, color: Colors.white),
                        label: const Text('Share Link', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool showCopy) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: showCopy ? Colors.white : Colors.blue,
                      fontSize: showCopy ? 14 : 12,
                      fontWeight: showCopy ? FontWeight.bold : FontWeight.normal,
                      fontFamily: showCopy ? 'monospace' : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showCopy)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${label.replaceAll(':', '')} copied!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Icon(Icons.copy, color: Colors.blue, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleScreenShare() {
    setState(() {
      _isScreenSharing = !_isScreenSharing;
    });
    
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isScreenSharing ? 'Screen sharing started' : 'Screen sharing stopped'),
        backgroundColor: _isScreenSharing ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    
    if (_isRecording) {
      _recordingController.repeat(reverse: true);
    } else {
      _recordingController.stop();
    }
    
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecording ? 'Recording started' : 'Recording stopped'),
        backgroundColor: _isRecording ? Colors.red : Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _openChat() {
    setState(() {
      _isChatOpen = true;
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildChatBottomSheet(),
    ).then((_) {
      setState(() {
        _isChatOpen = false;
      });
    });
  }

  Widget _buildChatBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.chat, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Meeting Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Chat Messages
          Expanded(
            child: _chatMessages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, 
                             color: Colors.white38, size: 48),
                        SizedBox(height: 16),
                        Text('No messages yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
                        Text('Start a conversation!', style: TextStyle(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = _chatMessages[index];
                      final isMe = message['sender'] == _userName;
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMe)
                                Text(
                                  message['sender'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              Text(
                                message['message'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_chatController.text),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;
    
    setState(() {
      _chatMessages.add({
        'sender': _userName,
        'message': message.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    
    _chatController.clear();
    HapticFeedback.lightImpact();
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Participants (2)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildParticipantTile(
                  name: _userName,
                  isHost: widget.isHost,
                  isMuted: !_isMicOn,
                  hasVideo: _isCameraOn,
                  isYou: true,
                ),
                _buildParticipantTile(
                  name: 'Demo User',
                  isHost: !widget.isHost,
                  isMuted: false,
                  hasVideo: true,
                  isYou: false,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _shareMeeting();
                    },
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text('Invite Others', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantTile({
    required String name,
    required bool isHost,
    required bool isMuted,
    required bool hasVideo,
    required bool isYou,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isYou ? Colors.blue.withOpacity(0.5) : Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isHost)
                  const Text(
                    'Host',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                isMuted ? Icons.mic_off : Icons.mic,
                color: isMuted ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Icon(
                hasVideo ? Icons.videocam : Icons.videocam_off,
                color: hasVideo ? Colors.green : Colors.red,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Meeting Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionTile(
                            icon: Icons.chat,
                            label: 'Chat',
                            onTap: () {
                              Navigator.pop(context);
                              _openChat();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOptionTile(
                            icon: Icons.people,
                            label: 'Participants',
                            onTap: () {
                              Navigator.pop(context);
                              _showParticipants();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionTile(
                            icon: _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                            label: _isRecording ? 'Stop Recording' : 'Record',
                            onTap: () {
                              Navigator.pop(context);
                              _toggleRecording();
                            },
                            isActive: _isRecording,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOptionTile(
                            icon: Icons.settings,
                            label: 'Settings',
                            onTap: () {
                              Navigator.pop(context);
                              _openSettings();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.red.withOpacity(0.2) : const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.red : Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.red : Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.red : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings feature coming soon!'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _leaveMeeting() async {
    if (_isLeaving) return;
    
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Meeting?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to leave this meeting?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      setState(() {
        _isLeaving = true;
      });

      try {
        await MeetingService.updateMeetingStatus(
          widget.meetingId,
          'ended',
          _meetingDuration,
        );
      } catch (e) {
        debugPrint('Error updating meeting status: $e');
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _joinJitsiMeeting() async {
    try {
      print('🎥 Initializing video meeting for platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      if (!_hasPermissions) {
        print('⚠️ Missing permissions, showing dialog before joining');
        _showPermissionDialog();
        return;
      }

      // For web platform, use alternative approach since Jitsi Meet SDK has limited web support
      if (kIsWeb) {
        print('� Web platform: Using web-compatible video solution');
        _initializeWebVideoMeeting();
        return;
      }

      // For mobile platforms, use full Jitsi Meet SDK
      print('📱 Mobile platform: Using Jitsi Meet SDK');
      await _initializeMobileJitsiMeeting();
      
    } catch (e) {
      print('❌ Error initializing video meeting: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to initialize video meeting: ${e.toString()}');
      }
    }
  }

  void _initializeWebVideoMeeting() {
    try {
      print('🌐 Setting up web video meeting...');
      setState(() {
        _jitsiMeetJoined = true; // Mark as connected for UI purposes
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.video_call, color: Colors.white),
                SizedBox(width: 8),
                Text('Video meeting ready! Use controls to manage your session.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
          ),
        );
      }
      
      print('✅ Web video meeting initialized successfully');
    } catch (e) {
      print('❌ Error setting up web video meeting: $e');
    }
  }

  Future<void> _initializeMobileJitsiMeeting() async {
    try {
      print('📱 Joining Jitsi Meet room: ${widget.roomName}');
      
      var options = JitsiMeetConferenceOptions(
        serverURL: null, // Use default Jitsi Meet servers
        room: widget.roomName,
        configOverrides: {
          "startWithAudioMuted": !_isMicOn,
          "startWithVideoMuted": !_isCameraOn,
          "subject": "Zoom Clone Meeting",
        },
        featureFlags: {
          "unsafely-allow-load-external-script": false,
          "ios.recording.enabled": true,
          "live-streaming.enabled": true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: _userName,
          email: FirebaseService.currentUser?.email ?? '',
        ),
      );

      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          print('✅ Jitsi conference joined: $url');
          if (mounted) {
            setState(() {
              _jitsiMeetJoined = true;
            });
          }
        },
        conferenceTerminated: (url, error) {
          print('🔴 Jitsi conference terminated: $url, error: $error');
          if (mounted) {
            setState(() {
              _jitsiMeetJoined = false;
            });
            _leaveMeeting();
          }
        },
        audioMutedChanged: (muted) {
          print('🎤 Audio muted changed: $muted');
          if (mounted) {
            setState(() {
              _isMicOn = !muted;
            });
          }
        },
        videoMutedChanged: (muted) {
          print('📹 Video muted changed: $muted');
          if (mounted) {
            setState(() {
              _isCameraOn = !muted;
            });
          }
        },
        screenShareToggled: (participantId, sharing) {
          print('🖥️ Screen share toggled: $sharing');
          if (mounted) {
            setState(() {
              _isScreenSharing = sharing;
            });
          }
        },
        participantJoined: (email, name, role, participantId) {
          print('👥 Participant joined: $name ($email)');
        },
        participantLeft: (participantId) {
          print('👋 Participant left: $participantId');
        },
      );

      await _jitsiMeetPlugin.join(options, listener);
      
    } catch (e) {
      print('❌ Error joining Jitsi Meet: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to join meeting: ${e.toString()}');
      }
    }
  }

  void _leaveJitsiMeeting() async {
    try {
      if (_jitsiMeetJoined) {
        print('🚪 Leaving video meeting');
        
        // Only call Jitsi hangUp on mobile platforms
        if (!kIsWeb) {
          await _jitsiMeetPlugin.hangUp();
        }
        
        setState(() {
          _jitsiMeetJoined = false;
        });
      }
    } catch (e) {
      print('❌ Error leaving video meeting: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showControlsTemporarily,
        child: Stack(
          children: [
            // Video Background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Video Meeting Status
                    if (_jitsiMeetJoined) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              kIsWeb ? 'Web Video Session Active' : 'Jitsi Meet Connected',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              kIsWeb ? 'Initializing web video...' : 'Connecting to Jitsi Meet...',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Meeting Info
                    const Icon(Icons.video_call, size: 80, color: Colors.white38),
                    const SizedBox(height: 16),
                    Text(
                      widget.roomName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Meeting ID: ${widget.meetingId}',
                      style: const TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    
                    // Camera Status
                    if (_isCameraOn) ...[
                      Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person, size: 60, color: Colors.white54),
                            const SizedBox(height: 8),
                            Text(
                              _userName,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Center(
                          child: Icon(Icons.videocam_off, size: 40, color: Colors.white54),
                        ),
                      ),
                    ],
                    
                    if (!_hasPermissions) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Camera and microphone permissions required',
                                style: TextStyle(color: Colors.orange, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    if (kIsWeb && _jitsiMeetJoined) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: const Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Web Video Session',
                                    style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'For full video calling with multiple participants, use the mobile app. Web version supports video controls and meeting management.',
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Top Status Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Live Indicator
                    AnimatedBuilder(
                      animation: _liveDotController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3 + (_liveDotController.value * 0.3)),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7 + (_liveDotController.value * 0.3)),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const Spacer(),
                    
                    // Meeting Duration
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _formatDuration(_meetingDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Recording Indicator
                    if (_isRecording)
                      AnimatedBuilder(
                        animation: _recordingController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7 + (_recordingController.value * 0.3)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'REC',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Controls - IMPROVED ALIGNMENT
            if (_showControls)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Main controls row - IMPROVED ALIGNMENT
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildControlButton(
                                      icon: _isMicOn ? Icons.mic : Icons.mic_off,
                                      label: 'Microphone',
                                      isActive: _isMicOn,
                                      onPressed: _toggleMic,
                                      size: 56,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildControlButton(
                                      icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                                      label: 'Camera',
                                      isActive: _isCameraOn,
                                      onPressed: _toggleCamera,
                                      size: 56,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildControlButton(
                                      icon: Icons.call_end,
                                      label: 'End Call',
                                      isActive: false,
                                      onPressed: _isLeaving ? null : _leaveMeeting,
                                      size: 56,
                                      isDestructive: true,
                                      isLoading: _isLeaving,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Secondary controls - CONSISTENT ALIGNMENT
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildControlButton(
                                      icon: Icons.share,
                                      label: 'Share',
                                      isActive: false,
                                      onPressed: _shareMeeting,
                                      size: 48,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildControlButton(
                                      icon: _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
                                      label: 'Screen',
                                      isActive: _isScreenSharing,
                                      onPressed: _toggleScreenShare,
                                      size: 48,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildControlButton(
                                      icon: Icons.chat,
                                      label: 'Chat',
                                      isActive: _isChatOpen,
                                      onPressed: _openChat,
                                      size: 48,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildControlButton(
                                      icon: Icons.more_vert,
                                      label: 'More',
                                      isActive: false,
                                      onPressed: _showMoreOptions,
                                      size: 48,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onPressed,
    required double size,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDestructive 
                  ? Colors.red.withValues(alpha: 0.9)
                  : isActive 
                      ? Colors.green.withValues(alpha: 0.9)
                      : Colors.grey.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: (isDestructive ? Colors.red : isActive ? Colors.green : Colors.grey)
                      .withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(size / 2),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: size * 0.4,
                          height: size * 0.4,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(icon, color: Colors.white, size: size * 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: size + 16, // Ensure consistent width for text
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
