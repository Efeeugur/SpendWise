import SwiftUI

struct IncomesView: View {
    @Binding var incomes: [Income]
    @Binding var userId: String
    @State private var searchText: String = ""
    @State private var showAddIncomeModal: Bool = false
    @State private var incomeToEdit: Income? = nil
    @State private var isLoading: Bool = false
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack {
            if filteredIncomes.isEmpty {
                    Spacer()
                    ContentUnavailableView(label: {
                        Label("No Income".localized, systemImage: "tray")
                    }, description: {
                        Text("You haven't added any income yet. You can add new income from the top right.".localized)
                    })
                    Spacer()
                } else {
                    List {
                        ForEach(filteredIncomes) { income in
                            Button {
                                incomeToEdit = income
                            } label: {
                            IncomeRow(income: income)
                            }
                            .listRowBackground(Color(.systemBackground))
                        }
                        .onDelete(perform: deleteIncomes)
                    }
                    .listStyle(.plain)
                    .background(Color(.systemBackground))
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Income".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddIncomeModal = true }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if isLoading { ProgressView() }
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

    var filteredIncomes: [Income] {
        if searchText.isEmpty {
            return incomes
        } else {
            return incomes.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }

    func deleteIncomes(at offsets: IndexSet) {
        let ids = offsets.map { incomes[$0].id }
        incomes.remove(atOffsets: offsets)
        if userId != "guest" {
            Task { for id in ids { try? await SupabaseService.shared.deleteIncome(id: id) } }
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

struct IncomeRow: View {
    let income: Income
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showingDetail = false
    
    var body: some View {
        HStack {
            // Show photo if exists
            if let photoData = income.photoData, let uiImage = UIImage(data: photoData) {
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
                Text(income.title)
                    .font(.headline)
                Text(currencyManager.formatAmount(income.amount, currency: income.currency))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(income.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(income.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
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
