# Project Handover: MY AI BUTLER Launcher

## 1. Project Overview
- **Goal**: A premium Android Home Launcher powered by Gemini 2.5.
- **Status**: Stable and functional with Gemini 2.5 Flash and enhanced Messenger integration.

## 2. Technical Stack
- **Flutter/Dart**: Framework (google_generative_ai: ^0.4.7).
- **Gemini**: **Gemini 2.5 Flash** (v1beta endpoint).
- **Native**: Kotlin for notification listening and smart home integration.

## 3. Latest Improvements
- **Service Status Dashboard**: A vertical stacked card at the bottom showing the health of AI, Weather, Google, and Messenger services.
- **Enhanced Messenger Analytics**: Kotlin side now extracts `sender` and `conversationTitle` from MessagingStyle notifications (LINE, WhatsApp).
- **UI Refinement**: Optimized clock font size (80% scale) and improved glassmorphism layout.

## 4. Pending Tasks
- [ ] **App Icon Retrieval**: Icons in the app drawer are still generic. Need to implement Kotlin side `getInstalledApps` with ByteArray icon support.
- [ ] **Notification Deduplication**: Handle rapid fire chat messages more gracefully in the AI prompt.
- [ ] **Service Status Expansion**: Add more detailed statuses for Smart Home connectivity.

## 5. Development Notes
- **Weather API**: Uses Open-Meteo with `current` parameter.
- **Model**: Must use `gemini-2.5-flash`.
