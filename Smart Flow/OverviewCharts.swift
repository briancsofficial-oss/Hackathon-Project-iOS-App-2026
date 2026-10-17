import SwiftUI

struct CashRunwayCard: View {
    let profile: BusinessProfile
    private var m: BusinessMetrics { BusinessMetrics(p: profile) }
    private let scaleMonths = 6.0

    init(profile: BusinessProfile) { self.profile = profile }

    var body: some View {
        AccountSection(title: "Cash runway") {
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
                    if let runway = m.runwayMonths {
                        Label(String(format: "Losing %@ a month, so the cash runs out in about %.1f months.", money(-m.netCashFlow), runway),
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                } else {
                    Text("Enter your cash on hand and monthly costs to see how long your cash would last.")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
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
