import Foundation

extension String {
    /// Parse a localized number string to Double, handling both comma and dot decimal separators
    func toLocalizedDouble() -> Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        
        // Try current locale first
        if let number = formatter.number(from: self) {
            return number.doubleValue
        }
        
        // Fallback: try replacing comma with dot
        let normalized = self.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
