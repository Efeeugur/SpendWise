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
                // ACCOUNT SECTION
                Section(header: Text("Account".localized)) {
                    Button(action: {
                        if let user = user, user.isGuest {
                            isAuthSheetPresented = true
                        } else {
                            showAccountSheet = true
                        }
                    }) {
                        HStack(spacing: 16) {
                            // Avatar
                            if let user = user, !user.isGuest, let avatarData = user.avatarData,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.accentColor)
                            }
                            
                            // User Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(getUserDisplayName())
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(user?.email ?? "Sign In or Create Account".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showAccountSheet) {
                        AccountSheetView(user: $user, onLogout: handleLogout)
                    }
                }
                
                // APPLICATION SECTION
                Section(header: Text("Application".localized)) {
                    // Notifications
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        Toggle(isOn: $notificationsEnabled) {
                            Text("Notifications".localized)
                        }
                    }
                    
                    // Theme
                    HStack {
                        Image(systemName: themeManager.selectedTheme == .dark ? "moon" : "sun.max")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Picker("Theme".localized, selection: $themeManager.selectedTheme) {
                            ForEach(UserDefaultsManager.AppTheme.allCases, id: \.self) { theme in
                                Text(theme.rawValue.localized).tag(theme)
                            }
                        }
                    }
                    
                    // Language
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Picker("Language".localized, selection: $languageManager.selectedLanguage) {
                            ForEach(languageManager.supportedLanguages, id: \.self) { lang in
                                Text(languageManager.languageDisplayNames[lang] ?? lang).tag(lang)
                            }
                        }
                    }
                    
                    // Currency
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.yellow)
                            .frame(width: 24)
                        Picker("Currency".localized, selection: $defaultCurrency) {
                            ForEach(Currency.allCases, id: \.self) { currency in
                                Text("\(currency.rawValue) (\(currency.symbol))").tag(currency)
                            }
                        }
                        .onChange(of: defaultCurrency) { newValue in
                            UserDefaultsManager.saveDefaultCurrency(newValue)
                        }
                    }
                    
                    // Smart Recommendations
                    HStack {
                        Image(systemName: "brain")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        Toggle(isOn: $recommendationsEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smart Recommendations".localized)
                                if recommendationsEnabled {
                                    Text("AI analyzes spending patterns for insights".localized)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onChange(of: recommendationsEnabled) { newValue in
                        UserDefaultsManager.saveRecommendationsEnabled(newValue)
                    }
                    
                    // Monthly Spending Limit
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("Monthly Spending Limit".localized)
                        Spacer()
                        TextField("0", text: $monthlyLimitText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Button(action: {
                            if let limit = Double(monthlyLimitText.replacingOccurrences(of: ",", with: ".")) {
                                UserDefaultsManager.saveMonthlyLimit(limit)
                                showLimitSaved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showLimitSaved = false
                                }
                            }
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    if showLimitSaved {
                        Text("Limit saved!".localized)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // SECURITY SECTION
                Section(header: Text("Security".localized)) {
                    Button {
                        showingSecurityView = true
                    } label: {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("App Protection".localized)
                                    .foregroundColor(.primary)
                                Text(UserDefaultsManager.loadSecurityType().rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // REPORTS SECTION
                Section(header: Text("Reports".localized)) {
                    // Export Data
                    Button {
                        // TODO: Implement export functionality
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.indigo)
                                .frame(width: 24)
                            Text("Export Data".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // SUPPORT SECTION
                Section(header: Text("Support".localized)) {
                    // Help & FAQ
                    Button {
                        // TODO: Implement help/FAQ
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("Help & FAQ".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Rate App
                    Button {
                        // TODO: Implement rate app functionality
                    } label: {
                        HStack {
                            Image(systemName: "star")
                                .foregroundColor(.yellow)
                                .frame(width: 24)
                            Text("Rate App".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // APP INFO SECTION
                Section(header: Text("App Info".localized)) {
                    HStack {
                        Text("Version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Developer".localized)
                        Spacer()
                        Text("SpendWise Team")
                            .foregroundColor(.secondary)
                    }
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
    @State private var showLogoutAlert = false
    @State private var isDeleting = false
    @State private var isEditing = false
    @State private var editingName: String = ""
    @State private var editingEmail: String = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var selectedAvatarImage: UIImage? = nil
    
    // Date formatter for member since display
    private var memberSinceFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // Placeholder date - could be enhanced to track actual registration date
    private var memberSinceDate: Date {
        // For demo purposes, using a static date
        Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with close and edit buttons
                    HStack {
                        Button("Close".localized) {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text("Profile".localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(isEditing ? "Done".localized : "Edit".localized) {
                            if isEditing {
                                saveChanges()
                            } else {
                                startEditing()
                            }
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    // Avatar Section
                    VStack(spacing: 16) {
                        ZStack {
                            // Avatar Image
                            if let ui = selectedAvatarImage {
                                Image(uiImage: ui)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 96, height: 96)
                                    .clipShape(Circle())
                            } else if let data = user?.avatarData, let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 96, height: 96)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 96))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Camera button for editing
                            if isEditing && !(user?.isGuest == true) {
                                PhotosPicker(selection: $avatarItem, matching: .images, photoLibrary: .shared()) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                .offset(x: 34, y: 34)
                            }
                        }
                        
                        // Member Since Info
                        VStack(spacing: 4) {
                            Text("Member Since".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(memberSinceFormatter.string(from: memberSinceDate))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 24)
                    
                    // User Information Section
                    VStack(spacing: 20) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                Text("Username".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            if isEditing && !(user?.isGuest == true) {
                                TextField("Enter username".localized, text: $editingName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(height: 44)
                            } else {
                                Text(getUserDisplayNameForAccount())
                                    .font(.body)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 44)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                Text("Email".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            if isEditing && !(user?.isGuest == true) {
                                TextField("Enter email".localized, text: $editingEmail)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .frame(height: 44)
                            } else {
                                Text(user?.email ?? "Sign In or Create Account".localized)
                                    .font(.body)
                                    .foregroundColor(user?.email != nil ? .primary : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 44)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Buttons Section
                    VStack(spacing: 16) {
                        if let u = user, !u.isGuest {
                            // Logout Button
                            Button {
                                showLogoutAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18))
                                    Text("Sign Out".localized)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .foregroundColor(.orange)
                                .cornerRadius(12)
                            }
                            
                            // Delete Account Button
                            Button {
                                showDeleteAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18))
                                    Text("Delete Account".localized)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            }
                        } else {
                            // Sign In Button for Guest
                            Button {
                                onLogout()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 18))
                                    Text("Sign In".localized)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .alert("Sign Out Confirmation".localized, isPresented: $showLogoutAlert) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Sign Out".localized, role: .destructive) {
                onLogout()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?".localized)
        }
        .alert("Delete Account".localized, isPresented: $showDeleteAlert) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                Task { await handleDeleteAccount(); dismiss() }
            }
        } message: {
            Text("Are you sure you want to permanently delete your account? This action cannot be undone.".localized)
        }
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
    
    private func startEditing() {
        isEditing = true
        editingName = user?.name ?? ""
        editingEmail = user?.email ?? ""
    }
    
    private func saveChanges() {
        if var u = user {
            u.name = editingName.isEmpty ? nil : editingName
            u.email = editingEmail.isEmpty ? nil : editingEmail
            user = u
            UserDefaultsManager.saveUser(u)
        }
        isEditing = false
    }
    private func getUserDisplayNameForAccount() -> String {
        guard let user = user else { return "Guest User".localized }
        
        if user.isGuest {
            return "Guest User".localized
        }
        
        // If user has a name, use it
        if let name = user.name, !name.isEmpty {
            return name
        }
        
        // Otherwise derive from email
        if let email = user.email, !email.isEmpty {
            return email.components(separatedBy: "@").first?.capitalized ?? "User".localized
        }
        
        return "User".localized
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
