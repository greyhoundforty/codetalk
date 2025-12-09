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
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
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
