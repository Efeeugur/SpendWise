import SwiftUI

struct IncomesView: View {
    @Binding var incomes: [Income]
    @Binding var userId: String
    @State private var searchText: String = ""
    @State private var showAddIncomeModal: Bool = false
    @State private var incomeToEdit: Income? = nil
    @State private var isLoading: Bool = false
    @State private var selectedFilter: IncomeFilter = .all
    @StateObject private var currencyManager = CurrencyManager.shared
    
    private var selectedDisplayCurrency: Currency { 
        UserDefaultsManager.loadDefaultCurrency() 
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Content
            if filteredIncomes.isEmpty {
                emptyStateView
            } else {
                incomeListView
            }
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Search Income".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                addIncomeButton
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if isLoading { 
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .sheet(isPresented: $showAddIncomeModal) {
            AddIncomeView(incomes: $incomes, userEmail: userId == "guest" ? nil : userId)
        }
        .sheet(item: $incomeToEdit) { income in
            EditIncomeView(incomes: $incomes, income: income)
        }
        .task(id: userId) { await loadRemoteIfNeeded() }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Summary Card
            incomeSummaryCard
            
            // Filter Tabs
            if !incomes.isEmpty {
                filterTabs
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    private var incomeSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("Total Income".localized)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currencyManager.formatAmount(totalIncome, currency: selectedDisplayCurrency))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text("\(incomes.count) income\(incomes.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.green, Color.green.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(IncomeFilter.allCases, id: \.self) { filter in
                    filterTab(filter)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }
    
    private func filterTab(_ filter: IncomeFilter) -> some View {
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
                Color.green : Color(.systemGray6)
            )
            .foregroundColor(
                selectedFilter == filter ? 
                .white : .primary
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Add Income Button
    private var addIncomeButton: some View {
        Button {
            showAddIncomeModal = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.green)
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
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "arrow.up.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.green.opacity(0.7))
            }
            
            VStack(spacing: 8) {
                Text("No Income Yet".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Start tracking your income sources to get insights into your financial growth.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                showAddIncomeModal = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add First Income")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(25)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Income List
    private var incomeListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredIncomes) { income in
                    IncomeCard(
                        income: income,
                        onTap: { incomeToEdit = income },
                        onDelete: { deleteIncome(income) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Computed Properties
    private var totalIncome: Double {
        incomes.reduce(0) { $0 + currencyManager.convert($1.amount, from: $1.currency, to: selectedDisplayCurrency) }
    }
    
    var filteredIncomes: [Income] {
        var filtered = incomes
        
        // Apply filter selection
        switch selectedFilter {
        case .all:
            break
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            filtered = filtered.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .category(let category):
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply search text
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
        
        // Sort by date (newest first)
        return filtered.sorted { $0.date > $1.date }
    }

    // MARK: - Actions
    private func deleteIncome(_ income: Income) {
        withAnimation {
            incomes.removeAll { $0.id == income.id }
        }
        
        if userId != "guest" {
            Task { 
                try? await SupabaseService.shared.deleteIncome(id: income.id) 
            }
        } else {
            UserDefaultsManager.saveIncomes(incomes, forUser: userId)
        }
    }

    func deleteIncomes(at offsets: IndexSet) {
        let incomesToDelete = offsets.map { filteredIncomes[$0] }
        
        withAnimation {
            for income in incomesToDelete {
                incomes.removeAll { $0.id == income.id }
            }
        }
        
        if userId != "guest" {
            Task { 
                for income in incomesToDelete {
                    try? await SupabaseService.shared.deleteIncome(id: income.id)
                }
            }
        } else {
            UserDefaultsManager.saveIncomes(incomes, forUser: userId)
        }
    }

    @MainActor
    private func loadRemoteIfNeeded() async {
        guard userId != "guest" else { return }
        isLoading = true
        defer { isLoading = false }
        do { incomes = try await SupabaseService.shared.fetchIncomes(email: userId) } catch {}
    }
}

// MARK: - Supporting Types
enum IncomeFilter: CaseIterable, Hashable {
    case all
    case thisMonth
    case category(IncomeCategory)
    
    static var allCases: [IncomeFilter] {
        var cases: [IncomeFilter] = [.all, .thisMonth]
        cases.append(contentsOf: IncomeCategory.allCases.map { .category($0) })
        return cases
    }
    
    var title: String {
        switch self {
        case .all:
            return "All"
        case .thisMonth:
            return "This Month"
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
        case .category(let category):
            switch category {
            case .salary:
                return "briefcase"
            case .additionalIncome:
                return "plus.circle"
            case .gift:
                return "gift"
            case .other:
                return "ellipsis.circle"
            }
        }
    }
}

// MARK: - Income Card Component
struct IncomeCard: View {
    let income: Income
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
                incomeIcon
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Title and Amount
                    HStack {
                        Text(income.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(currencyManager.formatAmount(income.amount, currency: income.currency))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    // Category and Date
                    HStack {
                        categoryTag
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDate(income.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Note if exists
                    if let note = income.note, !note.isEmpty {
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
        .alert("Delete Income", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this income entry?")
        }
    }
    
    private var incomeIcon: some View {
        Group {
            if let photoData = income.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: categoryIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var categoryTag: some View {
        Text(income.category.rawValue.localized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var categoryIcon: String {
        switch income.category {
        case .salary:
            return "briefcase.fill"
        case .additionalIncome:
            return "plus.circle.fill"
        case .gift:
            return "gift.fill"
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

// MARK: - Preview
struct IncomesView_Previews: PreviewProvider {
    static var previews: some View {
        IncomesView(incomes: .constant([
            Income(title: "Freelance Project", date: Date(), amount: 500, category: .additionalIncome, currency: .USD, note: nil, photoData: nil),
            Income(title: "Salary", date: Date().addingTimeInterval(-86400*14), amount: 2000, category: .salary, currency: .USD, note: nil, photoData: nil),
            Income(title: "Freelance Project", date: Date().addingTimeInterval(-86400*20), amount: 350, category: .additionalIncome, currency: .USD, note: nil, photoData: nil)
        ]), userId: .constant("previewUserId"))
        .environment(\.colorScheme, .light)
        IncomesView(incomes: .constant([
            Income(title: "Freelance Project", date: Date(), amount: 500, category: .additionalIncome, currency: .USD, note: nil, photoData: nil),
            Income(title: "Salary", date: Date().addingTimeInterval(-86400*14), amount: 2000, category: .salary, currency: .USD, note: nil, photoData: nil),
            Income(title: "Freelance Project", date: Date().addingTimeInterval(-86400*20), amount: 350, category: .additionalIncome, currency: .USD, note: nil, photoData: nil)
        ]), userId: .constant("previewUserId"))
        .environment(\.colorScheme, .dark)
    }
}
