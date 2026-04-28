# Changelog

All notable changes to the GC Private Markets Dashboard and tracker template are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Versions are tracked separately for the dashboard (`index.html`) and the tracker template (`releases/GC_Investment_Tracker_v*.xlsx`). They can be updated independently.

---

## [Unreleased]

Things being worked on — not yet shipped.

---

## Tracker 5.3 — 2026-04-28

Bug fixes and protection lockdown based on user testing.

### Tracker template (v5.3)
- **Fixed circular reference**: Investments column AA (Expected MOIC) had a self-referential formula `=IFERROR(Y/P,"")` on rows 19+ that combined with column Y's `=O*AA` to create a circular reference the moment a user added data on any row beyond row 18 (e.g. row 44). AA is now correctly user input on every row — yellow, unlocked, no formula. The behavior matches the working pattern of rows 7-18 from the original example portfolio.
- **Standardized formula columns**: rows 7-18 used Excel structured Table references (`tblInvestments[[#This Row],[Commitment ($)]]`) while rows 19+ used plain cell references. All 200 data rows now use the same plain-cell pattern for columns Q (Unfunded), X (Total Value), Y (Anticipated Value), AB (Actual MOIC). Removed the `tblInvestments` Table object since it's no longer needed.
- **Locked Pivot_Summary, Dashboard, CashFlow_Chart, and Lists tabs**: every cell on these four sheets is fully derived from user input on Investments / GC_Framework / CashFlows. Locking them prevents accidental edits to formula cells. The two filter cells on Dashboard (B6 Account filter, C6 Asset Class filter) remain editable so users can change views.
- **No password on protection**: power users can still go to Review → Unprotect Sheet to make changes if they really need to.

---

## Tracker 5.2 — 2026-04-28

Major usability overhaul addressing user feedback that entering deals was breaking formulas.

### Tracker template (v5.2)
- **Color-coded cells**: yellow for user input, grey for auto-calculated formulas, green for optional fields. A legend at the top of each working tab explains the system.
- **Sheet protection**: formula cells on Investments and CashFlows are locked to prevent accidental edits. No password — power users can unprotect via Review → Unprotect Sheet.
- **Data validation dropdowns** on constrained-vocabulary fields: Asset Class, Vehicle Type, Account Type, Tax Bucket, Deal Status, Flow Type, R-Code (R0–R9), Conviction Tier, Confidence. Custom values still allowed by typing — dropdowns are convenience, not constraint.
- **CashFlows simplification**: previously the CashFlows tab had formulas mirroring rows from the Investments tab, which confused users adding new events. Each row is now an independent event with hardcoded values; the only formula remaining is the auto-classifier in column G.
- **Formula auto-fill**: formula cells now extend to row 206 across the Investments tab, so newly added deals get their Unfunded / Total Value / Anticipated Value / Actual MOIC calculations automatically.
- **Rewritten Instructions tab**: replaces the previous brief instructions with a complete in-sheet quick-start covering colors, the two never-do rules, field-by-field guidance, common pitfalls, and dashboard sync.
- **TRACKER_USER_GUIDE.docx**: new external Word-document guide for members who prefer to read away from the spreadsheet. Includes troubleshooting for every failure mode reported by early users.

---

## Dashboard 1.0.0 / Tracker 5.1 — 2026-04-28

Initial public release on GitHub.

### Dashboard
- APEX-styled UI with KPI strip, allocation donut, R-code coverage grid, maturity ladder, capital call & distribution flow, and grouped deal cards.
- Local-first data flow: spreadsheet parsing happens entirely in the browser via SheetJS; no data leaves the user's computer.
- Version-check on load: fetches `version.json` and shows a non-intrusive banner if a newer dashboard or tracker template is available. Banner is dismissible per-version (won't re-appear for a version the user has already dismissed).
- Two-layer cashflow parser: aggregates raw events from the CashFlows tab in JavaScript, with the pre-aggregated CashFlow_Chart cache as a fallback for legacy files. Survives Excel formula-cache loss scenarios (Google Sheets exports, openpyxl-style saves, manual-calc-mode saves).

### Tracker template (v5.1)
- Dynamic CashFlow_Chart tab: quarterly aggregates use SUMIFS with explicit date-range bounds so they recalculate correctly in Excel. Avoids the Excel array-context bug that caused values to disappear on Enable Editing.
- Helper column G ("Call Type") on CashFlows distinguishes Initial vs Ongoing capital calls automatically based on chronological order.
- Dashboard MOIC at L10 and G20 is now a true commitment-weighted Expected MOIC: `Σ(commitment × Expected MOIC) / Σ(commitment)`.

### Bundled
- Offline bundle ZIP with HTML + tracker + Word-document setup guide.
