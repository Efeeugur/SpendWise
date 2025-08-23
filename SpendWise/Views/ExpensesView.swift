import SwiftUI

@MainActor

struct ExpensesView: View {
    @Binding var expenses: [Expense]
    @Binding var userId: String
    @State private var searchText: String = ""
    @State private var showAddExpenseModal: Bool = false
    @State private var expenseToEdit: Expense? = nil
    @State private var isLoading: Bool = false
    @State private var selectedFilter: ExpenseFilter = .all
    @StateObject private var currencyManager = CurrencyManager.shared
    
    private var selectedDisplayCurrency: Currency { 
        UserDefaultsManager.loadDefaultCurrency() 
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Content
            if filteredExpenses.isEmpty {
                emptyStateView
            } else {
                expenseListView
            }
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Search Expenses".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                addExpenseButton
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if isLoading { 
                    ProgressView()
                        .scaleEffect(0.8)
                }
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Summary Card
            expenseSummaryCard
            
            // Filter Tabs
            if !expenses.isEmpty {
                filterTabs
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    private var expenseSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("Total Expenses".localized)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                
                // Budget indicator if applicable
                if let monthlyLimit = UserDefaultsManager.loadMonthlyLimit() {
                    budgetIndicator(limit: monthlyLimit)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currencyManager.formatAmount(totalExpenses, currency: selectedDisplayCurrency))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text("\(expenses.count) expense\(expenses.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.red, Color.red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func budgetIndicator(limit: Double) -> some View {
        let percentage = totalExpenses / limit
        let isOverBudget = percentage > 1.0
        
        return VStack(alignment: .trailing, spacing: 2) {
            Text(isOverBudget ? "Over Budget" : "Budget")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(Int(min(percentage * 100, 999)))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isOverBudget ? .yellow : .white)
        }
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ExpenseFilter.allCases, id: \.self) { filter in
                    filterTab(filter)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }
    
    private func filterTab(_ filter: ExpenseFilter) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14))
                Text(filter.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                selectedFilter == filter ? 
                Color.red : Color(.systemGray6)
            )
            .foregroundColor(
                selectedFilter == filter ? 
                .white : .primary
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Add Expense Button
    private var addExpenseButton: some View {
        Button {
            showAddExpenseModal = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.red)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 30, height: 30)
                )
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.red.opacity(0.7))
            }
            
            VStack(spacing: 8) {
                Text("No Expenses Yet".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Start tracking your expenses to understand your spending patterns and manage your budget.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                showAddExpenseModal = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add First Expense")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(25)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Expense List
    private var expenseListView: some View {
        PerformantList(filteredExpenses) { expense in
            ExpenseCard(
                expense: expense,
                onTap: { expenseToEdit = expense },
                onDelete: { deleteExpense(expense) }
            )
            .performanceOptimized()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Computed Properties
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + currencyManager.convert($1.amount, from: $1.currency, to: selectedDisplayCurrency) }
    }
    
    private var filteredExpenses: [Expense] {
        // Cache expensive computations
        let cacheKey = "\(expenses.count)-\(selectedFilter)-\(searchText)"
        
        // Simple memoization for performance
        if let cached = filteredExpensesCache[cacheKey] {
            return cached
        }
        
        var filtered = expenses
        
        // Apply filter selection
        switch selectedFilter {
        case .all:
            break
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            filtered = filtered.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .type(let type):
            filtered = filtered.filter { $0.type == type }
        case .category(let category):
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply search text
        if !searchText.isEmpty {
            let lowercaseSearch = searchText.lowercased()
            filtered = filtered.filter { $0.title.lowercased().contains(lowercaseSearch) }
        }
        
        let result = filtered.sorted { $0.date > $1.date }
        
        // Cache result
        filteredExpensesCache[cacheKey] = result
        
        // Clean cache if it gets too large
        if filteredExpensesCache.count > 10 {
            filteredExpensesCache.removeAll()
            filteredExpensesCache[cacheKey] = result
        }
        
        return result
    }
    
    @State private var filteredExpensesCache: [String: [Expense]] = [:]

    // MARK: - Actions
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            expenses.removeAll { $0.id == expense.id }
        }
        
        if userId != "guest" {
            Task { 
                try? await SupabaseService.shared.deleteExpense(id: expense.id) 
            }
        } else {
            UserDefaultsManager.saveExpenses(expenses, forUser: userId)
        }
    }

    func deleteExpenses(at offsets: IndexSet) {
        let expensesToDelete = offsets.map { filteredExpenses[$0] }
        
        withAnimation {
            for expense in expensesToDelete {
                expenses.removeAll { $0.id == expense.id }
            }
        }
        
        if userId != "guest" {
            Task { 
                for expense in expensesToDelete {
                    try? await SupabaseService.shared.deleteExpense(id: expense.id)
                }
            }
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

// MARK: - Supporting Types
enum ExpenseFilter: CaseIterable, Hashable {
    case all
    case thisMonth
    case type(ExpenseType)
    case category(ExpenseCategory)
    
    static var allCases: [ExpenseFilter] {
        var cases: [ExpenseFilter] = [.all, .thisMonth]
        cases.append(contentsOf: ExpenseType.allCases.map { .type($0) })
        cases.append(contentsOf: ExpenseCategory.allCases.map { .category($0) })
        return cases
    }
    
    var title: String {
        switch self {
        case .all:
            return "All"
        case .thisMonth:
            return "This Month"
        case .type(let type):
            return type.rawValue.localized
        case .category(let category):
            return category.rawValue.localized
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "list.bullet"
        case .thisMonth:
            return "calendar"
        case .type(let type):
            switch type {
            case .oneTime:
                return "1.circle"
            case .monthly:
                return "repeat"
            }
        case .category(let category):
            switch category {
            case .food:
                return "fork.knife"
            case .transportation:
                return "car"
            case .entertainment:
                return "gamecontroller"
            case .health:
                return "cross.case"
            case .bill:
                return "doc.text"
            case .other:
                return "ellipsis.circle"
            }
        }
    }
}

// MARK: - Expense Card Component
struct ExpenseCard: View {
    let expense: Expense
    let onTap: () -> Void
    let onDelete: () -> Void
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 16) {
                // Icon or Photo
                expenseIcon
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Title and Amount
                    HStack {
                        Text(expense.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(currencyManager.formatAmount(expense.amount, currency: expense.currency))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    // Category, Type and Date
                    HStack {
                        categoryTag
                        typeTag
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDate(expense.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Note if exists
                    if let note = expense.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Edit", systemImage: "pencil") {
                onTap()
            }
            
            Button("Delete", systemImage: "trash", role: .destructive) {
                showingDeleteAlert = true
            }
        }
        .alert("Delete Expense", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this expense entry?")
        }
    }
    
    private var expenseIcon: some View {
        Group {
            if let photoData = expense.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: categoryIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var categoryTag: some View {
        Text(expense.category.rawValue.localized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var typeTag: some View {
        Text(expense.type.rawValue.localized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var categoryIcon: String {
        switch expense.category {
        case .food:
            return "fork.knife.circle.fill"
        case .transportation:
            return "car.circle.fill"
        case .entertainment:
            return "gamecontroller.fill"
        case .health:
            return "cross.case.circle.fill"
        case .bill:
            return "doc.text.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
                formatter.dateFormat = "MMM d"
            } else {
                formatter.dateFormat = "MMM d, yyyy"
            }
            return formatter.string(from: date)
        }
    }
}
