import SwiftUI
import PhotosUI

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
    @State private var selectedPhoto: PhotosPickerItem?
    
    private var isFormValid: Bool {
        !title.isEmpty && !amount.isEmpty && Double(amount) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        titleField
                        amountField
                        typeField
                        categoryField
                        dateField
                        reminderSection
                        photoSection
                        noteField
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save".localized) {
                        saveExpense()
                    }
                    .foregroundColor(isFormValid ? .blue : .secondary)
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("Add Expense".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Track your spending")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Form Fields
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "textformat")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 20)
                Text("Expense Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            TextField("Enter expense name", text: $title)
                .textFieldStyle(ExpenseTextFieldStyle())
        }
    }
    
    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 20)
                Text("Amount")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 12) {
                TextField("0", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(ExpenseTextFieldStyle())
                
                Picker("Currency", selection: $selectedCurrency) {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Text(currency.symbol).tag(currency)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 80)
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var typeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "repeat")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 20)
                Text("Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Picker("Type", selection: $type) {
                ForEach(ExpenseType.allCases, id: \.self) { expenseType in
                    Text(expenseType.rawValue.localized).tag(expenseType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tag")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 20)
                Text("Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Picker("Category", selection: $category) {
                ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                    Text(cat.rawValue.localized).tag(cat)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var dateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 20)
                Text("Date")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 20)
                Text("Reminder")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 12) {
                Toggle("Add Reminder".localized, isOn: $isReminderOn)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                if isReminderOn {
                    DatePicker("Reminder Date".localized, selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .slide))
                }
            }
        }
    }
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 20)
                Text("Photo")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            if let image = selectedImage {
                VStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Remove Photo") {
                        selectedImage = nil
                        selectedPhoto = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        
                        Text("Add Photo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(.secondary.opacity(0.3))
                    )
                }
            }
        }
    }
    
    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .frame(width: 20)
                Text("Note")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 100)
                
                TextEditor(text: $noteText)
                    .padding(12)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                
                if noteText.isEmpty {
                    Text("Add optional note...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func saveExpense() {
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
                do { 
                    try await SupabaseService.shared.createExpense(email: email, expense: newExpense) 
                } catch {}
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

// MARK: - Custom Text Field Style
struct ExpenseTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .font(.body)
    }
}
