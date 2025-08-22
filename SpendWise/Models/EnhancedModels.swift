import Foundation

// MARK: - Enhanced Models for Database Integration
// These models extend the existing app functionality for the comprehensive database structure

// MARK: - Enhanced User Model
struct UserProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var email: String?
    var fullName: String?
    var displayName: String?
    var avatarUrl: String?
    var avatarData: Data?
    var isGuest: Bool
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    var lastLoginAt: Date?
    
    init(id: UUID = UUID(), email: String? = nil, fullName: String? = nil, displayName: String? = nil, 
         avatarUrl: String? = nil, avatarData: Data? = nil, isGuest: Bool = false, isActive: Bool = true) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.avatarData = avatarData
        self.isGuest = isGuest
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastLoginAt = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case avatarData = "avatar_data"
        case isGuest = "is_guest"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastLoginAt = "last_login_at"
    }
    
    // Convert from existing User model
    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.fullName = user.name
        self.displayName = user.name
        self.avatarUrl = nil
        self.avatarData = user.avatarData
        self.isGuest = user.isGuest
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastLoginAt = nil
    }
    
    // Convert to existing User model
    func toLegacyUser() -> User {
        return User(
            email: self.email,
            name: self.fullName ?? self.displayName,
            isGuest: self.isGuest,
            avatarData: self.avatarData
        )
    }
}

// MARK: - App Theme Preferences
enum ThemePreference: String, Codable, CaseIterable {
    case system = "system"
    case light = "light" 
    case dark = "dark"
    
    // Convert from existing UserDefaultsManager.AppTheme
    init(from appTheme: UserDefaultsManager.AppTheme) {
        switch appTheme {
        case .system: self = .system
        case .light: self = .light
        case .dark: self = .dark
        }
    }
    
    // Convert to existing UserDefaultsManager.AppTheme
    func toLegacyTheme() -> UserDefaultsManager.AppTheme {
        switch self {
        case .system: return .system
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Language Preferences
enum LanguagePreference: String, Codable, CaseIterable {
    case en = "en"
    case tr = "tr"
}

// MARK: - User Preferences Model
struct UserPreferences: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var themePreference: ThemePreference
    var languagePreference: LanguagePreference
    var defaultCurrency: Currency
    var monthlySpendingLimit: Double?
    var notificationsEnabled: Bool
    var smartRecommendationsEnabled: Bool
    var securityType: SecurityType
    var homeCards: [String]
    let createdAt: Date
    var updatedAt: Date
    
    init(userId: UUID, themePreference: ThemePreference = .system, languagePreference: LanguagePreference = .en,
         defaultCurrency: Currency = .TRY, monthlySpendingLimit: Double? = nil, notificationsEnabled: Bool = true,
         smartRecommendationsEnabled: Bool = true, securityType: SecurityType = .none,
         homeCards: [String] = ["lastExpenses", "monthlySummary", "categoryDistribution"]) {
        self.id = UUID()
        self.userId = userId
        self.themePreference = themePreference
        self.languagePreference = languagePreference
        self.defaultCurrency = defaultCurrency
        self.monthlySpendingLimit = monthlySpendingLimit
        self.notificationsEnabled = notificationsEnabled
        self.smartRecommendationsEnabled = smartRecommendationsEnabled
        self.securityType = securityType
        self.homeCards = homeCards
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case themePreference = "theme_preference"
        case languagePreference = "language_preference"
        case defaultCurrency = "default_currency"
        case monthlySpendingLimit = "monthly_spending_limit"
        case notificationsEnabled = "notifications_enabled"
        case smartRecommendationsEnabled = "smart_recommendations_enabled"
        case securityType = "security_type"
        case homeCards = "home_cards"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Category Types
enum CategoryType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
}

// MARK: - Enhanced Category Model
struct EnhancedCategory: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var name: String
    let type: CategoryType
    var iconName: String?
    var colorHex: String
    var isDefault: Bool
    var isActive: Bool
    var sortOrder: Int
    let createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), userId: UUID, name: String, type: CategoryType,
         iconName: String? = nil, colorHex: String = "#007AFF", isDefault: Bool = false,
         isActive: Bool = true, sortOrder: Int = 0) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = type
        self.iconName = iconName
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, type
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case isDefault = "is_default"
        case isActive = "is_active"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Convert from existing category enums
    static func fromIncomeCategory(_ category: IncomeCategory, userId: UUID) -> EnhancedCategory {
        return EnhancedCategory(
            userId: userId,
            name: category.rawValue,
            type: .income,
            isDefault: true
        )
    }
    
    static func fromExpenseCategory(_ category: ExpenseCategory, userId: UUID) -> EnhancedCategory {
        return EnhancedCategory(
            userId: userId,
            name: category.rawValue,
            type: .expense,
            isDefault: true
        )
    }
}

// MARK: - Transaction Types
enum TransactionType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
}

// MARK: - Enhanced Transaction Model
struct EnhancedTransaction: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var categoryId: UUID?
    var title: String
    var description: String?
    var amount: Double
    var currency: Currency
    let transactionType: TransactionType
    var expenseType: ExpenseType?
    var transactionDate: Date
    var location: String?
    var note: String?
    var photoUrls: [String]
    var photoData: Data?
    var tags: [String]
    var isRecurring: Bool
    var parentTransactionId: UUID?
    var isDeleted: Bool
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    
    init(id: UUID = UUID(), userId: UUID, categoryId: UUID? = nil, title: String, description: String? = nil,
         amount: Double, currency: Currency = .TRY, transactionType: TransactionType, expenseType: ExpenseType? = nil,
         transactionDate: Date = Date(), location: String? = nil, note: String? = nil, photoUrls: [String] = [],
         photoData: Data? = nil, tags: [String] = [], isRecurring: Bool = false, parentTransactionId: UUID? = nil) {
        self.id = id
        self.userId = userId
        self.categoryId = categoryId
        self.title = title
        self.description = description
        self.amount = amount
        self.currency = currency
        self.transactionType = transactionType
        self.expenseType = expenseType
        self.transactionDate = transactionDate
        self.location = location
        self.note = note
        self.photoUrls = photoUrls
        self.photoData = photoData
        self.tags = tags
        self.isRecurring = isRecurring
        self.parentTransactionId = parentTransactionId
        self.isDeleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case categoryId = "category_id"
        case title, description, amount, currency
        case transactionType = "transaction_type"
        case expenseType = "expense_type"
        case transactionDate = "transaction_date"
        case location, note
        case photoUrls = "photo_urls"
        case photoData = "photo_data"
        case tags
        case isRecurring = "is_recurring"
        case parentTransactionId = "parent_transaction_id"
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    
    // Convert from existing Income model
    init(from income: Income, userId: UUID, categoryId: UUID? = nil) {
        self.id = income.id
        self.userId = userId
        self.categoryId = categoryId
        self.title = income.title
        self.description = nil
        self.amount = income.amount
        self.currency = income.currency
        self.transactionType = .income
        self.expenseType = nil
        self.transactionDate = income.date
        self.location = nil
        self.note = income.note
        self.photoUrls = []
        self.photoData = income.photoData
        self.tags = []
        self.isRecurring = false
        self.parentTransactionId = nil
        self.isDeleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
    
    // Convert from existing Expense model
    init(from expense: Expense, userId: UUID, categoryId: UUID? = nil) {
        self.id = expense.id
        self.userId = userId
        self.categoryId = categoryId
        self.title = expense.title
        self.description = nil
        self.amount = expense.amount
        self.currency = expense.currency
        self.transactionType = .expense
        self.expenseType = expense.type
        self.transactionDate = expense.date
        self.location = nil
        self.note = expense.note
        self.photoUrls = []
        self.photoData = expense.photoData
        self.tags = []
        self.isRecurring = false
        self.parentTransactionId = nil
        self.isDeleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
    
    // Convert to existing Income model
    func toLegacyIncome() -> Income? {
        guard transactionType == .income else { return nil }
        
        return Income(
            id: self.id,
            title: self.title,
            date: self.transactionDate,
            amount: self.amount,
            category: .other, // Default category, should be mapped properly
            currency: self.currency,
            note: self.note,
            photoData: self.photoData
        )
    }
    
    // Convert to existing Expense model
    func toLegacyExpense() -> Expense? {
        guard transactionType == .expense else { return nil }
        
        return Expense(
            id: self.id,
            title: self.title,
            date: self.transactionDate,
            amount: self.amount,
            type: self.expenseType ?? .oneTime,
            category: .other, // Default category, should be mapped properly
            currency: self.currency,
            note: self.note,
            photoData: self.photoData
        )
    }
}

// MARK: - Budget Period Types
enum BudgetPeriodType: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
}

// MARK: - Budget Model
struct Budget: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let categoryId: UUID
    var name: String
    var budgetAmount: Double
    var currency: Currency
    let periodType: BudgetPeriodType
    let startDate: Date
    let endDate: Date
    var spentAmount: Double
    var alertThreshold: Double
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), userId: UUID, categoryId: UUID, name: String, budgetAmount: Double,
         currency: Currency = .TRY, periodType: BudgetPeriodType, startDate: Date, endDate: Date,
         spentAmount: Double = 0, alertThreshold: Double = 0.8, isActive: Bool = true) {
        self.id = id
        self.userId = userId
        self.categoryId = categoryId
        self.name = name
        self.budgetAmount = budgetAmount
        self.currency = currency
        self.periodType = periodType
        self.startDate = startDate
        self.endDate = endDate
        self.spentAmount = spentAmount
        self.alertThreshold = alertThreshold
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case categoryId = "category_id"
        case name
        case budgetAmount = "budget_amount"
        case currency
        case periodType = "period_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case spentAmount = "spent_amount"
        case alertThreshold = "alert_threshold"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Goal Types
enum GoalType: String, Codable, CaseIterable {
    case general = "general"
    case emergency = "emergency"
    case purchase = "purchase"
    case vacation = "vacation"
    case education = "education"
}

enum ContributionFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

// MARK: - Financial Goal Model
struct FinancialGoal: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String?
    var targetAmount: Double
    var currentAmount: Double
    var currency: Currency
    var targetDate: Date?
    var goalType: GoalType
    var priorityLevel: Int
    var isActive: Bool
    var autoContribution: Bool
    var contributionAmount: Double?
    var contributionFrequency: ContributionFrequency?
    let createdAt: Date
    var updatedAt: Date
    var achievedAt: Date?
    
    init(id: UUID = UUID(), userId: UUID, name: String, description: String? = nil, targetAmount: Double,
         currentAmount: Double = 0, currency: Currency = .TRY, targetDate: Date? = nil, goalType: GoalType = .general,
         priorityLevel: Int = 1, isActive: Bool = true, autoContribution: Bool = false,
         contributionAmount: Double? = nil, contributionFrequency: ContributionFrequency? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.currency = currency
        self.targetDate = targetDate
        self.goalType = goalType
        self.priorityLevel = priorityLevel
        self.isActive = isActive
        self.autoContribution = autoContribution
        self.contributionAmount = contributionAmount
        self.contributionFrequency = contributionFrequency
        self.createdAt = Date()
        self.updatedAt = Date()
        self.achievedAt = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, description
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case currency
        case targetDate = "target_date"
        case goalType = "goal_type"
        case priorityLevel = "priority_level"
        case isActive = "is_active"
        case autoContribution = "auto_contribution"
        case contributionAmount = "contribution_amount"
        case contributionFrequency = "contribution_frequency"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case achievedAt = "achieved_at"
    }
}

// MARK: - Notification Types
enum NotificationType: String, Codable, CaseIterable {
    case budgetAlert = "budget_alert"
    case goalProgress = "goal_progress"
    case recurringReminder = "recurring_reminder"
    case recommendation = "recommendation"
    case security = "security"
    case general = "general"
}

// MARK: - Notification Model
struct UserNotification: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var title: String
    var message: String
    let notificationType: NotificationType
    var referenceId: UUID?
    var referenceType: String?
    var actionUrl: String?
    var isRead: Bool
    var isSent: Bool
    var priorityLevel: Int
    var scheduledAt: Date?
    var sentAt: Date?
    var readAt: Date?
    var expiresAt: Date?
    let createdAt: Date
    
    init(id: UUID = UUID(), userId: UUID, title: String, message: String, notificationType: NotificationType,
         referenceId: UUID? = nil, referenceType: String? = nil, actionUrl: String? = nil,
         isRead: Bool = false, isSent: Bool = false, priorityLevel: Int = 1,
         scheduledAt: Date? = nil, sentAt: Date? = nil, readAt: Date? = nil, expiresAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.message = message
        self.notificationType = notificationType
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.actionUrl = actionUrl
        self.isRead = isRead
        self.isSent = isSent
        self.priorityLevel = priorityLevel
        self.scheduledAt = scheduledAt
        self.sentAt = sentAt
        self.readAt = readAt
        self.expiresAt = expiresAt
        self.createdAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, message
        case notificationType = "notification_type"
        case referenceId = "reference_id"
        case referenceType = "reference_type"
        case actionUrl = "action_url"
        case isRead = "is_read"
        case isSent = "is_sent"
        case priorityLevel = "priority_level"
        case scheduledAt = "scheduled_at"
        case sentAt = "sent_at"
        case readAt = "read_at"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}