import Foundation
import os.log

/// Handles one-time migration from UserDefaults JSON storage to SwiftData.
/// Runs on first launch after the SwiftData update.
@MainActor
struct MigrationManager {
    
    private static let migrationKey = "swiftdata_migration_completed_v1"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SpendWise", category: "MigrationManager")
    
    /// Call this at app launch. Migrates data if not already done.
    static func migrateIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            logger.info("SwiftData migration already completed, skipping")
            return
        }
        
        logger.info("Starting UserDefaults → SwiftData migration")
        
        var totalMigrated = 0
        
        // Migrate current user
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            PersistenceManager.shared.saveUser(user)
            logger.info("Migrated current user: \(user.email ?? "guest")")
            totalMigrated += 1
            
            // Determine userId for data migration
            let userId = user.email ?? "guest"
            
            // Migrate expenses for this user
            let expenseCount = migrateExpenses(forUser: userId)
            totalMigrated += expenseCount
            
            // Migrate incomes for this user
            let incomeCount = migrateIncomes(forUser: userId)
            totalMigrated += incomeCount
        }
        
        // Also try to migrate guest data if it exists
        let guestExpenseCount = migrateExpenses(forUser: "guest")
        totalMigrated += guestExpenseCount
        let guestIncomeCount = migrateIncomes(forUser: "guest")
        totalMigrated += guestIncomeCount
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        
        logger.info("SwiftData migration completed. Total items migrated: \(totalMigrated)")
    }
    
    // MARK: - Private Migration Helpers
    
    private static func migrateExpenses(forUser userId: String) -> Int {
        let key = "expensesKey_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return 0 }
        
        do {
            let expenses = try JSONDecoder().decode([Expense].self, from: data)
            guard !expenses.isEmpty else { return 0 }
            
            // Check if already migrated (avoid duplicates)
            let existing = PersistenceManager.shared.fetchExpenses(forUser: userId)
            guard existing.isEmpty else {
                logger.info("Expenses for user \(userId) already exist in SwiftData, skipping")
                return 0
            }
            
            PersistenceManager.shared.saveExpenses(expenses, forUser: userId)
            logger.info("Migrated \(expenses.count) expenses for user: \(userId)")
            return expenses.count
        } catch {
            logger.error("Failed to decode expenses for migration: \(error.localizedDescription)")
            return 0
        }
    }
    
    private static func migrateIncomes(forUser userId: String) -> Int {
        let key = "incomesKey_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return 0 }
        
        do {
            let incomes = try JSONDecoder().decode([Income].self, from: data)
            guard !incomes.isEmpty else { return 0 }
            
            let existing = PersistenceManager.shared.fetchIncomes(forUser: userId)
            guard existing.isEmpty else {
                logger.info("Incomes for user \(userId) already exist in SwiftData, skipping")
                return 0
            }
            
            PersistenceManager.shared.saveIncomes(incomes, forUser: userId)
            logger.info("Migrated \(incomes.count) incomes for user: \(userId)")
            return incomes.count
        } catch {
            logger.error("Failed to decode incomes for migration: \(error.localizedDescription)")
            return 0
        }
    }
}
