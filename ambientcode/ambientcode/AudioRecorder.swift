import Foundation
import AVFoundation
import Speech
import Combine
import AppKit

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcription = ""
    @Published var recordingDuration = "00:00"
    @Published var lastRecordingURL: URL?

    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var startTime: Date?
    private var rawTranscription: String = "" // Store uncorrected version

    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // Transcription correction
    var corrector: TranscriptionCorrector?

    override init() {
        super.init()
    }

    // MARK: - Permission Handling

    func requestPermissionAndRecord() -> Bool {
        // Check microphone permission (macOS)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        switch micStatus {
        case .authorized:
            // Check speech recognition permission
            SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                DispatchQueue.main.async {
                    if authStatus == .authorized {
                        self?.startRecording()
                    }
                }
            }
            return true

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        SFSpeechRecognizer.requestAuthorization { authStatus in
                            DispatchQueue.main.async {
                                if authStatus == .authorized {
                                    self?.startRecording()
                                }
                            }
                        }
                    }
                }
            }
            return false

        case .denied, .restricted:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Recording Control

    func startRecording() {
        // Note: On macOS, we don't need AVAudioSession configuration
        // AVAudioRecorder and AVAudioEngine work directly

        // Create recordings directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDir = documentsPath.appendingPathComponent("Recordings")
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

        // Create audio file URL
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let audioFilename = recordingsDir.appendingPathComponent("recording_\(timestamp).m4a")

        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            // Start file recording
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()

            // Start live transcription
            try startTranscription()

            // Update state
            DispatchQueue.main.async {
                self.isRecording = true
                self.lastRecordingURL = audioFilename
                self.startTime = Date()
                self.startTimer()
            }

            print("Recording started: \(audioFilename.path)")

        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        // Stop file recording
        audioRecorder?.stop()
        audioRecorder = nil

        // Stop transcription
        stopTranscription()

        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Save transcription to file
        saveTranscription()

        // Update state
        DispatchQueue.main.async {
            self.isRecording = false
            self.recordingDuration = "00:00"
        }

        print("Recording stopped")
    }

    // MARK: - Transcription

    private func startTranscription() throws {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Note: On macOS, no audio session configuration needed

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "AudioRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        // Get audio input
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                let raw = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self?.rawTranscription = raw
                    // Apply learned corrections
                    if let corrector = self?.corrector {
                        self?.transcription = corrector.applyCorrections(to: raw)
                    } else {
                        self?.transcription = raw
                    }
                }
            }

            if error != nil || result?.isFinal == true {
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
            }
        }

        // Configure audio tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }

    private func stopTranscription() {
        audioEngine.stop()
        recognitionRequest?.endAudio()

        // Remove tap from audio engine input
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    func clearTranscription() {
        transcription = ""
    }

    // MARK: - File Management

    private func saveTranscription() {
        guard !transcription.isEmpty,
              let recordingURL = lastRecordingURL else {
            return
        }

        // Create transcription filename (same name as audio, but .txt)
        let transcriptionURL = recordingURL.deletingPathExtension().appendingPathExtension("txt")

        // Create metadata with timestamp
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let metadata = """
        Recording: \(recordingURL.lastPathComponent)
        Transcribed: \(timestamp)

        \(transcription)
        """

        do {
            try metadata.write(to: transcriptionURL, atomically: true, encoding: .utf8)
            print("Transcription saved: \(transcriptionURL.path)")
        } catch {
            print("Failed to save transcription: \(error.localizedDescription)")
        }
    }

    func sendToClaude() -> Bool {
        guard !transcription.isEmpty else {
            return false
        }

        // Create claude-prompts directory in Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let claudeDir = documentsPath.appendingPathComponent("claude-prompts")
        try? FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)

        // Save to claude-prompts with timestamp
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let claudePromptURL = claudeDir.appendingPathComponent("prompt_\(timestamp).txt")

        do {
            try transcription.write(to: claudePromptURL, atomically: true, encoding: .utf8)
            print("Prompt saved for Claude: \(claudePromptURL.path)")

            // Copy to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(transcription, forType: .string)

            return true
        } catch {
            print("Failed to save Claude prompt: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Claude Desktop Integration

    enum ClaudeDesktopProject: Int {
        case current = 0      // Stay in current project
        case project1 = 1     // Cmd+1
        case project2 = 2     // Cmd+2
        case project3 = 3     // Cmd+3
        case project4 = 4     // Cmd+4
        case project5 = 5     // Cmd+5
    }

    func sendToClaudeDesktop(project: ClaudeDesktopProject = .current) -> (success: Bool, error: String?) {
        guard !transcription.isEmpty else {
            return (false, "No transcription available")
        }

        // Copy to clipboard first (safer for Electron apps)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(transcription, forType: .string)

        // Build project navigation keystroke if needed
        let projectNavigation = project == .current ? "" : """
            -- Navigate to project \(project.rawValue)
            keystroke "\(project.rawValue)" using command down
            delay 0.3

        """

        // Use System Events exclusively (works better with Electron apps)
        let script = """
        tell application "System Events"
            -- Find Claude process
            if not (exists process "Claude") then
                error "Claude Desktop is not running. Please open Claude Desktop app."
            end if

            -- Activate Claude
            set frontmost of process "Claude" to true
            delay 0.5

            \(projectNavigation)
            -- Click in the input area first (ensures focus)
            -- Cmd+L focuses the input in Claude Desktop
            keystroke "l" using command down
            delay 0.2

            -- Paste the transcription
            keystroke "v" using command down
            delay 0.3

            -- Submit with Enter
            keystroke return
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                print("AppleScript error: \(errorMessage)")
                return (false, errorMessage)
            }
            return (true, nil)
        } else {
            return (false, "Failed to create AppleScript")
        }
    }

    // MARK: - Claude Code Integration

    enum ClaudeCodeMethod {
        case clipboard      // Copy to clipboard, you paste manually (safest)
        case iTerm         // Send to iTerm via AppleScript
        case tmux(String)  // Send to specific tmux session
        case file          // Write to file that Claude Code watches
    }

    func sendToClaudeCode(method: ClaudeCodeMethod = .clipboard) -> (success: Bool, error: String?) {
        guard !transcription.isEmpty else {
            return (false, "No transcription available")
        }

        switch method {
        case .clipboard:
            return sendToClaudeCodeViaClipboard()

        case .iTerm:
            return sendToClaudeCodeViaiTerm()

        case .tmux(let sessionName):
            return sendToClaudeCodeViaTmux(sessionName: sessionName)

        case .file:
            return sendToClaudeCodeViaFile()
        }
    }

    // Method 1: Clipboard (most reliable)
    private func sendToClaudeCodeViaClipboard() -> (success: Bool, error: String?) {
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(transcription, forType: .string)

        // Activate Terminal/iTerm
        let script = """
        tell application "System Events"
            -- Try to find Terminal or iTerm
            set terminalApp to ""
            if exists process "iTerm2" then
                set terminalApp to "iTerm2"
            else if exists process "Terminal" then
                set terminalApp to "Terminal"
            end if

            if terminalApp is not "" then
                set frontmost of process terminalApp to true
                delay 0.3
                -- Paste with Cmd+V
                keystroke "v" using command down
            else
                error "No terminal application running"
            end if
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                print("AppleScript error: \(errorMessage)")
                return (false, errorMessage)
            }
            return (true, nil)
        } else {
            return (false, "Failed to create AppleScript")
        }
    }

    // Method 2: iTerm AppleScript (if you use iTerm)
    private func sendToClaudeCodeViaiTerm() -> (success: Bool, error: String?) {
        // Escape for AppleScript
        let escapedText = transcription
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "iTerm"
            activate
            delay 0.3
            tell current session of current window
                write text "\(escapedText)"
            end tell
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                print("AppleScript error: \(errorMessage)")
                return (false, errorMessage)
            }
            return (true, nil)
        } else {
            return (false, "Failed to create AppleScript")
        }
    }

    // Method 3: tmux session targeting
    private func sendToClaudeCodeViaTmux(sessionName: String) -> (success: Bool, error: String?) {
        // Escape for shell
        let escapedText = transcription
            .replacingOccurrences(of: "'", with: "'\\''")

        // Use tmux send-keys to send to specific session
        let command = "tmux send-keys -t '\(sessionName)' '\(escapedText)' Enter"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                return (true, nil)
            } else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: data, encoding: .utf8) ?? "Unknown error"
                return (false, "tmux error: \(errorOutput)")
            }
        } catch {
            return (false, "Failed to run tmux: \(error.localizedDescription)")
        }
    }

    // Method 4: File-based communication
    private func sendToClaudeCodeViaFile() -> (success: Bool, error: String?) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let claudeCodeDir = documentsPath.appendingPathComponent("claude-code-inbox")
        try? FileManager.default.createDirectory(at: claudeCodeDir, withIntermediateDirectories: true)

        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let promptURL = claudeCodeDir.appendingPathComponent("prompt_\(timestamp).txt")

        do {
            try transcription.write(to: promptURL, atomically: true, encoding: .utf8)
            print("Prompt saved for Claude Code: \(promptURL.path)")
            return (true, nil)
        } catch {
            return (false, "Failed to save file: \(error.localizedDescription)")
        }
    }

    // MARK: - Ollama Integration

    func sendToOllama(serverURL: String = "http://192.168.50.96:11434",
                      model: String = "qwen2.5-coder:3b-instruct-q4_K_M",
                      completion: @escaping (Result<String, Error>) -> Void) {
        guard !transcription.isEmpty else {
            completion(.failure(NSError(domain: "AudioRecorder", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No transcription available"])))
            return
        }

        // Create request
        guard let url = URL(string: "\(serverURL)/api/generate") else {
            completion(.failure(NSError(domain: "AudioRecorder", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create JSON payload
        let payload: [String: Any] = [
            "model": model,
            "prompt": transcription,
            "stream": false
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }

        // Send request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "AudioRecorder", code: 4,
                    userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                // Parse JSON response
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = json["response"] as? String {
                    completion(.success(response))
                } else {
                    completion(.failure(NSError(domain: "AudioRecorder", code: 5,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    // MARK: - Timer

    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
    }

    private func updateDuration() {
        guard let startTime = startTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60

        DispatchQueue.main.async {
            self.recordingDuration = String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
