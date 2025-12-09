import Foundation

struct RecordingItem: Identifiable, Codable {
    let id: UUID
    let audioURL: URL
    let transcriptionURL: URL
    let timestamp: Date
    var transcription: String
    var duration: TimeInterval

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var filename: String {
        audioURL.lastPathComponent
    }

    init(audioURL: URL, transcriptionURL: URL, timestamp: Date, transcription: String, duration: TimeInterval = 0) {
        self.id = UUID()
        self.audioURL = audioURL
        self.transcriptionURL = transcriptionURL
        self.timestamp = timestamp
        self.transcription = transcription
        self.duration = duration
    }
}
