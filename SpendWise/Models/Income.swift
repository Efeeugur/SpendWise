import Foundation

enum IncomeCategory: String, Codable, CaseIterable, Equatable {
    case salary = "Salary"
    case additionalIncome = "Additional Income"
    case gift = "Gift"
    case other = "Other"
}

struct Income: Identifiable, Codable, Equatable {
    var id: UUID
    let title: String
    let date: Date
    let amount: Double
    let category: IncomeCategory
    let currency: Currency
    let note: String?
    let photoData: Data?
    
    init(id: UUID = UUID(), title: String, date: Date, amount: Double, category: IncomeCategory = .other, currency: Currency = .TRY, note: String? = nil, photoData: Data? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.amount = amount
        self.category = category
        self.currency = currency
        self.note = note
        self.photoData = photoData
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, date, amount, category, currency, note, photoData
    }
}
