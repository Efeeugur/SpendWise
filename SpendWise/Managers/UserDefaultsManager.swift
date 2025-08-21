import Foundation

struct UserDefaultsManager {
    private static let userKey = "currentUser"
    private static let monthlyLimitKey = "monthlyLimit"
    private static let defaultCurrencyKey = "defaultCurrency"
    private static let recommendationsEnabledKey = "recommendationsEnabled"
    private static let securityTypeKey = "securityType"
    private static let securityPasswordKey = "securityPassword"
    private static let lastGuestSessionKey = "lastGuestSession"
    private static let clearGuestOnLaunchKey = "clearGuestOnLaunch"
    
    // iCloud Key-Value Store
    private static let iCloudStore = NSUbiquitousKeyValueStore.default
    
    // Kullanıcıya özel gelir/gider anahtarları
    private static func incomesKey(for userId: String) -> String { "incomesKey_\(userId)" }
    private static func expensesKey(for userId: String) -> String { "expensesKey_\(userId)" }
    
    // Kullanıcıya özel gelir kaydetme/yükleme
    static func saveIncomes(_ incomes: [Income], forUser userId: String) {
        if let encoded = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(encoded, forKey: incomesKey(for: userId))
        }
    }
    static func loadIncomes(forUser userId: String) -> [Income] {
        if let data = UserDefaults.standard.data(forKey: incomesKey(for: userId)),
           let decoded = try? JSONDecoder().decode([Income].self, from: data) {
            return decoded
        }
        return []
    }
    // Kullanıcıya özel gider kaydetme/yükleme
    static func saveExpenses(_ expenses: [Expense], forUser userId: String) {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: expensesKey(for: userId))
        }
    }
    static func loadExpenses(forUser userId: String) -> [Expense] {
        if let data = UserDefaults.standard.data(forKey: expensesKey(for: userId)),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            return decoded
        }
        return []
    }
    
    // Kullanıcı Kaydetme
    static func saveUser(_ user: User?) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }
    
    // Kullanıcı Yükleme
    static func loadUser() -> User? {
        if let data = UserDefaults.standard.data(forKey: userKey),
           let decoded = try? JSONDecoder().decode(User.self, from: data) {
            return decoded
        }
        return nil
    }
    
    static func saveMonthlyLimit(_ limit: Double) {
        UserDefaults.standard.set(limit, forKey: monthlyLimitKey)
    }
    
    static func loadMonthlyLimit() -> Double? {
        let value = UserDefaults.standard.double(forKey: monthlyLimitKey)
        return value > 0 ? value : nil
    }
    
    // iCloud'a gelirleri kaydet
    static func saveIncomesToiCloud(_ incomes: [Income]) {
        if let encoded = try? JSONEncoder().encode(incomes) {
            iCloudStore.set(encoded, forKey: "incomesKey") // Bu kısım düzeltilecek, userId'ye göre olmalı
            iCloudStore.synchronize()
        }
    }
    // iCloud'dan gelirleri yükle
    static func loadIncomesFromiCloud() -> [Income] {
        if let data = iCloudStore.data(forKey: "incomesKey"), // Bu kısım düzeltilecek, userId'ye göre olmalı
           let decoded = try? JSONDecoder().decode([Income].self, from: data) {
            return decoded
        }
        return []
    }
    // iCloud'a giderleri kaydet
    static func saveExpensesToiCloud(_ expenses: [Expense]) {
        if let encoded = try? JSONEncoder().encode(expenses) {
            iCloudStore.set(encoded, forKey: "expensesKey") // Bu kısım düzeltilecek, userId'ye göre olmalı
            iCloudStore.synchronize()
        }
    }
    // iCloud'dan giderleri yükle
    static func loadExpensesFromiCloud() -> [Expense] {
        if let data = iCloudStore.data(forKey: "expensesKey"), // Bu kısım düzeltilecek, userId'ye göre olmalı
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            return decoded
        }
        return []
    }
    // iCloud'a kullanıcıyı kaydet
    static func saveUserToiCloud(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            iCloudStore.set(encoded, forKey: userKey)
            iCloudStore.synchronize()
        }
    }
    // iCloud'dan kullanıcıyı yükle
    static func loadUserFromiCloud() -> User? {
        if let data = iCloudStore.data(forKey: userKey),
           let decoded = try? JSONDecoder().decode(User.self, from: data) {
            return decoded
        }
        return nil
    }
    // iCloud'a aylık limiti kaydet
    static func saveMonthlyLimitToiCloud(_ limit: Double) {
        iCloudStore.set(limit, forKey: monthlyLimitKey)
        iCloudStore.synchronize()
    }
    // iCloud'dan aylık limiti yükle
    static func loadMonthlyLimitFromiCloud() -> Double? {
        let value = iCloudStore.double(forKey: monthlyLimitKey)
        return value > 0 ? value : nil
    }
    
    enum AppTheme: String, Codable, CaseIterable {
        case system = "Sistem Varsayılanı"
        case light = "Açık"
        case dark = "Koyu"
    }
    private static let appThemeKey = "appTheme"
    static func saveAppTheme(_ theme: AppTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: appThemeKey)
    }
    static func loadAppTheme() -> AppTheme {
        if let raw = UserDefaults.standard.string(forKey: appThemeKey),
           let theme = AppTheme(rawValue: raw) {
            return theme
        }
        return .system
    }
    
    // Varsayılan Döviz Ayarları
    static func saveDefaultCurrency(_ currency: Currency) {
        UserDefaults.standard.set(currency.rawValue, forKey: defaultCurrencyKey)
    }
    
    static func loadDefaultCurrency() -> Currency {
        if let raw = UserDefaults.standard.string(forKey: defaultCurrencyKey),
           let currency = Currency(rawValue: raw) {
            return currency
        }
        return .TRY
    }
    
    // Tavsiye Ayarları
    static func saveRecommendationsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: recommendationsEnabledKey)
    }
    
    static func loadRecommendationsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: recommendationsEnabledKey)
    }
    
    // Güvenlik Ayarları
    static func saveSecurityType(_ type: SecurityType) {
        UserDefaults.standard.set(type.rawValue, forKey: securityTypeKey)
    }
    
    static func loadSecurityType() -> SecurityType {
        if let raw = UserDefaults.standard.string(forKey: securityTypeKey),
           let type = SecurityType(rawValue: raw) {
            return type
        }
        return .none
    }
    
    static func saveSecurityPassword(_ password: String) {
        // Şifreyi güvenli bir şekilde hash'le (gerçek uygulamada daha güvenli yöntemler kullanılır)
        let hashedPassword = password.sha256()
        UserDefaults.standard.set(hashedPassword, forKey: securityPasswordKey)
    }
    
    static func loadSecurityPassword() -> String? {
        return UserDefaults.standard.string(forKey: securityPasswordKey)
    }
    
    static func clearSecurityPassword() {
        UserDefaults.standard.removeObject(forKey: securityPasswordKey)
    }
    
    // Şifreyi ve güvenlik tipini sıfırla
    static func resetSecurityPassword() {
        UserDefaults.standard.removeObject(forKey: securityPasswordKey)
        saveSecurityType(.none)
    }
    
    // iCloud son yedekleme tarihi
    static func saveLastiCloudBackupDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "LastiCloudBackupDate")
    }
    static func loadLastiCloudBackupDate() -> Date? {
        return UserDefaults.standard.object(forKey: "LastiCloudBackupDate") as? Date
    }

    private static let guestCreatedAtKey = "guestCreatedAt"

    // Misafir kullanıcı oluşturulunca çağrılacak
    static func saveGuestCreatedAt(_ date: Date) {
        UserDefaults.standard.set(date, forKey: guestCreatedAtKey)
    }
    static func loadGuestCreatedAt() -> Date? {
        return UserDefaults.standard.object(forKey: guestCreatedAtKey) as? Date
    }
    static func clearGuestCreatedAt() {
        UserDefaults.standard.removeObject(forKey: guestCreatedAtKey)
    }

    // Misafir kullanıcı verisi 7 gün kontrolü
    static func shouldClearGuestData() -> Bool {
        guard let createdAt = loadGuestCreatedAt() else { return false }
        return Date().timeIntervalSince(createdAt) > 7 * 24 * 60 * 60
    }

    // Tüm kullanıcı verilerini temizle
    static func clearAllUserData(forUser userId: String) {
        saveUser(nil)
        saveIncomes([], forUser: userId)
        saveExpenses([], forUser: userId)
        clearGuestCreatedAt()
        // Diğer UserDefaults anahtarları da eklenebilir
    }

    // MARK: - Guest ephemeral helpers
    static func markLastSessionAsGuest(_ isGuest: Bool) {
        UserDefaults.standard.set(isGuest, forKey: lastGuestSessionKey)
    }
    static func wasLastSessionGuest() -> Bool {
        UserDefaults.standard.bool(forKey: lastGuestSessionKey)
    }
    static func setClearGuestOnLaunch(_ shouldClear: Bool) {
        UserDefaults.standard.set(shouldClear, forKey: clearGuestOnLaunchKey)
    }
    static func shouldClearGuestOnLaunch() -> Bool {
        UserDefaults.standard.bool(forKey: clearGuestOnLaunchKey)
    }
}
