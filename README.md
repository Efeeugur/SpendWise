# 📱 SpendWise

A smart iOS expense tracking app built with SwiftUI, featuring multi-currency support and financial insights.

## ✨ Current Features

### 📊 Financial Tracking
- **Income & Expense Management** — Track all your financial transactions
- **Multi-Currency Support** — Support for TRY, USD, EUR, GBP
- **Category Organization** — Organized income and expense categories
- **Photo Receipts** — Attach photos to transactions for better record keeping

### 🔐 Security & Privacy
- **Biometric Authentication** — Touch ID / Face ID support
- **PIN Protection** — Custom PIN security option
- **Guest Mode** — Use without registration (data cleared on exit)

### 🎨 User Experience
- **Dark/Light Theme** — Manual theme selection
- **Smart Insights** — Rule-based spending recommendations
- **Modern UI** — SwiftUI design with smooth animations
- **Data Export** — Export transactions to CSV

## 🚧 Planned Features

> These features are on the roadmap and not yet implemented:

- [ ] Supabase cloud synchronization (proper implementation)
- [ ] iCloud Backup integration
- [ ] Multi-device sync
- [ ] Real-time exchange rates via API
- [ ] AI-powered spending recommendations
- [ ] Full Turkish/English localization (.strings files)
- [ ] Comprehensive test suite
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Charts and visual analytics (Swift Charts)

## 🏗️ Architecture

```
SpendWise/
├── Config/           # App configuration
├── Models/           # Data models (User, Income, Expense)
├── Views/            # SwiftUI views and screens
├── Managers/         # Business logic managers
├── Utils/            # Helper utilities and extensions
├── Assets/           # Images and app icons
Database/             # Supabase SQL schema (planned)
```

### Key Components
- **SwiftUI Views** — Declarative UI with state management
- **Manager Pattern** — Business logic separated into manager classes
- **UserDefaults** — Current data persistence (migration to SwiftData planned)

## 🚀 Technologies

- **SwiftUI** — Modern iOS UI framework
- **Foundation** — Core iOS frameworks
- **LocalAuthentication** — Biometric security
- **UserNotifications** — Spending alerts

## 📱 Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## 🛠️ Setup

1. Clone the repository
```bash
git clone https://github.com/Efeeugur/SpendWise.git
cd SpendWise
```

2. Open the project in Xcode
```bash
open SpendWise.xcodeproj
```

3. Build and run on your device or simulator

> **Note:** Supabase cloud features are not yet fully implemented. The app works entirely in offline/local mode.

## 🏃‍♀️ Usage

### Getting Started
1. **Launch** — The app starts with an animated splash screen
2. **Choose Mode** — Use as guest or create a local account
3. **Add Transactions** — Start tracking your income and expenses
4. **View Summary** — Check your financial totals

### Key Screens
- **Tab Navigation** — Income, Expenses, Summary, Settings
- **Quick Add** — Tap + to add new transactions
- **Security Setup** — Configure PIN or biometric authentication
- **Theme Selection** — Choose your preferred appearance

## 🔒 Privacy & Security

- **Local-First** — All data stored locally by default
- **No Tracking** — No analytics or user tracking
- **Guest Mode** — Use without any data persistence

> ⚠️ **Note:** Current data storage uses UserDefaults. Migration to encrypted storage (Keychain + SwiftData) is planned.

## 📄 License

This project is available under the MIT License. See [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions are welcome! Please check the [Issues](https://github.com/Efeeugur/SpendWise/issues) page for current tasks and feel free to submit a Pull Request.

## 📧 Support

For support or feature requests, please open an issue on GitHub.

---

Built with ❤️ using SwiftUI and modern iOS development practices.