# The Wealth App — guide for Claude

Student project (UW–Green Bay hackathon). A SwiftUI iOS app that gives a small business a financial checkup. Users answer questions, or upload or photograph financial documents that OpenAI reads.

## Layout
- `Safety First/` — SwiftUI app (iOS 15.2+, Swift 5). 5 tabs: Overview, Interview, Import, Results, Settings.
  - `BusinessProfile.swift` — the single source of truth for the ~40 questions (`BusinessField`) and all financial math (`BusinessMetrics`: DSCR, cash coverage, runway, current ratio). New questions or metrics go here only, never in views.
  - `AIServices.swift`, `BusinessAIAgents.swift` — OpenAI Responses API calls. Each feature's model is set in `AIFeature.model`. `BusinessDocumentReader` reads uploaded files and photos.
  - `BusinessViews.swift` — large file of views, including document import (file, photo library, camera). Split it only when a task requires it, one view at a time.
  - `ContentView.swift` — tab bar, Settings screens, and `CopyrightPrivacyView` (the in-app Privacy text).
- `PLAN.md` — current plan and task list. `docs/decisions.md` — decisions and why.

## How to work (Karpathy guidelines)
1. **Think before coding.** State your assumptions. If the request is ambiguous, list the possible readings and ask; don't guess. Suggest a simpler approach if one exists.
2. **Simplicity first.** Write the minimum code that solves the task. Add no features, abstractions, protocols, managers or dependencies unless asked.
3. **Surgical changes.** Touch only the lines the task needs and match the surrounding style. Don't reformat, rename or "clean up" unrelated code or comments. Mention unrelated problems in your summary instead of fixing them.
4. **Goal-driven.** Before editing, state how success will be checked. Finish by running that check and reporting the result. For multi-step work, give each step its own check.

## Code style
- Keep the beginner-friendly comments: short plain-English notes explaining *why*. New code gets comments at the same density. Never delete an explanatory comment unless the code it describes is gone.
- SwiftUI: small `View` structs, using `@State` / `@StateObject` / `@EnvironmentObject` the way the existing code does. No Swift packages.
- Money and metric math lives only in `BusinessMetrics`. The AI gets numbers from `summaryForAI` and never does its own math.

## Privacy and secrets (must follow)
- Never print, log or commit API keys, tokens or passwords.
- Any change that sends user data somewhere new (a new API, or a new field sent to OpenAI) MUST update the Privacy text in `CopyrightPrivacyView` (ContentView.swift) in the same change, and say so in your summary.
- Don't weaken sign-in: leave the Keychain-hashed password and the Face ID flow as they are unless the task is about them.
- The app calls OpenAI directly, using the user's key from the Keychain (or `OPENAI_API_KEY` when run from Xcode). This is a known demo limitation: flag it, but don't redesign it unless asked.

## Verify every change
- iOS build (must pass):
  `xcodebuild -project "Safety First.xcodeproj" -scheme "Safety First" -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -30`
- Unit tests (once a test target exists):
  `xcodebuild test -project "Safety First.xcodeproj" -scheme "Safety First" -destination 'platform=iOS Simulator,name=<any installed iPhone>'`
- When changing `BusinessMetrics`: write or update a unit test first, watch it fail, then make the fix.
- UI changes: run the app in the Simulator and take a screenshot of the affected screen. The camera button only appears on a real iPhone.
- Report exactly which checks you ran and what they showed. Never say something works without running a check.

## Working as a team
- This repo is the knowledge base. Anything the next person needs (decisions, plans, gotchas) goes in a file here, never only in a chat or in Claude's memory.
- `PLAN.md` holds the current plan and task list. Update it when you start or finish a task, and put your name on what you're working on.
- Record decisions and their reasons in `docs/decisions.md` (date, decision, why).
- Personal notes go in `CLAUDE.local.md` (git ignores it).
- Pull before starting work. One task per branch; merge through a pull request.

## Git
- Small commits, one task each. Review `git diff` before committing.
- Never commit `.env`, `xcuserdata/`, `DerivedData/` or `.DS_Store`.
- Don't edit `project.pbxproj` by hand unless the task requires it, and say so if you do.

## New device setup
1. Clone the repo. Open `Safety First.xcodeproj` in Xcode 16.1+.
2. Simulator builds need no signing changes. To run on a real iPhone, pick your own team under Signing & Capabilities, and don't commit that change.
3. Enter an OpenAI API key in the app's Settings (stored in the Keychain), or set `OPENAI_API_KEY` in the Xcode scheme's environment without committing the scheme change. Never send keys over chat or commit them.

## When working as a subagent
- Stay inside the files named in your task. If you need to touch others, stop and report back.
- End with: what changed (files), how it was checked, and what you noticed but didn't change.
