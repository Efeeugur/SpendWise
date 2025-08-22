import SwiftUI

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
}

struct ContentView: View {
    @State private var user: User? = UserDefaultsManager.loadUser()

    // Kullanıcı id'si (email veya guest)
    @State private var userId: String = UserDefaultsManager.loadUser()?.isGuest == true ? "guest" : (UserDefaultsManager.loadUser()?.email ?? "guest")

    @State private var incomes: [Income] = UserDefaultsManager.loadIncomes(forUser: UserDefaultsManager.loadUser()?.isGuest == true ? "guest" : (UserDefaultsManager.loadUser()?.email ?? "guest"))
    @State private var expenses: [Expense] = UserDefaultsManager.loadExpenses(forUser: UserDefaultsManager.loadUser()?.isGuest == true ? "guest" : (UserDefaultsManager.loadUser()?.email ?? "guest"))
    @State private var showProfileSheet = false
    @State private var currentUser: User? = UserDefaultsManager.loadUser()
    @State private var showAuthSheet: Bool = false // do not force auth on launch

    @StateObject private var securityManager = SecurityManager.shared
    @State private var showAuthentication: Bool = false
    @State private var selectedTab = 2 // Summary as default tab

    var incomesTab: some View {
        NavigationStack {
            IncomesView(incomes: $incomes, userId: $userId)
                .navigationTitle("Incomes".localized)
        }
        .tabItem {
            Label("Incomes".localized, systemImage: "arrow.up.circle")
        }
        .tag(0)
    }
    var expensesTab: some View {
        NavigationStack {
            ExpensesView(expenses: $expenses, userId: $userId)
                .navigationTitle("Expenses".localized)
        }
        .tabItem {
            Label("Expenses".localized, systemImage: "arrow.down.circle")
        }
        .tag(1)
    }
    var summaryTab: some View {
        NavigationStack {
            SummaryView(incomes: $incomes, expenses: $expenses)
                .navigationTitle("Summary".localized)
        }
        .tabItem {
            Label("Summary".localized, systemImage: "chart.pie")
        }
        .tag(2)
    }
    var settingsTab: some View {
        NavigationStack {
            ProfileSettingsView(user: $user, isAuthSheetPresented: $showAuthSheet)
        }
        .tabItem {
            Label("Settings".localized, systemImage: "gearshape")
        }
        .tag(3)
    }

    var body: some View {
        Group {
            if !securityManager.isAuthenticated && UserDefaultsManager.loadSecurityType() != .none {
                AuthenticationView {
                    securityManager.isAuthenticated = true
                }
            } else {
                TabView(selection: $selectedTab) {
                    incomesTab
                    expensesTab
                    summaryTab
                    settingsTab
                }
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
