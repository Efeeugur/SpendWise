import SwiftUI
import PhotosUI

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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var amountString: String

    init(incomes: Binding<[Income]>, income: Income) {
        self._incomes = incomes
        self.income = income
        self._newTitle = State(initialValue: income.title)
        self._newDate = State(initialValue: income.date)
        self._newAmount = State(initialValue: income.amount)
        self._newCategory = State(initialValue: income.category)
        self._newCurrency = State(initialValue: income.currency)
        self._newNote = State(initialValue: income.note ?? "")
        self._amountString = State(initialValue: String(income.amount))
        
        // Convert Data? to UIImage? on init
        if let data = income.photoData, let uiImage = UIImage(data: data) {
            self._newPhoto = State(initialValue: uiImage)
        } else {
            self._newPhoto = State(initialValue: nil)
        }
    }
    
    private var isFormValid: Bool {
        !newTitle.isEmpty && !amountString.isEmpty && Double(amountString) != nil
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
                        categoryField
                        dateField
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
                        saveIncome()
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
                    newPhoto = image
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
                            colors: [Color.green, Color.green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("Edit Income".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Update your income details")
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
                    .foregroundColor(.green)
                    .frame(width: 20)
                Text("Income Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            TextField("Enter income name", text: $newTitle)
                .textFieldStyle(EditIncomeTextFieldStyle())
        }
    }
    
    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                    .frame(width: 20)
                Text("Amount")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 12) {
                TextField("0", text: $amountString)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(EditIncomeTextFieldStyle())
                    .onChange(of: amountString) { _, newValue in
                        if let amount = Double(newValue) {
                            newAmount = amount
                        }
                    }
                
                Picker("Currency", selection: $newCurrency) {
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
    
    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tag")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                    .frame(width: 20)
                Text("Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Picker("Category", selection: $newCategory) {
                ForEach(IncomeCategory.allCases, id: \.self) { cat in
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
                    .foregroundColor(.green)
                    .frame(width: 20)
                Text("Date")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            DatePicker("", selection: $newDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                    .frame(width: 20)
                Text("Photo")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            if let image = newPhoto {
                VStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.badge.ellipsis")
                                    .font(.caption)
                                Text("Change")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Button("Remove") {
                            newPhoto = nil
                            selectedPhoto = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
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
                    .foregroundColor(.green)
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
                
                TextEditor(text: $newNote)
                    .padding(12)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                
                if newNote.isEmpty {
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
    private func saveIncome() {
        guard let amountDouble = Double(amountString), !newTitle.isEmpty else { return }
        
        if let index = incomes.firstIndex(where: { $0.id == income.id }) {
            let photoData = newPhoto?.jpegData(compressionQuality: 0.7)
            incomes[index] = Income(
                id: income.id,
                title: newTitle,
                date: newDate,
                amount: amountDouble,
                category: newCategory,
                currency: newCurrency,
                note: newNote.isEmpty ? nil : newNote,
                photoData: photoData
            )
            Task { 
                try? await SupabaseService.shared.updateIncome(incomes[index]) 
            }
        }
        dismiss()
    }
}

// MARK: - Custom Text Field Style
struct EditIncomeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .font(.body)
    }
}