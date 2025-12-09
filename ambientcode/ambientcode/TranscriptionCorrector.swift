import Foundation
import Combine

/// Learns from user corrections and applies them to future transcriptions
class TranscriptionCorrector: ObservableObject {
    @Published var corrections: [String: String] = [:] // wrong -> correct mapping

    private let correctionsURL: URL

    init() {
        // Store corrections in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDir = appSupport.appendingPathComponent("ambientcode")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        correctionsURL = appDir.appendingPathComponent("transcription-corrections.json")
        loadCorrections()
    }

    // MARK: - Learning from Corrections

    /// Learn from a user's correction by finding what changed
    func learnFromCorrection(original: String, corrected: String) {
        // Split into words for comparison
        let originalWords = original.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let correctedWords = corrected.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

        // Find word-level differences
        let maxCount = max(originalWords.count, correctedWords.count)

        for i in 0..<maxCount {
            if i < originalWords.count && i < correctedWords.count {
                let orig = originalWords[i].lowercased()
                let corr = correctedWords[i].lowercased()

                // If words differ, add to corrections
                if orig != corr && !orig.isEmpty && !corr.isEmpty {
                    corrections[orig] = corr
                    print("Learned correction: '\(orig)' -> '\(corr)'")
                }
            }
        }

        // Also look for phrase-level corrections (2-3 word phrases)
        learnPhraseCorrections(original: original, corrected: corrected)

        saveCorrections()
    }

    private func learnPhraseCorrections(original: String, corrected: String) {
        // Look for common phrases that might be misheard
        let originalSentences = original.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let correctedSentences = corrected.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        for (orig, corr) in zip(originalSentences, correctedSentences) {
            let origTrimmed = orig.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let corrTrimmed = corr.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            if origTrimmed != corrTrimmed && origTrimmed.count > 5 && corrTrimmed.count > 5 {
                // Store phrase-level corrections
                corrections[origTrimmed] = corrTrimmed
                print("Learned phrase correction: '\(origTrimmed)' -> '\(corrTrimmed)'")
            }
        }
    }

    // MARK: - Applying Corrections

    /// Apply learned corrections to a new transcription
    func applyCorrections(to text: String) -> String {
        var corrected = text

        // Apply word-level corrections
        for (wrong, right) in corrections {
            // Case-insensitive replacement while preserving original case pattern
            corrected = replacePreservingCase(in: corrected, wrong: wrong, right: right)
        }

        return corrected
    }

    private func replacePreservingCase(in text: String, wrong: String, right: String) -> String {
        var result = text

        // Replace exact case match
        result = result.replacingOccurrences(of: wrong, with: right)

        // Replace lowercase match
        result = result.replacingOccurrences(of: wrong.lowercased(), with: right)

        // Replace capitalized match
        if let firstChar = wrong.first, let rightFirstChar = right.first {
            let capitalizedWrong = firstChar.uppercased() + wrong.dropFirst()
            let capitalizedRight = rightFirstChar.uppercased() + right.dropFirst()
            result = result.replacingOccurrences(of: capitalizedWrong, with: capitalizedRight)
        }

        // Replace uppercase match
        result = result.replacingOccurrences(of: wrong.uppercased(), with: right.uppercased())

        return result
    }

    // MARK: - Persistence

    private func saveCorrections() {
        do {
            let data = try JSONEncoder().encode(corrections)
            try data.write(to: correctionsURL)
            print("Saved \(corrections.count) corrections to disk")
        } catch {
            print("Failed to save corrections: \(error)")
        }
    }

    private func loadCorrections() {
        do {
            let data = try Data(contentsOf: correctionsURL)
            corrections = try JSONDecoder().decode([String: String].self, from: data)
            print("Loaded \(corrections.count) corrections from disk")
        } catch {
            print("No existing corrections found, starting fresh")
            corrections = [:]
        }
    }

    // MARK: - Management

    func clearAllCorrections() {
        corrections.removeAll()
        saveCorrections()
    }

    func removeCorrection(for word: String) {
        corrections.removeValue(forKey: word.lowercased())
        saveCorrections()
    }

    func exportCorrections() -> String {
        var export = "# Transcription Corrections\n\n"
        export += "Total corrections learned: \(corrections.count)\n\n"

        for (wrong, right) in corrections.sorted(by: { $0.key < $1.key }) {
            export += "\"\(wrong)\" → \"\(right)\"\n"
        }

        return export
    }
}
