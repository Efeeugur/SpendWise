import Foundation
import SwiftData
import os.log

/// Central persistence manager backed by SwiftData.
/// Provides the same save/load API as the old UserDefaultsManager
/// so call sites can migrate incrementally.
@MainActor
final class PersistenceManager {
    static let shared = PersistenceManager()
    
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SpendWise", category: "PersistenceManager")
    
    private init() {
        do {
            let schema = Schema([SDExpense.self, SDIncome.self, SDUser.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
            logger.info("SwiftData ModelContainer initialized successfully")
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Expenses
    
    func fetchExpenses(forUser userId: String) -> [Expense] {
        let descriptor = FetchDescriptor<SDExpense>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            let results = try context.fetch(descriptor)
            return results.map { $0.toExpense() }
        } catch {
            logger.error("Failed to fetch expenses: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveExpenses(_ expenses: [Expense], forUser userId: String) {
        // Delete existing expenses for this user
        deleteAllExpenses(forUser: userId)
        
        // Insert new ones
        for expense in expenses {
            let sdExpense = SDExpense(from: expense, userId: userId)
            context.insert(sdExpense)
        }
        
        saveContext()
    }
    
    func appendExpense(_ expense: Expense, forUser userId: String) {
        let sdExpense = SDExpense(from: expense, userId: userId)
        context.insert(sdExpense)
        saveContext()
    }
    
    func deleteExpense(withId id: UUID, forUser userId: String) {
        let descriptor = FetchDescriptor<SDExpense>(
            predicate: #Predicate { $0.id == id && $0.userId == userId }
        )
        do {
            let results = try context.fetch(descriptor)
            for item in results {
                context.delete(item)
            }
            saveContext()
        } catch {
            logger.error("Failed to delete expense: \(error.localizedDescription)")
        }
    }
    
    private func deleteAllExpenses(forUser userId: String) {
        let descriptor = FetchDescriptor<SDExpense>(
            predicate: #Predicate { $0.userId == userId }
        )
        do {
            let results = try context.fetch(descriptor)
            for item in results {
                context.delete(item)
            }
        } catch {
            logger.error("Failed to delete all expenses: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Incomes
    
    func fetchIncomes(forUser userId: String) -> [Income] {
        let descriptor = FetchDescriptor<SDIncome>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            let results = try context.fetch(descriptor)
            return results.map { $0.toIncome() }
        } catch {
            logger.error("Failed to fetch incomes: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveIncomes(_ incomes: [Income], forUser userId: String) {
        deleteAllIncomes(forUser: userId)
        
        for income in incomes {
            let sdIncome = SDIncome(from: income, userId: userId)
            context.insert(sdIncome)
        }
        
        saveContext()
    }
    
    func appendIncome(_ income: Income, forUser userId: String) {
        let sdIncome = SDIncome(from: income, userId: userId)
        context.insert(sdIncome)
        saveContext()
    }
    
    func deleteIncome(withId id: UUID, forUser userId: String) {
        let descriptor = FetchDescriptor<SDIncome>(
            predicate: #Predicate { $0.id == id && $0.userId == userId }
        )
        do {
            let results = try context.fetch(descriptor)
            for item in results {
                context.delete(item)
            }
            saveContext()
        } catch {
            logger.error("Failed to delete income: \(error.localizedDescription)")
        }
    }
    
    private func deleteAllIncomes(forUser userId: String) {
        let descriptor = FetchDescriptor<SDIncome>(
            predicate: #Predicate { $0.userId == userId }
        )
        do {
            let results = try context.fetch(descriptor)
            for item in results {
                context.delete(item)
            }
        } catch {
            logger.error("Failed to delete all incomes: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User
    
    func saveUser(_ user: User?) {
        // Delete existing users
        let descriptor = FetchDescriptor<SDUser>()
        do {
            let existing = try context.fetch(descriptor)
            for u in existing {
                context.delete(u)
            }
        } catch {
            logger.error("Failed to clear existing users: \(error.localizedDescription)")
        }
        
        if let user = user {
            let sdUser = SDUser(from: user)
            context.insert(sdUser)
        }
        
        saveContext()
    }
    
    func loadUser() -> User? {
        let descriptor = FetchDescriptor<SDUser>()
        do {
            let results = try context.fetch(descriptor)
            return results.first?.toUser()
        } catch {
            logger.error("Failed to load user: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Clear All
    
    func clearAllData(forUser userId: String) {
        deleteAllExpenses(forUser: userId)
        deleteAllIncomes(forUser: userId)
        saveContext()
    }
    
    // MARK: - Private
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            logger.error("Failed to save SwiftData context: \(error.localizedDescription)")
        }
    }
}
