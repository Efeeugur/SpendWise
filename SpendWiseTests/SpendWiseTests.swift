//
//  SpendWiseTests.swift
//  SpendWiseTests
//
//  Created by Efe Uğur on 3.12.2024.
//

import XCTest
@testable import SpendWise

final class SpendWiseTests: XCTestCase {

    // MARK: - Expense Model Tests

    func testExpenseModelCreation() {
        let expense = Expense(
            title: "Grocery Store",
            date: Date(),
            amount: 150.0,
            type: .oneTime,
            category: .food,
            currency: .TRY,
            note: "Weekly shopping"
        )
        XCTAssertEqual(expense.title, "Grocery Store")
        XCTAssertEqual(expense.category, .food)
        XCTAssertEqual(expense.amount, 150.0)
        XCTAssertEqual(expense.type, .oneTime)
        XCTAssertEqual(expense.currency, .TRY)
        XCTAssertEqual(expense.note, "Weekly shopping")
    }

    // MARK: - Income Model Tests

    func testIncomeModelCreation() {
        let income = Income(
            title: "Salary",
            date: Date(),
            amount: 10000.0,
            category: .salary,
            currency: .TRY,
            note: nil
        )
        XCTAssertEqual(income.title, "Salary")
        XCTAssertEqual(income.category, .salary)
        XCTAssertEqual(income.amount, 10000.0)
    }

    // MARK: - UserDefaults Persistence Tests

    func testExpenseSaveAndLoad() {
        let userId = "test_user_\(UUID().uuidString)"
        let expenses = [
            Expense(title: "Grocery Store", date: Date(), amount: 100, type: .oneTime, category: .food, currency: .TRY),
            Expense(title: "Electricity Bill", date: Date(), amount: 200, type: .monthly, category: .bill, currency: .TRY)
        ]
        UserDefaultsManager.saveExpenses(expenses, forUser: userId)
        let loaded = UserDefaultsManager.loadExpenses(forUser: userId)
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].title, "Grocery Store")
        XCTAssertEqual(loaded[1].title, "Electricity Bill")

        // Clean up
        UserDefaultsManager.saveExpenses([], forUser: userId)
    }

    func testIncomeSaveAndLoad() {
        let userId = "test_user_\(UUID().uuidString)"
        let incomes = [
            Income(title: "Salary", date: Date(), amount: 10000, category: .salary, currency: .TRY),
            Income(title: "Freelance", date: Date(), amount: 3000, category: .additionalIncome, currency: .TRY)
        ]
        UserDefaultsManager.saveIncomes(incomes, forUser: userId)
        let loaded = UserDefaultsManager.loadIncomes(forUser: userId)
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].title, "Salary")
        XCTAssertEqual(loaded[1].title, "Freelance")

        // Clean up
        UserDefaultsManager.saveIncomes([], forUser: userId)
    }

    // MARK: - Monthly Limit Tests

    func testMonthlyLimitSaveAndLoad() {
        UserDefaultsManager.saveMonthlyLimit(5000)
        let limit = UserDefaultsManager.loadMonthlyLimit()
        XCTAssertEqual(limit, 5000)
    }

    func testDefaultCurrency() {
        UserDefaultsManager.saveDefaultCurrency(.USD)
        let currency = UserDefaultsManager.loadDefaultCurrency()
        XCTAssertEqual(currency, .USD)
    }

    // MARK: - Category Spending Tests

    func testCategoryBasedExpenseTotal() {
        let expenses = [
            Expense(title: "Grocery Store", date: Date(), amount: 100, type: .oneTime, category: .food, currency: .TRY),
            Expense(title: "Electricity Bill", date: Date(), amount: 200, type: .monthly, category: .bill, currency: .TRY),
            Expense(title: "Restaurant", date: Date(), amount: 50, type: .oneTime, category: .food, currency: .TRY)
        ]
        let foodTotal = expenses.filter { $0.category == .food }.reduce(0) { $0 + $1.amount }
        XCTAssertEqual(foodTotal, 150)
    }

    func testLimitExceeded() {
        let expenses = [
            Expense(title: "Grocery Store", date: Date(), amount: 3000, type: .oneTime, category: .food, currency: .TRY),
            Expense(title: "Electricity Bill", date: Date(), amount: 2500, type: .monthly, category: .bill, currency: .TRY)
        ]
        UserDefaultsManager.saveMonthlyLimit(5000)
        let total = expenses.reduce(0) { $0 + $1.amount }
        let limit = UserDefaultsManager.loadMonthlyLimit() ?? 0
        XCTAssertTrue(total > limit)
    }

    // MARK: - User Model Tests

    func testUserEquatable() {
        let user1 = User(email: "test@test.com", name: "Test", isGuest: false)
        let user2 = User(email: "test@test.com", name: "Test", isGuest: false)
        // Different UUIDs should make them not equal
        XCTAssertNotEqual(user1, user2)
    }

    func testUserGuestCreation() {
        let guest = User(isGuest: true)
        XCTAssertTrue(guest.isGuest)
        XCTAssertNil(guest.email)
        XCTAssertNil(guest.name)
    }

    // MARK: - Password Security Tests

    func testPasswordHashing() {
        let password = "TestPassword123"
        let hash = password.sha256()
        XCTAssertNotEqual(password, hash)
        // Same password should always produce same hash
        XCTAssertEqual(password.sha256(), hash)
    }
}
