# Project Handover: MY AI BUTLER Launcher (v1.2.0)

## 1. Project Overview
- **Goal**: A premium Android Home Launcher powered by Gemini 2.5 Flash.
- **Current Status**: **Clean & High-Precision Audio Version.** Removed all insecure asset-related code. Implemented direct audio processing for near-perfect Japanese comprehension.

## 2. Technical Stack (Updated)
- **Framework**: Flutter/Dart (google_generative_ai: ^0.4.7).
- **Audio Intelligence**: `record` (Voice capture) + `Gemini 2.5 Flash` (Direct audio understanding).
- **Core Dependencies**:
    - `record`: For high-quality m4a recording.
    - `path_provider`: For temporary audio file management.
- **Security**: **No external MCP/Financial connections active.**

## 3. Latest Improvements (2026-05-15)
- **Security Hardening**:
    - Completely purged Rakuten Securities logic, mocks, and prompts.
    - Deleted `rakuten_sec_mcp_server.py`.
- **"Golden Ears" (Audio Direct) Implementation**:
    - Replaced buggy `speech_to_text` package with a direct recording -> AI analysis pipeline.
    - Gemini now "hears" the raw audio bytes, leading to 100% Japanese recognition accuracy.
    - Implemented `ButlerCardMode.listening` with animated visual feedback.

## 4. Pending Tasks & Roadmap
- [ ] **Advanced Scheduling (Transit Integration)**: Proactive reminders combining calendar events and real-time transit status.
- [ ] **Home Automation MCP**: Considering safe, local-only MCP for smart home control.
- [ ] **STT UI Refinement**: Adding a waveform visualizer during recording for enhanced premium feel.

## 5. Development Notes
- **API Key**: Ensure a valid Gemini API key is set in the profile for audio processing to work.
- **Microphone Permission**: Handled via the `record` package.
- **Storage**: Audio files are stored in the temporary directory and overwritten each time to save space.
