# Ambient Code - macOS Voice Capture & Transcription

A native macOS app for recording audio, transcribing with live speech recognition, and managing recording history with AI transcription corrections and integration with local Ollama servers.

## Features

- **Voice recording** with spacebar shortcuts and duration tracking
- **Live transcription** using Apple's Speech Recognition framework
- **Recording history** with full playback and management capabilities
- **AI transcription correction** that learns from your edits
- **Ollama integration** to send transcriptions to local LLM servers
- **Claude Desktop/Code integration** with project-aware context
- **Theme support** (light/dark modes)
- **Audio file saving** in high-quality M4A format (44.1kHz, mono AAC)

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Microphone access and speech recognition permissions
- (Optional) Ollama running locally for LLM features

## Building

1. Open `ambientcode/ambientcode.xcodeproj` in Xcode
2. Select the **ambientcode** target
3. Verify **Signing & Capabilities**:
   - Ensure **Hardened Runtime** is enabled
   - Audio Input capability is present
4. Set **macOS Deployment Target** to 13.0+
5. Build and run (Cmd+R)

## Usage

### Recording
- Click "Start Recording" or press **Spacebar** to begin
- Speak into your microphone
- Click "Stop Recording" or press **Spacebar** to finish
- Transcription updates live as you speak

### Managing Recordings
- View all recordings in the left sidebar
- Click any recording to view details
- Edit transcriptions directly in the detail view
- Delete recordings via right-click context menu
- Refresh recording list with the reload button

### Ollama Integration
- Ensure Ollama is running at `http://192.168.50.96:11434` (configurable in code)
- Click "Send to Ollama" on any recording to send the transcription to your local LLM
- View LLM responses in a modal window
- Copy responses to clipboard with the copy button

### Claude Integration
- Send transcriptions to Claude Desktop or Code projects
- Choose from available projects in the project selector
- Transcriptions maintain context for better AI responses

### Transcription Learning
- When you edit a transcription, corrections are saved automatically
- The AI corrector learns from your edits over time
- Better transcription quality on similar audio patterns

## Storage

- Recordings saved to: `~/Documents/Recordings/`
- Named with ISO8601 timestamps: `recording_YYYY-MM-DDTHH-MM-SS.m4a`

## Troubleshooting

### Microphone Permission Denied
1. Go to **System Settings** → **Privacy & Security** → **Microphone**
2. Ensure **ambientcode** is in the allowed list
3. Restart the app

### Speech Recognition Not Working
1. Go to **System Settings** → **Privacy & Security** → **Speech Recognition**
2. Ensure **ambientcode** is in the allowed list
3. Check that you have internet connectivity (for cloud recognition)
4. Speak clearly and at a moderate pace

### No Audio Recorded
- Verify microphone is connected and selected in **System Settings** → **Sound** → **Input**
- Check input volume is not muted
- Try restarting the app

### Ollama Connection Failed
- Verify Ollama is running: `curl http://192.168.50.96:11434/api/tags`
- Check network connectivity to the Ollama server
- Confirm the server URL matches your configuration (default: `http://192.168.50.96:11434`)
- Verify the model exists on your Ollama server

### Transcription Shows Errors
- Check you have speech recognition permission granted
- Ensure microphone is working properly
- Try a new recording with clearer audio

### Build Issues
- Clean build folder: **Product** → **Clean Build Folder** (Cmd+Shift+K)
- Verify all files are added to the **ambientcode** target
- Ensure deployment target is set to macOS 13.0+
- Restart Xcode if issues persist

## Architecture

**Key Components:**
- `AudioRecorder.swift` - Recording, speech recognition, and LLM integration
- `ContentView.swift` - Main UI with recording controls and history
- `RecordingsManager.swift` - Handles recording file management
- `TranscriptionCorrector.swift` - AI-powered transcription learning
- `ColorTheme.swift` - Theme management (light/dark)
- `RecordingItem.swift` - Recording data model

## License

Created for personal use with Claude and Claude Code.
