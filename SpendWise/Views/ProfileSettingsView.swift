import SwiftUI
import Combine
import UIKit
import PhotosUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @State private var notificationsEnabled: Bool = true
    @State private var darkModeEnabled: Bool = false
    @Binding var user: User?
    @Binding var isAuthSheetPresented: Bool
    @State private var monthlyLimitText: String = ""
    @State private var showLimitSaved: Bool = false
    @State private var showiCloudMessage: String? = nil
    @State private var defaultCurrency: Currency = UserDefaultsManager.loadDefaultCurrency()
    @State private var recommendationsEnabled: Bool = UserDefaultsManager.loadRecommendationsEnabled()
    @State private var showingSecurityView = false
    @State private var showAccountSheet = false
    @AppStorage("homeCards") private var homeCardsRaw: String = "[\"lastExpenses\",\"monthlySummary\",\"categoryDistribution\"]"
    private var allCards: [(String, String)] = [
        ("lastExpenses", "Recent Expenses"),
        ("monthlySummary", "Monthly Summary"),
        ("categoryDistribution", "Category Distribution")
    ]
    private var userId: String {
        if let user = user {
            if user.isGuest { return "guest" }
            if let email = user.email, !email.isEmpty { return email }
        }
        return "guest"
    }
    var homeCards: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(homeCardsRaw.utf8))) ?? ["lastExpenses", "monthlySummary", "categoryDistribution"]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue), let str = String(data: data, encoding: .utf8) {
                homeCardsRaw = str
            }
        }
    }
    public init(user: Binding<User?>, isAuthSheetPresented: Binding<Bool> = .constant(false)) {
        self._user = user
        self._isAuthSheetPresented = isAuthSheetPresented
    }
    var body: some View {
        NavigationStack {
            SwiftUI.Form {
                // ACCOUNT
                Section(header: Text("Account")) {
                    VStack(spacing: 12) {
                        Button(action: {
                            if let user = user, user.isGuest {
                                isAuthSheetPresented = true
                            } else {
                                showAccountSheet = true
                            }
                        }) {
                            if let user = user, !user.isGuest, let avatarData = user.avatarData,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: 80, height: 80)
                                    .padding(.top, 16)
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.accentColor)
                                    .padding(.top, 16)
                            }
                        }
                        .sheet(isPresented: $showAccountSheet) {
                            AccountSheetView(user: $user, onLogout: handleLogout)
                        }
                        Text(getUserDisplayName())
                            .font(.title2.bold())
                        if let email = user?.email, !email.isEmpty {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                // APP
                Section(header: Text("App")) {
                    Picker("Theme", selection: $themeManager.selectedTheme) {
                        ForEach(UserDefaultsManager.AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    Picker("Language", selection: $languageManager.selectedLanguage) {
                        ForEach(languageManager.supportedLanguages, id: \.self) { lang in
                            Text(languageManager.languageDisplayNames[lang] ?? lang).tag(lang)
                        }
                    }
                    Toggle(isOn: $notificationsEnabled) { Text("Notifications Enabled") }
                    Toggle(isOn: $recommendationsEnabled) { Text("Smart Recommendations") }
                        .onChange(of: recommendationsEnabled) { newValue in
                            UserDefaultsManager.saveRecommendationsEnabled(newValue)
                        }
                    if recommendationsEnabled {
                        Text("The app analyzes your spending habits and offers personalized suggestions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Button { showingSecurityView = true } label: {
                        HStack {
                            Image(systemName: "lock.shield"); Text("Security"); Spacer()
                            Text(UserDefaultsManager.loadSecurityType().rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    // Monthly limit
                    HStack {
                        Text("Monthly Spending Limit"); Spacer()
                        TextField("0", text: $monthlyLimitText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Button(action: {
                            if let limit = Double(monthlyLimitText.replacingOccurrences(of: ",", with: ".")) {
                                UserDefaultsManager.saveMonthlyLimit(limit)
                                showLimitSaved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showLimitSaved = false }
                            }
                        }) { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                    }
                    if showLimitSaved { Text("Limit saved!").font(.caption).foregroundColor(.green) }
                }
            }
            .navigationTitle("Profile & Settings")
            .onAppear {
                if let user = user, user.isGuest, UserDefaultsManager.loadGuestCreatedAt() == nil { UserDefaultsManager.saveGuestCreatedAt(Date()) }
                if let user = user, user.isGuest, UserDefaultsManager.shouldClearGuestData() {
                    UserDefaultsManager.clearAllUserData(forUser: userId)
                    self.user = nil
                }
                if let limit = UserDefaultsManager.loadMonthlyLimit() { monthlyLimitText = String(format: "%.2f", limit) }
            }
            .sheet(isPresented: $showingSecurityView) { SecurityView() }
            .sheet(isPresented: $isAuthSheetPresented) { LoginOrRegisterView(user: $user, isPresented: $isAuthSheetPresented) }
        }
    }
    private var dateFormatter: DateFormatter {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }
    private func bindingForCard(_ cardKey: String) -> Binding<Bool> {
        Binding(get: { homeCards.contains(cardKey) }, set: { isOn in
            var updated = homeCards
            if isOn { if !updated.contains(cardKey) { updated.append(cardKey) } } else { updated.removeAll { $0 == cardKey } }
            if let data = try? JSONEncoder().encode(updated), let str = String(data: data, encoding: .utf8) { homeCardsRaw = str }
        })
    }
    private func getUserDisplayName() -> String {
        guard let user = user else { return "Guest User" }
        
        if user.isGuest {
            return "Guest User"
        }
        
        // If user has a name, use it
        if let name = user.name, !name.isEmpty {
            return name
        }
        
        // Otherwise derive from email
        if let email = user.email, !email.isEmpty {
            return email.components(separatedBy: "@").first?.capitalized ?? "User"
        }
        
        return "User"
    }
    
    func handleLogout() {
        UserDefaultsManager.clearAllUserData(forUser: userId)
        UserDefaultsManager.saveIncomes([], forUser: userId)
        UserDefaultsManager.saveExpenses([], forUser: userId)
        user = nil
        isAuthSheetPresented = true
    }
}

struct AccountSheetView: View {
    @Binding var user: User?
    let onLogout: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var age: Int = 0
    @State private var gender: String = "Not Specified"
    @State private var avatarItem: PhotosPickerItem?
    @State private var selectedAvatarImage: UIImage? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile")) {
                    HStack(spacing: 16) {
                        ZStack {
                            if let ui = selectedAvatarImage {
                                Image(uiImage: ui)
                                    .resizable().scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else if let data = user?.avatarData, let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable().scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill").font(.system(size: 80)).foregroundColor(.secondary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(getUserDisplayNameForAccount()).font(.headline)
                            if let email = user?.email { Text(email).font(.subheadline).foregroundColor(.secondary) }
                            PhotosPicker(selection: $avatarItem, matching: .images, photoLibrary: .shared()) {
                                Label("Change Photo", systemImage: "camera").font(.subheadline)
                            }
                            .disabled(user?.isGuest == true)
                        }
                    }
                }
                if let u = user, !u.isGuest {
                    Section(header: Text("Preferences")) {
                        Stepper(value: $age, in: 0...120) { Text("Age: \(age)") }
                        Picker("Gender", selection: $gender) {
                            Text("Not Specified").tag("Not Specified"); Text("Male").tag("Male"); Text("Female").tag("Female"); Text("Other").tag("Other")
                        }.pickerStyle(.segmented)
                    }
                    Section(header: Text("Session")) {
                        Button(role: .destructive) { onLogout(); dismiss() } label: { Label("Logout", systemImage: "rectangle.portrait.and.arrow.right") }
                        Button(role: .destructive) { showDeleteAlert = true } label: { Label("Clear All Data", systemImage: "trash") }
                            .alert(isPresented: $showDeleteAlert) {
                                Alert(title: Text("Clear All Data"), message: Text("Are you sure you want to permanently clear all your data? This action cannot be undone."), primaryButton: .destructive(Text("Yes, Clear")) { Task { await handleDeleteAccount(); dismiss() } }, secondaryButton: .cancel())
                            }
                    }
                } else {
                    Section(header: Text("Session")) {
                        Button { onLogout(); dismiss() } label: { Label("Sign In", systemImage: "person.crop.circle.badge.plus") }
                    }
                }
            }
            .navigationTitle("Account Details").navigationBarTitleDisplayMode(.inline)
            .onChange(of: avatarItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        selectedAvatarImage = UIImage(data: data)
                        if var u = user { u.avatarData = data; user = u }
                    }
                }
            }
        }
    }
    private func getUserDisplayNameForAccount() -> String {
        guard let user = user else { return "Guest User" }
        
        if user.isGuest {
            return "Guest User"
        }
        
        // If user has a name, use it
        if let name = user.name, !name.isEmpty {
            return name
        }
        
        // Otherwise derive from email
        if let email = user.email, !email.isEmpty {
            return email.components(separatedBy: "@").first?.capitalized ?? "User"
        }
        
        return "User"
    }
    
    @MainActor
    func handleDeleteAccount() async {
        guard let u = user else { return }
        let userId: String
        if u.isGuest { userId = "guest" } else if let email = u.email, !email.isEmpty { userId = email } else { userId = "guest" }
        if userId != "guest" { isDeleting = true; do { try await SupabaseService.shared.deleteAllData(forEmail: userId) } catch { }; isDeleting = false }
        UserDefaultsManager.saveIncomes([], forUser: userId)
        UserDefaultsManager.saveExpenses([], forUser: userId)
        UserDefaultsManager.saveUser(nil)
        UserDefaultsManager.clearGuestCreatedAt()
    }
}
