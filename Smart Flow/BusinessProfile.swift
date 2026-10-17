//
//  BusinessProfile.swift
//  Smart Flow
//
// BUSINESS CHECKUP: the data side. The whole app is built around this (see the tabs in ContentView.swift).
// It asks about revenue, payroll, operating costs, business debt, cash and goals,
// then works out lender-style health numbers.
//
//   BusinessPhase     = the 6 phases of questions, in order
//   BusinessField     = every single question: its wording, hint, phase and what kind of answer it takes.
//                       The question form, the AI interviewer and the document import are ALL built from this
//                       one list, so adding a question here adds it everywhere.
//   BusinessProfile   = the answers (saved on the phone)
//   BusinessStore     = shares the answers between screens and saves them
//   BusinessMetrics   = the math: DSCR, cash runway, payroll %, current ratio, etc.

import SwiftUI

// MARK: - Phases

enum BusinessPhase: Int, CaseIterable, Identifiable, Codable {
    case revenue, payroll, operating, debt, liquidity, goals
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .revenue:   return "Revenue & Income"
        case .payroll:   return "Payroll & People"
        case .operating: return "Operating Costs"
        case .debt:      return "Business Debt"
        case .liquidity: return "Cash & Working Capital"
        case .goals:     return "Goals & Horizon"
        }
    }

    // One line shown under the phase title, explaining why we ask.
    var purpose: String {
        switch self {
        case .revenue:   return "What the business brings in, and how steady it is."
        case .payroll:   return "Usually the biggest monthly cost. Includes what you pay yourself."
        case .operating: return "The fixed bills that are due whether sales are good or slow."
        case .debt:      return "Monthly payments lenders count when they look at your debt coverage."
        case .liquidity: return "How much cushion the business has, and how fast money moves in and out."
        case .goals:     return "Where you want the business to go, so the advice fits."
        }
    }

    var icon: String {
        switch self {
        case .revenue:   return "chart.line.uptrend.xyaxis"
        case .payroll:   return "person.3.fill"
        case .operating: return "building.2.fill"
        case .debt:      return "creditcard.fill"
        case .liquidity: return "banknote.fill"
        case .goals:     return "target"
        }
    }
}

// MARK: - Questions

// What kind of answer a question takes. This decides the input box AND the type the AI is told to send.
enum FieldKind {
    case money(suffix: String)     // dollars, e.g. suffix "/ mo"
    case percent                   // 0 to 100
    case count(unit: String)       // whole number, e.g. "people"
    case text
    case choice([String])          // pick one from a list
    case yesNo

    var isNumber: Bool {
        switch self {
        case .money, .percent, .count: return true
        default: return false
        }
    }
}

// Every question in the checkup. rawValue = the key used for saving and for the AI tools (snake_case on purpose).
enum BusinessField: String, CaseIterable, Identifiable {
    // Phase 1: Revenue & Income
    case businessName = "business_name"
    case industry = "industry"
    case entityType = "entity_type"
    case yearsInBusiness = "years_in_business"
    case annualRevenue = "annual_revenue"
    case cogsPercent = "cogs_percent"
    case recurringPercent = "recurring_revenue_percent"
    case isSeasonal = "is_seasonal"
    case slowMonthRevenue = "slowest_month_revenue"
    case otherIncome = "other_monthly_income"
    // Phase 2: Payroll & People
    case w2Employees = "w2_employees"
    case contractors = "contractors"
    case payrollFrequency = "payroll_frequency"
    case grossPayroll = "monthly_gross_payroll"
    case employerCosts = "monthly_employer_taxes_benefits"
    case contractorPay = "monthly_contractor_pay"
    case ownerPay = "monthly_owner_pay"
    // Phase 3: Operating Costs
    case rent = "monthly_rent"
    case insurance = "monthly_insurance"
    case softwareMarketing = "monthly_software_marketing"
    case otherOperating = "monthly_other_operating"
    // Phase 4: Business Debt
    case termLoanPayment = "monthly_term_loan_payment"
    case termLoanBalance = "term_loan_balance"
    case locBalance = "line_of_credit_balance"
    case locLimit = "line_of_credit_limit"
    case locPayment = "monthly_line_of_credit_payment"
    case equipmentPayment = "monthly_equipment_payment"
    case cardBalance = "business_card_balance"
    case cardMinimum = "monthly_business_card_minimum"
    case mcaPayment = "monthly_mca_payment"
    case owesBackTaxes = "owes_back_taxes"
    case backTaxesOwed = "back_taxes_owed"
    // Phase 5: Cash & Working Capital
    case cashOnHand = "cash_on_hand"
    case accountsReceivable = "accounts_receivable"
    case daysToGetPaid = "days_to_get_paid"
    case accountsPayable = "accounts_payable"
    case inventoryValue = "inventory_value"
    case taxReserve = "tax_reserve"
    // Phase 6: Goals & Horizon
    case primaryFocus = "primary_focus"
    case timeline = "goal_timeline"

    var id: String { rawValue }

    var phase: BusinessPhase {
        switch self {
        case .businessName, .industry, .entityType, .yearsInBusiness, .annualRevenue, .cogsPercent,
             .recurringPercent, .isSeasonal, .slowMonthRevenue, .otherIncome:
            return .revenue
        case .w2Employees, .contractors, .payrollFrequency, .grossPayroll, .employerCosts, .contractorPay, .ownerPay:
            return .payroll
        case .rent, .insurance, .softwareMarketing, .otherOperating:
            return .operating
        case .termLoanPayment, .termLoanBalance, .locBalance, .locLimit, .locPayment, .equipmentPayment,
             .cardBalance, .cardMinimum, .mcaPayment, .owesBackTaxes, .backTaxesOwed:
            return .debt
        case .cashOnHand, .accountsReceivable, .daysToGetPaid, .accountsPayable, .inventoryValue, .taxReserve:
            return .liquidity
        case .primaryFocus, .timeline:
            return .goals
        }
    }

    var question: String {
        switch self {
        case .businessName:      return "What is the name of your business?"
        case .industry:          return "What industry are you in?"
        case .entityType:        return "How is the business set up legally?"
        case .yearsInBusiness:   return "How many years has the business been operating?"
        case .annualRevenue:     return "What was your gross revenue over the last 12 months?"
        case .cogsPercent:       return "Roughly what percent of revenue goes to cost of goods sold?"
        case .recurringPercent:  return "What percent of revenue is recurring?"
        case .isSeasonal:        return "Is your revenue seasonal?"
        case .slowMonthRevenue:  return "What does a slow month bring in?"
        case .otherIncome:       return "Any other regular business income each month?"
        case .w2Employees:       return "How many W-2 employees do you have?"
        case .contractors:       return "How many 1099 contractors do you use regularly?"
        case .payrollFrequency:  return "How often do you run payroll?"
        case .grossPayroll:      return "What is your total monthly gross payroll?"
        case .employerCosts:     return "What do employer payroll taxes and benefits cost each month?"
        case .contractorPay:     return "How much do you pay contractors each month?"
        case .ownerPay:          return "How much do you pay yourself each month?"
        case .rent:              return "What is your monthly rent or lease?"
        case .insurance:         return "What do you pay each month for business insurance?"
        case .softwareMarketing: return "What do software, subscriptions and marketing cost each month?"
        case .otherOperating:    return "Any other fixed monthly operating costs?"
        case .termLoanPayment:   return "What are your monthly payments on term loans?"
        case .termLoanBalance:   return "What is the remaining balance on those loans?"
        case .locBalance:        return "How much is drawn on your line of credit?"
        case .locLimit:          return "What is the credit limit on that line?"
        case .locPayment:        return "What is the monthly payment on the line of credit?"
        case .equipmentPayment:  return "What are your monthly equipment loan or lease payments?"
        case .cardBalance:       return "What is the total balance on business credit cards?"
        case .cardMinimum:       return "What is the total minimum monthly payment on those cards?"
        case .mcaPayment:        return "Do you make merchant cash advance or revenue-based financing payments?"
        case .owesBackTaxes:     return "Do you owe any past-due income or payroll taxes?"
        case .backTaxesOwed:     return "How much is owed?"
        case .cashOnHand:        return "How much cash does the business have in the bank right now?"
        case .accountsReceivable:return "How much do customers currently owe you?"
        case .daysToGetPaid:     return "On average, how many days does it take to get paid?"
        case .accountsPayable:   return "How much do you currently owe suppliers and vendors?"
        case .inventoryValue:    return "What is your inventory worth at cost?"
        case .taxReserve:        return "How much have you set aside for upcoming taxes?"
        case .primaryFocus:      return "What is the business's primary financial focus right now?"
        case .timeline:          return "What is your target timeline for this goal?"
        }
    }

    var hint: String {
        switch self {
        case .businessName:      return "Used only to personalize your results."
        case .industry:          return "e.g. restaurant, construction, consulting, e-commerce"
        case .entityType:        return "Affects how owner pay and taxes are treated."
        case .yearsInBusiness:   return "Most lenders want to see at least 2 years."
        case .annualRevenue:     return "Total sales before any expenses."
        case .cogsPercent:       return "Materials, inventory and direct labor to deliver what you sell. Enter 0 for most service businesses."
        case .recurringPercent:  return "Subscriptions, retainers or contracts that repeat. Recurring revenue is steadier."
        case .isSeasonal:        return "Some months much busier than others."
        case .slowMonthRevenue:  return "Used to stress-test your cash in the slow season."
        case .otherIncome:       return "Interest, rental income, grants, licensing."
        case .w2Employees:       return "Not counting yourself."
        case .contractors:       return "Freelancers paid on a 1099."
        case .payrollFrequency:  return "Helps plan the cash you need on payday."
        case .grossPayroll:      return "Employee wages before withholding."
        case .employerCosts:     return "Employer FICA, unemployment tax, health insurance, retirement match."
        case .contractorPay:     return "Average per month."
        case .ownerPay:          return "Salary or owner's draw. Enter 0 if you don't take one."
        case .rent:              return "Office, shop, warehouse or storefront."
        case .insurance:         return "General liability, property, workers' comp, etc."
        case .softwareMarketing: return "Software, phone, internet, ads."
        case .otherOperating:    return "Utilities, professional fees, vehicle costs, anything else that repeats."
        case .termLoanPayment:   return "SBA and bank loans. Enter 0 if none."
        case .termLoanBalance:   return "Total still owed."
        case .locBalance:        return "Enter 0 if you don't have one or haven't drawn on it."
        case .locLimit:          return "Enter 0 if you don't have a line of credit."
        case .locPayment:        return "Minimum required payment."
        case .equipmentPayment:  return "Vehicles, machinery, computers."
        case .cardBalance:       return "Across all business cards."
        case .cardMinimum:       return "Counted even if you pay in full."
        case .mcaPayment:        return "Monthly total of daily or weekly payments. Enter 0 if none."
        case .owesBackTaxes:     return "Tax debt is a priority. It can lead to liens and penalties."
        case .backTaxesOwed:     return "Include penalties and interest if you know them."
        case .cashOnHand:        return "Checking, savings and money market accounts."
        case .accountsReceivable:return "Unpaid invoices."
        case .daysToGetPaid:     return "From sending an invoice to having the money."
        case .accountsPayable:   return "Unpaid bills."
        case .inventoryValue:    return "Enter 0 if you don't carry inventory."
        case .taxReserve:        return "Money held for estimated or sales taxes."
        case .primaryFocus:      return "Pick the one that matters most right now."
        case .timeline:          return "When you want to reach it."
        }
    }

    var kind: FieldKind {
        switch self {
        case .businessName, .industry:
            return .text
        case .entityType:
            return .choice(["Sole proprietorship", "LLC", "S corporation", "C corporation", "Partnership", "Nonprofit"])
        case .yearsInBusiness:
            return .count(unit: "years")
        case .annualRevenue:
            return .money(suffix: "/ yr")
        case .cogsPercent, .recurringPercent:
            return .percent
        case .isSeasonal, .owesBackTaxes:
            return .yesNo
        case .w2Employees, .contractors:
            return .count(unit: "people")
        case .daysToGetPaid:
            return .count(unit: "days")
        case .payrollFrequency:
            return .choice(["Weekly", "Every two weeks", "Twice a month", "Monthly", "No payroll"])
        case .termLoanBalance, .locBalance, .locLimit, .cardBalance, .backTaxesOwed, .cashOnHand,
             .accountsReceivable, .accountsPayable, .inventoryValue, .taxReserve:
            return .money(suffix: "")
        case .primaryFocus:
            return .choice(BusinessFocus.allCases.map(\.rawValue))
        case .timeline:
            return .choice(["Short-term (under 1 year)", "Medium-term (1–3 years)", "Long-term (3+ years)"])
        default:
            return .money(suffix: "/ mo")
        }
    }

    // Follow-up questions that only apply when the parent answer is "Yes" (or, for the line of credit,
    // when there is a limit). Hidden from the form and not required otherwise.
    var dependsOn: BusinessField? {
        switch self {
        case .slowMonthRevenue: return .isSeasonal
        case .backTaxesOwed:    return .owesBackTaxes
        case .termLoanBalance:  return .termLoanPayment
        case .locBalance, .locPayment: return .locLimit
        case .cardMinimum:      return .cardBalance
        default: return nil
        }
    }

    // Answers that aren't needed to call a phase finished.
    var isOptional: Bool {
        switch self {
        case .businessName, .industry, .recurringPercent, .inventoryValue, .taxReserve: return true
        default: return false
        }
    }

    static func fields(in phase: BusinessPhase) -> [BusinessField] {
        allCases.filter { $0.phase == phase }
    }
}

enum BusinessFocus: String, CaseIterable {
    case growRevenue = "Grow revenue"
    case reduceDebt = "Pay down business debt"
    case cashReserve = "Build a cash reserve"
    case hire = "Hire or expand"
    case financing = "Get ready for a loan or financing"
    case exit = "Prepare to sell the business"
}

// MARK: - Answers

// All answers. Numbers and text are kept in two dictionaries keyed by BusinessField.rawValue,
// so a missing key means "not answered yet" (which is different from answering 0).
struct BusinessProfile: Codable, Equatable {
    var numbers: [String: Double] = [:]
    var texts: [String: String] = [:]

    // Reads a number; unanswered counts as 0 in the math.
    subscript(_ field: BusinessField) -> Double {
        numbers[field.rawValue] ?? 0
    }

    func text(_ field: BusinessField) -> String? { texts[field.rawValue] }

    func isAnswered(_ field: BusinessField) -> Bool {
        field.kind.isNumber ? numbers[field.rawValue] != nil : !(texts[field.rawValue] ?? "").isEmpty
    }

    // Whether a question should be asked right now (follow-ups only when their parent says so).
    func applies(_ field: BusinessField) -> Bool {
        guard let parent = field.dependsOn else { return true }
        if parent.kind.isNumber { return self[parent] > 0 }
        return text(parent) == "Yes"
    }

    // Required questions that still need an answer.
    func missing(in phase: BusinessPhase) -> [BusinessField] {
        BusinessField.fields(in: phase).filter { !$0.isOptional && applies($0) && !isAnswered($0) }
    }

    func isComplete(_ phase: BusinessPhase) -> Bool { missing(in: phase).isEmpty }

    var completedPhases: Int { BusinessPhase.allCases.filter(isComplete).count }
    var isEmpty: Bool { numbers.isEmpty && texts.isEmpty }

    var displayName: String {
        let name = (text(.businessName) ?? "").trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Your business" : name
    }

    // Sets one answer from any source (form, AI interviewer, document import).
    // Returns false if the value doesn't fit the question, so bad AI output is ignored instead of saved.
    @discardableResult
    mutating func set(_ field: BusinessField, from value: Any?) -> Bool {
        guard let value = value, !(value is NSNull) else { return false }
        switch field.kind {
        case .money, .percent, .count:
            let number: Double?
            if let d = value as? Double { number = d }
            else if let i = value as? Int { number = Double(i) }
            else if let s = value as? String { number = Double(s.filter { "0123456789.-".contains($0) }) }
            else { number = nil }
            guard var n = number, n.isFinite, n >= 0 else { return false }
            if case .percent = field.kind { n = min(n, 100) }
            numbers[field.rawValue] = n
        case .text:
            guard let s = value as? String, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
            texts[field.rawValue] = s
        case .choice(let options):
            // Accept the option even if the AI changed capitalization.
            guard let s = value as? String,
                  let match = options.first(where: { $0.lowercased() == s.lowercased() }) else { return false }
            texts[field.rawValue] = match
        case .yesNo:
            if let b = value as? Bool { texts[field.rawValue] = b ? "Yes" : "No" }
            else if let s = value as? String, ["yes", "no"].contains(s.lowercased()) {
                texts[field.rawValue] = s.capitalized
            } else { return false }
        }
        return true
    }

    // Plain-text list of every answer, handed to the AI models as background.
    var summaryForAI: String {
        BusinessPhase.allCases.map { phase in
            let lines = BusinessField.fields(in: phase).compactMap { field -> String? in
                guard isAnswered(field) else { return nil }
                return "- \(field.rawValue): \(formatted(field))"
            }
            return "\(phase.title):\n" + (lines.isEmpty ? "- (nothing yet)" : lines.joined(separator: "\n"))
        }.joined(separator: "\n")
    }

    // An answer written out for people, e.g. "$4,500 / mo", "35%", "12 people".
    func formatted(_ field: BusinessField) -> String {
        guard isAnswered(field) else { return "—" }
        switch field.kind {
        case .money(let suffix): return money(self[field]) + (suffix.isEmpty ? "" : " \(suffix)")
        case .percent:           return "\(Int(self[field].rounded()))%"
        case .count(let unit):   return "\(Int(self[field].rounded())) \(unit)"
        default:                 return text(field) ?? "—"
        }
    }
}

// MARK: - Store

// Shared copy of the answers, saved to the phone (UserDefaults) as JSON every time they change.
// (UserDefaults + JSON, the same way the old personal-finance stores saved.)
final class BusinessStore: ObservableObject {
    static let shared = BusinessStore()
    private let key = "business.profile"

    @Published var profile: BusinessProfile {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(BusinessProfile.self, from: data) {
            profile = saved
        } else {
            profile = BusinessProfile()
        }
    }

    func reset() { profile = BusinessProfile() }

    private func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - The math

// How healthy one number is. Colors come from the app palette.
enum BusinessRating {
    case healthy, watch, concern, unknown

    var label: String {
        switch self {
        case .healthy: return "Healthy"
        case .watch:   return "Watch"
        case .concern: return "At risk"
        case .unknown: return "—"
        }
    }

    var color: Color {
        switch self {
        case .healthy: return confirmGreen
        case .watch:   return .orange
        case .concern: return .red
        case .unknown: return .gray
        }
    }
}

struct BusinessMetrics {
    let p: BusinessProfile

    // Income, per month
    var monthlyRevenue: Double { p[.annualRevenue] / 12 }
    var monthlyCOGS: Double { monthlyRevenue * p[.cogsPercent] / 100 }
    var grossProfit: Double { monthlyRevenue - monthlyCOGS + p[.otherIncome] }
    var grossMargin: Double? { monthlyRevenue > 0 ? (monthlyRevenue - monthlyCOGS) / monthlyRevenue : nil }

    // Costs, per month
    var payrollCost: Double { p[.grossPayroll] + p[.employerCosts] + p[.contractorPay] + p[.ownerPay] }
    var operatingCost: Double { p[.rent] + p[.insurance] + p[.softwareMarketing] + p[.otherOperating] }
    var debtService: Double {
        p[.termLoanPayment] + p[.locPayment] + p[.equipmentPayment] + p[.cardMinimum] + p[.mcaPayment]
    }

    // Net operating income: what's left after running the business, before debt payments.
    var netOperatingIncome: Double { grossProfit - payrollCost - operatingCost }
    // What's left after debt payments too. Negative = the business is burning cash.
    var netCashFlow: Double { netOperatingIncome - debtService }

    // Debt service coverage ratio (DSCR). Lenders, including SBA lenders, usually want 1.25 or more:
    // $1.25 of operating income for every $1 of debt payments.
    var dscr: Double? { debtService > 0 ? netOperatingIncome / debtService : nil }
    var dscrRating: BusinessRating {
        guard let d = dscr else { return debtService == 0 && monthlyRevenue > 0 ? .healthy : .unknown }
        switch d {
        case 1.25...: return .healthy
        case 1.0..<1.25: return .watch
        default: return .concern
        }
    }

    var payrollShare: Double? { monthlyRevenue > 0 ? payrollCost / monthlyRevenue : nil }
    // Rough guide only: service businesses run higher than retail or manufacturing.
    var payrollRating: BusinessRating {
        guard let s = payrollShare else { return .unknown }
        switch s {
        case ..<0.35: return .healthy
        case ..<0.50: return .watch
        default: return .concern
        }
    }

    // How many months of fixed costs (payroll + operating + debt) the cash in the bank covers.
    var fixedMonthlyCosts: Double { payrollCost + operatingCost + debtService }
    var cashCoverageMonths: Double? { fixedMonthlyCosts > 0 ? p[.cashOnHand] / fixedMonthlyCosts : nil }
    var cashRating: BusinessRating {
        guard let m = cashCoverageMonths else { return .unknown }
        switch m {
        case 3...: return .healthy
        case 1..<3: return .watch
        default: return .concern
        }
    }

    // If the business is losing money each month: how long until the cash runs out.
    var runwayMonths: Double? { netCashFlow < 0 ? p[.cashOnHand] / -netCashFlow : nil }

    // Current ratio: short-term assets ÷ short-term debts. Above 1.5 is comfortable; below 1 is tight.
    var currentAssets: Double { p[.cashOnHand] + p[.accountsReceivable] + p[.inventoryValue] }
    var currentLiabilities: Double { p[.accountsPayable] + p[.locBalance] + p[.cardBalance] + p[.backTaxesOwed] }
    var currentRatio: Double? { currentLiabilities > 0 ? currentAssets / currentLiabilities : nil }
    var currentRatioRating: BusinessRating {
        guard let r = currentRatio else { return currentAssets > 0 ? .healthy : .unknown }
        switch r {
        case 1.5...: return .healthy
        case 1.0..<1.5: return .watch
        default: return .concern
        }
    }

    var totalDebt: Double { p[.termLoanBalance] + p[.locBalance] + p[.cardBalance] + p[.backTaxesOwed] }
    var lineUtilization: Double? { p[.locLimit] > 0 ? p[.locBalance] / p[.locLimit] : nil }

    // Cash needed on one payday, from the monthly payroll and how often it runs.
    var cashPerPayroll: Double? {
        let monthly = p[.grossPayroll] + p[.employerCosts]
        guard monthly > 0 else { return nil }
        switch p.text(.payrollFrequency) {
        case "Weekly":          return monthly * 12 / 52
        case "Every two weeks": return monthly * 12 / 26
        case "Twice a month":   return monthly / 2
        case "Monthly":         return monthly
        default:                return nil
        }
    }

    // Numbers the AI writes its action plan from (so it doesn't do its own, possibly wrong, math).
    var summaryForAI: String {
        func r(_ x: Double?) -> String { x.map { String(format: "%.2f", $0) } ?? "n/a" }
        return """
        Monthly revenue: \(money(monthlyRevenue)); gross profit: \(money(grossProfit)); gross margin: \(grossMargin.map { "\(Int(($0 * 100).rounded()))%" } ?? "n/a")
        Monthly payroll cost (incl. owner pay): \(money(payrollCost)) = \(payrollShare.map { "\(Int(($0 * 100).rounded()))%" } ?? "n/a") of revenue [\(payrollRating.label)]
        Monthly operating costs: \(money(operatingCost)); monthly debt payments: \(money(debtService))
        Net operating income: \(money(netOperatingIncome)) / mo; net cash flow after debt: \(money(netCashFlow)) / mo
        DSCR: \(r(dscr)) [\(dscrRating.label)]; cash covers \(r(cashCoverageMonths)) months of fixed costs [\(cashRating.label)]
        Runway if losing money: \(runwayMonths.map { String(format: "%.1f months", $0) } ?? "not losing money")
        Current ratio: \(r(currentRatio)) [\(currentRatioRating.label)]; total debt balances: \(money(totalDebt)); line of credit used: \(lineUtilization.map { "\(Int(($0 * 100).rounded()))%" } ?? "n/a")
        """
    }
}
