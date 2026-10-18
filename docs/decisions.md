# Decisions

Newest first. Each entry: date, decision, why.

## 2026-10-17 — What-if simulator built on one scenario engine
**Decision:** `BusinessScenario` (in `BusinessProfile.swift`) holds four changes: material cost %, revenue %, a one-time expense and a monthly debt payment change. It applies them to a copy of `BusinessProfile`, and `BusinessMetrics` runs on that copy unchanged. Material cost % scales `cogsPercent`. Revenue % scales `annualRevenue` only (other income stays put). The one-time expense comes out of cash on hand, floored at $0, and the shortfall is shown separately. A debt change is spread across existing payments in proportion, or becomes a term loan payment if there's no debt yet. Break-even points use closed-form math (`netCashFlow / monthlyCOGS` and `netCashFlow / (revenue − COGS)`) from today's numbers. The driver breakdown applies each change on its own and reports the change in monthly net cash flow. The one-time expense doesn't change monthly cash flow, so it's reported as a cash hit instead of a bar. The screen is a row on the Results tab, not a 6th tab.
**Why:** One engine for the simulator, thresholds and drivers keeps all the math in `BusinessMetrics`, where it can be unit tested. Cash flow is linear in these inputs, so exact formulas beat search loops. Drivers taken one at a time don't add up to the combined total, because revenue and material cost changes interact through COGS. The screen shows the combined total next to them so that isn't hidden.

## 2026-10-17 — Unit test target
**Decision:** Added `Smart FlowTests` (XCTest, hosted by the app, `@testable import Smart_Flow`) to the project and to the shared scheme's Test action. Its deployment target follows the app's (`RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET`).
**Why:** CLAUDE.md asks for a test before any `BusinessMetrics` change. A test bundle with a lower deployment target than the app won't compile against it.

## 2026-10-17 — Cream-and-black redesign; reset lives in Settings
**Decision:** Restyled the app after a reference fintech mockup: cream background, white cards with black titles, black buttons and action bar, a pink highlight card. The Overview got a greeting header and a 3-button action bar. The trash button on the Overview was removed; "Clear all business answers" in Settings is the one place to reset.
**Why:** A cleaner, more modern look, and a destructive action shouldn't sit one tap away on the home screen.

## 2026-10-17 — Rename the app to Smart Flow
**Decision:** Renamed "The Wealth App" / "Safety First" to Smart Flow everywhere: display name, Xcode project, target, scheme, source folder, `SmartFlowApp.swift`, bundle ID `com.briansanchez.smartflow`, and the Keychain service names (`SmartFlow.login`, `SmartFlow.aiKeys`).
**Why:** One name for the product. The new bundle ID means it installs as a new app, so a saved password and OpenAI key from the old app don't carry over.

## 2026-10-17 — Remove Plaid; documents come in through OpenAI
**Decision:** Removed the Plaid bank connection (`BankConnection.swift`, the `Plaid Server/` Node server, the LinkKit package). Financial data now comes from the interview or from documents the user uploads or photographs, which OpenAI reads.
**Why:** Simpler setup for the team (no server, no Plaid keys) and one data path instead of two.

## 2026-10-17 — The repo is the team knowledge base
**Decision:** Rules live in `CLAUDE.md`, the plan in `PLAN.md`, decisions here. Personal notes go in `CLAUDE.local.md` (git-ignored).
**Why:** Several people work on this from different devices. Anything kept only in one person's chat or Claude memory doesn't move with the project.

## 2026-10-17 — Karpathy guidelines for AI-assisted work
**Decision:** Claude follows four rules: think before coding, simplicity first, surgical changes, goal-driven verification.
**Why:** Small, checked diffs are easy for a human to review when work is delegated to AI agents.
