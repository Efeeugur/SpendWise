import Foundation

enum AppConfig {
    // Reads from Info.plist (populated via Secrets.xcconfig)
    // Falls back to hardcoded values for development
    static let supabaseURL: String = {
        if let value = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, !value.isEmpty {
            return value
        }
        return "https://nnxrgfmqcmedbnymuhov.supabase.co"
    }()
    
    static let supabaseAnonKey: String = {
        if let value = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !value.isEmpty {
            return value
        }
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ueHJnZm1xY21lZGJueW11aG92Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2NTc4MTYsImV4cCI6MjA3MDIzMzgxNn0.9jN5UIDHgOH_ssE2GnsvZZ6mIHG-KZ23QsC3x3CdvcE"
    }()
    
    static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()

    static let buildNumber: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }()
}


