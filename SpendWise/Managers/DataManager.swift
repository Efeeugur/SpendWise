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
    
    func updateIncome(_ income: Income) async {
        if let index = incomes.firstIndex(where: { $0.id == income.id }) {
            incomes[index] = income
            saveLocalData()
            if userId != "guest" {
                do {
                    try await SupabaseService.shared.updateIncome(income)
                } catch {
                    print("Failed to update income in Supabase: \(error)")
                }
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
    
    func updateExpense(_ expense: Expense) async {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveLocalData()
            if userId != "guest" {
                do {
                    try await SupabaseService.shared.updateExpense(expense)
                } catch {
                    print("Failed to update expense in Supabase: \(error)")
                }
            }
        }
    }
    
    // MARK: - Synchronization
    func sync() async {
        guard userId != "guest" else { return }
        do {
            let remoteIncomes = try await SupabaseService.shared.fetchIncomes(email: userId)
            let remoteExpenses = try await SupabaseService.shared.fetchExpenses(email: userId)
            
            // Merge logic: Prevent local unsynced data from being wiped out
            let localIncomes = UserDefaultsManager.loadIncomes(forUser: userId)
            let localExpenses = UserDefaultsManager.loadExpenses(forUser: userId)
            
            var finalIncomes = remoteIncomes
            for localIncome in localIncomes {
                if !remoteIncomes.contains(where: { $0.id == localIncome.id }) {
                    do {
                        try await SupabaseService.shared.createIncome(email: userId, income: localIncome)
                        finalIncomes.append(localIncome)
                    } catch {
                        print("Failed to upload missing local income: \(error)")
                        finalIncomes.append(localIncome)
                    }
                }
            }
            
            var finalExpenses = remoteExpenses
            for localExpense in localExpenses {
                if !remoteExpenses.contains(where: { $0.id == localExpense.id }) {
                    do {
                        try await SupabaseService.shared.createExpense(email: userId, expense: localExpense)
                        finalExpenses.append(localExpense)
                    } catch {
                        print("Failed to upload missing local expense: \(error)")
                        finalExpenses.append(localExpense)
                    }
                }
            }
            
            self.incomes = finalIncomes.sorted { $0.date > $1.date }
            self.expenses = finalExpenses.sorted { $0.date > $1.date }
            saveLocalData()
        } catch {
            print("Failed to sync data from Supabase: \(error)")
        }
    }
}
