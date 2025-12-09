# Voice Capture for macOS

A simple, native macOS app for recording and transcribing voice audio, designed to work seamlessly with Claude and Claude Code.

## Features

- **One-click voice recording** with spacebar shortcut
- **Live transcription** using Apple's Speech Recognition framework
- **Audio file saving** in high-quality M4A format
- **Copy transcription** to clipboard for use with Claude
- **Clean, minimal UI** focused on quick voice capture
- **Native macOS integration** with proper permissions handling

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Microphone access
- Speech recognition permissions

## Project Setup

### 1. Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **macOS** → **App**
4. Configure project:
   - Product Name: `VoiceCapture`
   - Team: Your development team
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None needed
   - Include Tests: Optional

### 2. Add Project Files

Copy the provided files into your Xcode project:

```
VoiceCapture/
├── Info.plist
├── VoiceCaptureApp.swift
├── ContentView.swift
└── AudioRecorder.swift
```

Make sure to add them to your target in Xcode (check the target membership in File Inspector).

### 3. Configure Capabilities

1. Select your project in Xcode
2. Select the **VoiceCapture** target
3. Go to **Signing & Capabilities** tab
4. Ensure **Hardened Runtime** is enabled
5. Under Hardened Runtime, enable:
   - **Audio Input**
   - **User Selected Files** (for file access)

### 4. Set Deployment Target

1. In project settings, set **macOS Deployment Target** to 13.0 or later
2. This ensures compatibility with the latest SwiftUI features

## How It Works

### Audio Recording

The app uses **AVFoundation** framework for recording:

- **AVAudioRecorder**: Captures high-quality audio to M4A files
- **Recording format**: 44.1kHz, AAC encoding, mono channel
- **Storage location**: `~/Documents/Recordings/`
- **File naming**: `recording_YYYY-MM-DDTHH-MM-SS.m4a`

### Speech Recognition

The app uses **Speech** framework for live transcription:

- **SFSpeechRecognizer**: Apple's on-device/cloud recognition
- **Live transcription**: Updates in real-time as you speak
- **Language**: English (US) by default
- **Partial results**: Shows interim transcription while recording

### Key Components

#### 1. AudioRecorder.swift

The main service class that handles:
- Microphone permissions
- Audio recording lifecycle
- Speech recognition setup
- File management
- Timer for recording duration

```swift
@Published var isRecording = false
@Published var transcription = ""
@Published var recordingDuration = "00:00"
```

#### 2. ContentView.swift

The SwiftUI interface that provides:
- Recording status indicator
- Start/stop recording button (spacebar shortcut)
- Live transcription display
- Copy/clear transcription actions
- Last recording file info

#### 3. VoiceCaptureApp.swift

The app entry point that:
- Initializes the SwiftUI app
- Configures window style (no title bar)
- Sets window to content size

## Usage

### Recording Audio

1. **Launch the app**
2. **Grant permissions** when prompted:
   - Microphone access
   - Speech recognition
3. **Start recording**:
   - Click "Start Recording" button, or
   - Press **Spacebar**
4. **Speak clearly** into your microphone
5. **Stop recording**:
   - Click "Stop Recording" button, or
   - Press **Spacebar** again

### Using Transcription

1. **View transcription** in the text area (updates live)
2. **Copy to clipboard** using "Copy" button
3. **Paste into Claude** or Claude Code
4. **Clear transcription** with "Clear" button when done

### Finding Recordings

- Recordings are saved to: `~/Documents/Recordings/`
- Click **"Open in Finder"** to locate the last recording
- Files are named with ISO8601 timestamps

## Integration with Claude Code

### Use Case 1: Voice Commands

1. Record a voice description of what you want Claude Code to do
2. Copy the transcription
3. Paste into Claude Code terminal
4. Example: "Create a function that validates email addresses and returns true if valid"

### Use Case 2: Code Documentation

1. Record an explanation of complex code logic
2. Copy transcription
3. Ask Claude Code to format it as code comments
4. Example: "This algorithm uses dynamic programming to calculate the shortest path..."

### Use Case 3: Bug Reporting

1. Record a description of a bug you encountered
2. Copy transcription
3. Paste into Claude Code with request to investigate
4. Example: "The login form is submitting twice when I press enter..."

## Keyboard Shortcuts

- **Spacebar**: Start/Stop recording (global in app)
- **⌘C**: Copy transcription (when text is selected)
- **⌘Q**: Quit app

## Troubleshooting

### Permission Issues

If microphone access is denied:
1. Open **System Settings**
2. Go to **Privacy & Security** → **Microphone**
3. Enable access for **VoiceCapture**

If speech recognition is denied:
1. Open **System Settings**
2. Go to **Privacy & Security** → **Speech Recognition**
3. Enable access for **VoiceCapture**

### No Audio Recording

- Check that your microphone is connected
- Verify microphone is selected in System Settings → Sound → Input
- Check input volume is not muted
- Try restarting the app

### Transcription Not Working

- Ensure you have internet connection (for cloud-based recognition)
- Speak clearly and at a moderate pace
- Check language is set to English in System Settings
- Verify Speech Recognition permission is granted

### Build Errors

If you get compiler errors:
- Ensure deployment target is macOS 13.0+
- Verify all files are added to target
- Clean build folder: Product → Clean Build Folder
- Restart Xcode

## Technical Architecture

```
┌─────────────────────────────────────────┐
│           ContentView (UI)              │
│  - Recording button                     │
│  - Status indicator                     │
│  - Transcription display                │
└──────────────────┬──────────────────────┘
                   │
                   │ @StateObject
                   │
┌──────────────────▼──────────────────────┐
│        AudioRecorder (Service)          │
│  ┌────────────────────────────────────┐ │
│  │   AVAudioRecorder                  │ │
│  │   - File recording                 │ │
│  │   - Audio format configuration     │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │   SFSpeechRecognizer              │ │
│  │   - Live transcription             │ │
│  │   - Audio buffer processing        │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## File Structure

```
VoiceCapture/
├── VoiceCaptureApp.swift      # App entry point
├── ContentView.swift           # Main UI view
├── AudioRecorder.swift         # Recording service
├── Info.plist                  # Permissions & config
└── Assets.xcassets/           # (Auto-generated)
```

## Future Enhancements

Potential features to add:
- [ ] Multiple language support
- [ ] Custom recording quality settings
- [ ] Export to different audio formats
- [ ] Recording history list
- [ ] Playback functionality
- [ ] Integration with system menu bar
- [ ] Hotkey for global recording trigger
- [ ] Custom output directory selection

## License

Created for use with Claude and Claude Code. Modify as needed for your workflow.

## Credits

Built with:
- **SwiftUI** for native macOS UI
- **AVFoundation** for audio recording
- **Speech** framework for transcription
- Designed for **Claude Code** integration
