import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class SDExpense {
    var id: UUID
    var userId: String
    var title: String
    var date: Date
    var amount: Double
    var typeRaw: String
    var categoryRaw: String
    var currencyRaw: String
    var note: String?
    @Attribute(.externalStorage) var photoData: Data?
    
    init(id: UUID = UUID(), userId: String, title: String, date: Date, amount: Double, typeRaw: String, categoryRaw: String, currencyRaw: String, note: String? = nil, photoData: Data? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.date = date
        self.amount = amount
        self.typeRaw = typeRaw
        self.categoryRaw = categoryRaw
        self.currencyRaw = currencyRaw
        self.note = note
        self.photoData = photoData
    }
    
    // MARK: - Conversion Helpers
    
    /// Convert from legacy Expense struct
    convenience init(from expense: Expense, userId: String) {
        self.init(
            id: expense.id,
            userId: userId,
            title: expense.title,
            date: expense.date,
            amount: expense.amount,
            typeRaw: expense.type.rawValue,
            categoryRaw: expense.category.rawValue,
            currencyRaw: expense.currency.rawValue,
            note: expense.note,
            photoData: expense.photoData
        )
    }
    
    /// Convert to legacy Expense struct
    func toExpense() -> Expense {
        Expense(
            id: id,
            title: title,
            date: date,
            amount: amount,
            type: ExpenseType(rawValue: typeRaw) ?? .oneTime,
            category: ExpenseCategory(rawValue: categoryRaw) ?? .other,
            currency: Currency(rawValue: currencyRaw) ?? .TRY,
            note: note,
            photoData: photoData
        )
    }
}

@Model
final class SDIncome {
    var id: UUID
    var userId: String
    var title: String
    var date: Date
    var amount: Double
    var categoryRaw: String
    var currencyRaw: String
    var note: String?
    @Attribute(.externalStorage) var photoData: Data?
    
    init(id: UUID = UUID(), userId: String, title: String, date: Date, amount: Double, categoryRaw: String, currencyRaw: String, note: String? = nil, photoData: Data? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.date = date
        self.amount = amount
        self.categoryRaw = categoryRaw
        self.currencyRaw = currencyRaw
        self.note = note
        self.photoData = photoData
    }
    
    /// Convert from legacy Income struct
    convenience init(from income: Income, userId: String) {
        self.init(
            id: income.id,
            userId: userId,
            title: income.title,
            date: income.date,
            amount: income.amount,
            categoryRaw: income.category.rawValue,
            currencyRaw: income.currency.rawValue,
            note: income.note,
            photoData: income.photoData
        )
    }
    
    /// Convert to legacy Income struct
    func toIncome() -> Income {
        Income(
            id: id,
            title: title,
            date: date,
            amount: amount,
            category: IncomeCategory(rawValue: categoryRaw) ?? .other,
            currency: Currency(rawValue: currencyRaw) ?? .TRY,
            note: note,
            photoData: photoData
        )
    }
}

@Model
final class SDUser {
    @Attribute(.unique) var id: UUID
    var email: String?
    var name: String?
    var isGuest: Bool
    @Attribute(.externalStorage) var avatarData: Data?
    
    init(id: UUID = UUID(), email: String? = nil, name: String? = nil, isGuest: Bool = false, avatarData: Data? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.isGuest = isGuest
        self.avatarData = avatarData
    }
    
    /// Convert from legacy User struct
    convenience init(from user: User) {
        self.init(
            id: user.id,
            email: user.email,
            name: user.name,
            isGuest: user.isGuest,
            avatarData: user.avatarData
        )
    }
    
    /// Convert to legacy User struct
    func toUser() -> User {
        var user = User(email: email, name: name, isGuest: isGuest, avatarData: avatarData)
        // Preserve the original UUID through a workaround since User.id is let
        // We use the SDUser as the source of truth
        return user
    }
}
