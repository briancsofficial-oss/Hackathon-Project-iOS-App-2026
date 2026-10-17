//
//  CashSplitChart.swift
//  Safety First
//
// The pie chart at the top of the Overview tab: this month's income split into expenses
// and the cash left over, with the left-over amount in the middle so it's readable at a glance.
//   CashSlice      = one slice (cost of goods, payroll, operating costs, debt payments, cash left over)
//   CashSplitCard  = the whole card: donut, legend, income / expenses / left over
//   CashDonut      = the ring itself
// The numbers come from BusinessMetrics (BusinessProfile.swift), the same math as the Results tab.

import SwiftUI

struct CashSlice: Identifiable {
    enum Kind: String, CaseIterable {
        case cogs = "Cost of goods"
        case payroll = "Payroll & owner pay"
        case operating = "Operating costs"
        case debt = "Debt payments"
        case leftOver = "Cash left over"
    }
    let kind: Kind
    let amount: Double
    var id: Kind { kind }

    // Each kind keeps the same color no matter which slices are showing.
    // These light/dark pairs were checked for color-blind separation. Several are light on a white
    // background, so every slice also has a labeled legend row with its amount (color is never the only cue).
    var color: Color {
        switch kind {
        case .cogs:      return dynamicColor(light: 0x2A78D6, dark: 0x3987E5)   // blue
        case .payroll:   return dynamicColor(light: 0xEB6834, dark: 0xD95926)   // orange
        case .operating: return dynamicColor(light: 0x1BAF7A, dark: 0x199E70)   // aqua
        case .debt:      return dynamicColor(light: 0xEDA100, dark: 0xC98500)   // yellow
        case .leftOver:  return dynamicColor(light: 0xE87BA4, dark: 0xD55181)   // magenta
        }
    }
}

// A color from hex values, with separate light and Dark Mode versions. Also used by OverviewCharts.swift.
func dynamicColor(light: UInt32, dark: UInt32) -> Color {
    func ui(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
    return Color(UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
}

struct CashSplitCard: View {
    let profile: BusinessProfile
    // Called by the "Start the AI interview" button when there's nothing to chart yet.
    let onStart: () -> Void
    // The slice picked in the legend (nil = none). Tapping highlights it and shows it in the middle.
    @State private var focused: CashSlice.Kind?

    // Written out because the private state above would otherwise hide the automatic initializer from other files.
    init(profile: BusinessProfile, onStart: @escaping () -> Void) {
        self.profile = profile
        self.onStart = onStart
    }

    private var m: BusinessMetrics { BusinessMetrics(p: profile) }
    private var income: Double { m.monthlyRevenue + profile[.otherIncome] }
    private var expenses: Double { m.monthlyCOGS + m.payrollCost + m.operatingCost + m.debtService }
    private var leftOver: Double { income - expenses }   // same as BusinessMetrics.netCashFlow

    // With cash left over, the full circle = income. When spending is bigger than income,
    // the full circle = expenses, and there's no left-over slice.
    private var slices: [CashSlice] {
        [
            CashSlice(kind: .cogs, amount: m.monthlyCOGS),
            CashSlice(kind: .payroll, amount: m.payrollCost),
            CashSlice(kind: .operating, amount: m.operatingCost),
            CashSlice(kind: .debt, amount: m.debtService),
            CashSlice(kind: .leftOver, amount: max(leftOver, 0)),
        ].filter { $0.amount > 0 }
    }
    private var pieTotal: Double { max(income, expenses) }

    var body: some View {
        AccountSection(title: "Monthly cash flow") {
            if income > 0 {
                chartContent.padding(20)
            } else {
                emptyContent.padding(20)
            }
        }
    }

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    CashDonut(slices: slices, total: pieTotal, focused: focused)
                    centerLabel
                }
                .frame(width: 150, height: 150)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(slices) { slice in legendRow(slice) }
                }
            }

            Divider()

            HStack {
                summaryStat("Income", income)
                Spacer()
                summaryStat("Expenses", expenses)
                Spacer()
                summaryStat(leftOver >= 0 ? "Left over" : "Short by", abs(leftOver))
            }

            if leftOver < 0 {
                Label("Expenses are \(Int((expenses / income * 100).rounded()))% of income. The chart shows where the spending goes.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            if profile.completedPhases < BusinessPhase.allCases.count {
                Text("Unanswered costs count as $0, so finish every phase for the full picture.")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
    }

    // Middle of the donut: the cash left over, or the slice picked in the legend.
    private var centerLabel: some View {
        VStack(spacing: 2) {
            if let kind = focused, let slice = slices.first(where: { $0.kind == kind }) {
                Text(slice.kind.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text(compactMoney(slice.amount))
                    .font(.system(size: 22, weight: .bold))
                Text(percent(slice.amount))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else if leftOver >= 0 {
                Text("Left over")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(compactMoney(leftOver))
                    .font(.system(size: 24, weight: .bold))
                Text("per month")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                Label("Short", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
                Text("-" + compactMoney(-leftOver))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.red)
                Text("per month")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .minimumScaleFactor(0.7)
        .lineLimit(2)
        .frame(width: 92)
    }

    private func legendRow(_ slice: CashSlice) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                focused = focused == slice.kind ? nil : slice.kind
            }
        } label: {
            HStack(alignment: .top, spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(slice.color)
                    .frame(width: 12, height: 12)
                    .padding(.top, 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(slice.kind.rawValue)
                        .font(.system(size: 14, weight: slice.kind == .leftOver ? .semibold : .regular))
                        .foregroundColor(.primary)
                    Text("\(money(slice.amount)) · \(percent(slice.amount))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .opacity(focused == nil || focused == slice.kind ? 1 : 0.45)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(slice.kind.rawValue), \(money(slice.amount)), \(percent(slice.amount))")
    }

    private func summaryStat(_ label: String, _ amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 13)).foregroundColor(.gray)
            Text(money(amount)).font(.system(size: 17, weight: .semibold))
        }
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 14)
                    .frame(width: 56, height: 56)
                Text("Add your revenue and costs to see how much cash the business keeps each month.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
            Button("Start the AI interview", action: onStart)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(brandColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Share of the circle, e.g. "32%".
    private func percent(_ amount: Double) -> String {
        guard pieTotal > 0 else { return "0%" }
        return "\(Int((amount / pieTotal * 100).rounded()))%"
    }

    // What VoiceOver reads for the chart.
    private var accessibilitySummary: String {
        let parts = slices.map { "\($0.kind.rawValue) \(money($0.amount))" }.joined(separator: ", ")
        let lead = leftOver >= 0 ? "Cash left over \(money(leftOver)) a month" : "Short by \(money(-leftOver)) a month"
        return "\(lead). Monthly income \(money(income)). \(parts)."
    }

    // Short amounts for the middle of the donut: $850, $4.2K, $38K, $1.2M.
    private func compactMoney(_ value: Double) -> String {
        let v = abs(value)
        if v >= 1_000_000 { return "$" + String(format: "%.1fM", v / 1_000_000) }
        if v >= 10_000 { return "$" + String(format: "%.0fK", v / 1_000) }
        if v >= 1_000 { return "$" + String(format: "%.1fK", v / 1_000) }
        return money(v)
    }
}

// The ring, drawn with trimmed circles so it works on iOS 15 (Swift Charts' pie chart needs iOS 17).
struct CashDonut: View {
    let slices: [CashSlice]
    let total: Double
    let focused: CashSlice.Kind?
    private let lineWidth: CGFloat = 24

    init(slices: [CashSlice], total: Double, focused: CashSlice.Kind?) {
        self.slices = slices
        self.total = total
        self.focused = focused
    }

    // Start and end of each slice as fractions of the full circle (0 to 1).
    private struct Segment: Identifiable {
        let slice: CashSlice
        let start: Double
        let end: Double
        var id: CashSlice.Kind { slice.kind }
    }

    private var segments: [Segment] {
        guard total > 0 else { return [] }
        var start = 0.0
        var result: [Segment] = []
        for slice in slices {
            let end = start + slice.amount / total
            result.append(Segment(slice: slice, start: start, end: end))
            start = end
        }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            // The ring sits inside the frame, leaving room for a highlighted slice to grow.
            let inset = lineWidth / 2 + 4
            let circumference = Double.pi * Double(size - inset * 2)
            // A 2-point gap between slices so neighbors stay distinct (only when there's more than one).
            let gap = slices.count > 1 && circumference > 0 ? 2 / circumference : 0

            ZStack {
                Circle().stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)
                ForEach(segments) { seg in
                    Circle()
                        .trim(from: seg.start + gap / 2, to: max(seg.start + gap / 2, seg.end - gap / 2))
                        .stroke(seg.slice.color,
                                style: StrokeStyle(lineWidth: focused == seg.slice.kind ? lineWidth + 6 : lineWidth))
                        .opacity(focused == nil || focused == seg.slice.kind ? 1 : 0.35)
                }
            }
            .rotationEffect(.degrees(-90))   // first slice starts at 12 o'clock
            .padding(inset)
            .frame(width: size, height: size)
        }
    }
}
