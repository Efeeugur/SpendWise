import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Equatable {
    case food = "Food"
    case transportation = "Transportation"
    case bill = "Bill"
    case entertainment = "Entertainment"
    case health = "Health"
    case other = "Other"
}

enum ExpenseType: String, Codable, CaseIterable, Equatable {
    case oneTime = "One Time"
    case monthly = "Monthly"
}

struct Expense: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var date: Date
    var amount: Double
    var type: ExpenseType
    var category: ExpenseCategory
    var currency: Currency
    var note: String?
    var photoData: Data?
    
    init(id: UUID = UUID(), title: String, date: Date, amount: Double, type: ExpenseType, category: ExpenseCategory = .other, currency: Currency = .TRY, note: String? = nil, photoData: Data? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.amount = amount
        self.type = type
        self.category = category
        self.currency = currency
        self.note = note
        self.photoData = photoData
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, date, amount, type, category, currency, note, photoData
    }
}
