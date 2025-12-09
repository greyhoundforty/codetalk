import Foundation

/// Model representing a single recording and its transcription metadata.
/// Conforms to Identifiable and Hashable so it can be used directly with SwiftUI's
/// List selection and .tag(...) APIs.
///
/// This version keeps the property names expected by RecordingsManager:
/// - audioURL
/// - transcriptionURL
/// - timestamp
/// - transcription
struct RecordingItem: Identifiable, Hashable {
    let id: UUID
    let filename: String
    var transcription: String
    let audioURL: URL
    let transcriptionURL: URL
    let timestamp: Date
    /// Optional duration in seconds (if available)
    let duration: TimeInterval?

    // MARK: - Computed properties used by the UI

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var formattedDuration: String {
        guard let duration = duration, duration > 0 else { return "" }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? ""
    }

    // MARK: - Initializers

    /// Primary initializer that matches how RecordingsManager constructs items:
    /// RecordingItem(audioURL: , transcriptionURL: , timestamp: , transcription: )
    init(
        id: UUID = UUID(),
        filename: String? = nil,
        transcription: String = "",
        audioURL: URL,
        transcriptionURL: URL,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.audioURL = audioURL
        self.transcriptionURL = transcriptionURL
        self.timestamp = timestamp
        self.transcription = transcription
        self.duration = duration
        // If filename isn't provided, default to the audio file's lastPathComponent
        self.filename = filename ?? audioURL.lastPathComponent
    }

    /// Convenience initializer that mirrors the call-site ordering used in RecordingsManager.
    /// Allows calls like:
    /// RecordingItem(audioURL: audioURL, transcriptionURL: transcriptionURL, timestamp: timestamp, transcription: transcription)
    init(audioURL: URL, transcriptionURL: URL, timestamp: Date = Date(), transcription: String = "") {
        self.init(id: UUID(), filename: audioURL.lastPathComponent, transcription: transcription, audioURL: audioURL, transcriptionURL: transcriptionURL, timestamp: timestamp, duration: nil)
    }
}
