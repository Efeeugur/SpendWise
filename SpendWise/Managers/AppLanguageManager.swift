import Foundation
import SwiftUI

class AppLanguageManager: ObservableObject {
    static let shared = AppLanguageManager()
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "AppLanguage")
            Bundle.setLanguage(selectedLanguage)
            objectWillChange.send()
        }
    }
    let supportedLanguages = ["en", "tr"]
    let languageDisplayNames = ["en": "English", "tr": "Türkçe"]

    private init() {
        // Load saved language or default to English
        let saved = UserDefaults.standard.string(forKey: "AppLanguage") ?? "en"
        self.selectedLanguage = saved
        Bundle.setLanguage(saved)
    }
}

extension Bundle {
    private static var bundleKey: UInt8 = 0
    static func setLanguage(_ language: String) {
        object_setClass(Bundle.main, PrivateBundle.self)
        objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle(path: Bundle.main.path(forResource: language, ofType: "lproj") ?? ""), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    private class PrivateBundle: Bundle, @unchecked Sendable {
        override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
            if let bundle = objc_getAssociatedObject(self, &Bundle.bundleKey) as? Bundle {
                return bundle.localizedString(forKey: key, value: value, table: tableName)
            } else {
                return super.localizedString(forKey: key, value: value, table: tableName)
            }
        }
    }
} 
