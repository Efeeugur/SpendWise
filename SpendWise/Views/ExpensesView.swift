import SwiftUI

struct ExpensesView: View {
    @Binding var expenses: [Expense]
    @Binding var userId: String
    @State private var searchText: String = ""
    @State private var showAddExpenseModal: Bool = false
    @State private var expenseToEdit: Expense? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack {
                if filteredExpenses.isEmpty {
                    Spacer()
                    ContentUnavailableView(label: {
                        Label("No Expense".localized, systemImage: "tray")
                    }, description: {
                        Text("You haven't added any expense yet. You can add new expense from the top right.".localized)
                    })
                    Spacer()
                } else {
                    List {
                        ForEach(filteredExpenses) { expense in
                            Button {
                                expenseToEdit = expense
                            } label: {
                                ExpenseRow(expense: expense)
                            }
                            .listRowBackground(Color(.systemBackground))
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                    .listStyle(.plain)
                    .background(Color(.systemBackground))
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Expense".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddExpenseModal = true }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if isLoading { ProgressView() }
            }
        }
        .sheet(isPresented: $showAddExpenseModal) {
            AddExpenseView(expenses: $expenses, userEmail: userId == "guest" ? nil : userId)
        }
        .sheet(item: $expenseToEdit) { expense in
            if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                EditExpenseView(expenses: $expenses, expense: $expenses[index])
            }
        }
        .task(id: userId) { await loadRemoteIfNeeded() }
    }

    var filteredExpenses: [Expense] {
        if searchText.isEmpty {
            return expenses
        } else {
            return expenses.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }

    func deleteExpenses(at offsets: IndexSet) {
        let ids = offsets.map { expenses[$0].id }
        expenses.remove(atOffsets: offsets)
        if userId != "guest" {
            Task { for id in ids { try? await SupabaseService.shared.deleteExpense(id: id) } }
        } else {
            UserDefaultsManager.saveExpenses(expenses, forUser: userId)
        }
    }

    @MainActor
    private func loadRemoteIfNeeded() async {
        guard userId != "guest" else { return }
        isLoading = true
        defer { isLoading = false }
        do { expenses = try await SupabaseService.shared.fetchExpenses(email: userId) } catch {}
    }
}

struct ExpenseRow: View {
    let expense: Expense
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingDetail = false
    
    var body: some View {
        HStack {
            // Show photo if exists
            if let photoData = expense.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                Text(currencyManager.formatAmount(expense.amount, currency: expense.currency))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(expense.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(expense.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
