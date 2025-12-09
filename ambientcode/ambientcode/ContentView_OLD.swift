import SwiftUI

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingPermissionAlert = false
    @State private var showingClaudeSentAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Voice Capture")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(audioRecorder.isRecording ? Color.red : Color.gray)
                    .frame(width: 12, height: 12)

                Text(audioRecorder.isRecording ? "Recording..." : "Ready")
                    .font(.headline)
            }

            // Recording duration
            if audioRecorder.isRecording {
                Text(audioRecorder.recordingDuration)
                    .font(.title2)
                    .monospacedDigit()
            }

            // Record button
            Button(action: {
                toggleRecording()
            }) {
                HStack {
                    Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
                    Text(audioRecorder.isRecording ? "Stop Recording" : "Start Recording")
                }
                .frame(width: 200, height: 50)
                .background(audioRecorder.isRecording ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .keyboardShortcut(.space, modifiers: [])

            // Transcription area
            if !audioRecorder.transcription.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Transcription:")
                        .font(.headline)

                    ScrollView {
                        Text(audioRecorder.transcription)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(height: 150)

                    HStack(spacing: 10) {
                        Button("Copy") {
                            copyToClipboard()
                        }

                        Button("Send to Claude") {
                            sendToClaude()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .cornerRadius(5)

                        Button("Clear") {
                            audioRecorder.clearTranscription()
                        }
                        .foregroundColor(.red)
                    }
                }
            }

            // Last recording info
            if let lastRecording = audioRecorder.lastRecordingURL {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Last Recording:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(lastRecording.lastPathComponent)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Button("Open in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([lastRecording])
                    }
                    .font(.caption)
                }
            }
        }
        .padding(30)
        .frame(width: 400)
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please grant microphone access in System Settings to use this app.")
        }
        .alert("Sent to Claude! 🎉", isPresented: $showingClaudeSentAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Transcription copied to clipboard and saved to ~/Documents/claude-prompts/\n\nPaste into Claude Desktop or Claude Code now!")
        }
    }

    private func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
        } else {
            let hasPermission = audioRecorder.requestPermissionAndRecord()
            if !hasPermission {
                showingPermissionAlert = true
            }
        }
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(audioRecorder.transcription, forType: .string)
    }

    private func sendToClaude() {
        if audioRecorder.sendToClaude() {
            showingClaudeSentAlert = true
        }
    }
}

#Preview {
    ContentView()
}
