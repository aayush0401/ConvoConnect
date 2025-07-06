import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/jitsi_service.dart';
import '../../core/services/firebase_service.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  String _generatedMeetingId = '';
  bool _isVideoMuted = false;
  bool _isAudioMuted = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _generateMeetingId();
  }

  void _generateMeetingId() {
    // Generate a random meeting ID in format: abcd-1234
    final random = DateTime.now().millisecondsSinceEpoch;
    final letters = String.fromCharCodes(List.generate(4, (index) => 
        65 + (random + index) % 26)); // A-Z
    final numbers = (random % 10000).toString().padLeft(4, '0');
    
    setState(() {
      _generatedMeetingId = '${letters.toLowerCase()}-$numbers';
    });
  }

  void _copyMeetingId() {
    Clipboard.setData(ClipboardData(text: _generatedMeetingId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting ID copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _startMeeting() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final currentUser = FirebaseService.currentUser;
      final userName = currentUser?.displayName ?? 
                      currentUser?.email?.split('@')[0] ?? 
                      'Host';
      
      // Create room name from meeting ID
      final roomName = JitsiService.getRoomFromMeetingId(_generatedMeetingId);
      
      // Start Jitsi meeting with mute settings
      await JitsiService.joinMeeting(
        roomName: roomName,
        userDisplayName: userName,
        userEmail: currentUser?.email,
        isAudioMuted: _isAudioMuted,
        isVideoMuted: _isVideoMuted,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meeting started! ID: $_generatedMeetingId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Return to home screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start meeting: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF424242),
      appBar: AppBar(
        title: const Text(
          'Create New Meeting',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF424242), Color(0xFF303030)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Meeting ID Section
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Meeting ID Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF424242).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          size: 48,
                          color: Color(0xFF424242),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Meeting ID Label
                      const Text(
                        '🆔 Meeting ID',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Meeting ID Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF424242).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF424242).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _generatedMeetingId,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF424242),
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _copyMeetingId,
                              icon: const Icon(
                                Icons.copy,
                                color: Color(0xFF424242),
                                size: 20,
                              ),
                              tooltip: 'Copy Meeting ID',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Regenerate Button
                      TextButton.icon(
                        onPressed: _generateMeetingId,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Generate New ID'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Audio/Video Controls
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meeting Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Video Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isVideoMuted ? Icons.videocam_off : Icons.videocam,
                              color: _isVideoMuted ? Colors.red : Colors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Start with video muted',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                            Switch(
                              value: _isVideoMuted,
                              onChanged: (value) {
                                setState(() {
                                  _isVideoMuted = value;
                                });
                              },
                              activeColor: const Color(0xFF424242),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Audio Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isAudioMuted ? Icons.mic_off : Icons.mic,
                              color: _isAudioMuted ? Colors.red : Colors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Start with audio muted',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ),
                            Switch(
                              value: _isAudioMuted,
                              onChanged: (value) {
                                setState(() {
                                  _isAudioMuted = value;
                                });
                              },
                              activeColor: const Color(0xFF424242),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Start Meeting Button
                Container(
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _startMeeting,
                    icon: _isCreating
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
                      _isCreating ? 'Starting Meeting...' : 'Start Meeting',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424242),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Share the Meeting ID with participants to let them join',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
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
    );
  }
}
