import Foundation

// Minimal Supabase integration: Auth + REST DB calls
// Reads configuration from AppConfig (hard-coded) instead of Info.plist per user request

final class SupabaseService {
    static let shared = SupabaseService()

    private init() {}

    private var supabaseUrl: String { AppConfig.supabaseURL }
    private var anonKey: String { AppConfig.supabaseAnonKey }

    private func baseUrl(_ path: String) throws -> URL {
        guard let url = URL(string: supabaseUrl), ["http","https"].contains(url.scheme?.lowercased()) else {
            throw SupabaseError.config("Invalid SUPABASE_URL")
        }
        guard let final = URL(string: path, relativeTo: url) else { throw SupabaseError.config("Invalid path") }
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

    // MARK: Auth (email/password)
    func signUp(email: String, password: String, name: String) async throws -> String {
        let url = try baseUrl("auth/v1/signup")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["full_name": name] as [String: Any] // bazı Supabase kurulumlarında "user_metadata" yerine "data" olabiliyor
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw SupabaseError.server("Sign up: invalid response") }
        if !(200...299).contains(http.statusCode) {
            if let json = String(data: data, encoding: .utf8) { throw SupabaseError.server("Sign up failed: \(json)") }
            throw SupabaseError.server("Sign up failed")
        }

        // Supabase değişik payload'lar dönebilir; robust decode
        if let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // access_token veya session olabilir
            if let accessToken = (decoded["access_token"] as? String) ?? (decoded["accessToken"] as? String) {
                UserDefaults.standard.set(accessToken, forKey: "supabase_token")
            }
            // Kullanıcı e-postasını çeşitli alanlarda arıyoruz
            if let user = decoded["user"] as? [String: Any], let mail = user["email"] as? String {
                return mail
            }
            if let emailField = decoded["email"] as? String { return emailField }
        }

        // fallback: parametre olarak gelen email
        return email
    }

    func signIn(email: String, password: String) async throws -> String {
        guard var components = URLComponents(string: try baseUrl("auth/v1/token").absoluteString) else { throw SupabaseError.config("Bad URL") }
        components.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        var req = URLRequest(url: components.url!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = ["email": email, "password": password]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw SupabaseError.server("Sign in: invalid response") }
        if !(200...299).contains(http.statusCode) {
            if let json = String(data: data, encoding: .utf8) { throw SupabaseError.server("Sign in failed: \(json)") }
            throw SupabaseError.server("Sign in failed")
        }

        // Robust decode: access_token at top-level or inside session
        if let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let accessToken = decoded["access_token"] as? String ?? decoded["accessToken"] as? String {
                UserDefaults.standard.set(accessToken, forKey: "supabase_token")
            }
            if let user = decoded["user"] as? [String: Any], let mail = user["email"] as? String {
                return mail
            }
            // some responses include "session" or "data"
            if let session = decoded["session"] as? [String: Any],
               let user = session["user"] as? [String: Any],
               let mail = user["email"] as? String {
                if let token = session["access_token"] as? String { UserDefaults.standard.set(token, forKey: "supabase_token") }
                return mail
            }
        }

        // fallback to input email
        return email
    }

    // MARK: OAuth: Apple with id_token
    func signInWithApple(idToken: String, nonce: String?) async throws -> String {
        guard var components = URLComponents(string: try baseUrl("auth/v1/token").absoluteString) else { throw SupabaseError.config("Bad URL") }
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "id_token"),
            URLQueryItem(name: "provider", value: "apple")
        ]
        var req = URLRequest(url: components.url!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        var body: [String: Any] = ["id_token": idToken]
        if let nonce { body["nonce"] = nonce }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Sign in with Apple failed"
            throw SupabaseError.server(msg)
        }
        if let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let accessToken = decoded["access_token"] as? String ?? decoded["accessToken"] as? String {
                UserDefaults.standard.set(accessToken, forKey: "supabase_token")
            }
            if let user = decoded["user"] as? [String: Any], let mail = user["email"] as? String {
                return mail
            }
            if let email = decoded["email"] as? String { return email }
        }
        return ""
    }

    // MARK: Models mapping
    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
    }()

    private struct IncomeRow: Codable {
        let id: String
        let user_email: String
        let title: String
        let date: String
        let amount: Double
        let category: String
        let currency: String
        let note: String?
        let photo_url: String?
    }
    private struct ExpenseRow: Codable {
        let id: String
        let user_email: String
        let title: String
        let date: String
        let amount: Double
        let type: String
        let category: String
        let currency: String
        let note: String?
        let photo_url: String?
    }

    // MARK: Incomes
    func fetchIncomes(email: String) async throws -> [Income] {
        let req = try makeRequest(path: "incomes", query: [
            URLQueryItem(name: "user_email", value: "eq.\(email)"),
            URLQueryItem(name: "select", value: "*")
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch incomes failed")
        }
        let rows = try JSONDecoder().decode([IncomeRow].self, from: data)
        return rows.compactMap { r in
            guard let d = iso.date(from: r.date), let id = UUID(uuidString: r.id),
                  let cat = IncomeCategory(rawValue: r.category), let cur = Currency(rawValue: r.currency) else { return nil }
            return Income(id: id, title: r.title, date: d, amount: r.amount, category: cat, currency: cur, note: r.note, photoData: nil)
        }
    }
    func createIncome(email: String, income: Income) async throws {
        let row = IncomeRow(id: income.id.uuidString, user_email: email, title: income.title, date: iso.string(from: income.date), amount: income.amount, category: income.category.rawValue, currency: income.currency.rawValue, note: income.note, photo_url: nil)
        let body = try JSONEncoder().encode([row]) // array is acceptable for bulk insert; supabase accepts array or object
        let req = try makeRequest(path: "incomes", method: "POST", body: body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw SupabaseError.server("Create income failed") }
    }
    func updateIncome(_ income: Income) async throws {
        let row = IncomeRow(id: income.id.uuidString, user_email: "", title: income.title, date: iso.string(from: income.date), amount: income.amount, category: income.category.rawValue, currency: income.currency.rawValue, note: income.note, photo_url: nil)
        let body = try JSONEncoder().encode([row])
        let req = try makeRequest(path: "incomes", method: "PATCH", query: [URLQueryItem(name: "id", value: "eq.\(income.id.uuidString)")], body: body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw SupabaseError.server("Update income failed") }
    }
    func deleteIncome(id: UUID) async throws {
        let req = try makeRequest(path: "incomes", method: "DELETE", query: [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")])
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw SupabaseError.server("Delete income failed") }
    }

    // MARK: Expenses
    func fetchExpenses(email: String) async throws -> [Expense] {
        let req = try makeRequest(path: "expenses", query: [
            URLQueryItem(name: "user_email", value: "eq.\(email)"),
            URLQueryItem(name: "select", value: "*")
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Fetch expenses failed")
        }
        let rows = try JSONDecoder().decode([ExpenseRow].self, from: data)
        return rows.compactMap { r in
            guard let d = iso.date(from: r.date), let id = UUID(uuidString: r.id),
                  let typ = ExpenseType(rawValue: r.type), let cat = ExpenseCategory(rawValue: r.category), let cur = Currency(rawValue: r.currency) else { return nil }
            return Expense(id: id, title: r.title, date: d, amount: r.amount, type: typ, category: cat, currency: cur, note: r.note, photoData: nil)
        }
    }
    func createExpense(email: String, expense: Expense) async throws {
        let row = ExpenseRow(id: expense.id.uuidString, user_email: email, title: expense.title, date: iso.string(from: expense.date), amount: expense.amount, type: expense.type.rawValue, category: expense.category.rawValue, currency: expense.currency.rawValue, note: expense.note, photo_url: nil)
        let body = try JSONEncoder().encode([row])
        let req = try makeRequest(path: "expenses", method: "POST", body: body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw SupabaseError.server("Create expense failed") }
    }
    func updateExpense(_ expense: Expense) async throws {
        let row = ExpenseRow(id: expense.id.uuidString, user_email: "", title: expense.title, date: iso.string(from: expense.date), amount: expense.amount, type: expense.type.rawValue, category: expense.category.rawValue, currency: expense.currency.rawValue, note: expense.note, photo_url: nil)
        let body = try JSONEncoder().encode([row])
        let req = try makeRequest(path: "expenses", method: "PATCH", query: [URLQueryItem(name: "id", value: "eq.\(expense.id.uuidString)")], body: body)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw SupabaseError.server("Update expense failed") }
    }
    func deleteExpense(id: UUID) async throws {
        let req = try makeRequest(path: "expenses", method: "DELETE", query: [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")])
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw SupabaseError.server("Delete expense failed") }
    }

    // MARK: Bulk delete for user
    func deleteAllIncomes(forEmail email: String) async throws {
        let req = try makeRequest(path: "incomes", method: "DELETE", query: [
            URLQueryItem(name: "user_email", value: "eq.\(email)")
        ])
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Delete all incomes failed")
        }
    }

    func deleteAllExpenses(forEmail email: String) async throws {
        let req = try makeRequest(path: "expenses", method: "DELETE", query: [
            URLQueryItem(name: "user_email", value: "eq.\(email)")
        ])
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.server("Delete all expenses failed")
        }
    }

    func deleteAllData(forEmail email: String) async throws {
        try await deleteAllIncomes(forEmail: email)
        try await deleteAllExpenses(forEmail: email)
    }

    // MARK: User profile upsert (schema-agnostic)
    func upsertUserProfile(email: String, name: String?) async throws {
        let tablesToTry = ["users", "profiles"]
        let emailFieldCandidates = ["email", "user_email"]
        let nameFieldCandidates = ["full_name", "name", "username"]

        var lastError: String = "unknown error"

        for table in tablesToTry {
            for emailField in emailFieldCandidates {
                // 1) Minimal payload: only email field
                var minimal: [String: Any] = [emailField: email]
                do {
                    try await upsertProfile(into: table, body: try JSONSerialization.data(withJSONObject: [minimal]), conflictKey: emailField)
                    return
                } catch let SupabaseError.server(message) {
                    lastError = message
                    // if error indicates table/column missing, try next variant
                }

                // 2) Email + name with different name columns
                for nameField in nameFieldCandidates {
                    var payload: [String: Any] = [emailField: email]
                    if let name, !name.isEmpty { payload[nameField] = name }
                    do {
                        try await upsertProfile(into: table, body: try JSONSerialization.data(withJSONObject: [payload]), conflictKey: emailField)
                        return
                    } catch let SupabaseError.server(message) {
                        lastError = message
                        // continue trying next variant
                    }
                }
            }
        }
        throw SupabaseError.server("Upsert user profile failed: \(lastError)")
    }

    private func upsertProfile(into table: String, body: Data, conflictKey: String) async throws {
        var req = try makeRequest(path: table, method: "POST", query: [
            URLQueryItem(name: "on_conflict", value: conflictKey)
        ], body: body)
        req.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown error"
            throw SupabaseError.server("HTTP \((resp as? HTTPURLResponse)?.statusCode ?? -1): \(msg)")
        }
    }

    private func httpStatus(_ resp: URLResponse) -> String {
        guard let http = resp as? HTTPURLResponse else { return "" }
        return "HTTP \(http.statusCode)"
    }
}

enum SupabaseError: Error { case config(String), server(String) }
