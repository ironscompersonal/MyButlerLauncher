# Project Handover: MY AI BUTLER Launcher

## 1. Project Overview
- **Goal**: A premium Android Home Launcher powered by Gemini 2.5.
- **Status**: Stable and functional with enhanced transit info, messenger notifications, and UI optimizations.

## 2. Technical Stack
- **Flutter/Dart**: Framework (google_generative_ai: ^0.4.7).
- **Gemini**: **Gemini 2.5 Flash** (v1beta endpoint).
- **Native**: Kotlin for notification listening (now correctly namespaced to `com.mybutler.launcher_app`).

## 3. Latest Improvements
- **Transit Integration**: 
    - Added `TransitService` to fetch real-time train status via Yahoo RSS.
    - Added `TransitCard` to the home screen for visual status updates.
    - Integrated transit data into the AI Butler's insights for proactive reporting.
- **Messenger Notification Card**: 
    - Added a dedicated card to show recent notifications from LINE, WhatsApp, Slack, etc., with app-specific icons and colors.
- **App Drawer Optimization**: 
    - Implemented a "Top 16" limit to the initial drawer view to improve performance and organization.
    - Added a "SHOW ALL" toggle to reveal the full application list.
- **AI Text Formatting**: 
    - Implemented Markdown-style bold text parsing (`**text**`) in the AI Insight Card using RichText.
- **App Icon Fix**: 
    - Corrected Android adaptive icon configuration and manually updated mipmap resources.

## 4. Pending Tasks
- [x] **Service Status Expansion**: Transit status added to dashboard.
- [x] **UI Refinement**: Bold text support for AI messages.
- [x] **Messenger List**: Visual notification list added to home screen.
- [ ] **Notification Deduplication**: Further refine AI prompt to handle rapid fire chat messages more gracefully.
- [ ] **Smart Home Integration**: Re-implement or fix connectivity if needed (previously deleted service).

## 5. Development Notes
- **Transit RSS**: Fetches from Yahoo! Japan. AI is instructed to prioritize "Abnormal" status.
- **Model**: Continues to use `gemini-2.5-flash`.
- **Package Name**: Refactored from `com.example` to `com.mybutler.launcher_app`.
