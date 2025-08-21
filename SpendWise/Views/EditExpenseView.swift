import SwiftUI

struct EditExpenseView: View {
    @Binding var expenses: [Expense]
    @Binding var expense: Expense
    @Environment(\.dismiss) var dismiss
    
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    @State private var newCategory: ExpenseCategory
    @State private var newCurrency: Currency
    @State private var newPhoto: UIImage?
    @State private var newNote: String

    init(expenses: Binding<[Expense]>, expense: Binding<Expense>) {
        self._expenses = expenses
        self._expense = expense
        self._newCategory = State(initialValue: expense.wrappedValue.category)
        self._newCurrency = State(initialValue: expense.wrappedValue.currency)
        self._newNote = State(initialValue: expense.wrappedValue.note ?? "")
        
        // Convert Data? to UIImage? for photo
        if let data = expense.wrappedValue.photoData, let uiImage = UIImage(data: data) {
            self._newPhoto = State(initialValue: uiImage)
        } else {
            self._newPhoto = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Title", text: $expense.title)
                    DatePicker("Date", selection: $expense.date, displayedComponents: .date)
                    TextField("Amount", value: $expense.amount, formatter: decimalFormatter)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $newCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.symbol) \(currency.name)").tag(currency)
                        }
                    }
                    Picker("Type", selection: $expense.type) {
                        ForEach(ExpenseType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    Picker("Category", selection: $newCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
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
            .navigationTitle("Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                            let photoData = newPhoto?.jpegData(compressionQuality: 0.7)
                            expenses[index] = Expense(
                                title: expense.title,
                                date: expense.date,
                                amount: expense.amount,
                                type: expense.type,
                                category: newCategory,
                                currency: newCurrency,
                                note: newNote.isEmpty ? nil : newNote,
                                photoData: photoData
                            )
                            Task { try? await SupabaseService.shared.updateExpense(expenses[index]) }
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}