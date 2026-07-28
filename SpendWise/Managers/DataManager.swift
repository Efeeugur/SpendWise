import SwiftUI
import Combine

@MainActor
final class DataManager: ObservableObject {
    @Published var user: User?
    @Published var incomes: [Income] = []
    @Published var expenses: [Expense] = []
    
    var userId: String {
        guard let u = user else { return "guest" }
        if u.isGuest { return "guest" }
        return u.email ?? "guest"
    }
    
    init() {
        if UserDefaultsManager.loadUser() == nil {
            UserDefaultsManager.saveUser(User(isGuest: true))
        }
        self.user = UserDefaultsManager.loadUser()
        loadLocalData()
    }
    
    func updateUser(_ newUser: User?) {
        self.user = newUser
        if let u = newUser {
            UserDefaultsManager.saveUser(u)
        } else {
            UserDefaultsManager.saveUser(User(isGuest: true))
            self.user = User(isGuest: true)
        }
        loadLocalData()
    }
    
    func loadLocalData() {
        if userId == "guest" {
            incomes = []
            expenses = []
        } else {
            incomes = UserDefaultsManager.loadIncomes(forUser: userId)
            expenses = UserDefaultsManager.loadExpenses(forUser: userId)
        }
    }
    
    func saveLocalData() {
        if userId != "guest" {
            UserDefaultsManager.saveIncomes(incomes, forUser: userId)
            UserDefaultsManager.saveExpenses(expenses, forUser: userId)
        }
    }
    
    func logout() {
        updateUser(nil)
        incomes = []
        expenses = []
    }
    
    // MARK: - CRUD Operations
    func addIncome(_ income: Income) async {
        incomes.append(income)
        saveLocalData()
        if userId != "guest" {
            do {
                try await SupabaseService.shared.createIncome(email: userId, income: income)
            } catch {
                print("Failed to sync new income to Supabase: \(error)")
            }
        }
    }
    
    func deleteIncome(id: UUID) async {
        incomes.removeAll { $0.id == id }
        saveLocalData()
        if userId != "guest" {
            do {
                try await SupabaseService.shared.deleteIncome(id: id)
            } catch {
                print("Failed to delete income from Supabase: \(error)")
            }
        }
    }
    
    func addExpense(_ expense: Expense) async {
        expenses.append(expense)
        saveLocalData()
        if userId != "guest" {
            do {
                try await SupabaseService.shared.createExpense(email: userId, expense: expense)
            } catch {
                print("Failed to sync new expense to Supabase: \(error)")
            }
        }
    }
    
    func deleteExpense(id: UUID) async {
        expenses.removeAll { $0.id == id }
        saveLocalData()
        if userId != "guest" {
            do {
                try await SupabaseService.shared.deleteExpense(id: id)
            } catch {
                print("Failed to delete expense from Supabase: \(error)")
            }
        }
    }
    
    // MARK: - Synchronization
    func sync() async {
        guard userId != "guest" else { return }
        do {
            let remoteIncomes = try await SupabaseService.shared.fetchIncomes(email: userId)
            let remoteExpenses = try await SupabaseService.shared.fetchExpenses(email: userId)
            
            // Simple overwrite strategy for now (Server wins)
            self.incomes = remoteIncomes
            self.expenses = remoteExpenses
            saveLocalData()
        } catch {
            print("Failed to sync data from Supabase: \(error)")
        }
    }
}
