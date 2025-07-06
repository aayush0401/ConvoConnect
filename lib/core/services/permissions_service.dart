import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionsService {
  /// Request camera and microphone permissions
  static Future<Map<String, bool>> requestMediaPermissions() async {
    try {
      print('🔐 Requesting camera and microphone permissions...');
      
      // For web platform, permissions are handled by the browser
      if (kIsWeb) {
        print('🌐 Web platform detected - permissions handled by browser');
        // On web, assume permissions are available as Jitsi Meet will handle them
        return {
          'camera': true,
          'microphone': true,
        };
      }
      
      // Check current status first
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      
      print('📹 Current camera status: $cameraStatus');
      print('🎤 Current microphone status: $micStatus');
      
      // Request permissions for mobile platforms
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

      print('📹 Camera permission: ${cameraGranted ? "GRANTED ✅" : "DENIED ❌"}');
      print('🎤 Microphone permission: ${micGranted ? "GRANTED ✅" : "DENIED ❌"}');

      return {
        'camera': cameraGranted,
        'microphone': micGranted,
      };
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      
      // For web, assume permissions are available 
      if (kIsWeb) {
        print('🌐 Web platform - returning default permissions');
        return {
          'camera': true,
          'microphone': true,
        };
      }
      
      return {
        'camera': false,
        'microphone': false,
      };
    }
  }

  /// Check current permission status
  static Future<Map<String, bool>> checkMediaPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      return {
        'camera': cameraStatus.isGranted,
        'microphone': micStatus.isGranted,
      };
    } catch (e) {
      print('❌ Error checking permissions: $e');
      return {
        'camera': false,
        'microphone': false,
      };
    }
  }

  /// Show permission rationale dialog
  static Future<bool> shouldShowPermissionRationale() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    
    return cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied;
  }

  /// Open app settings for permission management
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Check if permissions are granted for web platform
  static Future<Map<String, bool>> checkWebPermissions() async {
    if (kIsWeb) {
      // For web, we can't check permissions directly
      // Return true to allow the browser to handle permission requests
      return {
        'camera': true,
        'microphone': true,
      };
    }
    return await checkMediaPermissions();
  }
}
