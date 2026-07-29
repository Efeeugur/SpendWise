import SwiftUI

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
}

@MainActor

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    @State private var showProfileSheet = false
    @State private var showAuthSheet: Bool = false // do not force auth on launch

    @ObservedObject private var securityManager = SecurityManager.shared
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
                    showAuthSheet: $showAuthSheet
                )
                .errorHandling()
                .performanceToast()
                .sheet(isPresented: $showAuthSheet) {
                    LoginOrRegisterView(isPresented: $showAuthSheet)
                }
            }
        }
        .onAppear {
            if UserDefaultsManager.loadSecurityType() != .none {
                securityManager.isAuthenticated = false
            }
            Task {
                await dataManager.sync()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
            dataManager.updateUser(UserDefaultsManager.loadUser())
            Task {
                await dataManager.sync()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if UserDefaultsManager.loadSecurityType() != .none {
                securityManager.logout()
            }
            // Update last active time for session timeout
            KeychainManager.updateLastActiveTime()
            if dataManager.userId == "guest" {
                dataManager.logout()
                UserDefaultsManager.markLastSessionAsGuest(true)
                UserDefaultsManager.setClearGuestOnLaunch(true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check session timeout on return from background
            if UserDefaultsManager.loadSecurityType() != .none {
                securityManager.checkSessionTimeout()
            }
        }
    }
    
    func handleLogout() {
        dataManager.logout()
        showAuthentication = false
    }
}
