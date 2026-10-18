import SwiftUI

struct CashRunwayCard: View {
    let profile: BusinessProfile
    let onAddCosts: () -> Void
    @State private var editingCash = false
    private var m: BusinessMetrics { BusinessMetrics(p: profile) }
    private let scaleMonths = 6.0

    init(profile: BusinessProfile, onAddCosts: @escaping () -> Void) {
        self.profile = profile
        self.onAddCosts = onAddCosts
    }

    var body: some View {
        AccountSection(title: "Cash runway") {
            VStack(alignment: .leading, spacing: 14) {
                summary
                    .accessibilityElement(children: .combine)
                actions
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $editingCash) { CashOnHandSheet() }
    }

    private var projection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text("Projected cash balance")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            HStack {
                ForEach([3, 6, 12], id: \.self) { months in
                    let cash = m.projectedCash(afterMonths: months)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("In \(months) mo").font(.system(size: 12)).foregroundColor(.gray)
                        Text(money(cash))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(cash < 0 ? .red : .primary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    if months != 12 { Spacer() }
                }
            }
            Text("If this month's net cash flow of \(money(m.netCashFlow)) repeats.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder private var actions: some View {
        if !profile.isAnswered(.cashOnHand) {
            Button { editingCash = true } label: {
                Label("Add cash on hand", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(brandColor))
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: 18) {
                Button("Update cash on hand") { editingCash = true }
                if m.cashCoverageMonths == nil {
                    Button("Add monthly costs", action: onAddCosts)
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(brandColor)
        }
    }

    private var summary: some View {
            VStack(alignment: .leading, spacing: 12) {
                if let months = m.cashCoverageMonths, profile.isAnswered(.cashOnHand) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(String(format: "%.1f", months))
                            .font(.system(size: 34, weight: .semibold))
                        Text("months of fixed costs covered")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                        Spacer()
                        ratingBadge(m.cashRating)
                    }
                    meter(months: months)
                    Text("\(money(profile[.cashOnHand])) cash ÷ \(money(m.fixedMonthlyCosts)) a month in payroll, operating costs and debt payments.")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    projection
                    if let runway = m.runwayMonths {
                        Label(String(format: "Losing %@ a month, so the cash runs out in about %.1f months.", money(-m.netCashFlow), runway),
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                } else if profile.isAnswered(.cashOnHand) {
                    Text("\(money(profile[.cashOnHand])) cash on hand. Add your payroll and operating costs to see how long it would last.")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                } else {
                    Text("Enter your cash on hand and monthly costs to see how long your cash would last.")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
            }
    }

    private func meter(months: Double) -> some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                let w = geo.size.width
                let fill = CGFloat(min(max(months, 0), scaleMonths) / scaleMonths) * w
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6).fill(m.cashRating.color).frame(width: max(fill, 6))
                    ForEach([3.0, 6.0], id: \.self) { target in
                        Rectangle()
                            .fill(Color.primary.opacity(0.35))
                            .frame(width: 2)
                            .offset(x: CGFloat(target / scaleMonths) * w - 1)
                    }
                }
            }
            .frame(height: 14)
            HStack {
                Text("0").font(.system(size: 11)).foregroundColor(.gray)
                Spacer()
                Text("3 mo target").font(.system(size: 11)).foregroundColor(.gray)
                Spacer()
                Text("6+ mo").font(.system(size: 11)).foregroundColor(.gray)
            }
        }
    }
}

struct CashOnHandSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = BusinessStore.shared

    var body: some View {
        NavigationView {
            ScrollView {
                BusinessQuestionRow(field: .cashOnHand, store: store)
                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBackground))
                    .padding(16)
            }
            .background(pageBackground.ignoresSafeArea())
            .navigationTitle("Cash on hand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

func ratingBadge(_ rating: BusinessRating) -> some View {
    let icon: String
    switch rating {
    case .healthy: icon = "checkmark.circle.fill"
    case .watch:   icon = "exclamationmark.circle.fill"
    case .concern: icon = "exclamationmark.triangle.fill"
    case .unknown: icon = "questionmark.circle"
    }
    return Label(rating.label, systemImage: icon)
        .font(.system(size: 12, weight: .bold))
        .padding(.horizontal, 8).padding(.vertical, 3)
        .foregroundColor(rating.color)
        .background(Capsule().fill(rating.color.opacity(0.15)))
}

struct PlanChartView: View {
    let chart: PlanChart
    let profile: BusinessProfile
    private var m: BusinessMetrics { BusinessMetrics(p: profile) }

    var body: some View {
        switch chart {
        case .cashRunway:
            if let months = m.cashCoverageMonths, profile.isAnswered(.cashOnHand) {
                TargetBar(title: "Cash cushion", valueText: String(format: "%.1f months", months),
                          value: months, scale: 6, targets: [(3, "3 mo"), (6, "6 mo")],
                          color: m.cashRating.color, caption: "Months of fixed costs your cash covers. Aim for 3+.")
            }
        case .debtCoverage:
            if let dscr = m.dscr {
                TargetBar(title: "Debt coverage (DSCR)", valueText: String(format: "%.2fx", dscr),
                          value: dscr, scale: 2.5, targets: [(1.25, "1.25x")],
                          color: m.dscrRating.color, caption: "Lenders look for 1.25x or more.")
            }
        case .payrollShare:
            if let share = m.payrollShare {
                TargetBar(title: "Payroll share of revenue", valueText: "\(Int((share * 100).rounded()))%",
                          value: share, scale: 1, targets: [(0.35, "35%"), (0.5, "50%")],
                          color: m.payrollRating.color, caption: "Under 35% is healthy, over 50% is a concern.")
            }
        case .currentRatio:
            if let ratio = m.currentRatio {
                TargetBar(title: "Current ratio", valueText: String(format: "%.2f", ratio),
                          value: ratio, scale: 3, targets: [(1, "1.0"), (1.5, "1.5")],
                          color: m.currentRatioRating.color, caption: "Short-term assets ÷ short-term debts. 1.5+ is healthy.")
            }
        case .cashFlow:
            MoneyBars(title: "Monthly cash flow", rows: [
                ("Money in", m.monthlyIncome, confirmGreen),
                ("Money out", m.monthlyOutflow, .orange),
                ("Net cash flow", m.netCashFlow, m.netCashFlow >= 0 ? confirmGreen : .red),
            ])
        case .expenseBreakdown:
            MoneyBars(title: "Where the money goes each month", rows: [
                (CashSlice.Kind.cogs.rawValue, m.monthlyCOGS, CashSlice(kind: .cogs, amount: 0).color),
                (CashSlice.Kind.payroll.rawValue, m.payrollCost, CashSlice(kind: .payroll, amount: 0).color),
                (CashSlice.Kind.operating.rawValue, m.operatingCost, CashSlice(kind: .operating, amount: 0).color),
                (CashSlice.Kind.debt.rawValue, m.debtService, CashSlice(kind: .debt, amount: 0).color),
            ].filter { $0.1 > 0 })
        case .debtBalances:
            MoneyBars(title: "What the business owes", rows: [
                ("Term loans", profile[.termLoanBalance], brandColor),
                ("Line of credit", profile[.locBalance], brandColor),
                ("Credit cards", profile[.cardBalance], brandColor),
                ("Past-due taxes", profile[.backTaxesOwed], .red),
            ].filter { $0.1 > 0 })
        case .none:
            EmptyView()
        }
    }
}

struct TargetBar: View {
    let title: String
    let valueText: String
    let value: Double
    let scale: Double
    let targets: [(Double, String)]
    let color: Color
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
                Spacer()
                Text(valueText).font(.system(size: 18, weight: .bold)).foregroundColor(color)
            }
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6).fill(color)
                        .frame(width: max(CGFloat(min(max(value, 0), scale) / scale) * w, 6))
                    ForEach(targets, id: \.0) { target in
                        Rectangle()
                            .fill(Color.primary.opacity(0.4))
                            .frame(width: 2)
                            .offset(x: CGFloat(target.0 / scale) * w - 1)
                    }
                }
            }
            .frame(height: 14)
            GeometryReader { geo in
                ForEach(targets, id: \.0) { target in
                    Text(target.1)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .fixedSize()
                        .position(x: CGFloat(target.0 / scale) * geo.size.width, y: 6)
                }
            }
            .frame(height: 12)
            Text(caption).font(.system(size: 12)).foregroundColor(.gray)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(pageBackground))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(valueText). \(caption)")
    }
}

struct MoneyBars: View {
    let title: String
    let rows: [(String, Double, Color)]

    private var largest: Double { rows.map { abs($0.1) }.max() ?? 0 }

    var body: some View {
        if !rows.isEmpty && largest > 0 {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
                ForEach(rows, id: \.0) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.0).font(.system(size: 13))
                            Spacer()
                            Text(money(row.1)).font(.system(size: 13, weight: .semibold))
                        }
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(row.2)
                                .frame(width: max(CGFloat(abs(row.1) / largest) * geo.size.width, 4))
                        }
                        .frame(height: 10)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(pageBackground))
        }
    }
}
