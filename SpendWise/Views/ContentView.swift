import SwiftUI

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
}

@MainActor

struct ContentView: View {
    @State private var user: User? = UserDefaultsManager.loadUser()

    // Kullanıcı id'si (email veya guest)
    @State private var userId: String = UserDefaultsManager.loadUser()?.isGuest == true ? "guest" : (UserDefaultsManager.loadUser()?.email ?? "guest")

    @State private var incomes: [Income] = []
    @State private var expenses: [Expense] = []
    @State private var showProfileSheet = false
    @State private var currentUser: User? = UserDefaultsManager.loadUser()
    @State private var showAuthSheet: Bool = false // do not force auth on launch

    @StateObject private var securityManager = SecurityManager.shared
    @State private var showAuthentication: Bool = false
    @State private var selectedTab = 2 // Summary as default tab


    var body: some View {
        Group {
            if !securityManager.isAuthenticated && UserDefaultsManager.loadSecurityType() != .none {
                AuthenticationView {
                    securityManager.isAuthenticated = true
                }
            } else {
                AnimatedTabView(
                    selectedTab: $selectedTab,
                    incomes: $incomes,
                    expenses: $expenses,
                    user: $user,
                    userId: $userId,
                    showAuthSheet: $showAuthSheet
                )
                .errorHandling()
                .performanceToast()
                .sheet(isPresented: $showAuthSheet) {
                    LoginOrRegisterView(user: $user, isPresented: $showAuthSheet)
                }
            }
        }
        .onAppear {
            // Ensure a user exists entry (guest by default allowed)
            if UserDefaultsManager.loadUser() == nil { UserDefaultsManager.saveUser(User(isGuest: true)) }
            user = UserDefaultsManager.loadUser()
            if UserDefaultsManager.loadSecurityType() != .none {
                securityManager.isAuthenticated = false
            }
            
            // Load data lazily
            Task {
                await loadInitialData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
            // Reload user when login notification is received
            user = UserDefaultsManager.loadUser()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if UserDefaultsManager.loadSecurityType() != .none {
                securityManager.logout()
            }
            // Requirement 2: if not signed in (guest), clear data when leaving app
            if userId == "guest" {
                incomes = []
                expenses = []
                UserDefaultsManager.saveIncomes([], forUser: "guest")
                UserDefaultsManager.saveExpenses([], forUser: "guest")
                UserDefaultsManager.markLastSessionAsGuest(true)
                UserDefaultsManager.setClearGuestOnLaunch(true)
            }
        }
        .onChange(of: user ?? User(isGuest: true)) { newUser in
            let newId = (newUser.isGuest == true) ? "guest" : (newUser.email ?? "guest")
            userId = newId
            
            // Save the updated user state
            UserDefaultsManager.saveUser(newUser)
            
            if newId == "guest" {
                incomes = []
                expenses = []
            } else {
                incomes = UserDefaultsManager.loadIncomes(forUser: newId)
                expenses = UserDefaultsManager.loadExpenses(forUser: newId)
            }
        }
        .onChange(of: incomes) { newIncomes in
            UserDefaultsManager.saveIncomes(newIncomes, forUser: userId)
        }
        .onChange(of: expenses) { newExpenses in
            UserDefaultsManager.saveExpenses(newExpenses, forUser: userId)
        }
    }
    
    @MainActor
    private func loadInitialData() async {
        let currentUserId = (user?.isGuest == true) ? "guest" : (user?.email ?? "guest")
        
        do {
            // Load data in background to avoid blocking UI
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    do {
                        let loadedIncomes = UserDefaultsManager.loadIncomes(forUser: currentUserId)
                        await MainActor.run {
                            self.incomes = loadedIncomes
                        }
                    } catch {
                        await MainActor.run {
                            ErrorHandler.shared.handle(
                                AppError.dataCorruption("Failed to load incomes: \(error.localizedDescription)"),
                                context: "loadInitialData"
                            )
                        }
                    }
                }
                
                group.addTask {
                    do {
                        let loadedExpenses = UserDefaultsManager.loadExpenses(forUser: currentUserId)
                        await MainActor.run {
                            self.expenses = loadedExpenses
                        }
                    } catch {
                        await MainActor.run {
                            ErrorHandler.shared.handle(
                                AppError.dataCorruption("Failed to load expenses: \(error.localizedDescription)"),
                                context: "loadInitialData"
                            )
                        }
                    }
                }
            }
        }
    }

    func handleLogout() {
        UserDefaultsManager.saveIncomes([], forUser: userId)
        UserDefaultsManager.saveExpenses([], forUser: userId)
        UserDefaultsManager.saveUser(nil)
        user = nil
        incomes = []
        expenses = []
        showAuthentication = false
    }
}
