# Zoom Clone - Flutter Video Calling App

A modern video calling application built with Flutter, featuring real-time video/audio communication, screen sharing, and chat messaging capabilities similar to Zoom.

## Features

🎥 **Video Calling**
- High-quality video calls using WebRTC
- Multiple participants support
- Camera controls (on/off, switch front/back)

🎙️ **Audio Features**
- Crystal clear audio communication
- Mute/unmute functionality
- Audio-only calls support

💬 **Real-time Chat**
- In-meeting text messaging
- Message history
- Emoji support

📱 **Cross-Platform**
- iOS, Android, and Web support
- Responsive design for all screen sizes

🔐 **Security & Authentication**
- Firebase authentication
- Secure meeting rooms
- User management

## Tech Stack

- **Flutter** - Cross-platform framework
- **WebRTC** - Real-time communication
- **Socket.IO** - Real-time messaging
- **Firebase** - Authentication & backend
- **Provider/Riverpod** - State management

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd zoom_clone
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Add your `google-services.json` (Android)
   - Add your `GoogleService-Info.plist` (iOS)

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/           # Core utilities and constants
├── features/       # Feature-based modules
│   ├── auth/       # Authentication
│   ├── video_call/ # Video calling functionality
│   ├── chat/       # Chat messaging
│   └── home/       # Home screen and navigation
├── shared/         # Shared widgets and utilities
└── main.dart       # App entry point
```

## Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
