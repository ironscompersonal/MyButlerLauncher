# Project Handover: MY AI BUTLER Launcher

## 1. Project Overview
- **Goal**: A premium Android Home Launcher powered by Gemini 2.5.
- **Key Features**: 
  - AI-driven insight summaries (Calendar, Gmail, Notifications).
  - Voice/Chat command control for Google Home devices via Function Calling.
  - Minimalist, glassmorphism-based UI.

## 2. Technical Stack
- **Flutter/Dart**: Framework (Targeting Dart SDK compatible with `google_generative_ai: ^0.4.7`).
- **Gemini (Google Generative AI)**: **Gemini 2.5 Flash** (v1beta endpoint).
- **Google APIs**: HomeGraph (Smart Home integration).

## 3. Current Implementation Status
### ✅ Implemented & Working
- **AI Intelligence**: `AIInsightService` and `ChatService` are fully functional with Gemini 2.5.
- **System Instruction**: Professional butler persona implemented.
- **Function Calling**: `ChatService` can now emit commands for `SmartHomeService` (OnOff, Temperature, etc.).
- **Build Environment**: Resolved Gradle and dependency conflicts. App runs smoothly on physical Android devices.

### ⚠️ Pending / Next Tasks
- **App Drawer Enhancement**: 
  - Icons are currently generic. Need to modify Kotlin `MainActivity.kt` to fetch app icons as ByteArrays and display them in Flutter.
- **Google Home Integration**: 
  - `SmartHomeService` is ready but requires verification with real devices/service accounts in a production-like environment.
- **Notification Listener**:
  - Refine parsing for complex notifications (e.g., summary of multiple chat messages).

## 4. Critical Knowledge for Future Work
- **Model Choice**: Use **`gemini-2.5-flash`**. Older versions (1.5) or "-latest" suffixes may not be available depending on the API key/region.
- **API Key**: Ensure the key is unrestricted or explicitly allows "Gemini API" in the Google Cloud Console. Using an AI Studio key is the most stable option.
- **SDK Constraints**: Stick to `google_generative_ai: ^0.4.7` unless the Dart SDK environment is upgraded to 3.4.0+.

## 5. File References
- **AI Services**: `lib/core/services/ai_insight_service.dart`, `lib/core/services/chat_service.dart`
- **Smart Home**: `lib/core/services/smart_home_service.dart`
- **Native Logic**: `android/app/src/main/kotlin/com/example/ai_butler_launcher/MainActivity.kt`
