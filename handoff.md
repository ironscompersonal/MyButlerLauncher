# Project Handover: MY AI BUTLER Launcher

## 1. Project Overview
- **Goal**: A premium Android Home Launcher powered by Gemini 2.5.
- **Status**: Stable with personalized profile, voice input, and comprehensive status monitoring (Weather/Transit/Notifications).

## 2. Technical Stack
- **Flutter/Dart**: Framework (google_generative_ai: ^0.4.7).
- **Gemini**: **Gemini 2.5 Flash** (v1beta endpoint).
- **Native**: Kotlin for notification listening (`com.mybutler.launcher_app`).
- **Additional Packages**: `speech_to_text` (voice input), `intl` (local date/time).

## 3. Latest Improvements (2026-05-01)
- **Personal Profile (ご主人様の覚書)**: 
    - Added a persistence-based profile system where the user can store habits, preferences, and personal info.
    - This profile is injected into all AI prompts (Chat & Insights) for tailored service.
- **Voice Input (Mic)**:
    - Integrated `speech_to_text` in the Chat Overlay.
    - Users can now talk to the butler directly via the mic button.
- **Enhanced Weather**:
    - Expanded from current weather to a 3-day view (Current + 2-day forecast).
    - Fetches max/min temperatures and weather codes via Open-Meteo.
- **Transit Scraping Fix**:
    - Replaced the discontinued Yahoo! RSS with a direct Web Scraper for real-time transit info.
    - Implemented HTML tag stripping to ensure clean text display.
- **Live Context (Time-Awareness)**:
    - AI is now fed the exact current date and time.
    - Instructed to provide time-appropriate greetings (Good morning/evening) and proactive reporting.
- **System Synchronization**:
    - Added a "FORCE RE-SYNC" button to the status dashboard to manually refresh all API data.

## 4. Pending Tasks
- [x] **Personalization**: "Master's Memory" (覚書) implemented.
- [x] **Voice Support**: Mic input added to chat.
- [x] **Weather Forecast**: Next 2 days added to clock section.
- [x] **Transit Fix**: Switched from RSS to Scraper.
- [ ] **Notification Refinement**: Continued tuning of the AI's "Live Greeting" frequency to avoid redundancy.
- [ ] **Custom Themes**: Allow user to choose different glassmorphism accent colors.

## 5. Development Notes
- **Locales**: `ja_JP` locale is initialized in `main.dart` for date formatting.
- **Scraping**: `TransitService` parses `transit.yahoo.co.jp` HTML. Brittle if UI changes, but most comprehensive for JP transit.
- **Mic Permissions**: `RECORD_AUDIO` permission is required and added to `AndroidManifest.xml`.
- **Model**: `gemini-2.5-flash` is used for high-speed, cost-effective processing.
