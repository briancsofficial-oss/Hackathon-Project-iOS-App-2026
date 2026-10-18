import SwiftUI

struct WhatIfView: View {
    @ObservedObject private var store = BusinessStore.shared
    @EnvironmentObject var router: TabRouter
    @State private var scenario = BusinessScenario()
    @State private var reserveText = ""

    private var p: BusinessProfile { store.profile }
    private var now: BusinessMetrics { BusinessMetrics(p: p) }
    private var next: BusinessMetrics { BusinessMetrics(p: scenario.applied(to: p)) }
    private var reserveTarget: Double? { Double(reserveText.filter(\.isNumber)) }

    var body: some View {
        Group {
            if p.isAnswered(.annualRevenue) {
                content
            } else {
                emptyState
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("What-if")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") { scenario = BusinessScenario() }
                    .foregroundColor(brandColor)
                    .disabled(scenario.isBaseline)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 44))
                .foregroundColor(brandColor)
            Text("Nothing to test yet")
                .font(.system(size: 20, weight: .semibold))
            Text("Add your yearly revenue first. Then you can see what happens if sales drop, materials cost more, or a surprise bill shows up.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Start the AI interview") { router.selected = .interview }
                .buttonStyle(.borderedProminent)
                .tint(brandColor)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                adjustments
                comparison
                drivers
                thresholds
                Text("Each change is applied to your current answers. Educational estimates, not financial advice.")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .padding(16)
        }
    }

    private var adjustments: some View {
        AccountSection(title: "Change the numbers") {
            VStack(spacing: 18) {
                sliderRow("Material costs", value: $scenario.materialCostChange, range: -50...100, step: 5,
                          valueText: percentText(scenario.materialCostChange),
                          caption: now.monthlyCOGS > 0 ? "Today \(money(now.monthlyCOGS)) / mo" : "No cost of goods entered, so this has no effect.")
                sliderRow("Revenue", value: $scenario.revenueChange, range: -100...50, step: 5,
                          valueText: percentText(scenario.revenueChange),
                          caption: "Today \(money(now.monthlyRevenue)) / mo")
                sliderRow("Unexpected one-time expense", value: $scenario.oneTimeExpense, range: 0...expenseLimit, step: 500,
                          valueText: money(scenario.oneTimeExpense),
                          caption: "Comes out of the \(money(p[.cashOnHand])) cash on hand.")
                sliderRow("Monthly debt payments", value: $scenario.debtPaymentChange, range: debtRange, step: 50,
                          valueText: (scenario.debtPaymentChange > 0 ? "+" : "") + money(scenario.debtPaymentChange) + " / mo",
                          caption: "Today \(money(now.debtService)) / mo")
            }
            .padding(20)
        }
    }

    private var expenseLimit: Double { max(50_000, (p[.cashOnHand] / 500).rounded(.up) * 500) }

    private var debtRange: ClosedRange<Double> {
        let floor = (now.debtService / 50).rounded(.up) * 50
        return -floor...max(5_000, floor)
    }

    private func percentText(_ value: Double) -> String {
        (value > 0 ? "+" : "") + "\(Int(value.rounded()))%"
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double,
                           valueText: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.system(size: 16, weight: .medium))
                Spacer()
                Text(valueText).font(.system(size: 16, weight: .semibold))
            }
            Slider(value: value, in: range, step: step)
                .tint(brandColor)
                .accessibilityLabel(title)
                .accessibilityValue(valueText)
            Text(caption).font(.system(size: 13)).foregroundColor(.gray)
        }
    }

    private var comparison: some View {
        AccountSection(title: "Now vs. what-if") {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Text("Now").frame(width: 92, alignment: .trailing)
                    Text("What-if").frame(width: 92, alignment: .trailing)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
                compareRow("Money in / mo", now.monthlyIncome, next.monthlyIncome, higherIsBetter: true, text: money)
                compareRow("Money out / mo", now.monthlyOutflow, next.monthlyOutflow, higherIsBetter: false, text: money)
                compareRow("Net cash flow / mo", now.netCashFlow, next.netCashFlow, higherIsBetter: true, text: money)
                Divider()
                compareRow("Cash on hand", p[.cashOnHand], next.p[.cashOnHand], higherIsBetter: true, text: money)
                compareRow("Cash cushion", now.cashCoverageMonths, next.cashCoverageMonths, higherIsBetter: true) {
                    String(format: "%.1f mo", $0)
                }
                compareRow("Runway", now.runwayMonths, next.runwayMonths, higherIsBetter: true, missing: "Not losing") {
                    String(format: "%.1f mo", $0)
                }
                compareRow("DSCR", now.dscr, next.dscr, higherIsBetter: true, missing: "No debt") {
                    String(format: "%.2fx", $0)
                }
                if scenario.cashShortfall(for: p) > 0 {
                    Label("The one-time expense is \(money(scenario.cashShortfall(for: p))) more than your cash on hand.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
    }

    private func compareRow(_ label: String, _ before: Double?, _ after: Double?, higherIsBetter: Bool,
                            missing: String = "—", text: (Double) -> String) -> some View {
        var color = Color.primary
        if let b = before, let a = after, abs(a - b) > 0.005 {
            color = (a > b) == higherIsBetter ? confirmGreen : .red
        }
        return HStack {
            Text(label).font(.system(size: 15))
            Spacer()
            Text(before.map(text) ?? missing)
                .frame(width: 92, alignment: .trailing)
            Text(after.map(text) ?? missing)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(width: 92, alignment: .trailing)
        }
        .font(.system(size: 15))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .combine)
    }

    private var drivers: some View {
        let impacts = scenario.driverImpacts(on: p)
        let monthly = impacts.filter { abs($0.monthlyCashFlow) >= 0.5 }
        let cashHit = impacts.first { $0.driver == .oneTimeExpense }?.cash ?? 0
        return AccountSection(title: "What moves the needle") {
            VStack(alignment: .leading, spacing: 12) {
                if scenario.isBaseline {
                    Text("Move a slider above to see which change hits your cash flow hardest.")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                } else {
                    MoneyBars(title: "Change in monthly net cash flow, each on its own",
                              rows: monthly.map { ($0.driver.rawValue, $0.monthlyCashFlow, $0.monthlyCashFlow >= 0 ? confirmGreen : .red) })
                    if let top = monthly.first {
                        Text("Biggest factor: \(top.driver.rawValue.lowercased()), \(signedMoney(top.monthlyCashFlow)) a month.")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text("All changes together: \(signedMoney(scenario.netCashFlowChange(on: p))) a month.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    if cashHit != 0 {
                        Text("The one-time expense lowers cash by \(money(-cashHit)) once. It doesn't change monthly cash flow.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func signedMoney(_ value: Double) -> String {
        (value > 0 ? "+" : "") + money(value)
    }

    private var thresholds: some View {
        AccountSection(title: "How much room you have") {
            VStack(alignment: .leading, spacing: 16) {
                thresholdRow("Material costs could rise", value: materialThreshold)
                thresholdRow("Revenue could drop", value: revenueThreshold)
                Divider()
                reserve
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var materialThreshold: String {
        guard let pct = now.materialCostBreakEvenPercent else { return "No cost of goods entered" }
        if now.netCashFlow <= 0 { return "Already losing money each month" }
        return "\(Int(pct.rounded(.down)))% before cash flow hits $0"
    }

    private var revenueThreshold: String {
        guard let pct = now.revenueDeclineBreakEvenPercent else { return "Costs of goods use up all revenue" }
        if now.netCashFlow <= 0 { return "Already losing money each month" }
        if pct >= 100 { return "All of it. Other income covers your costs" }
        return "\(Int(pct.rounded(.down)))% before cash flow hits $0"
    }

    private func thresholdRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 14)).foregroundColor(.gray)
            Text(value).font(.system(size: 17, weight: .semibold))
        }
        .accessibilityElement(children: .combine)
    }

    private var reserve: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cash reserve target").font(.system(size: 16, weight: .medium))
            HStack(spacing: 4) {
                Text("$").foregroundColor(.gray)
                TextField("e.g. 20000", text: $reserveText).keyboardType(.numberPad)
            }
            .font(.system(size: 18))
            .padding(12)
            .background(pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            if let target = reserveTarget {
                reserveLine("Today", months: now.monthsUntilCash(below: target))
                if !scenario.isBaseline {
                    reserveLine("With your changes", months: next.monthsUntilCash(below: target))
                }
                if now.reserveHeadroom(above: target) > 0 {
                    Text("A one-time expense over \(money(now.reserveHeadroom(above: target))) would put you below it right away.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Enter the least cash you want to keep in the bank to see how long you stay above it.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
    }

    private func reserveLine(_ label: String, months: Double?) -> some View {
        let text: String
        if let m = months {
            text = m == 0 ? "Already below the target" : String(format: "Drops below in about %.1f months", m)
        } else {
            text = "Stays above it. Cash isn't shrinking"
        }
        return HStack(alignment: .firstTextBaseline) {
            Text(label).font(.system(size: 14)).foregroundColor(.gray)
            Spacer()
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(months == nil ? confirmGreen : (months ?? 0) < 3 ? .red : .orange)
                .multilineTextAlignment(.trailing)
        }
    }
}
