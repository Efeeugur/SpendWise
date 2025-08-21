import SwiftUI

struct EditIncomeView: View {
    @Binding var incomes: [Income]
    var income: Income
    @Environment(\.dismiss) var dismiss
    
    @State private var newTitle: String
    @State private var newDate: Date
    @State private var newAmount: Double
    @State private var newCategory: IncomeCategory
    @State private var newCurrency: Currency
    @State private var newPhoto: UIImage?
    @State private var newNote: String

    init(incomes: Binding<[Income]>, income: Income) {
        self._incomes = incomes
        self.income = income
        self._newTitle = State(initialValue: income.title)
        self._newDate = State(initialValue: income.date)
        self._newAmount = State(initialValue: income.amount)
        self._newCategory = State(initialValue: income.category)
        self._newCurrency = State(initialValue: income.currency)
        self._newNote = State(initialValue: income.note ?? "")
        
        // Convert Data? to UIImage? on init
        if let data = income.photoData, let uiImage = UIImage(data: data) {
            self._newPhoto = State(initialValue: uiImage)
        } else {
            self._newPhoto = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Income Details")) {
                    TextField("Title", text: $newTitle)
                    DatePicker("Date", selection: $newDate, displayedComponents: .date)
                    TextField("Amount", value: $newAmount, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $newCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.symbol) \(currency.name)").tag(currency)
                        }
                    }
                    Picker("Category", selection: $newCategory) {
                        ForEach(IncomeCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("Photo and Note")) {
                    PhotoNoteView(image: $newPhoto)
                    
                    TextEditor(text: $newNote)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
            .navigationTitle("Edit Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let index = incomes.firstIndex(where: { $0.id == income.id }) {
                            let photoData = newPhoto?.jpegData(compressionQuality: 0.7)
                            incomes[index] = Income(
                                title: newTitle,
                                date: newDate,
                                amount: newAmount,
                                category: newCategory,
                                currency: newCurrency,
                                note: newNote.isEmpty ? nil : newNote,
                                photoData: photoData
                            )
                            Task { try? await SupabaseService.shared.updateIncome(incomes[index]) }
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}