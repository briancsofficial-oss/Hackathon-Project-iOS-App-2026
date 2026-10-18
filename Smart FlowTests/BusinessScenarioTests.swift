import XCTest
@testable import Smart_Flow

final class BusinessScenarioTests: XCTestCase {
    private func profile(_ values: [BusinessField: Double]) -> BusinessProfile {
        var p = BusinessProfile()
        for (field, value) in values { p.numbers[field.rawValue] = value }
        return p
    }

    private var sample: BusinessProfile {
        profile([.annualRevenue: 120_000, .cogsPercent: 30, .grossPayroll: 4_000, .rent: 1_000,
                 .termLoanPayment: 600, .equipmentPayment: 400, .cashOnHand: 10_000])
    }

    func testSampleNetCashFlow() {
        XCTAssertEqual(BusinessMetrics(p: sample).netCashFlow, 1_000, accuracy: 0.001)
    }

    func testBaselineScenarioChangesNothing() {
        XCTAssertEqual(BusinessScenario().applied(to: sample), sample)
        XCTAssertTrue(BusinessScenario().isBaseline)
    }

    func testMaterialCostBreakEven() {
        let pct = BusinessMetrics(p: sample).materialCostBreakEvenPercent!
        XCTAssertEqual(pct, 100.0 / 3.0, accuracy: 0.001)
        let at = BusinessScenario(materialCostChange: pct).applied(to: sample)
        XCTAssertEqual(BusinessMetrics(p: at).netCashFlow, 0, accuracy: 0.001)
    }

    func testRevenueDeclineBreakEven() {
        let pct = BusinessMetrics(p: sample).revenueDeclineBreakEvenPercent!
        XCTAssertEqual(pct, 100.0 / 7.0, accuracy: 0.001)
        let at = BusinessScenario(revenueChange: -pct).applied(to: sample)
        XCTAssertEqual(BusinessMetrics(p: at).netCashFlow, 0, accuracy: 0.001)
    }

    func testThresholdsWithoutCOGSOrWhenLosingMoney() {
        var noCOGS = sample
        noCOGS.numbers[BusinessField.cogsPercent.rawValue] = 0
        XCTAssertNil(BusinessMetrics(p: noCOGS).materialCostBreakEvenPercent)
        XCTAssertEqual(BusinessMetrics(p: noCOGS).revenueDeclineBreakEvenPercent!, 40, accuracy: 0.001)

        var losing = sample
        losing.numbers[BusinessField.rent.rawValue] = 3_000
        XCTAssertEqual(BusinessMetrics(p: losing).materialCostBreakEvenPercent, 0)
        XCTAssertEqual(BusinessMetrics(p: losing).revenueDeclineBreakEvenPercent, 0)

        XCTAssertNil(BusinessMetrics(p: BusinessProfile()).revenueDeclineBreakEvenPercent)
    }

    func testMonthsUntilCashBelowReserve() {
        var losing = sample
        losing.numbers[BusinessField.rent.rawValue] = 2_500
        let m = BusinessMetrics(p: losing)
        XCTAssertEqual(m.netCashFlow, -500, accuracy: 0.001)
        XCTAssertEqual(m.monthsUntilCash(below: 4_000)!, 12, accuracy: 0.001)
        XCTAssertEqual(m.monthsUntilCash(below: 12_000), 0)
        XCTAssertEqual(m.reserveHeadroom(above: 4_000), 6_000)
        XCTAssertNil(BusinessMetrics(p: sample).monthsUntilCash(below: 4_000))
    }

    func testDebtPaymentChange() {
        let up = BusinessScenario(debtPaymentChange: 500).applied(to: sample)
        XCTAssertEqual(BusinessMetrics(p: up).debtService, 1_500, accuracy: 0.001)
        XCTAssertEqual(up[.termLoanPayment], 900, accuracy: 0.001)

        let gone = BusinessScenario(debtPaymentChange: -2_000).applied(to: sample)
        XCTAssertEqual(BusinessMetrics(p: gone).debtService, 0, accuracy: 0.001)

        var noDebt = sample
        noDebt.numbers[BusinessField.termLoanPayment.rawValue] = nil
        noDebt.numbers[BusinessField.equipmentPayment.rawValue] = nil
        let added = BusinessScenario(debtPaymentChange: 300).applied(to: noDebt)
        XCTAssertEqual(BusinessMetrics(p: added).debtService, 300, accuracy: 0.001)
    }

    func testOneTimeExpenseHitsCashNotCashFlow() {
        let s = BusinessScenario(oneTimeExpense: 4_000)
        let after = s.applied(to: sample)
        XCTAssertEqual(after[.cashOnHand], 6_000)
        XCTAssertEqual(BusinessMetrics(p: after).netCashFlow, 1_000, accuracy: 0.001)
        XCTAssertEqual(s.cashShortfall(for: sample), 0)

        let big = BusinessScenario(oneTimeExpense: 15_000)
        XCTAssertEqual(big.applied(to: sample)[.cashOnHand], 0)
        XCTAssertEqual(big.cashShortfall(for: sample), 5_000)
    }

    func testCombinedScenarioAndDrivers() {
        let s = BusinessScenario(materialCostChange: 20, revenueChange: -10, oneTimeExpense: 1_000)
        XCTAssertEqual(BusinessMetrics(p: s.applied(to: sample)).netCashFlow, -240, accuracy: 0.001)
        XCTAssertEqual(s.netCashFlowChange(on: sample), -1_240, accuracy: 0.001)

        let impacts = s.driverImpacts(on: sample)
        XCTAssertEqual(impacts.map(\.driver).prefix(2), [.revenue, .materialCost])
        XCTAssertEqual(impacts[0].monthlyCashFlow, -700, accuracy: 0.001)
        XCTAssertEqual(impacts[1].monthlyCashFlow, -600, accuracy: 0.001)
        let expense = impacts.first { $0.driver == .oneTimeExpense }!
        XCTAssertEqual(expense.monthlyCashFlow, 0)
        XCTAssertEqual(expense.cash, -1_000)
    }
}
