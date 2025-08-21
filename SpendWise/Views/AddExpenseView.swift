import SwiftUI

struct AddExpenseView: View {
    @Binding var expenses: [Expense]
    var userEmail: String? = nil
    @Environment(\.dismiss) var dismiss
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var amount: String = ""
    @State private var type: ExpenseType = .oneTime
    @State private var category: ExpenseCategory = .other
    @State private var selectedCurrency: Currency = UserDefaultsManager.loadDefaultCurrency()
    @State private var selectedImage: UIImage? = nil
    @State private var noteText: String = ""
    @State private var reminderDate: Date = Date()
    @State private var isReminderOn: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Expense Details".localized)) {
                    TextField("Title".localized, text: $title)
                    DatePicker("Date".localized, selection: $date, displayedComponents: .date)
                    TextField("Amount".localized, text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Currency".localized, selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.symbol) \(currency.name)").tag(currency)
                        }
                    }
                    Picker("Type".localized, selection: $type) {
                        ForEach(ExpenseType.allCases, id: \.self) { type in
                            Text(type.rawValue.localized).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    Picker("Category".localized, selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
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
                Section("Reminder".localized) {
                    Toggle("Add Reminder".localized, isOn: $isReminderOn)
                    if isReminderOn {
                        DatePicker("Reminder Date".localized, selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Add Expense".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        guard let amountDouble = Double(amount), !title.isEmpty else { return }
                        
                        let photoData = selectedImage?.jpegData(compressionQuality: 0.7)
                        let newExpense = Expense(
                            title: title,
                            date: date,
                            amount: amountDouble,
                            type: type,
                            category: category,
                            currency: selectedCurrency,
                            note: noteText.isEmpty ? nil : noteText,
                            photoData: photoData
                        )
                        
                        if let email = userEmail, email != "guest" {
                            Task {
                                do { try await SupabaseService.shared.createExpense(email: email, expense: newExpense) } catch {}
                                expenses.append(newExpense)
                                handleLimitAndReminder(amount: amountDouble, date: date)
                                dismiss()
                            }
                        } else {
                            expenses.append(newExpense)
                            handleLimitAndReminder(amount: amountDouble, date: date)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func handleLimitAndReminder(amount: Double, date: Date) {
        // Limit kontrolü ve bildirimler
        if let limit = UserDefaultsManager.loadMonthlyLimit() {
            let month = Calendar.current.component(.month, from: date)
            let year = Calendar.current.component(.year, from: date)
            let totalMonthExpense = expenses.filter {
                let t = $0.date
                return Calendar.current.component(.month, from: t) == month && Calendar.current.component(.year, from: t) == year
            }.reduce(0) { $0 + $1.amount } + amount
            if totalMonthExpense > limit {
                let totalStr = String(format: "%.2f", totalMonthExpense)
                let limitStr = String(format: "%.2f", limit)
                let body = "You have exceeded your monthly expense limit. Total: ₺\(totalStr) / Limit: ₺\(limitStr)".localized
                NotificationManager.shared.scheduleNotification(
                    title: "Expense Limit Exceeded!".localized,
                    body: body,
                    date: Date().addingTimeInterval(2)
                )
            }
        }
        if isReminderOn {
            NotificationManager.shared.scheduleNotification(
                title: "Expense Reminder".localized,
                body: "\(title) payment due!".localized,
                date: reminderDate
            )
        }
    }
}