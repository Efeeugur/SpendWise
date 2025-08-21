import SwiftUI

class ThemeManager: ObservableObject {
    @Published var selectedTheme: UserDefaultsManager.AppTheme {
        didSet {
            UserDefaultsManager.saveAppTheme(selectedTheme)
        }
    }
    
    init() {
        self.selectedTheme = UserDefaultsManager.loadAppTheme()
    }
    
    func updateTheme(_ theme: UserDefaultsManager.AppTheme) {
        selectedTheme = theme
    }
    
    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
} 