import Foundation

// Enhanced Supabase Service for comprehensive database operations
final class EnhancedSupabaseService {
    static let shared = EnhancedSupabaseService()
    
    private init() {}
    
    private var supabaseUrl: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }
    
    private let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    // MARK: - Base Request Helper
    private func baseUrl(_ path: String) throws -> URL {
        guard let url = URL(string: supabaseUrl), ["http","https"].contains(url.scheme?.lowercased()) else {
            throw SupabaseError.config("Invalid SUPABASE_URL")
        }
        guard let final = URL(string: path, relativeTo: url) else {
            throw SupabaseError.config("Invalid path")
        }
        return final
    }
    
    private func makeRequest(path: String, method: String = "GET", query: [URLQueryItem] = [], body: Data? = nil) throws -> URLRequest {
        let restBase = try baseUrl("rest/v1/")
        var components = URLComponents(url: restBase.appendingPathComponent(path), resolvingAgainstBaseURL: true)!
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw SupabaseError.config("Invalid URLComponents") }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let bearer = UserDefaults.standard.string(forKey: "supabase_token") ?? anonKey
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = body
        
        return request
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String, fullName: String) async throws -> UserProfile {
        let url = try baseUrl("auth/v1/signup")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["full_name": fullName]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Sign up failed"
            throw SupabaseError.server(msg)
        }
        
        if let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let user = decoded["user"] as? [String: Any],
           let userEmail = user["email"] as? String,
           let userId = user["id"] as? String,
           let userUUID = UUID(uuidString: userId) {
            
            if let accessToken = decoded["access_token"] as? String {
                UserDefaults.standard.set(accessToken, forKey: "supabase_token")
            }
            
            // Create user profile
            let userProfile = UserProfile(
                id: userUUID,
                email: userEmail,
                fullName: fullName,
                displayName: fullName,
                isGuest: false
            )
            
            // Initialize user in database
            try await createUserProfile(userProfile)
            
            return userProfile
        }
        
        throw SupabaseError.server("Invalid sign up response")
    }
    
    func signIn(email: String, password: String) async throws -> UserProfile {
        guard var components = URLComponents(string: try baseUrl("auth/v1/token").absoluteString) else {
            throw SupabaseError.config("Bad URL")
        }
        components.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        
        var req = URLRequest(url: components.url!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["email": email, "password": password]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Sign in failed"
            throw SupabaseError.server(msg)
        }
        
        if let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let accessToken = decoded["access_token"] as? String {
            UserDefaults.standard.set(accessToken, forKey: "supabase_token")
            
            // Fetch user profile
            return try await fetchUserProfile(email: email)
        }
        
        throw SupabaseError.server("Invalid sign in response")
    }
    
    // MARK: - User Profile Operations
    func createUserProfile(_ user: UserProfile) async throws {
        let request = try makeRequest(path: "users", method: "POST", body: try JSONEncoder().encode(user))
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Create user profile failed")
        }
    }
    
    func fetchUserProfile(email: String) async throws -> UserProfile {
        let request = try makeRequest(path: "users", query: [
            URLQueryItem(name: "email", value: "eq.\(email)"),
            URLQueryItem(name: "select", value: "*")
        ])
        
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch user profile failed")
        }
        
        let users = try JSONDecoder().decode([UserProfile].self, from: data)
        guard let user = users.first else {
            throw SupabaseError.server("User not found")
        }
        
        return user
    }
    
    func updateUserProfile(_ user: UserProfile) async throws {
        let request = try makeRequest(
            path: "users",
            method: "PATCH",
            query: [URLQueryItem(name: "id", value: "eq.\(user.id)")],
            body: try JSONEncoder().encode(user)
        )
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Update user profile failed")
        }
    }
    
    // MARK: - User Preferences Operations
    func fetchUserPreferences(userId: UUID) async throws -> UserPreferences {
        let request = try makeRequest(path: "user_preferences", query: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*")
        ])
        
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch preferences failed")
        }
        
        let preferences = try JSONDecoder().decode([UserPreferences].self, from: data)
        guard let prefs = preferences.first else {
            throw SupabaseError.server("Preferences not found")
        }
        
        return prefs
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async throws {
        let request = try makeRequest(
            path: "user_preferences",
            method: "PATCH",
            query: [URLQueryItem(name: "user_id", value: "eq.\(preferences.userId)")],
            body: try JSONEncoder().encode(preferences)
        )
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Update preferences failed")
        }
    }
    
    // MARK: - Category Operations
    func fetchCategories(userId: UUID, type: CategoryType? = nil) async throws -> [EnhancedCategory] {
        var queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "is_active", value: "eq.true"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "sort_order,name")
        ]
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: "eq.\(type.rawValue)"))
        }
        
        let request = try makeRequest(path: "categories", query: queryItems)
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch categories failed")
        }
        
        return try JSONDecoder().decode([EnhancedCategory].self, from: data)
    }
    
    func createCategory(_ category: EnhancedCategory) async throws {
        let request = try makeRequest(path: "categories", method: "POST", body: try JSONEncoder().encode(category))
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Create category failed")
        }
    }
    
    func updateCategory(_ category: EnhancedCategory) async throws {
        let request = try makeRequest(
            path: "categories",
            method: "PATCH",
            query: [URLQueryItem(name: "id", value: "eq.\(category.id)")],
            body: try JSONEncoder().encode(category)
        )
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Update category failed")
        }
    }
    
    func deleteCategory(id: UUID) async throws {
        // Soft delete by setting is_active to false
        let updateData: [String: Any] = ["is_active": false, "updated_at": iso.string(from: Date())]
        let request = try makeRequest(
            path: "categories",
            method: "PATCH",
            query: [URLQueryItem(name: "id", value: "eq.\(id)")],
            body: try JSONSerialization.data(withJSONObject: updateData)
        )
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Delete category failed")
        }
    }
    
    // MARK: - Transaction Operations
    func fetchTransactions(userId: UUID, type: TransactionType? = nil, startDate: Date? = nil, endDate: Date? = nil, limit: Int? = nil) async throws -> [EnhancedTransaction] {
        var queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "is_deleted", value: "eq.false"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "transaction_date.desc")
        ]
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "transaction_type", value: "eq.\(type.rawValue)"))
        }
        
        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "transaction_date", value: "gte.\(iso.string(from: startDate))"))
        }
        
        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "transaction_date", value: "lte.\(iso.string(from: endDate))"))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        
        let request = try makeRequest(path: "transactions", query: queryItems)
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch transactions failed")
        }
        
        return try JSONDecoder().decode([EnhancedTransaction].self, from: data)
    }
    
    func createTransaction(_ transaction: EnhancedTransaction) async throws {
        let request = try makeRequest(path: "transactions", method: "POST", body: try JSONEncoder().encode(transaction))
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Create transaction failed")
        }
    }
    
    func updateTransaction(_ transaction: EnhancedTransaction) async throws {
        let request = try makeRequest(
            path: "transactions",
            method: "PATCH",
            query: [URLQueryItem(name: "id", value: "eq.\(transaction.id)")],
            body: try JSONEncoder().encode(transaction)
        )
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Update transaction failed")
        }
    }
    
    func deleteTransaction(id: UUID, userId: UUID) async throws {
        // Soft delete
        let updateData = [
            "is_deleted": true,
            "deleted_at": iso.string(from: Date()),
            "updated_at": iso.string(from: Date())
        ] as [String: Any]
        
        let request = try makeRequest(
            path: "transactions",
            method: "PATCH",
            query: [
                URLQueryItem(name: "id", value: "eq.\(id)"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)")
            ],
            body: try JSONSerialization.data(withJSONObject: updateData)
        )
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Delete transaction failed")
        }
    }
    
    // MARK: - Budget Operations
    func fetchBudgets(userId: UUID, isActive: Bool = true) async throws -> [Budget] {
        let request = try makeRequest(path: "budgets", query: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "is_active", value: "eq.\(isActive)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "start_date.desc")
        ])
        
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch budgets failed")
        }
        
        return try JSONDecoder().decode([Budget].self, from: data)
    }
    
    func createBudget(_ budget: Budget) async throws {
        let request = try makeRequest(path: "budgets", method: "POST", body: try JSONEncoder().encode(budget))
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Create budget failed")
        }
    }
    
    func updateBudget(_ budget: Budget) async throws {
        let request = try makeRequest(
            path: "budgets",
            method: "PATCH",
            query: [URLQueryItem(name: "id", value: "eq.\(budget.id)")],
            body: try JSONEncoder().encode(budget)
        )
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Update budget failed")
        }
    }
    
    // MARK: - Financial Goals Operations
    func fetchFinancialGoals(userId: UUID, isActive: Bool = true) async throws -> [FinancialGoal] {
        let request = try makeRequest(path: "financial_goals", query: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "is_active", value: "eq.\(isActive)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "priority_level.desc,created_at.desc")
        ])
        
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch financial goals failed")
        }
        
        return try JSONDecoder().decode([FinancialGoal].self, from: data)
    }
    
    func createFinancialGoal(_ goal: FinancialGoal) async throws {
        let request = try makeRequest(path: "financial_goals", method: "POST", body: try JSONEncoder().encode(goal))
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Create financial goal failed")
        }
    }
    
    func updateFinancialGoal(_ goal: FinancialGoal) async throws {
        let request = try makeRequest(
            path: "financial_goals",
            method: "PATCH",
            query: [URLQueryItem(name: "id", value: "eq.\(goal.id)")],
            body: try JSONEncoder().encode(goal)
        )
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Update financial goal failed")
        }
    }
    
    // MARK: - Analytics and Reporting
    func fetchTransactionSummary(userId: UUID, startDate: Date, endDate: Date) async throws -> TransactionSummary {
        let request = try makeRequest(path: "rpc/get_transaction_summary", method: "POST", body: try JSONSerialization.data(withJSONObject: [
            "p_user_id": userId.uuidString,
            "p_start_date": iso.string(from: startDate),
            "p_end_date": iso.string(from: endDate)
        ]))
        
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch transaction summary failed")
        }
        
        return try JSONDecoder().decode(TransactionSummary.self, from: data)
    }
    
    func fetchCategorySpending(userId: UUID, startDate: Date, endDate: Date) async throws -> [CategorySpendingSummary] {
        let request = try makeRequest(path: "category_spending_summary", query: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*")
        ])
        
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch category spending failed")
        }
        
        return try JSONDecoder().decode([CategorySpendingSummary].self, from: data)
    }
    
    // MARK: - Notifications Operations
    func fetchNotifications(userId: UUID, unreadOnly: Bool = false) async throws -> [UserNotification] {
        var queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        
        if unreadOnly {
            queryItems.append(URLQueryItem(name: "is_read", value: "eq.false"))
        }
        
        let request = try makeRequest(path: "notifications", query: queryItems)
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch notifications failed")
        }
        
        return try JSONDecoder().decode([UserNotification].self, from: data)
    }
    
    func markNotificationAsRead(id: UUID) async throws {
        let updateData = [
            "is_read": true,
            "read_at": iso.string(from: Date())
        ] as [String: Any]
        
        let request = try makeRequest(
            path: "notifications",
            method: "PATCH",
            query: [URLQueryItem(name: "id", value: "eq.\(id)")],
            body: try JSONSerialization.data(withJSONObject: updateData)
        )
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Mark notification as read failed")
        }
    }
    
    // MARK: - Bulk Operations
    func deleteAllUserData(userId: UUID) async throws {
        // This should call a stored procedure that handles cascading deletes properly
        let request = try makeRequest(path: "rpc/delete_all_user_data", method: "POST", body: try JSONSerialization.data(withJSONObject: [
            "p_user_id": userId.uuidString
        ]))
        
        let (_, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Delete all user data failed")
        }
    }
}

// MARK: - Supporting Models
struct TransactionSummary: Codable {
    let totalIncome: Double
    let totalExpenses: Double
    let netAmount: Double
    let transactionCount: Int
    let currency: Currency
    
    enum CodingKeys: String, CodingKey {
        case totalIncome = "total_income"
        case totalExpenses = "total_expenses"
        case netAmount = "net_amount"
        case transactionCount = "transaction_count"
        case currency
    }
}

struct CategorySpendingSummary: Codable {
    let categoryName: String
    let categoryType: CategoryType
    let totalAmount: Double
    let transactionCount: Int
    let currency: Currency
    
    enum CodingKeys: String, CodingKey {
        case categoryName = "category_name"
        case categoryType = "category_type"
        case totalAmount = "total_amount"
        case transactionCount = "transaction_count"
        case currency
    }
}

// SupabaseError is defined in the original SupabaseService.swift