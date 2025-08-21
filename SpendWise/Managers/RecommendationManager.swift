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
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let monthlyExpenses = expenses.filter { expense in
            let expenseMonth = Calendar.current.component(.month, from: expense.date)
            let expenseYear = Calendar.current.component(.year, from: expense.date)
            return expenseMonth == currentMonth && expenseYear == currentYear
        }
        
        let totalSpending = monthlyExpenses.reduce(0) { $0 + $1.amount }
        let limitPercentage = (totalSpending / monthlyLimit) * 100
        
        if limitPercentage >= 90 {
            return Recommendation(
                type: .spendingLimit,
                title: "Spending Limit Alert!",
                description: "You have spent \(Int(limitPercentage))% of your monthly spending limit this month. Be careful!",
                priority: 5,
                date: Date(),
                actionable: true,
                actionTitle: "Set Limit",
                action: nil
            )
        }
        
        return nil
    }
    
    private func analyzeCategorySpending(expenses: [Expense]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let monthlyExpenses = expenses.filter { expense in
            let expenseMonth = Calendar.current.component(.month, from: expense.date)
            let expenseYear = Calendar.current.component(.year, from: expense.date)
            return expenseMonth == currentMonth && expenseYear == currentYear
        }
        
        // Kategori bazlı harcama analizi
        let categoryTotals = Dictionary(grouping: monthlyExpenses, by: { $0.category })
            .mapValues { expenses in expenses.reduce(0) { $0 + $1.amount } }
        
        let totalSpending = monthlyExpenses.reduce(0) { $0 + $1.amount }
        
        for (category, amount) in categoryTotals {
            let percentage = (amount / totalSpending) * 100
            
            if percentage > 40 {
                recommendations.append(Recommendation(
                    type: .categoryAlert,
                    title: "\(category.rawValue) High Spending",
                    description: "Your spending is \(Int(percentage))% of your total spending in the \(category.rawValue) category. You can save in this area.",
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
        
        let totalIncome = monthlyIncomes.reduce(0) { $0 + $1.amount }
        let totalExpenses = monthlyExpenses.reduce(0) { $0 + $1.amount }
        
        if totalExpenses > totalIncome * 0.8 {
            recommendations.append(Recommendation(
                type: .savingTip,
                title: "Saving Tip",
                description: "More than 80% of your income is being spent. Consider saving for emergencies.",
                priority: 3,
                date: Date(),
                actionable: false,
                actionTitle: nil,
                action: nil
            ))
        }
        
        // Gıda harcaması yüksekse öneri
        let foodExpenses = monthlyExpenses.filter { $0.category == .food }.reduce(0) { $0 + $1.amount }
        if foodExpenses > totalIncome * 0.3 {
            recommendations.append(Recommendation(
                type: .savingTip,
                title: "Food Savings",
                description: "More than 30% of your income is being spent on food. You can prepare meals and do bulk shopping.",
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
        
        // Gelir-gider dengesi analizi
        let totalIncome = incomes.reduce(0) { $0 + $1.amount }
        let totalExpenses = expenses.reduce(0) { $0 + $1.amount }
        
        if totalIncome > 0 {
            let savingsRate = ((totalIncome - totalExpenses) / totalIncome) * 100
            
            if savingsRate < 10 {
                recommendations.append(Recommendation(
                    type: .budgetOptimization,
                    title: "Budget Optimization",
                    description: "Your savings rate is \(Int(savingsRate)). Aim to save at least 20% of your income.",
                    priority: 3,
                    date: Date(),
                    actionable: false,
                    actionTitle: nil,
                    action: nil
                ))
            } else if savingsRate > 30 {
                recommendations.append(Recommendation(
                    type: .budgetOptimization,
                    title: "Perfect Savings!",
                    description: "Your savings rate is \(Int(savingsRate)). Great job!",
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
        
        // Son 3 ayın trend analizi
        let calendar = Calendar.current
        let now = Date()
        
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        
        let recentExpenses = expenses.filter { $0.date >= threeMonthsAgo }
        _ = incomes.filter { $0.date >= threeMonthsAgo }
        
        if recentExpenses.count > 5 {
            let avgMonthlyExpense = recentExpenses.reduce(0) { $0 + $1.amount } / 3
            
            let currentMonthExpenses = expenses.filter { expense in
                let expenseMonth = calendar.component(.month, from: expense.date)
                let expenseYear = calendar.component(.year, from: expense.date)
                let currentMonth = calendar.component(.month, from: now)
                let currentYear = calendar.component(.year, from: now)
                return expenseMonth == currentMonth && expenseYear == currentYear
            }
            
            let currentMonthTotal = currentMonthExpenses.reduce(0) { $0 + $1.amount }
            
            if currentMonthTotal > avgMonthlyExpense * 1.2 {
                recommendations.append(Recommendation(
                    type: .trendAnalysis,
                    title: "Spending Increase",
                    description: "You spent \(Int(currentMonthTotal - avgMonthlyExpense * 1.2)) more than your average monthly expense this month. Check the trend.",
                    priority: 4,
                    date: Date(),
                    actionable: false,
                    actionTitle: nil,
                    action: nil
                ))
            } else if currentMonthTotal < avgMonthlyExpense * 0.8 {
                recommendations.append(Recommendation(
                    type: .trendAnalysis,
                    title: "Spending Decrease",
                    description: "You spent \(Int(avgMonthlyExpense * 0.8 - currentMonthTotal)) less than your average monthly expense this month. Well done!",
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
