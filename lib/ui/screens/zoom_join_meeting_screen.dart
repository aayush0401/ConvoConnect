import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/jitsi_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/meeting_service.dart';
import 'zoom_meeting_screen.dart';

class ZoomJoinMeetingScreen extends StatefulWidget {
  const ZoomJoinMeetingScreen({super.key});

  @override
  State<ZoomJoinMeetingScreen> createState() => _ZoomJoinMeetingScreenState();
}

class _ZoomJoinMeetingScreenState extends State<ZoomJoinMeetingScreen> {
  final _meetingIdController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isJoining = false;
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _initializeUserInfo();
  }

  @override
  void dispose() {
    _meetingIdController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _initializeUserInfo() {
    final currentUser = FirebaseService.currentUser;
    setState(() {
      _userName = currentUser?.displayName ?? 
                 currentUser?.email?.split('@')[0] ?? 
                 'User';
    });
    _displayNameController.text = _userName;
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _joinMeeting() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isJoining = true;
      });

      HapticFeedback.mediumImpact();

      try {
        final meetingId = _meetingIdController.text.trim();
        final displayName = _displayNameController.text.trim();
        final currentUser = FirebaseService.currentUser;
        
        // Convert meeting ID to room name
        final roomName = JitsiService.getRoomFromMeetingId(meetingId);
        
        // Join meeting in Firebase first
        await MeetingService.joinMeeting(
          meetingId: meetingId,
          userName: displayName,
        );
        
        // Join Jitsi meeting
        await JitsiService.joinMeeting(
          roomName: roomName,
          userDisplayName: displayName,
          userEmail: currentUser?.email,
          isAudioMuted: !_isAudioEnabled,
          isVideoMuted: !_isVideoEnabled,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joining meeting: $meetingId'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
            ),
          );
          
          // Navigate to Zoom-style meeting screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ZoomMeetingScreen(
                meetingId: meetingId,
                roomName: roomName,
                isHost: false,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to join meeting: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isJoining = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Join Meeting',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1A1A1A),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // User Preview Section
                  Center(
                    child: Column(
                      children: [
                        // User Avatar
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF424242),
                                const Color(0xFF303030),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: _isVideoEnabled 
                                  ? Colors.green.withOpacity(0.6)
                                  : Colors.white.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: _isVideoEnabled
                                ? Text(
                                    _userName.isNotEmpty 
                                        ? _userName[0].toUpperCase() 
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const Icon(
                                    Icons.videocam_off,
                                    size: 40,
                                    color: Colors.white70,
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Preview controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Audio toggle
                            _buildPreviewControl(
                              icon: _isAudioEnabled ? Icons.mic : Icons.mic_off,
                              isActive: _isAudioEnabled,
                              onPressed: _toggleAudio,
                            ),
                            
                            const SizedBox(width: 20),
                            
                            // Video toggle
                            _buildPreviewControl(
                              icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                              isActive: _isVideoEnabled,
                              onPressed: _toggleVideo,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Meeting ID Input
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🆔 Meeting ID',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _meetingIdController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter meeting ID (e.g., abcd-1234)',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.meeting_room,
                              color: Colors.white70,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a meeting ID';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Display Name Input
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '👤 Your Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _displayNameController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your display name',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.white70,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Join Meeting Button
                  Container(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isJoining ? null : _joinMeeting,
                      icon: _isJoining
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.video_call, size: 28),
                      label: Text(
                        _isJoining ? 'Joining Meeting...' : 'Join Meeting',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade300,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Make sure you have the correct Meeting ID from the host',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade200,
                              height: 1.4,
                            ),
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
    );
  }

  Widget _buildPreviewControl({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Center(
            child: Icon(
              icon,
              color: isActive ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
