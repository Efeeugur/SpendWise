//
//  Phase2_SecurityTests.swift
//  SpendWiseTests
//
//  Phase 2-5 feature tests
//

import XCTest
@testable import SpendWise

// MARK: - NumberParsing Tests
final class NumberParsingTests: XCTestCase {
    
    func testBasicIntegerParsing() {
        XCTAssertEqual("42".toLocalizedDouble(), 42.0)
        XCTAssertEqual("0".toLocalizedDouble(), 0.0)
    }
    
    func testDotDecimalParsing() {
        XCTAssertEqual("10.50".toLocalizedDouble(), 10.50)
        XCTAssertEqual("1234.99".toLocalizedDouble(), 1234.99)
    }
    
    func testCommaDecimalParsing() {
        // Comma should be handled as decimal separator fallback
        let result = "10,50".toLocalizedDouble()
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 10.50, accuracy: 0.01)
    }
    
    func testEmptyStringReturnsNil() {
        XCTAssertNil("".toLocalizedDouble())
    }
    
    func testNonNumericReturnsNil() {
        XCTAssertNil("abc".toLocalizedDouble())
        XCTAssertNil("$100".toLocalizedDouble())
    }
    
    func testNegativeNumber() {
        let result = "-25.50".toLocalizedDouble()
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, -25.50, accuracy: 0.01)
    }
}

// MARK: - ExportManager Tests
final class ExportManagerTests: XCTestCase {
    
    let exportManager = ExportManager.shared
    
    func testCSVEscapeNoSpecialChars() {
        XCTAssertEqual(exportManager.csvEscape("Hello"), "Hello")
    }
    
    func testCSVEscapeWithComma() {
        XCTAssertEqual(exportManager.csvEscape("Hello, World"), "\"Hello, World\"")
    }
    
    func testCSVEscapeWithQuotes() {
        XCTAssertEqual(exportManager.csvEscape("Say \"hi\""), "\"Say \"\"hi\"\"\"")
    }
    
    func testCSVEscapeWithNewline() {
        XCTAssertEqual(exportManager.csvEscape("Line1\nLine2"), "\"Line1\nLine2\"")
    }
    
    func testCSVEscapeEmptyString() {
        XCTAssertEqual(exportManager.csvEscape(""), "")
    }
    
    func testGenerateCSVHeader() {
        let csv = exportManager.generateCSV(incomes: [], expenses: [])
        // Should contain BOM + header
        XCTAssertTrue(csv.contains("Type,Title,Date,Amount,Currency,Category,Note"))
    }
    
    func testGenerateCSVWithIncome() {
        let income = Income(
            title: "Salary",
            date: Date(),
            amount: 5000.0,
            category: .salary,
            currency: .TRY,
            note: nil
        )
        let csv = exportManager.generateCSV(incomes: [income], expenses: [])
        XCTAssertTrue(csv.contains("Income,Salary"))
        XCTAssertTrue(csv.contains("5000.00"))
        XCTAssertTrue(csv.contains("TRY"))
    }
    
    func testGenerateCSVWithExpense() {
        let expense = Expense(
            title: "Groceries",
            date: Date(),
            amount: 250.75,
            type: .oneTime,
            category: .food,
            currency: .USD,
            note: "Weekly shopping"
        )
        let csv = exportManager.generateCSV(incomes: [], expenses: [expense])
        XCTAssertTrue(csv.contains("Expense,Groceries"))
        XCTAssertTrue(csv.contains("250.75"))
        XCTAssertTrue(csv.contains("USD"))
    }
    
    func testCSVSpecialCharactersInTitle() {
        let expense = Expense(
            title: "Coffee, Tea & \"Snacks\"",
            date: Date(),
            amount: 50.0,
            type: .oneTime,
            category: .food,
            currency: .TRY,
            note: nil
        )
        let csv = exportManager.generateCSV(incomes: [], expenses: [expense])
        // Title with comma and quotes should be properly escaped
        XCTAssertTrue(csv.contains("\"Coffee, Tea & \"\"Snacks\"\"\""))
    }
    
    func testGenerateSummaryTotals() {
        let incomes = [
            Income(title: "Salary", date: Date(), amount: 10000, category: .salary, currency: .TRY)
        ]
        let expenses = [
            Expense(title: "Rent", date: Date(), amount: 3000, type: .monthly, category: .bill, currency: .TRY)
        ]
        let summary = exportManager.generateSummary(incomes: incomes, expenses: expenses)
        XCTAssertTrue(summary.contains("10000.00"))
        XCTAssertTrue(summary.contains("3000.00"))
        XCTAssertTrue(summary.contains("7000.00")) // Net balance
    }
}

// MARK: - AppConfig Tests
final class AppConfigTests: XCTestCase {
    
    func testAppVersionNotEmpty() {
        let version = AppConfig.appVersion
        XCTAssertFalse(version.isEmpty)
    }
    
    func testBuildNumberNotEmpty() {
        let build = AppConfig.buildNumber
        XCTAssertFalse(build.isEmpty)
    }
}
