import Foundation

enum AppConfig {
    // MARK: - Supabase Configuration
    // Reads from Info.plist (populated via Secrets.xcconfig)
    // In development, create a Secrets.xcconfig file with:
    //   SUPABASE_URL = https://your-project.supabase.co
    //   SUPABASE_ANON_KEY = your-anon-key
    
    static let supabaseURL: String = {
        if let value = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, !value.isEmpty, value != "$(SUPABASE_URL)" {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        #if DEBUG
        print("⚠️ SUPABASE_URL not found in Info.plist. Falling back to Secrets.xcconfig value.")
        #endif
        return "https://nnxrgfmqcmedbnymuhov.supabase.co"
    }()
    
    static let supabaseAnonKey: String = {
        if let value = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !value.isEmpty, value != "$(SUPABASE_ANON_KEY)" {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        #if DEBUG
        print("⚠️ SUPABASE_ANON_KEY not found in Info.plist. Falling back to Secrets.xcconfig value.")
        #endif
        return "sb_publishable_Ggz3XpB9XDYq7ySR91DH9g_sIgJ32Wu"
    }()
    
    // MARK: - App Info (from Bundle)
    static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()
    
    static let buildNumber: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }()
    
    // MARK: - Supabase Availability
    static var isSupabaseConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }
}
