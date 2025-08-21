import SwiftUI

@main
struct SpendWiseApp: App {
    @StateObject private var themeManager = ThemeManager()
    init() {
        NotificationManager.shared.requestAuthorization { _ in }
    }
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}

