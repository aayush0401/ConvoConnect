import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
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
      _joinTestMeeting();
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _meetingTimer?.cancel();
    _liveDotController.dispose();
    _recordingController.dispose();
    _chatController.dispose();
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
            Text(
              '• Camera: For video calls',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '• Microphone: For audio calls',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializePermissions();
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Exit meeting
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _joinTestMeeting() {
    setState(() {
      _jitsiMeetJoined = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.video_call, color: Colors.white),
            SizedBox(width: 8),
            Text('Connected to meeting room: ${widget.roomName}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _startMeetingTimer() {
    _meetingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _meetingDuration = Duration(seconds: _meetingDuration.inSeconds + 1);
        });
      }
    });
  }

  void _setupControlsAutoHide() {
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleMic() {
    setState(() {
      _isMicOn = !_isMicOn;
    });
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMicOn ? 'Microphone enabled' : 'Microphone disabled'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOn = !_isCameraOn;
    });
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCameraOn ? 'Camera enabled' : 'Camera disabled'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _leaveMeeting() async {
    if (_isLeaving) return;

    setState(() {
      _isLeaving = true;
    });

    try {
      // Update meeting status in Firebase
      await MeetingService.updateMeetingStatus(widget.meetingId, 'ended');
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error leaving meeting: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = true;
          });
          _resetControlsTimer();
        },
        child: Stack(
          children: [
            // Video area - placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Meeting ID: ${widget.meetingId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top status bar
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live indicator
                    AnimatedBuilder(
                      animation: _liveDotController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(
                                    0.5 + 0.5 * _liveDotController.value,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Meeting duration
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDuration(_meetingDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Microphone toggle
                      _buildControlButton(
                        icon: _isMicOn ? Icons.mic : Icons.mic_off,
                        onTap: _toggleMic,
                        isActive: _isMicOn,
                        backgroundColor: _isMicOn ? Colors.grey[800]! : Colors.red,
                      ),

                      // Camera toggle
                      _buildControlButton(
                        icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                        onTap: _toggleCamera,
                        isActive: _isCameraOn,
                        backgroundColor: _isCameraOn ? Colors.grey[800]! : Colors.red,
                      ),

                      // End call
                      _buildControlButton(
                        icon: Icons.call_end,
                        onTap: _leaveMeeting,
                        backgroundColor: Colors.red,
                      ),
                    ],
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
    required VoidCallback onTap,
    Color? backgroundColor,
    bool isActive = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
