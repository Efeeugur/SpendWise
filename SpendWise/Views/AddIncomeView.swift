import SwiftUI

struct AddIncomeView: View {
    @Binding var incomes: [Income]
    var userEmail: String? = nil
    @Environment(\.dismiss) var dismiss
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var amount: String = ""
    @State private var category: IncomeCategory = .other
    @State private var selectedCurrency: Currency = UserDefaultsManager.loadDefaultCurrency()
    @State private var selectedImage: UIImage? = nil
    @State private var noteText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Income Details".localized)) {
                    TextField("Title".localized, text: $title)
                    DatePicker("Date".localized, selection: $date, displayedComponents: .date)
                    TextField("Amount".localized, text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Currency".localized, selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.symbol) \(currency.name)").tag(currency)
                        }
                    }
                    Picker("Category".localized, selection: $category) {
                        ForEach(IncomeCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.localized).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("Photo and Note".localized)) {
                    PhotoNoteView(image: $selectedImage)
                    
                    TextEditor(text: $noteText)
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
            .navigationTitle("Add Income".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        guard let amountDouble = Double(amount), !title.isEmpty else { return }
                        
                        let photoData = selectedImage?.jpegData(compressionQuality: 0.7)
                        let newIncome = Income(
                            title: title,
                            date: date,
                            amount: amountDouble,
                            category: category,
                            currency: selectedCurrency,
                            note: noteText.isEmpty ? nil : noteText,
                            photoData: photoData
                        )
                        
                        if let email = userEmail, email != "guest" {
                            Task {
                                do { try await SupabaseService.shared.createIncome(email: email, income: newIncome) } catch {}
                                incomes.append(newIncome)
                                dismiss()
                            }
                        } else {
                            incomes.append(newIncome)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}