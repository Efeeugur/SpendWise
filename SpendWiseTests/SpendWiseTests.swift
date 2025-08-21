//
//  SpendWiseTests.swift
//  SpendWiseTests
//
//  Created by Efe Uğur on 3.12.2024.
//

import XCTest
@testable import SpendWise
final class SpendWiseTests: XCTestCase {

    func testGiderModeliOlusturma() {
        let gider = Gider(
            baslik: "Market",
            tarih: Date(),
            miktar: 150.0,
            tur: .anlik,
            kategori: .gida,
            currency: .TRY,
            not: "Haftalık alışveriş"
        )
        XCTAssertEqual(gider.baslik, "Market")
        XCTAssertEqual(gider.kategori, .gida)
        XCTAssertEqual(gider.miktar, 150.0)
    }

    func testGelirModeliOlusturma() {
        let gelir = Gelir(
            baslik: "Maaş",
            tarih: Date(),
            miktar: 10000.0,
            kategori: .maas,
            currency: .TRY,
            not: nil
        )
        XCTAssertEqual(gelir.baslik, "Maaş")
        XCTAssertEqual(gelir.kategori, .maas)
        XCTAssertEqual(gelir.miktar, 10000.0)
    }

    func testGiderKaydetYukle() {
        let giderler = [
            Gider(baslik: "Market", tarih: Date(), miktar: 100, tur: .anlik, kategori: .gida, currency: .TRY),
            Gider(baslik: "Fatura", tarih: Date(), miktar: 200, tur: .anlik, kategori: .fatura, currency: .TRY)
        ]
        UserDefaultsManager.saveGiderler(giderler)
        let yuklenen = UserDefaultsManager.loadGiderler()
        XCTAssertEqual(yuklenen.count, 2)
        XCTAssertEqual(yuklenen[0].baslik, "Market")
    }

    func testAylikLimitKaydetYukle() {
        UserDefaultsManager.saveMonthlyLimit(5000)
        let limit = UserDefaultsManager.loadMonthlyLimit()
        XCTAssertEqual(limit, 5000)
    }

    func testVarsayilanParaBirimi() {
        UserDefaultsManager.saveDefaultCurrency(.USD)
        let currency = UserDefaultsManager.loadDefaultCurrency()
        XCTAssertEqual(currency, .USD)
    }

    func testKategoriBazliGiderToplami() {
        let giderler = [
            Gider(baslik: "Market", tarih: Date(), miktar: 100, tur: .anlik, kategori: .gida, currency: .TRY),
            Gider(baslik: "Fatura", tarih: Date(), miktar: 200, tur: .anlik, kategori: .fatura, currency: .TRY),
            Gider(baslik: "Restoran", tarih: Date(), miktar: 50, tur: .anlik, kategori: .gida, currency: .TRY)
        ]
        let gidaToplam = giderler.filter { $0.kategori == .gida }.reduce(0) { $0 + $1.miktar }
        XCTAssertEqual(gidaToplam, 150)
    }

    func testLimitAsimi() {
        let giderler = [
            Gider(baslik: "Market", tarih: Date(), miktar: 3000, tur: .anlik, kategori: .gida, currency: .TRY),
            Gider(baslik: "Fatura", tarih: Date(), miktar: 2500, tur: .anlik, kategori: .fatura, currency: .TRY)
        ]
        UserDefaultsManager.saveMonthlyLimit(5000)
        let toplam = giderler.reduce(0) { $0 + $1.miktar }
        let limit = UserDefaultsManager.loadMonthlyLimit() ?? 0
        XCTAssertTrue(toplam > limit)
    }
}
