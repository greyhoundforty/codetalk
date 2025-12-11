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
                    .foregroundColor(AppColorTheme.accent)
                Text("\(corrector.corrections.count) corrections learned")
                    .font(.caption)
                    .foregroundColor(AppColorTheme.textSecondary)
                Spacer()
            }
            .padding()
            .background(AppColorTheme.sidebarBackground)
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
                    .fill(audioRecorder.isRecording ? AppColorTheme.recording : AppColorTheme.inactive)
                    .frame(width: 12, height: 12)

                Text(audioRecorder.isRecording ? "Recording..." : "Ready")
                    .font(.headline)
                    .foregroundColor(AppColorTheme.textPrimary)
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
            }
            .buttonStyle(PrimaryButtonStyle(isDestructive: audioRecorder.isRecording))
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
                                    .foregroundColor(AppColorTheme.success)
                                    .font(.caption)
                                Text("Auto-corrected")
                                    .font(.caption)
                                    .foregroundColor(AppColorTheme.textSecondary)
                            }
                        }
                    }

                    ScrollView {
                        Text(audioRecorder.transcription)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transcriptionStyle()
                    }
                    .frame(height: 150)

                    HStack(spacing: 10) {
                        Button("Copy") {
                            copyToClipboard(audioRecorder.transcription)
                        }
                        .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.primary))

                        Button("Send to Claude") {
                            sendToClaude()
                        }
                        .buttonStyle(SuccessButtonStyle())

                        Button("Clear") {
                            audioRecorder.clearTranscription()
                        }
                        .buttonStyle(DangerButtonStyle(isText: true))
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
                        .foregroundColor(AppColorTheme.textSecondary)
                }
                Spacer()
                Button(action: { selectedRecording = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColorTheme.inactive)
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
                        .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.accent))
                    }
                }

                if isEditingMode {
                    // Editable text
                    TextEditor(text: $editingTranscription)
                        .font(.body)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .border(AppColorTheme.focusBorder, width: 2)
                        .frame(height: 300)

                    HStack {
                        Text("Edit the transcription to correct mistakes. Your corrections will be learned!")
                            .font(.caption)
                            .foregroundColor(AppColorTheme.textSecondary)
                        Spacer()
                    }

                    HStack(spacing: 10) {
                        Button("Save & Learn") {
                            saveAndLearn(recording: recording)
                        }
                        .buttonStyle(SuccessButtonStyle())

                        Button("Cancel") {
                            isEditingMode = false
                        }
                        .buttonStyle(DangerButtonStyle(isText: true))
                    }
                } else {
                    // Read-only view
                    ScrollView {
                        Text(recording.transcription)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transcriptionStyle()
                    }
                    .frame(height: 300)

                    HStack(spacing: 10) {
                        Button("Copy") {
                            copyToClipboard(recording.transcription)
                        }
                        .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.primary))

                        Button("Send to Claude") {
                            sendToClaudeFromHistory(recording)
                        }
                        .buttonStyle(SuccessButtonStyle())

                        Button("Open in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([recording.audioURL])
                        }
                        .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.secondary))
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
                .foregroundColor(AppColorTheme.textPrimary)

            if !recording.transcription.isEmpty {
                Text(recording.transcription)
                    .font(.caption)
                    .foregroundColor(AppColorTheme.textSecondary)
                    .lineLimit(2)
            } else {
                Text("No transcription")
                    .font(.caption)
                    .foregroundColor(AppColorTheme.danger)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
