import SwiftUI
import Charts

struct SummaryView: View {
    @Binding var incomes: [Income]
    @Binding var expenses: [Expense]
    @StateObject private var currencyManager = CurrencyManager.shared
    private var selectedDisplayCurrency: Currency { UserDefaultsManager.loadDefaultCurrency() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance Cards Section
                    balanceCardsSection
                    
                    // Income vs Expense Chart
                    incomeExpenseChartSection
                    
                    // Category Breakdowns
                    categoryBreakdownsSection
                    
                    // Recent Transactions
                    recentTransactionsSection
                    
                    // Spending Analysis
                    spendingAnalysisSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Balance Cards Section
    private var balanceCardsSection: some View {
        VStack(spacing: 16) {
            // Net Balance - Full Width
            netBalanceCard
            
            // Income & Expense Cards - Side by Side
            HStack(spacing: 16) {
                incomeCard
                expenseCard
            }
        }
    }
    
    private var netBalanceCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "wallet")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text("Net Balance".localized)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currencyManager.formatAmount(netBalance, currency: selectedDisplayCurrency))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    Text(netBalance >= 0 ? "Positive Balance" : "Needs Attention")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var incomeCard: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 32, height: 32)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Total Income".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text(currencyManager.formatAmount(totalIncomeConverted, currency: selectedDisplayCurrency))
                    .font(.title3.bold())
                    .foregroundColor(.green)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 2)
        )
        .cornerRadius(12)
    }
    
    private var expenseCard: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 32, height: 32)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Total Expenses".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text(currencyManager.formatAmount(totalExpenseConverted, currency: selectedDisplayCurrency))
                    .font(.title3.bold())
                    .foregroundColor(.red)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 2)
        )
        .cornerRadius(12)
    }
    
    // MARK: - Income vs Expense Chart
    private var incomeExpenseChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Income vs Expenses".localized)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    SectorMark(
                        angle: .value("Income", totalIncomeConverted),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(Color.green)
                    .opacity(0.8)
                    
                    SectorMark(
                        angle: .value("Expenses", totalExpenseConverted),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(Color.red)
                    .opacity(0.8)
                }
                .frame(height: 200)
                .chartLegend(position: .bottom)
            } else {
                // Fallback for iOS 15
                pieChartFallback
            }
            
            // Legend
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Income (\(currencyManager.formatAmount(totalIncomeConverted, currency: selectedDisplayCurrency)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("Expenses (\(currencyManager.formatAmount(totalExpenseConverted, currency: selectedDisplayCurrency)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var pieChartFallback: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: totalIncomeConverted / (totalIncomeConverted + totalExpenseConverted))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: totalIncomeConverted / (totalIncomeConverted + totalExpenseConverted), to: 1)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(height: 200)
    }
    
    // MARK: - Category Breakdowns
    private var categoryBreakdownsSection: some View {
        VStack(spacing: 16) {
            // Income Categories
            categoryBreakdownCard(
                title: "Income Categories".localized,
                data: incomeCategories,
                color: .green,
                total: totalIncomeConverted
            )
            
            // Expense Categories
            categoryBreakdownCard(
                title: "Expense Categories".localized,
                data: expenseCategories,
                color: .red,
                total: totalExpenseConverted
            )
        }
    }
    
    private func categoryBreakdownCard(title: String, data: [(String, Double)], color: Color, total: Double) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if data.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(data.prefix(5), id: \.0) { category, amount in
                        categoryRow(
                            name: category,
                            amount: amount,
                            percentage: total > 0 ? amount / total : 0,
                            color: color
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func categoryRow(name: String, amount: Double, percentage: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(name.localized)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text(currencyManager.formatAmount(amount, currency: selectedDisplayCurrency))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.6), value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Recent Transactions
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Transactions".localized)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if recentTransactions.isEmpty {
                Text("No recent transactions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentTransactions.prefix(5), id: \.id) { transaction in
                        transactionRow(transaction)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func transactionRow(_ transaction: TransactionItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.isIncome ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.isIncome ? "arrow.up" : "arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(transaction.isIncome ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(transaction.category.localized) • \(formatDate(transaction.date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(transaction.isIncome ? "+" : "-")\(currencyManager.formatAmount(transaction.amount, currency: selectedDisplayCurrency))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.isIncome ? .green : .red)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Spending Analysis
    private var spendingAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Analysis".localized)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Spending Ratio".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(spendingPercentage)%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                            .cornerRadius(6)
                        
                        Rectangle()
                            .fill(spendingColor)
                            .frame(width: geometry.size.width * (Double(spendingPercentage) / 100.0), height: 12)
                            .cornerRadius(6)
                            .animation(.easeInOut(duration: 0.6), value: spendingPercentage)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("Excellent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Caution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Danger")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    
    // MARK: - Computed Properties
    private var netBalance: Double {
        totalIncomeConverted - totalExpenseConverted
    }
    
    private var totalIncomeConverted: Double {
        incomes.reduce(0) { $0 + currencyManager.convert($1.amount, from: $1.currency, to: selectedDisplayCurrency) }
    }
    
    private var totalExpenseConverted: Double {
        expenses.reduce(0) { $0 + currencyManager.convert($1.amount, from: $1.currency, to: selectedDisplayCurrency) }
    }
    
    private var incomeCategories: [(String, Double)] {
        let grouped = Dictionary(grouping: incomes, by: { $0.category.rawValue })
        return grouped.map { category, items in
            let total = items.reduce(0) { $0 + currencyManager.convert($1.amount, from: $1.currency, to: selectedDisplayCurrency) }
            return (category, total)
        }.sorted { $0.1 > $1.1 }
    }
    
    private var expenseCategories: [(String, Double)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category.rawValue })
        return grouped.map { category, items in
            let total = items.reduce(0) { $0 + currencyManager.convert($1.amount, from: $1.currency, to: selectedDisplayCurrency) }
            return (category, total)
        }.sorted { $0.1 > $1.1 }
    }
    
    private var recentTransactions: [TransactionItem] {
        let incomeItems = incomes.map { income in
            TransactionItem(
                id: income.id.uuidString,
                title: income.title,
                amount: currencyManager.convert(income.amount, from: income.currency, to: selectedDisplayCurrency),
                category: income.category.rawValue,
                date: income.date,
                isIncome: true
            )
        }
        
        let expenseItems = expenses.map { expense in
            TransactionItem(
                id: expense.id.uuidString,
                title: expense.title,
                amount: currencyManager.convert(expense.amount, from: expense.currency, to: selectedDisplayCurrency),
                category: expense.category.rawValue,
                date: expense.date,
                isIncome: false
            )
        }
        
        return (incomeItems + expenseItems)
            .sorted { $0.date > $1.date }
    }
    
    private var spendingPercentage: Int {
        guard totalIncomeConverted > 0 else { return 0 }
        return min(Int((totalExpenseConverted / totalIncomeConverted) * 100), 100)
    }
    
    private var spendingColor: Color {
        let percentage = Double(spendingPercentage) / 100.0
        if percentage > 0.8 {
            return .red
        } else if percentage > 0.6 {
            return .orange
        } else {
            return .green
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Supporting Types
struct TransactionItem {
    let id: String
    let title: String
    let amount: Double
    let category: String
    let date: Date
    let isIncome: Bool
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView(incomes: .constant([]), expenses: .constant([]))
            .environment(\.colorScheme, .light)
        SummaryView(incomes: .constant([]), expenses: .constant([]))
            .environment(\.colorScheme, .dark)
    }
}
