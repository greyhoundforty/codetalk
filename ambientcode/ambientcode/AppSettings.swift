import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var ollamaServerURL: String {
        didSet {
            UserDefaults.standard.set(ollamaServerURL, forKey: "ollamaServerURL")
        }
    }
    
    @Published var ollamaModel: String {
        didSet {
            UserDefaults.standard.set(ollamaModel, forKey: "ollamaModel")
        }
    }
    
    init() {
        self.ollamaServerURL = UserDefaults.standard.string(forKey: "ollamaServerURL") ?? "http://192.168.50.96:11434"
        self.ollamaModel = UserDefaults.standard.string(forKey: "ollamaModel") ?? "qwen2.5-coder:3b-instruct-q4_K_M"
    }
    
    func resetToDefaults() {
        ollamaServerURL = "http://192.168.50.96:11434"
        ollamaModel = "qwen2.5-coder:3b-instruct-q4_K_M"
    }
}
