import Foundation

enum RecommendationType: String, CaseIterable {
    case spendingLimit = "Spending Limit"
    case categoryAlert = "Category Alert"
    case savingTip = "Saving Tip"
    case budgetOptimization = "Budget Optimization"
    case trendAnalysis = "Trend Analysis"
    
    var icon: String {
        switch self {
        case .spendingLimit: return "exclamationmark.triangle"
        case .categoryAlert: return "chart.pie"
        case .savingTip: return "lightbulb"
        case .budgetOptimization: return "chart.line.uptrend.xyaxis"
        case .trendAnalysis: return "chart.bar"
        }
    }
    
    var color: String {
        switch self {
        case .spendingLimit: return "red"
        case .categoryAlert: return "orange"
        case .savingTip: return "green"
        case .budgetOptimization: return "blue"
        case .trendAnalysis: return "purple"
        }
    }
}

struct Recommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let priority: Int // 1-5, 5 is the highest priority
    let date: Date
    let actionable: Bool
    let actionTitle: String?
    let action: (() -> Void)?
}

class RecommendationManager: ObservableObject {
    static let shared = RecommendationManager()
    
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading = false
    
    private init() {}
    
    func generateRecommendations(incomes: [Income], expenses: [Expense]) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var newRecommendations: [Recommendation] = []
            
            // Harcama limiti kontrolü
            if let limitRecommendation = self.checkSpendingLimit(incomes: incomes, expenses: expenses) {
                newRecommendations.append(limitRecommendation)
            }
            
            // Kategori bazlı analiz
            let categoryRecommendations = self.analyzeCategorySpending(expenses: expenses)
            newRecommendations.append(contentsOf: categoryRecommendations)
            
            // Tasarruf önerileri
            let savingRecommendations = self.generateSavingTips(incomes: incomes, expenses: expenses)
            newRecommendations.append(contentsOf: savingRecommendations)
            
            // Bütçe optimizasyonu
            let budgetRecommendations = self.optimizeBudget(incomes: incomes, expenses: expenses)
            newRecommendations.append(contentsOf: budgetRecommendations)
            
            // Trend analizi
            let trendRecommendations = self.analyzeTrends(incomes: incomes, expenses: expenses)
            newRecommendations.append(contentsOf: trendRecommendations)
            
            // Öncelik sırasına göre sırala
            newRecommendations.sort { $0.priority > $1.priority }
            
            DispatchQueue.main.async {
                self.recommendations = newRecommendations
                self.isLoading = false
            }
        }
    }
    
    private func checkSpendingLimit(incomes: [Income], expenses: [Expense]) -> Recommendation? {
        guard let monthlyLimit = UserDefaultsManager.loadMonthlyLimit() else { return nil }
        let defaultCurrency = UserDefaultsManager.loadDefaultCurrency()
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let monthlyExpenses = expenses.filter { expense in
            let expenseMonth = Calendar.current.component(.month, from: expense.date)
            let expenseYear = Calendar.current.component(.year, from: expense.date)
            return expenseMonth == currentMonth && expenseYear == currentYear
        }
        
        let totalSpending = monthlyExpenses.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) }
        let limitPercentage = (totalSpending / monthlyLimit) * 100
        
        if limitPercentage >= 90 {
            return Recommendation(
                type: .spendingLimit,
                title: "Spending Limit Alert!".localized,
                description: String(format: "You have spent %d%% of your monthly spending limit this month. Be careful!".localized, Int(limitPercentage)),
                priority: 5,
                date: Date(),
                actionable: true,
                actionTitle: "Set Limit".localized,
                action: nil
            )
        }
        
        return nil
    }
    
    private func analyzeCategorySpending(expenses: [Expense]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        let defaultCurrency = UserDefaultsManager.loadDefaultCurrency()
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let monthlyExpenses = expenses.filter { expense in
            let expenseMonth = Calendar.current.component(.month, from: expense.date)
            let expenseYear = Calendar.current.component(.year, from: expense.date)
            return expenseMonth == currentMonth && expenseYear == currentYear
        }
        
        // Kategori bazlı harcama analizi
        let categoryTotals = Dictionary(grouping: monthlyExpenses, by: { $0.category })
            .mapValues { expenses in expenses.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) } }
        
        let totalSpending = monthlyExpenses.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) }
        
        for (category, amount) in categoryTotals {
            let percentage = (amount / totalSpending) * 100
            
            if percentage > 40 {
                recommendations.append(Recommendation(
                    type: .categoryAlert,
                    title: String(format: "%@ High Spending".localized, category.rawValue),
                    description: String(format: "Your spending is %d%% of your total spending in the %@ category. You can save in this area.".localized, Int(percentage), category.rawValue),
                    priority: 4,
                    date: Date(),
                    actionable: false,
                    actionTitle: nil,
                    action: nil
                ))
            }
        }
        
        return recommendations
    }
    
    private func generateSavingTips(incomes: [Income], expenses: [Expense]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        let defaultCurrency = UserDefaultsManager.loadDefaultCurrency()
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let monthlyIncomes = incomes.filter { income in
            let incomeMonth = Calendar.current.component(.month, from: income.date)
            let incomeYear = Calendar.current.component(.year, from: income.date)
            return incomeMonth == currentMonth && incomeYear == currentYear
        }
        
        let monthlyExpenses = expenses.filter { expense in
            let expenseMonth = Calendar.current.component(.month, from: expense.date)
            let expenseYear = Calendar.current.component(.year, from: expense.date)
            return expenseMonth == currentMonth && expenseYear == currentYear
        }
        
        let totalIncome = monthlyIncomes.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) }
        let totalExpenses = monthlyExpenses.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) }
        
        if totalExpenses > totalIncome * 0.8 {
            recommendations.append(Recommendation(
                type: .savingTip,
                title: "Saving Tip".localized,
                description: "More than 80% of your income is being spent. Consider saving for emergencies.".localized,
                priority: 3,
                date: Date(),
                actionable: false,
                actionTitle: nil,
                action: nil
            ))
        }
        
        // Gıda harcaması yüksekse öneri
        let foodExpenses = monthlyExpenses.filter { $0.category == .food }.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) }
        if foodExpenses > totalIncome * 0.3 {
            recommendations.append(Recommendation(
                type: .savingTip,
                title: "Food Savings".localized,
                description: "More than 30% of your income is being spent on food. You can prepare meals and do bulk shopping.".localized,
                priority: 3,
                date: Date(),
                actionable: false,
                actionTitle: nil,
                action: nil
            ))
        }
        
        return recommendations
    }
    
    private func optimizeBudget(incomes: [Income], expenses: [Expense]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        let defaultCurrency = UserDefaultsManager.loadDefaultCurrency()
        
        // Gelir-gider dengesi analizi
        let totalIncome = incomes.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) }
        let totalExpenses = expenses.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) }
        
        if totalIncome > 0 {
            let savingsRate = ((totalIncome - totalExpenses) / totalIncome) * 100
            
            if savingsRate < 10 {
                recommendations.append(Recommendation(
                    type: .budgetOptimization,
                    title: "Budget Optimization".localized,
                    description: String(format: "Your savings rate is %d. Aim to save at least 20%% of your income.".localized, Int(savingsRate)),
                    priority: 3,
                    date: Date(),
                    actionable: false,
                    actionTitle: nil,
                    action: nil
                ))
            } else if savingsRate > 30 {
                recommendations.append(Recommendation(
                    type: .budgetOptimization,
                    title: "Perfect Savings!".localized,
                    description: String(format: "Your savings rate is %d. Great job!".localized, Int(savingsRate)),
                    priority: 2,
                    date: Date(),
                    actionable: false,
                    actionTitle: nil,
                    action: nil
                ))
            }
        }
        
        return recommendations
    }
    
    private func analyzeTrends(incomes: [Income], expenses: [Expense]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        let defaultCurrency = UserDefaultsManager.loadDefaultCurrency()
        
        // Son 3 ayın trend analizi
        let calendar = Calendar.current
        let now = Date()
        
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        
        let recentExpenses = expenses.filter { $0.date >= threeMonthsAgo }
        
        if recentExpenses.count > 5 {
            let avgMonthlyExpense = recentExpenses.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) } / 3
            
            let currentMonthExpenses = expenses.filter { expense in
                let expenseMonth = calendar.component(.month, from: expense.date)
                let expenseYear = calendar.component(.year, from: expense.date)
                let currentMonth = calendar.component(.month, from: now)
                let currentYear = calendar.component(.year, from: now)
                return expenseMonth == currentMonth && expenseYear == currentYear
            }
            
            let currentMonthTotal = currentMonthExpenses.reduce(0) { $0 + CurrencyManager.shared.convert($1.amount, from: $1.currency, to: defaultCurrency) }
            
            if currentMonthTotal > avgMonthlyExpense * 1.2 {
                recommendations.append(Recommendation(
                    type: .trendAnalysis,
                    title: "Spending Increase".localized,
                    description: String(format: "You spent %d more than your average monthly expense this month. Check the trend.".localized, Int(currentMonthTotal - avgMonthlyExpense * 1.2)),
                    priority: 4,
                    date: Date(),
                    actionable: false,
                    actionTitle: nil,
                    action: nil
                ))
            } else if currentMonthTotal < avgMonthlyExpense * 0.8 {
                recommendations.append(Recommendation(
                    type: .trendAnalysis,
                    title: "Spending Decrease".localized,
                    description: String(format: "You spent %d less than your average monthly expense this month. Well done!".localized, Int(avgMonthlyExpense * 0.8 - currentMonthTotal)),
                    priority: 2,
                    date: Date(),
                    actionable: false,
                    actionTitle: nil,
                    action: nil
                ))
            }
        }
        
        return recommendations
    }
} 
