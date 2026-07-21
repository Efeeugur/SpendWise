import Foundation
import UIKit

class ExportManager {
    static let shared = ExportManager()
    
    private init() {}
    
    /// Generates an RFC 4180 compliant CSV string from the user's incomes and expenses
    func generateCSV(incomes: [Income], expenses: [Expense]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // ISO-like, locale-independent
        
        // UTF-8 BOM for Excel compatibility
        var csv = "\u{FEFF}"
        csv += "Type,Title,Date,Amount,Currency,Category,Note\n"
        
        // Add incomes
        for income in incomes {
            let date = dateFormatter.string(from: income.date)
            let amount = String(format: "%.2f", income.amount) // Locale-independent decimal
            csv += "Income,"
            csv += "\(csvEscape(income.title)),"
            csv += "\(date),"
            csv += "\(amount),"
            csv += "\(income.currency.rawValue),"
            csv += "\(csvEscape(income.category.rawValue)),"
            csv += "\(csvEscape(income.note ?? ""))\n"
        }
        
        // Add expenses
        for expense in expenses {
            let date = dateFormatter.string(from: expense.date)
            let amount = String(format: "%.2f", expense.amount) // Locale-independent decimal
            csv += "Expense,"
            csv += "\(csvEscape(expense.title)),"
            csv += "\(date),"
            csv += "\(amount),"
            csv += "\(expense.currency.rawValue),"
            csv += "\(csvEscape(expense.category.rawValue)),"
            csv += "\(csvEscape(expense.note ?? ""))\n"
        }
        
        return csv
    }
    
    /// Escapes a CSV field per RFC 4180: wraps in quotes if it contains comma, quote, or newline
    private func csvEscape(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
        if needsQuoting {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    /// Generates a summary text report
    func generateSummary(incomes: [Income], expenses: [Expense]) -> String {
        let totalIncome = incomes.reduce(0) { $0 + $1.amount }
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        let balance = totalIncome - totalExpense
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var report = """
        ═══════════════════════════════════
        SpendWise Financial Report
        Generated: \(dateFormatter.string(from: Date()))
        ═══════════════════════════════════
        
        SUMMARY
        ───────────────────────────────────
        Total Income:   \(String(format: "%.2f", totalIncome))
        Total Expense:  \(String(format: "%.2f", totalExpense))
        Net Balance:    \(String(format: "%.2f", balance))
        
        """
        
        // Expense breakdown by category
        if !expenses.isEmpty {
            report += "EXPENSE BREAKDOWN BY CATEGORY\n"
            report += "───────────────────────────────────\n"
            
            let grouped = Dictionary(grouping: expenses) { $0.category }
            let sorted = grouped.sorted { $0.value.reduce(0) { $0 + $1.amount } > $1.value.reduce(0) { $0 + $1.amount } }
            
            for (category, items) in sorted {
                let total = items.reduce(0) { $0 + $1.amount }
                let percentage = totalExpense > 0 ? (total / totalExpense * 100) : 0
                report += "  \(category.rawValue): \(String(format: "%.2f", total)) (\(String(format: "%.1f", percentage))%)\n"
            }
            report += "\n"
        }
        
        // Income breakdown by category
        if !incomes.isEmpty {
            report += "INCOME BREAKDOWN BY CATEGORY\n"
            report += "───────────────────────────────────\n"
            
            let grouped = Dictionary(grouping: incomes) { $0.category }
            let sorted = grouped.sorted { $0.value.reduce(0) { $0 + $1.amount } > $1.value.reduce(0) { $0 + $1.amount } }
            
            for (category, items) in sorted {
                let total = items.reduce(0) { $0 + $1.amount }
                report += "  \(category.rawValue): \(String(format: "%.2f", total))\n"
            }
        }
        
        return report
    }
    
    /// Exports data as CSV and presents a share sheet
    @MainActor
    func exportCSV(incomes: [Income], expenses: [Expense]) {
        let csv = generateCSV(incomes: incomes, expenses: expenses)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("SpendWise_Export.csv")
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            presentShareSheet(with: [tempURL])
        } catch {
            ErrorHandler.shared.handle(
                AppError.general("Failed to export data: \(error.localizedDescription)"),
                context: "ExportManager"
            )
        }
    }
    
    /// Presents the iOS share sheet with given items
    @MainActor
    private func presentShareSheet(with items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Find the topmost presented view controller
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            
            // iPad support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topVC.present(activityVC, animated: true)
        }
    }
}
