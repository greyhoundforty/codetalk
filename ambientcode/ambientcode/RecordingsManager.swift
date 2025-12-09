import Foundation
import Combine

class RecordingsManager: ObservableObject {
    @Published var recordings: [RecordingItem] = []

    private let recordingsDirectory: URL
    private let fileManager = FileManager.default

    init() {
        recordingsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings")

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)

        loadRecordings()
    }

    func loadRecordings() {
        do {
            let files = try fileManager.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)

            // Find all .m4a files
            let audioFiles = files.filter { $0.pathExtension == "m4a" }

            var items: [RecordingItem] = []

            for audioURL in audioFiles {
                let transcriptionURL = audioURL.deletingPathExtension().appendingPathExtension("txt")

                // Read transcription if exists
                var transcription = ""
                if fileManager.fileExists(atPath: transcriptionURL.path) {
                    transcription = (try? String(contentsOf: transcriptionURL)) ?? ""

                    // Extract just the transcription text (skip metadata lines)
                    let lines = transcription.components(separatedBy: .newlines)
                    if lines.count > 2 {
                        transcription = lines.dropFirst(3).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }

                // Get creation date
                let attributes = try? fileManager.attributesOfItem(atPath: audioURL.path)
                let timestamp = attributes?[.creationDate] as? Date ?? Date()

                let item = RecordingItem(
                    audioURL: audioURL,
                    transcriptionURL: transcriptionURL,
                    timestamp: timestamp,
                    transcription: transcription
                )

                items.append(item)
            }

            // Sort by date, newest first
            recordings = items.sorted { $0.timestamp > $1.timestamp }

            print("Loaded \(recordings.count) recordings")

        } catch {
            print("Failed to load recordings: \(error)")
            recordings = []
        }
    }

    func addRecording(_ item: RecordingItem) {
        recordings.insert(item, at: 0) // Add to beginning
    }

    func updateRecording(_ item: RecordingItem, withTranscription newTranscription: String) {
        // Find and update the recording
        if let index = recordings.firstIndex(where: { $0.id == item.id }) {
            recordings[index].transcription = newTranscription

            // Save updated transcription to file
            saveTranscription(newTranscription, to: item.transcriptionURL, audioFilename: item.audioURL.lastPathComponent)
        }
    }

    private func saveTranscription(_ text: String, to url: URL, audioFilename: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let metadata = """
        Recording: \(audioFilename)
        Transcribed: \(timestamp)

        \(text)
        """

        do {
            try metadata.write(to: url, atomically: true, encoding: .utf8)
            print("Updated transcription saved: \(url.path)")
        } catch {
            print("Failed to save transcription: \(error)")
        }
    }

    func deleteRecording(_ item: RecordingItem) {
        // Remove from array
        recordings.removeAll { $0.id == item.id }

        // Delete files
        try? fileManager.removeItem(at: item.audioURL)
        try? fileManager.removeItem(at: item.transcriptionURL)
    }

    func refreshRecordings() {
        loadRecordings()
    }
}
