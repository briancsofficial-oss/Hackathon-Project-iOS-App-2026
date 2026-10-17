# Decisions

Newest first. Each entry: date, decision, why.

## 2026-10-17 — Remove Plaid; documents come in through OpenAI
**Decision:** Removed the Plaid bank connection (`BankConnection.swift`, the `Plaid Server/` Node server, the LinkKit package). Financial data now comes from the interview or from documents the user uploads or photographs, which OpenAI reads.
**Why:** Simpler setup for the team (no server, no Plaid keys) and one data path instead of two.

## 2026-10-17 — The repo is the team knowledge base
**Decision:** Rules live in `CLAUDE.md`, the plan in `PLAN.md`, decisions here. Personal notes go in `CLAUDE.local.md` (git-ignored).
**Why:** Several people work on this from different devices. Anything kept only in one person's chat or Claude memory doesn't move with the project.

## 2026-10-17 — Karpathy guidelines for AI-assisted work
**Decision:** Claude follows four rules: think before coding, simplicity first, surgical changes, goal-driven verification.
**Why:** Small, checked diffs are easy for a human to review when work is delegated to AI agents.
