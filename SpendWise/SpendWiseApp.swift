import SwiftUI
import SwiftData

@main
struct SpendWiseApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var dataManager = DataManager()
    let container: ModelContainer
    
    init() {
        // Initialize SwiftData container
        do {
            let schema = Schema([SDExpense.self, SDIncome.self, SDUser.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        NotificationManager.shared.requestAuthorization { _ in }
        
        // Run one-time UserDefaults → SwiftData migration
        MigrationManager.migrateIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(themeManager)
                .environmentObject(dataManager)
                .preferredColorScheme(themeManager.colorScheme)
                .modelContainer(container)
        }
    }
}
