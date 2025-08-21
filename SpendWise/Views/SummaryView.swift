import SwiftUI

struct SummaryView: View {
    @Binding var incomes: [Income]
    @Binding var expenses: [Expense]
    @StateObject private var currencyManager = CurrencyManager.shared
    // Currency is only taken from settings, no selector on screen
    private var selectedDisplayCurrency: Currency { UserDefaultsManager.loadDefaultCurrency() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // No title, using navigationTitle
                // Current Balance
                VStack(spacing: 4) {
                    Text("Current Balance")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.secondary)
                    Text(currencyManager.formatAmount(totalIncomeConverted - totalExpenseConverted, currency: selectedDisplayCurrency))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor((totalIncomeConverted - totalExpenseConverted) >= 0 ? .green : .red)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .padding(.top, 24)
                // Income & Expense boxes
                HStack(spacing: 18) {
                    summaryBox(title: "Total Income", value: currencyManager.formatAmount(totalIncomeConverted, currency: selectedDisplayCurrency), color: .green, icon: "arrow.up.circle")
                    summaryBox(title: "Total Expense", value: currencyManager.formatAmount(totalExpenseConverted, currency: selectedDisplayCurrency), color: .red, icon: "arrow.down.circle")
                }
                Spacer()
            }
            .padding(.horizontal)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    // Simple and smooth summary box
    func summaryBox(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            HStack {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(color)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    var totalIncomeConverted: Double {
        incomes.reduce(0) { $0 + currencyManager.convert($1.amount, from: $1.currency, to: selectedDisplayCurrency) }
    }
    var totalExpenseConverted: Double {
        expenses.reduce(0) { $0 + currencyManager.convert($1.amount, from: $1.currency, to: selectedDisplayCurrency) }
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView(incomes: .constant([]), expenses: .constant([]))
            .environment(\.colorScheme, .light)
        SummaryView(incomes: .constant([]), expenses: .constant([]))
            .environment(\.colorScheme, .dark)
    }
}
