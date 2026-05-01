# Project Handover: MY AI BUTLER Launcher

## 1. Project Overview
- **Goal**: A premium Android Home Launcher powered by Gemini 2.5.
- **Status**: Stable with personalized profile, voice input, and comprehensive status monitoring (Weather/Transit/Notifications).

## 2. Technical Stack
- **Flutter/Dart**: Framework (google_generative_ai: ^0.4.7).
- **Gemini**: **Gemini 2.5 Flash** (v1beta endpoint).
- **Native**: Kotlin for notification listening (`com.mybutler.launcher_app`).
- **Additional Packages**: `speech_to_text` (voice input), `intl` (local date/time).

## 3. Latest Improvements (2026-05-02)
- **Application Loading Optimization**:
    - Decoupled application list fetching from icon processing.
    - Implemented on-demand, asynchronous icon loading with resizing (100x100) in Kotlin.
    - Added caching in Flutter (Riverpod), resulting in near-instant App Drawer loading.
- **Health Connect Integration**:
    - Integrated Android Health Connect via the `health` package.
    - Captures steps, sleep, and heart rate data from the last 24 hours.
    - Includes a smart installation assistant that detects if Health Connect is missing and provides a direct Play Store link.
- **AI Insight Refinement**:
    - Tuned the system prompt to be more concise and "butler-like," focusing on key information without redundant greetings.
    - Integrated health data into AI insights for proactive health advice.
- **Android System Update**:
    - Upgraded `compileSdkVersion` and `targetSdkVersion` to 35.
    - Upgraded `minSdkVersion` to 26 (Android 8.0) to support Health Connect.
    - Switched `MainActivity` to `FlutterFragmentActivity` for enhanced permission handling.

## 4. Pending Tasks
- [x] **Application Loading Speed**: Optimized with on-demand icon loading.
- [x] **Health Integration**: Health Connect linked with AI insights.
- [x] **Concise AI**: Prompts adjusted for brevity.
- [ ] **Custom Themes**: Allow user to choose different glassmorphism accent colors.
- [ ] **Advanced Scheduling**: Proactive reminders for calendar events based on transit times.

## 5. Development Notes
- **Locales**: `ja_JP` locale is initialized in `main.dart` for date formatting.
- **Health Connect**: Requires the "Health Connect" app to be installed on the device. Supported on Android 8.0+.
- **Icon Resizing**: Native Kotlin implementation resizes app icons to 100x100 for memory and performance efficiency.
- **SDK Version**: Project is now targeting Android API 35.
