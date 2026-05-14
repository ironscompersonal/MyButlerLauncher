# Project Handover: MY AI BUTLER Launcher (v1.1.0)

## 1. Project Overview
- **Goal**: A premium Android Home Launcher powered by Gemini 2.5 Flash.
- **Current Status**: **Fully Operational on Real Devices (Android 16/API 36).** Integrated with real-time health, asset, and schedule data. Voice-interactive via the main insight card.

## 2. Technical Stack
- **Framework**: Flutter/Dart (google_generative_ai: ^0.4.7).
- **AI**: Gemini 2.5 Flash (v1beta) with Context Awareness.
- **MCP**: Real-time HTTP/JSON-RPC client for Rakuten Securities.
- **Native**: Kotlin for notification listening and app icon management.
- **Health**: Health Connect (Steps, Sleep, Heart Rate).

## 3. Latest Improvements (2026-05-14)
- **Real-Device Porting & Stabilization**:
    - Fixed Windows-specific crashes and established absolute path for Flutter commands.
    - Verified full connectivity on SC-51D (Android 16).
- **Full Data Integration (The "Real Data" Update)**:
    - **Google Services**: Expanded scope to fetch 1 month of calendar events.
    - **Health Connect**: Implemented robust per-type fetching for Steps, Sleep (ASLEEP), and Heart Rate.
    - **Rakuten Securities (MCP)**: Switched from mocks to a real HTTP/JSON-RPC client. Created a reference Python MCP server script.
- **Interactive Voice Insight Card**:
    - Transformed the AI Insight Card into a two-way chat interface.
    - Integrated `speech_to_text` for Japanese voice input.
    - Implemented a state machine (Insight -> Listening -> Thinking -> Chat) for the card UI.
- **AI Sincerity & Privacy**:
    - Updated system prompts for privacy (masking numbers on request) and sincerity (explaining the "querying" process).

## 4. Pending Tasks & Roadmap
- [ ] **Advanced Scheduling (Transit Integration)**: Proactive reminders combining calendar events, real-time transit status, and asset balance (Taxi vs Walk logic).
- [ ] **Custom Themes**: Implementation of user-selectable glassmorphism accent colors.
- [ ] **Physical Space (Location MCP)**: Integrating real location data via MCP instead of static coordinates.
- [ ] **STT Locale Fine-tuning**: Final verification of Japanese recognition stability on API 36.

## 5. Development Notes
- **MCP Base URL**: Must be configured in `lib/core/services/mcp_service.dart` (`_mcpBaseUrl`).
- **Health Connect**: Requires other apps (Google Fit, etc.) to write data into Health Connect for the Butler to read.
- **Voice Input**: Currently uses the system's default locale, fallback to `ja_JP`.
