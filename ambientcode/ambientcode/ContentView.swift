import SwiftUI

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var recordingsManager = RecordingsManager()
    @StateObject private var corrector = TranscriptionCorrector()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var appSettings = AppSettings()
    
    @State private var showingPermissionAlert = false
    @State private var showingClaudeSentAlert = false
    @State private var selectedRecording: RecordingItem?
    @State private var editingTranscription: String = ""
    @State private var isEditingMode = false
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all
    @State private var showingSettings = false
    
    // Ollama integration
    @State private var ollamaResponse: String = ""
    @State private var isLoadingOllama = false
    @State private var ollamaError: String?
    @State private var showingOllamaPanel = false
    
    // Claude Desktop/Code integration
    @State private var showingClaudeDesktopAlert = false
    @State private var showingClaudeCodeAlert = false
    @State private var claudeIntegrationError: String?
    @State private var selectedClaudeProject: AudioRecorder.ClaudeDesktopProject = .current
    @State private var showingProjectSelector = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            // SIDEBAR: Recording History
            sidebarContent
        } content: {
            // MAIN CONTENT: Current Recording or Selected Recording
            if let selected = selectedRecording {
                recordingDetailView(selected)
            } else {
                currentRecordingView
            }
        } detail: {
            // RIGHT PANEL: Ollama Response
            if showingOllamaPanel {
                ollamaPanelContent
            } else {
                emptyOllamaPanelContent
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            audioRecorder.corrector = corrector
            AppColorTheme.current = themeManager.currentTheme
        }
        .onChange(of: themeManager.currentTheme) { newTheme in
            AppColorTheme.current = newTheme
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(appSettings: appSettings, themeManager: themeManager, isPresented: $showingSettings)
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
            
            // Footer with correction count and settings button
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(AppColorTheme.accent)
                    Text("\(corrector.corrections.count) corrections learned")
                        .font(.caption)
                        .foregroundColor(AppColorTheme.textSecondary)
                    Spacer()
                }
                
                // Settings Button
                Button(action: { showingSettings = true }) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(AppColorTheme.textSecondary)
                            .font(.caption)
                        Text("Settings")
                            .font(.caption)
                            .foregroundColor(AppColorTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(AppColorTheme.backgroundSecondary)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
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
                    
                    // DIVIDER: Context vs Destinations
                    Divider()
                        .padding(.vertical, 8)
                    
                    // SECTION HEADER: Send To
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(AppColorTheme.textSecondary)
                            .font(.caption)
                        Text("Send To")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColorTheme.textSecondary)
                            .textCase(.uppercase)
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    VStack(spacing: 12) {
                        // Row 1: Quick Actions
                        HStack(spacing: 12) {
                            Button(action: { copyToClipboard(audioRecorder.transcription) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.primary))
                            
                            Button(action: { sendToClaude() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.fill")
                                    Text("Save File")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.success))
                            
                            Button(action: { audioRecorder.clearTranscription() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text("Clear")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(DangerButtonStyle(isText: true))
                        }
                        
                        // Row 2: AI Integrations
                        HStack(spacing: 12) {
                            Menu {
                                Button(action: { sendToClaudeDesktop(project: .current) }) {
                                    Label("Current Project", systemImage: "circle")
                                }
                                Divider()
                                Button(action: { sendToClaudeDesktop(project: .project1) }) {
                                    Label("Project 1", systemImage: "1.circle")
                                }
                                Button(action: { sendToClaudeDesktop(project: .project2) }) {
                                    Label("Project 2", systemImage: "2.circle")
                                }
                                Button(action: { sendToClaudeDesktop(project: .project3) }) {
                                    Label("Project 3", systemImage: "3.circle")
                                }
                                Button(action: { sendToClaudeDesktop(project: .project4) }) {
                                    Label("Project 4", systemImage: "4.circle")
                                }
                                Button(action: { sendToClaudeDesktop(project: .project5) }) {
                                    Label("Project 5", systemImage: "5.circle")
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "brain")
                                    Text("Claude Desktop")
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.accent))
                            
                            Button(action: { sendToClaudeCode() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "terminal.fill")
                                    Text("Claude Code")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.secondary))
                            
                            Button(action: { sendToOllama() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isLoadingOllama ? "hourglass" : "cpu")
                                    Text(isLoadingOllama ? "Sending..." : "Ollama")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.warning))
                            .disabled(isLoadingOllama)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColorTheme.backgroundPrimary)
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
        .alert("Sent to Claude Desktop! 🎉", isPresented: $showingClaudeDesktopAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = claudeIntegrationError {
                Text("Error: \(error)")
            } else {
                Text("Transcription sent to Claude Desktop app!")
            }
        }
        .alert("Ready for Claude Code! 📋", isPresented: $showingClaudeCodeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = claudeIntegrationError {
                Text("Error: \(error)")
            } else {
                Text("Transcription copied to clipboard and Terminal activated!\n\nPress ⌘V or paste into your Claude Code session.")
            }
        }
    }
    
    // MARK: - Recording Detail View
    
    private func recordingDetailView(_ recording: RecordingItem) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: { selectedRecording = nil }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColorTheme.primary)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading) {
                    Text(recording.formattedDate)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(recording.filename)
                        .font(.caption)
                        .foregroundColor(AppColorTheme.textSecondary)
                }
                Spacer()
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
                    
                    // DIVIDER: Context vs Actions
                    Divider()
                        .padding(.vertical, 8)
                    
                    // SECTION HEADER: Actions
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(AppColorTheme.textSecondary)
                            .font(.caption)
                        Text("Actions")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColorTheme.textSecondary)
                            .textCase(.uppercase)
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    VStack(spacing: 12) {
                        // Row 1: Quick Actions
                        HStack(spacing: 12) {
                            Button(action: { copyToClipboard(recording.transcription) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.primary))
                            
                            Button(action: { sendToClaudeFromHistory(recording) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.fill")
                                    Text("Save File")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.success))
                            
                            Button(action: { NSWorkspace.shared.activateFileViewerSelecting([recording.audioURL]) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.badge.gearshape")
                                    Text("Finder")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.secondary))
                        }
                        
                        // Row 2: AI Integrations
                        HStack(spacing: 12) {
                            Menu {
                                Button(action: { sendToClaudeDesktopFromHistory(recording, project: .current) }) {
                                    Label("Current Project", systemImage: "circle")
                                }
                                Divider()
                                Button(action: { sendToClaudeDesktopFromHistory(recording, project: .project1) }) {
                                    Label("Project 1", systemImage: "1.circle")
                                }
                                Button(action: { sendToClaudeDesktopFromHistory(recording, project: .project2) }) {
                                    Label("Project 2", systemImage: "2.circle")
                                }
                                Button(action: { sendToClaudeDesktopFromHistory(recording, project: .project3) }) {
                                    Label("Project 3", systemImage: "3.circle")
                                }
                                Button(action: { sendToClaudeDesktopFromHistory(recording, project: .project4) }) {
                                    Label("Project 4", systemImage: "4.circle")
                                }
                                Button(action: { sendToClaudeDesktopFromHistory(recording, project: .project5) }) {
                                    Label("Project 5", systemImage: "5.circle")
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "brain")
                                    Text("Claude Desktop")
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.accent))
                            
                            Button(action: { sendToClaudeCodeFromHistory(recording) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "terminal.fill")
                                    Text("Claude Code")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.secondary))
                            
                            Button(action: { sendToOllamaFromHistory(recording) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isLoadingOllama ? "hourglass" : "cpu")
                                    Text(isLoadingOllama ? "Sending..." : "Ollama")
                                }
                                .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.warning))
                            .disabled(isLoadingOllama)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColorTheme.backgroundPrimary)
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
    
    private func sendToClaudeDesktop(project: AudioRecorder.ClaudeDesktopProject = .current) {
        let result = audioRecorder.sendToClaudeDesktop(project: project)
        claudeIntegrationError = result.error
        showingClaudeDesktopAlert = true
    }
    
    private func sendToClaudeDesktopFromHistory(_ recording: RecordingItem, project: AudioRecorder.ClaudeDesktopProject = .current) {
        let originalTranscription = audioRecorder.transcription
        audioRecorder.transcription = recording.transcription
        let result = audioRecorder.sendToClaudeDesktop(project: project)
        audioRecorder.transcription = originalTranscription
        claudeIntegrationError = result.error
        showingClaudeDesktopAlert = true
    }
    
    private func sendToClaudeCode() {
        // Default to clipboard method (most reliable)
        let result = audioRecorder.sendToClaudeCode(method: .clipboard)
        claudeIntegrationError = result.error
        showingClaudeCodeAlert = true
    }
    
    private func sendToClaudeCodeFromHistory(_ recording: RecordingItem) {
        let originalTranscription = audioRecorder.transcription
        audioRecorder.transcription = recording.transcription
        let result = audioRecorder.sendToClaudeCode(method: .clipboard)
        audioRecorder.transcription = originalTranscription
        claudeIntegrationError = result.error
        showingClaudeCodeAlert = true
    }
    
    private func sendToOllama() {
        isLoadingOllama = true
        ollamaError = nil
        showingOllamaPanel = true
        
        audioRecorder.sendToOllama { result in
            DispatchQueue.main.async {
                isLoadingOllama = false
                
                switch result {
                case .success(let response):
                    ollamaResponse = response
                case .failure(let error):
                    ollamaError = error.localizedDescription
                }
            }
        }
    }
    
    private func sendToOllamaFromHistory(_ recording: RecordingItem) {
        isLoadingOllama = true
        ollamaError = nil
        showingOllamaPanel = true
        
        // Temporarily set transcription for sending
        let originalTranscription = audioRecorder.transcription
        audioRecorder.transcription = recording.transcription
        
        audioRecorder.sendToOllama { result in
            DispatchQueue.main.async {
                // Restore original transcription
                audioRecorder.transcription = originalTranscription
                isLoadingOllama = false
                
                switch result {
                case .success(let response):
                    ollamaResponse = response
                case .failure(let error):
                    ollamaError = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Ollama Panel (Right Column)
    
    private var emptyOllamaPanelContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu")
                .font(.system(size: 40))
                .foregroundColor(AppColorTheme.textSecondary)
            
            Text("Send to Ollama")
                .font(.headline)
                .foregroundColor(AppColorTheme.textPrimary)
            
            Text("Send a transcription to your local Ollama server to see responses here")
                .font(.caption)
                .foregroundColor(AppColorTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColorTheme.backgroundPrimary)
    }
    
    private var ollamaPanelContent: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(AppColorTheme.warning)
                    .font(.title3)
                
                Text("Ollama Response")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingOllamaPanel = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColorTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(AppColorTheme.sidebarBackground)
            
            // Content
            if let error = ollamaError {
                // Error view
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(AppColorTheme.danger)
                    
                    Text("Error")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppColorTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button("Retry") {
                        sendToOllama()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            } else if isLoadingOllama {
                // Loading state
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5, anchor: .center)
                    
                    Text("Sending to Ollama...")
                        .font(.body)
                        .foregroundColor(AppColorTheme.textSecondary)
                    
                    Spacer()
                }
                .padding()
            } else {
                // Success view
                VStack(alignment: .leading, spacing: 10) {
                    ScrollView {
                        Text(ollamaResponse)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transcriptionStyle()
                    }
                    
                    HStack(spacing: 10) {
                        Button(action: { copyToClipboard(ollamaResponse) }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(SecondaryButtonStyle(color: AppColorTheme.primary))
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColorTheme.backgroundPrimary)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings
    @ObservedObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    @State private var testingServerURL = ""
    @State private var testResult: String?
    @State private var isTesting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Form {
                    Section(header: Text("Appearance")) {
                        Text("Theme")
                            .font(.headline)
                            .foregroundColor(AppColorTheme.textPrimary)
                        
                        Picker("Theme", selection: $themeManager.currentTheme) {
                            ForEach(ThemeType.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("Choose your preferred appearance")
                            .font(.caption2)
                            .foregroundColor(AppColorTheme.textSecondary)
                    }
                    
                    Section(header: Text("Ollama Configuration")) {
                        Text("Server URL")
                            .font(.headline)
                            .foregroundColor(AppColorTheme.textPrimary)
                        
                        TextField("http://localhost:11434", text: $appSettings.ollamaServerURL)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                        
                        Text("Example: http://192.168.1.100:11434")
                            .font(.caption2)
                            .foregroundColor(AppColorTheme.textSecondary)
                        
                        Text("Model")
                            .font(.headline)
                            .foregroundColor(AppColorTheme.textPrimary)
                            .padding(.top, 12)
                        
                        TextField("qwen2.5-coder:3b-instruct-q4_K_M", text: $appSettings.ollamaModel)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                        
                        Text("The model to use for transcription processing")
                            .font(.caption2)
                            .foregroundColor(AppColorTheme.textSecondary)
                    }
                    
                    Section(header: Text("Actions")) {
                        Button(action: { testConnection() }) {
                            HStack {
                                Image(systemName: isTesting ? "hourglass" : "checkmark.circle")
                                Text(isTesting ? "Testing..." : "Test Connection")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(isTesting)
                        
                        if let result = testResult {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(result.lowercased().contains("success") ? AppColorTheme.success : AppColorTheme.danger)
                        }
                        
                        Button(action: { appSettings.resetToDefaults() }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset to Defaults")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(AppColorTheme.danger)
                        }
                    }
                }
            }
            .frame(minWidth: 500, minHeight: 600)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func testConnection() {
        isTesting = true
        testResult = nil
        
        guard let url = URL(string: "\(appSettings.ollamaServerURL)/api/tags") else {
            testResult = "Invalid URL"
            isTesting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isTesting = false
                
                if let error = error {
                    testResult = "Failed: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    testResult = "✓ Connection successful"
                } else {
                    testResult = "Failed: Invalid response"
                }
            }
        }.resume()
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
