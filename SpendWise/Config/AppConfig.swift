import Foundation

enum AppConfig {
    // MARK: - Supabase Configuration
    // Reads from Info.plist (populated via Secrets.xcconfig)
    // In development, create a Secrets.xcconfig file with:
    //   SUPABASE_URL = https://your-project.supabase.co
    //   SUPABASE_ANON_KEY = your-anon-key
    
    static let supabaseURL: String = {
        if let value = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, !value.isEmpty {
            return value
        }
        #if DEBUG
        print("⚠️ SUPABASE_URL not found in Info.plist. Create a Secrets.xcconfig file.")
        #endif
        return ""
    }()
    
    static let supabaseAnonKey: String = {
        if let value = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !value.isEmpty {
            return value
        }
        #if DEBUG
        print("⚠️ SUPABASE_ANON_KEY not found in Info.plist. Create a Secrets.xcconfig file.")
        #endif
        return ""
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
