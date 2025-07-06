# Copilot Instructions for Zoom Clone Flutter Project

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

This is a Flutter project for building a Zoom clone video calling application.

## Project Context
- **Framework**: Flutter (Dart)
- **Target Platforms**: iOS, Android, Web
- **Main Features**: Video calling, audio calling, screen sharing, chat messaging, meeting rooms

## Key Dependencies & Technologies
- **WebRTC**: For peer-to-peer video/audio communication
- **Socket.IO**: For real-time messaging and signaling
- **Firebase**: For authentication and backend services
- **Provider/Riverpod**: For state management
- **Camera**: For camera access and controls
- **Permission Handler**: For managing device permissions

## Code Style Guidelines
- Follow Dart/Flutter naming conventions
- Use meaningful widget names and class names
- Implement proper error handling for network operations
- Use async/await for asynchronous operations
- Organize code into feature-based folder structure
- Write widget tests for critical UI components

## Architecture Patterns
- Use MVVM or Clean Architecture principles
- Separate business logic from UI components
- Implement proper dependency injection
- Use repository pattern for data layer

## Security Considerations
- Implement proper authentication flows
- Handle sensitive data securely
- Validate all user inputs
- Use HTTPS for all network communications
