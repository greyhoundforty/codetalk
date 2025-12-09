import SwiftUI

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var recordingsManager = RecordingsManager()
    @StateObject private var corrector = TranscriptionCorrector()

    @State private var showingPermissionAlert = false
    @State private var showingClaudeSentAlert = false
    @State private var selectedRecording: RecordingItem?
    @State private var editingTranscription: String = ""
    @State private var isEditingMode = false
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            // SIDEBAR: Recording History
            sidebarContent
        } detail: {
            // MAIN CONTENT: Current Recording or Selected Recording
            if let selected = selectedRecording {
                recordingDetailView(selected)
            } else {
                currentRecordingView
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            audioRecorder.corrector = corrector
        }
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recordings")
                    .font(.headline)
                Spacer()
                Button(action: { recordingsManager.refreshRecordings() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .padding()

            // Recording List
            List(recordingsManager.recordings, selection: $selectedRecording) { recording in
                RecordingRow(recording: recording)
                    .tag(recording)
                    .contextMenu {
                        Button("Delete") {
                            recordingsManager.deleteRecording(recording)
                            if selectedRecording?.id == recording.id {
                                selectedRecording = nil
                            }
                        }
                    }
            }
            .listStyle(.sidebar)

            // Footer with correction count
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.blue)
                Text("\(corrector.corrections.count) corrections learned")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 250)
    }

    // MARK: - Current Recording View

    private var currentRecordingView: some View {
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
            Button(action: { toggleRecording() }) {
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
                    HStack {
                        Text("Transcription:")
                            .font(.headline)
                        Spacer()
                        if corrector.corrections.count > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Auto-corrected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

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
                            copyToClipboard(audioRecorder.transcription)
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

            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: - Recording Detail View

    private func recordingDetailView(_ recording: RecordingItem) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(recording.formattedDate)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(recording.filename)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { selectedRecording = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            // Transcription editor
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Transcription:")
                        .font(.headline)
                    Spacer()
                    if !isEditingMode {
                        Button("Edit & Learn") {
                            editingTranscription = recording.transcription
                            isEditingMode = true
                        }
                        .foregroundColor(.blue)
                    }
                }

                if isEditingMode {
                    // Editable text
                    TextEditor(text: $editingTranscription)
                        .font(.body)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .border(Color.blue, width: 2)
                        .frame(height: 300)

                    HStack {
                        Text("Edit the transcription to correct mistakes. Your corrections will be learned!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    HStack(spacing: 10) {
                        Button("Save & Learn") {
                            saveAndLearn(recording: recording)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)

                        Button("Cancel") {
                            isEditingMode = false
                        }
                        .foregroundColor(.red)
                    }
                } else {
                    // Read-only view
                    ScrollView {
                        Text(recording.transcription)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(height: 300)

                    HStack(spacing: 10) {
                        Button("Copy") {
                            copyToClipboard(recording.transcription)
                        }

                        Button("Send to Claude") {
                            sendToClaudeFromHistory(recording)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .cornerRadius(5)

                        Button("Open in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([recording.audioURL])
                        }
                        .font(.caption)
                    }
                }
            }

            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            // Refresh recordings list after stopping
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                recordingsManager.refreshRecordings()
            }
        } else {
            let hasPermission = audioRecorder.requestPermissionAndRecord()
            if !hasPermission {
                showingPermissionAlert = true
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func sendToClaude() {
        if audioRecorder.sendToClaude() {
            showingClaudeSentAlert = true
        }
    }

    private func sendToClaudeFromHistory(_ recording: RecordingItem) {
        // Save to claude-prompts
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let claudeDir = documentsPath.appendingPathComponent("claude-prompts")
        try? FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)

        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let claudePromptURL = claudeDir.appendingPathComponent("prompt_\(timestamp).txt")

        do {
            try recording.transcription.write(to: claudePromptURL, atomically: true, encoding: .utf8)
            copyToClipboard(recording.transcription)
            showingClaudeSentAlert = true
        } catch {
            print("Failed to save Claude prompt: \(error)")
        }
    }

    private func saveAndLearn(recording: RecordingItem) {
        let original = recording.transcription
        let corrected = editingTranscription

        // Learn from the correction
        corrector.learnFromCorrection(original: original, corrected: corrected)

        // Update the recording
        recordingsManager.updateRecording(recording, withTranscription: corrected)

        // Update selected recording
        if let index = recordingsManager.recordings.firstIndex(where: { $0.id == recording.id }) {
            selectedRecording = recordingsManager.recordings[index]
        }

        isEditingMode = false
    }
}

// MARK: - Recording Row

struct RecordingRow: View {
    let recording: RecordingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recording.formattedDate)
                .font(.headline)

            if !recording.transcription.isEmpty {
                Text(recording.transcription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text("No transcription")
                    .font(.caption)
                    .foregroundColor(.red)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
