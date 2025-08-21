# 📱 SpendWise

A smart iOS expense tracking app built with SwiftUI, featuring multi-currency support, cloud synchronization, and intelligent financial insights.

## ✨ Features

### 📊 Financial Tracking
- **Income & Expense Management** - Track all your financial transactions
- **Multi-Currency Support** - Support for TRY, USD, EUR, GBP with real-time exchange rates
- **Category Organization** - Organized income and expense categories
- **Photo Receipts** - Attach photos to transactions for better record keeping

### 🔐 Security & Privacy
- **Biometric Authentication** - Touch ID / Face ID support
- **PIN Protection** - Custom PIN security option
- **Guest Mode** - Use without registration (data cleared on exit)
- **Secure Storage** - Local data encryption and secure cloud sync

### ☁️ Cloud & Sync
- **Supabase Integration** - Real-time cloud synchronization
- **iCloud Backup** - Native iOS iCloud integration
- **Multi-Device Support** - Sync across all your devices
- **Offline Support** - Works completely offline

### 🎨 User Experience
- **Dark/Light Theme** - System-adaptive or manual theme selection
- **Localization** - English and Turkish language support
- **Smart Insights** - AI-powered spending recommendations
- **Beautiful UI** - Modern SwiftUI design with smooth animations

## 🏗️ Architecture

```
SpendWise/
├── Models/           # Data models (User, Income, Expense)
├── Views/            # SwiftUI views and screens
├── Managers/         # Business logic managers
├── Services/         # External service integrations
├── Utils/            # Helper utilities and extensions
├── Config/           # App configuration
├── Localization/     # Multi-language support
└── Assets/           # Images and app icons
```

### Key Components
- **MVVM Architecture** - Clean separation of concerns
- **Reactive UI** - SwiftUI with Combine for state management
- **Core Data Alternative** - UserDefaults + Supabase for data persistence
- **Modular Design** - Well-organized, testable components

## 🚀 Technologies

- **SwiftUI** - Modern iOS UI framework
- **Combine** - Reactive programming framework
- **Supabase** - Backend as a Service for cloud sync
- **Foundation** - Core iOS frameworks
- **LocalAuthentication** - Biometric security
- **UserNotifications** - Smart spending alerts

## 📱 Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 🛠️ Setup

1. Clone the repository
```bash
git clone https://github.com/[YOUR_USERNAME]/SpendWise.git
cd SpendWise
```

2. Open the project in Xcode
```bash
open SpendWise.xcodeproj
```

3. Configure Supabase (optional for cloud features):
   - Update `SpendWise/Config/AppConfig.swift` with your Supabase credentials
   - Or use the app in offline mode without cloud sync

4. Build and run on your device or simulator

## 🏃‍♀️ Usage

### Getting Started
1. **Launch** - The app starts with a beautiful splash screen
2. **Choose Mode** - Use as guest or create an account for cloud sync
3. **Add Transactions** - Start tracking your income and expenses
4. **View Insights** - Check your financial summary and trends

### Key Features
- **Tab Navigation** - Income, Expenses, Summary, Settings
- **Quick Add** - Tap + to add new transactions
- **Search & Filter** - Find transactions quickly
- **Security Setup** - Configure PIN or biometric authentication
- **Theme Selection** - Choose your preferred appearance

## 🧪 Testing

Run tests with Xcode:
```bash
# Unit Tests
⌘ + U

# UI Tests  
⌘ + U (with UI Test scheme selected)
```

Test coverage includes:
- Model creation and validation
- Data persistence and loading
- Business logic calculations
- User interface interactions

## 🔒 Privacy & Security

SpendWise takes privacy seriously:
- **Local-First** - All data stored locally by default
- **Optional Cloud Sync** - Cloud features are opt-in
- **Guest Mode** - Use without any data persistence
- **Secure Storage** - Encrypted data storage
- **No Tracking** - No analytics or user tracking

## 📄 License

This project is available under the MIT License. See LICENSE for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Support

For support or feature requests, please open an issue on GitHub.

---

Built with ❤️ using SwiftUI and modern iOS development practices.