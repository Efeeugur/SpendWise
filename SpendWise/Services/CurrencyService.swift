import Foundation

enum Currency: String, Codable, CaseIterable {
    case TRY = "TRY"
    case USD = "USD"
    case EUR = "EUR"
    case GBP = "GBP"
    
    var symbol: String {
        switch self {
        case .TRY: return "₺"
        case .USD: return "$"
        case .EUR: return "€"
        case .GBP: return "£"
        }
    }
    
    var name: String {
        switch self {
        case .TRY: return "Turkish Lira"
        case .USD: return "US Dollar"
        case .EUR: return "Euro"
        case .GBP: return "British Pound"
        }
    }
}

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var exchangeRates: [String: Double] = [:]
    @Published var isLoading = false
    
    private init() {
        loadExchangeRates()
    }
    
    func loadExchangeRates() {
        isLoading = true
        
        // Free API endpoint (ExchangeRate-API)
        let urlString = "https://api.exchangerate-api.com/v4/latest/TRY"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let rates = json["rates"] as? [String: Double] {
                    
                    // TRY'den diğer para birimlerine dönüşüm oranları
                    self?.exchangeRates = rates
                }
            }
        }.resume()
    }
    
    func convert(_ amount: Double, from: Currency, to: Currency) -> Double {
        if from == to { return amount }
        
        // TRY'ye çevir, sonra hedef para birimine çevir
        let tryAmount: Double
        if from == .TRY {
            tryAmount = amount
        } else {
            // Diğer para biriminden TRY'ye çevir
            let rate = exchangeRates[from.rawValue] ?? 1.0
            tryAmount = amount / rate
        }
        
        if to == .TRY {
            return tryAmount
        } else {
            // TRY'den hedef para birimine çevir
            let rate = exchangeRates[to.rawValue] ?? 1.0
            return tryAmount * rate
        }
    }
    
    func formatAmount(_ amount: Double, currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0.00"
        return "\(currency.symbol)\(formattedAmount)"
    }
} 