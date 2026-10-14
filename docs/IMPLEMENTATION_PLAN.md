# Drivometry — Audit & Implementation Plan

Source requirements: `project-plan.txt`. Audit date: 2026-10-13, branch `feature/VRF-1-fuel-consumption` (PR #2 open into `dev`).
No code was changed for this audit. Everything under **Verified** was checked in code or by running a command; everything under **Proposed** is a plan.

---

## 0. How to work through this plan

**Per ticket (standing workflow):**
1. Create GitHub issue titled `VRF: <ticket title>` → issue number `N`.
2. Branch `feature/VRF-N-<slug>` from `dev`.
3. Commits: `VRF-N: <message>`.
4. Run `dart format`, `flutter analyze`, `flutter test` (and a build/emulator check for UI tickets).
5. PR into `dev` linked with `Closes #N`. One ticket = one PR. Close only when acceptance criteria pass.

**Models:** planning/audit on **Opus 5.5**; implementation on **Sonnet 5.5**.
Claude cannot switch its own model mid-session, so for implementation either:
- run `/model sonnet` before saying "implement VRF-N", or
- ask Claude to delegate each ticket to a sub-agent with `model: sonnet` (Claude reviews the result on Opus before the PR).

**Order:** tickets are numbered in dependency order (`T01` → `T30`). The GitHub issue number is assigned on creation; the `T` id is this plan's reference.

---

## 1. Verified current state (audit)

### 1.1 Stack
| Item | Finding |
|---|---|
| Flutter / Dart | Flutter 3.41.4 stable; `sdk >=3.3.0` |
| State | `flutter_bloc` Cubits |
| DI | `get_it` (`lib/injection_container.dart`) |
| Storage | Hive, untyped `Box<dynamic>` of `Map`s (`lib/core/database/hive_storage.dart`) — **no schema version, no migrations** |
| Routing | `go_router` (`lib/core/router/app_router.dart`), shell `lib/core/shell/main_shell.dart` |
| Notifications | `flutter_local_notifications` 17 + `timezone` |
| Charts | `fl_chart` (one BarChart in analytics) |
| Architecture | Clean-ish layers per feature (data/domain/presentation), documented in `docs/ARCHITECTURE.md` |
| Tests | 3 files, 22 tests, all fuel (`test/features/fuel/`) — **pass** |
| `flutter analyze` | 111 issues: 0 errors, 6 warnings (3 removed lints in `analysis_options.yaml`, 3 unused fields), rest info (`withOpacity`, deprecated Radio API, etc.) |
| `dart format` | 61 of 104 files not formatted |
| CI | **None** (`.github/` does not exist) |
| Modules not in requirements | Rentals (bottom-nav tab), onboarding, vehicle documents (registration/tax/fitness images) |

### 1.2 Requirements traceability

| # | Requirement | Status | Evidence |
|---|---|---|---|
| V1 | Multiple vehicles (car/bike/other) | Complete | `Vehicle.type`, `vehicles_page.dart` |
| V2 | Records scoped per vehicle | Partial | All entities carry `vehicleId`, but **deleting a vehicle leaves orphan fuel/maintenance/parts/rentals** (`DeleteVehicle` → `_box.delete(id)` only) while the dialog says "and all its records" |
| V3 | Dashboard: odometer, recent, upcoming maintenance | Partial | `vehicles_page.dart` + `VehicleDashboardMetrics`; health uses parts that are never saved (see P1) |
| V4 | Configurable distance & currency units | Missing | `Formatters.formatCurrency(symbol: '৳')`, `formatDistance(unit: 'km')` defaults; no setting |
| F1 | Fuel entry: date, odometer, volume, total, unit price, full/partial, notes, receipt | Complete | `add_fuel_entry_page.dart` |
| F2 | Fuel entry: time, fuel type, station | Missing | `FuelEntry` has neither |
| F3 | Fuelio full-to-full calc, partials, missed fill, odometer reset, gauge estimate | Complete (PR #2, not merged) | `fuel_consumption_calculator.dart`, 22 tests |
| F4 | Edit a fuel entry / correct mistakes | Missing | Detail page is read-only; no edit route (`/vehicles/:id/fuel/:entryId` is view only) |
| F5 | Duplicate / decreasing odometer detection | Partial | Add page rejects odometer ≤ current; no duplicate detection; vehicle edit can set any odometer |
| F6 | Fuel cost/km, avg fuel price, monthly fuel spend | Partial | Analytics shows cost/km (buggy, see A2); no average fuel price |
| M1 | Maintenance types, title, cost, odometer, date | Complete | `MaintenanceEntry`, `add_maintenance_page.dart` |
| M2 | Interval schedules (months / km / combined) | Partial | Stores one-off `nextServiceDate` / `nextServiceOdometer`; no recurring interval rule, no auto next-due after completion |
| M3 | Service history / completion flow | Partial | `reminderAcknowledged` hides reminder; no "complete → log service → roll next due" |
| M4 | Edit maintenance entry | Missing | Only `/maintenance/add` route |
| P1 | Parts: lifespan, install, warranty, history | **Defective** | `PartReplacement` entity + repo exist but **nothing ever calls `PartReplacementRepository.add`**; parts chosen in maintenance only feed `nextServiceOdometer`. Lifespan km only, no months/warranty/status |
| P2 | Parts / Maintenance tabs | Missing | No parts UI |
| S1 | Statistics tab | Partial | "Analytics" tab exists |
| S2 | Monthly/quarterly/yearly/custom ranges | Partial | Weekly/Monthly/Yearly/Lifetime only (`_getDateRange`) |
| S3 | Expense categories beyond fuel & maintenance (insurance, tax, parking…) | Missing | No generic expense entity |
| S4 | Pie + trend charts, vehicle comparison | Partial | One 6-month BarChart; per-vehicle cards |
| S5 | Export XLSX/CSV/PDF | Missing | No packages, no code |
| R1 | Reminder centre: upcoming/due/overdue | Partial | `notifications_page.dart` lists overdue/upcoming maintenance |
| R2 | Completed / dismissed / snooze states | Partial | Only "acknowledged"; no snooze, no history |
| R3 | Custom reminders (insurance, registration, tax, fitness, personal) | Missing | `fitnessExpiryDate` stored but never reminded |
| R4 | Configurable advance notice & preferences | Missing | Hard-coded 50 km / 7 days (`RunMaintenanceReminderChecks`) |
| R5 | Reliable local scheduling (tz, reboot, dedupe) | **Defective** | see N1–N3 |
| D1 | Backup / restore | Missing | — |
| D2 | Migrations, no data loss | Missing | No schema version; ad-hoc legacy handling per model |
| U1 | Bottom nav Home/Fuel/Maintenance/Statistics/Reminders | Different | Current: Dashboard/Rental/Analytics/Reminder (needs decision Q1) |
| U2 | Searchable history, quick-add | Missing | — |
| Q1 | CI on PRs | Missing | — |

### 1.3 Defects & risks (evidence)

| ID | Severity | Finding | Evidence |
|---|---|---|---|
| N1 | P0 | Notification times use **UTC**, not device zone: `tz.initializeTimeZones()` is called but `tz.setLocalLocation(...)` never is, so `tz.local` = UTC | `injection_container.dart:52`, `notification_service.dart:67` |
| N2 | P1 | Notification ids from `String.hashCode` — not guaranteed stable across runs/SDK versions; cancel/reschedule can miss | `maintenance_notification_ids.dart` |
| N3 | P1 | Reminder checks run only when app opens/screens load; "burst" schedules 7 notifications once and flags `…Scheduled=true` — editing the entry or odometer later doesn't reschedule | `maintenance_usecases.dart` (`RunMaintenanceReminderChecks`), `main.dart:107` |
| N4 | P1 | `RECEIVE_BOOT_COMPLETED` + boot receiver exist only in your **uncommitted** `AndroidManifest.xml` change | `git status` |
| B1 | P0 | `dev` (`39df516`) doesn't compile without `maintenance_notification_ids.dart` — fixed in PR #2 (`787fba7`), so PR #2 must merge first | PR #2 |
| A1 | P1 | Analytics page starts with `_period = Weekly` but cubit loads `Monthly` — chip and data disagree on first open | `analytics_page.dart:18,32` |
| A2 | P1 | Cost/km = **period** cost ÷ **lifetime** distance (distance & efficiency ignore the date range) | `analytics_cubit.dart` (`totalDistance`, `costPerKm`) |
| V2 | P1 | Vehicle delete orphans all records | `vehicle_hive_datasource.dart:45` |
| P1 | P1 | Parts never persisted (dead feature, dashboard "health" meaningless) | grep: no `PartReplacementRepository.add` caller |
| D2 | P1 | No schema versioning — every model change relies on hand-written fallbacks | `hive_storage.dart` |
| T1 | P2 | Two copy-pasted vehicle screens (`vehicle_detail_page.dart` and `vehicle_dashboard_tabs_page.dart`) incl. `_FuelList`; one may be dead | both files |
| T2 | P2 | Analyzer warnings + 61 unformatted files make CI noisy | analyze/format output |
| U3 | P3 | Tank capacity / odometer fields accept absurd values (e.g. 4,533,333 L seen in emulator test) | `add_vehicle_page.dart` validators |

### 1.4 Decisions (agreed 2026-10-13)
- **Q1 Rentals:** hidden for now (next phase). Code and data stay; the tab and routes are turned off behind a feature flag (T07). Bottom nav becomes Home · Fuel · Maintenance · Statistics · Reminders (T27).
- **Q2 Storage:** **keep Hive**. Data volumes are small (hundreds–thousands of rows per vehicle), everything is local, and the repository layer already isolates storage. Add schema versioning + migrations (T03) and in-memory aggregation for reports. Revisit SQLite/Drift only if reports become slow; the repository interfaces make that swap local to `data/`.
- **Q3 Full-tank liters:** keep current behaviour — a full-tank fill uses the vehicle's tank capacity unless the user types the pumped liters.
- **Q4 Export:** export to PDF and Excel (XLSX) + CSV from a **Settings / drawer item** ("Export reports"), using `excel`, `pdf`, `share_plus` (T25).
- **Q5 Currency & costing:** one **global** currency and unit setting (Settings, T08). Costs are shown both **globally** (all vehicles combined) and **per vehicle** (Home cards, vehicle screen, Statistics vehicle filter/comparison — T24).

## Progress tracker
Tick a line (`[x]`) when the ticket's PR is merged into `dev`.

- [x] Audit and plan (this document)
- [ ] T01 Merge fuel consumption PR and fix dev build
- [x] T02 Add GitHub Actions CI and automated PR review (VRF-5)
- [ ] T03 Add Hive schema versioning and migration runner
- [ ] T04 Fix notification time zone and stable notification ids
- [ ] T05 Cascade-delete vehicle records
- [ ] T06 Fix analytics period mismatch and cost-per-km
- [ ] T07 Hide Rentals behind a feature flag and remove duplicated vehicle screen
- [ ] T08 Settings screen with global currency and units
- [ ] T09 Odometer validation and correction
- [ ] T10 Edit and delete fuel entries
- [ ] T11 Fuel entry time, fuel type and station
- [ ] T12 Fuel statistics — average price, monthly spend, economy trend
- [ ] T13 Maintenance schedule model (date, distance, combined intervals)
- [ ] T14 Complete maintenance from schedule (service history)
- [ ] T15 Edit and delete maintenance entries
- [ ] T16 Parts lifecycle — install, lifespan, warranty, replace
- [ ] T17 Maintenance tab with Parts and Maintenance sub-tabs
- [ ] T18 Reminder engine with reschedule-on-change
- [ ] T19 Reminder centre states — snooze, complete, dismiss, history
- [ ] T20 Custom and document reminders
- [ ] T21 Notification preferences and advance notice
- [ ] T22 General expense records
- [ ] T23 Expense aggregation rules without double counting
- [ ] T24 Statistics tab — ranges, charts, global and per-vehicle costs
- [ ] T25 Export reports (PDF, Excel, CSV) from Settings / drawer
- [ ] T26 Backup and restore
- [ ] T27 Bottom navigation restructure
- [ ] T28 Searchable history and quick-add
- [ ] T29 Accessibility and deprecated API cleanup
- [ ] T30 Release checklist and integration tests

---

## 2. Milestones & tickets

Legend — **P**: priority (P0 critical … P3 low) · **Size**: XS/S/M/L/XL · **Deps**: must be merged first.
Files are estimates.

### M0 — Correctness & foundation fixes

#### T01 · `VRF: Merge fuel consumption PR and fix dev build`
- **P0 · XS · Deps:** none
- **Problem:** `dev` doesn't compile (B1); fuel algorithm waiting in PR #2.
- **Requirements:** review & merge PR #2 into `dev`; commit or drop your uncommitted `AndroidManifest.xml` / `vehicle_document_storage.dart` / `add_vehicle_page.dart` changes in their own ticket.
- **Acceptance:** `dev` builds; `flutter test` passes on `dev`.

#### T02 · `VRF: Add GitHub Actions CI and automated PR review`
- **P0 · S · Deps:** T01
- **Requirements:** `.github/workflows/ci.yml` on PRs and pushes to `dev`/`main`: `subosito/flutter-action` pinned to 3.41.4 with cache, `flutter pub get`, `dart format --set-exit-if-changed` on **changed `.dart` files only** (PRs; generated `*.g.dart`/`*.freezed.dart` excluded; the repo has many legacy unformatted files so a whole-repo gate is not used), `flutter analyze --no-fatal-infos`, `flutter test`. Remove the 3 removed lint rules; fix 3 unused-field warnings. Add `.github/workflows/claude-review.yml` using `anthropics/claude-code-action@v1`: reviews every non-draft PR to `dev`/`main`, posts inline comments for real problems and one top-level verdict comment, and answers `@claude` follow-ups on PRs. It never approves, merges or pushes; the owner decides. **Required secret:** `CLAUDE_CODE_OAUTH_TOKEN` (generate with `claude setup-token`) or `ANTHROPIC_API_KEY`; if neither is set the review job is skipped with a warning.
- **Acceptance:** CI green on a PR; a deliberately unformatted changed file fails CI; Claude review comment appears on a PR once the secret is configured.
- **Files:** `.github/workflows/ci.yml`, `.github/workflows/claude-review.yml`, `analysis_options.yaml`, `lib/core/theme/app_theme.dart`, `maintenance_cubit.dart`, `injection_container.dart`.

#### T03 · `VRF: Add Hive schema versioning and migration runner`
- **P0 · M · Deps:** T01
- **Problem:** D2 — no versioning; model changes risk data loss.
- **Requirements:** `meta` box with `schemaVersion`; `MigrationRunner` executing ordered, idempotent steps at startup before DI; migration 1 = stamp existing data (e.g. write `missed_previous_fill` defaults so legacy fuel rows no longer depend on key-presence detection); log + never delete user data on failure.
- **Acceptance:** fresh install → latest version; old data → migrated once; re-run is a no-op; unit tests per migration with fixture maps.
- **Files:** `lib/core/database/hive_storage.dart`, new `lib/core/database/migrations/`, `injection_container.dart`, tests.

#### T04 · `VRF: Fix notification time zone and stable notification ids`
- **P0 · S · Deps:** T01
- **Problem:** N1, N2.
- **Requirements:** set `tz.setLocalLocation` from device zone (`flutter_timezone`, or `DateTime.now().timeZoneName` fallback); deterministic ids (e.g. FNV-1a 31-bit hash of entity id + slot) with collision-safe ranges; commit boot receiver + permissions (N4).
- **Acceptance:** reminder scheduled for 09:00 local fires at 09:00 local on emulator in a non-UTC zone; id function unit-tested for stability.
- **Files:** `injection_container.dart`, `notification_service.dart`, `maintenance_notification_ids.dart`, `AndroidManifest.xml`, `pubspec.yaml`.

#### T05 · `VRF: Cascade-delete vehicle records`
- **P1 · S · Deps:** T01
- **Requirements:** `DeleteVehicle` use case deletes fuel, maintenance, parts, rentals, documents, and cancels notifications for that vehicle; one migration (T03) to purge existing orphans (or reattach — none possible, so purge after confirm).
- **Acceptance:** after delete, no box contains the vehicle id; notifications cancelled; unit test with fakes.

#### T06 · `VRF: Fix analytics period mismatch and cost-per-km`
- **P1 · S · Deps:** T01
- **Problem:** A1, A2.
- **Requirements:** single source of truth for selected period; distance for cost/km = odometer span of fills inside the range; efficiency from segments ending inside the range.
- **Acceptance:** first open shows matching chip and numbers; cost/km test with 2 periods.

#### T07 · `VRF: Hide Rentals behind a feature flag and remove duplicated vehicle screen`
- **P1 · S · Deps:** T01 (Q1)
- **Requirements:** `kRentalsEnabled = false` in `app_constants.dart`; when false hide the Rental bottom-nav tab, rental routes, rental figures in Analytics and Home cards. Keep rental code, box and data untouched (next phase). Confirm which of `vehicle_detail_page.dart` / `vehicle_dashboard_tabs_page.dart` is routed; delete the dead one or extract shared `_FuelList`/hero into widgets.
- **Acceptance:** with the flag off no rental UI is reachable and existing rental data is still in the box; flipping the flag restores it; one vehicle screen implementation; analyze clean.

### M1 — Data foundation & vehicle management

#### T08 · `VRF: Settings screen with global currency and units`
- **P1 · M · Deps:** T03 (Q5)
- **Requirements:** Settings page reachable from a Home drawer/app-bar menu (also hosts Export T25 and Backup T26); **global** currency symbol + code, distance unit km/mi, volume L/gal; stored via `shared_preferences`; `Formatters` read settings (no hard-coded ৳/km). Data stays stored in km/L; convert only for display.
- **Acceptance:** switching to miles converts odometer/economy display (mpg) everywhere; widget test.

#### T09 · `VRF: Odometer validation and correction`
- **P1 · M · Deps:** T03
- **Requirements:** shared `OdometerValidator`: reject decreasing reading vs nearest earlier record (fuel or maintenance), warn on duplicates (same date+odometer+liters), warn on implausible jump (> configurable, e.g. 2,000 km since last); vehicle current odometer = max of records unless user confirms override; sane bounds for tank capacity (1–200 L) and odometer.
- **Acceptance:** unit tests for each rule; fuel and maintenance forms show the message.

#### T10 · `VRF: Edit and delete fuel entries`
- **P1 · M · Deps:** T09
- **Requirements:** Edit action on fuel detail → reuse add page in edit mode; recalc consumption (`RecalculateFuelConsumption`) and vehicle odometer after edit/delete; confirm before delete.
- **Acceptance:** editing liters of a middle fill updates the next full-tank km/L; widget test.

#### T11 · `VRF: Fuel entry time, fuel type and station`
- **P2 · S · Deps:** T03, T10
- **Requirements:** add optional `fuelType` (enum + custom), `station` (free text with recent suggestions), time-of-day on date picker; migration adds defaults; shown on detail and export.
- **Acceptance:** fields round-trip through model; legacy rows load.

### M2 — Fuel analytics

#### T12 · `VRF: Fuel statistics — average price, monthly spend, economy trend`
- **P2 · M · Deps:** T06, T08
- **Requirements:** per vehicle and range: total liters, average price/L (liter-weighted), fuel cost/km, economy trend line (per segment), monthly fuel spend bars; exclude estimated segments from "best/worst" but show them flagged.
- **Acceptance:** calculator-level unit tests; charts render empty/1-point/many-point cases.

### M3 — Parts & maintenance

#### T13 · `VRF: Maintenance schedule model (date, distance, combined intervals)`
- **P1 · M · Deps:** T03
- **Requirements:** new `MaintenanceSchedule` entity per vehicle: task (type/title), `intervalMonths?`, `intervalKm?`, `lastDoneDate`, `lastDoneOdometer`, `advanceDays`, `advanceKm`, active flag. Pure `DueStateCalculator`: next due date = last + months, next due km = last + km, state = `upcoming/dueSoon/due/overdue` by **whichever comes first**; flags stale odometer (no odometer update in N days).
- **Rules to document:** early/late completion → next due always from the *actual* completion (date & odometer).
- **Acceptance:** table-driven unit tests (date-only, km-only, combined, early, late, stale odometer).

#### T14 · `VRF: Complete maintenance from schedule (service history)`
- **P1 · M · Deps:** T13
- **Requirements:** "Mark done" on a schedule opens prefilled maintenance entry (cost, odometer, date, notes) → saves `MaintenanceEntry` linked by `scheduleId` → rolls schedule's last-done; migrate existing entries with next-due values into schedules.
- **Acceptance:** completing creates history row and new next-due; migration test from legacy entries.

#### T15 · `VRF: Edit and delete maintenance entries`
- **P2 · S · Deps:** T14
- **Acceptance:** edit route + form edit mode; schedule recomputed when the latest completion changes.

#### T16 · `VRF: Parts lifecycle — install, lifespan, warranty, replace`
- **P1 · L · Deps:** T03, T13
- **Problem:** P1 (parts never saved).
- **Requirements:** extend `PartReplacement` → `Part`: category, purchase/install date, install odometer, cost, lifespan months and/or km, warranty months/km, status `active/due/replaced/retired`, `replacedById`. Replacing keeps the old record (status `replaced`) and links the new one. Parts selected in a maintenance "Parts change" create Part records (cost counted once — see T19).
- **Acceptance:** due-state reuses `DueStateCalculator`; history visible per part; migration from `part_replacements` box.

#### T17 · `VRF: Maintenance tab with Parts and Maintenance sub-tabs`
- **P1 · M · Deps:** T14, T16 (Q1)
- **Requirements:** Maintenance screen (bottom nav) with vehicle selector; tabs **Maintenance** (schedules by due state + history) and **Parts** (active/due/replaced, filter by category); clear overdue badges; empty states.
- **Acceptance:** widget tests for states; emulator check.

### M4 — Reminders & notifications

#### T18 · `VRF: Reminder engine with reschedule-on-change`
- **P0 · L · Deps:** T04, T13, T16
- **Requirements:** one `ReminderScheduler` that, from schedules/parts/custom reminders, computes desired notifications and diffs against a persisted "scheduled" registry (id → fire time, payload) — cancel stale, schedule new, never duplicate. Triggered on: app start/resume, any data change, odometer update, settings change, boot (via plugin receiver), time-zone change. Replaces burst flags (`odometerReminderScheduled`, `dateProximityReminderScheduled`). Handles permission denied (in-app banner, no crash) and iOS 64-pending limit (schedule nearest first).
- **Acceptance:** unit tests with fake notification service for add/edit/complete/delete; no duplicate ids; emulator: change due date → old notification cancelled.

#### T19 · `VRF: Reminder centre states — snooze, complete, dismiss, history`
- **P1 · M · Deps:** T18
- **Requirements:** sections Overdue / Due today / Upcoming / Completed / Dismissed; actions complete (→ T14 flow), snooze (1 d / 3 d / 1 w / custom), dismiss (until next occurrence); notification action buttons where supported.
- **Acceptance:** state transitions unit-tested; UI shows each section.

#### T20 · `VRF: Custom and document reminders (insurance, registration, tax, fitness, personal)`
- **P1 · M · Deps:** T18
- **Requirements:** `Reminder` entity (title, category, vehicleId?, due date, repeat yearly/monthly/none, advance days); auto-create from vehicle `fitnessExpiryDate`; quick-add from Reminders tab.
- **Acceptance:** repeat rolls forward after complete; fitness expiry produces reminder.

#### T21 · `VRF: Notification preferences and advance notice`
- **P2 · S · Deps:** T18, T08
- **Requirements:** settings: enable per category, default advance days/km, quiet hour time of day; per-item override.
- **Acceptance:** changing preference reschedules (via T18).

### M5 — Expenses, statistics & export

#### T22 · `VRF: General expense records (insurance, tax, parking, misc)`
- **P1 · M · Deps:** T03
- **Requirements:** `Expense` entity: vehicleId, date, category (fuel, maintenance, parts, repair, insurance, registration, tax, parking, toll, wash, misc), amount, odometer?, notes, receipt; quick-add from Home.
- **Acceptance:** CRUD + model tests.

#### T23 · `VRF: Expense aggregation rules without double counting`
- **P1 · M · Deps:** T16, T22, T14
- **Requirements:** single `ExpenseLedger` producing one row per money event: fuel entries, maintenance invoices (labour + parts **as one invoice**), parts bought outside maintenance, general expenses. A part installed in a maintenance carries `invoiceId` and is excluded from separate part spend. Document rules in `docs/EXPENSE_RULES.md`.
- **Acceptance:** tests: part inside invoice counted once; standalone part counted; totals equal sum of categories.

#### T24 · `VRF: Statistics tab — ranges, charts, global and per-vehicle costs`
- **P1 · L · Deps:** T23, T12, T06
- **Requirements:** ranges month / quarter / year / custom; vehicle filter **All vehicles** (global costing) or a single vehicle (per-vehicle costing); pie by category; stacked monthly bars; totals, cost/km, economy; vehicle comparison table; accessible (labels, not colour-only). Rename tab "Statistics".
- **Acceptance:** widget tests for empty/one/many; numbers match ledger tests.

#### T25 · `VRF: Export reports (PDF, Excel, CSV) from Settings / drawer`
- **P2 · L · Deps:** T08, T23, T24 (Q4)
- **Requirements:** "Export reports" item in Settings / Home drawer opens an export sheet: format (PDF / Excel XLSX / CSV), filters (all vehicles or one, date range, categories); CSV + XLSX (sheets: Fuel, Maintenance, Parts, Expenses, Summary with totals) + PDF summary; share sheet; works offline; clear errors.
- **Acceptance:** golden test of CSV output; XLSX opens in Sheets/Excel; PDF renders totals.

### M6 — Reliability, UX & release

#### T26 · `VRF: Backup and restore (local file)`
- **P1 · M · Deps:** T03
- **Requirements:** export all boxes + receipt/document images to a versioned `.zip`/JSON; restore validates version and contents, runs migrations, confirms before overwrite, keeps a pre-restore backup.
- **Acceptance:** round-trip test (backup → wipe → restore equals original); corrupted file rejected.

#### T27 · `VRF: Bottom navigation restructure (Home, Fuel, Maintenance, Statistics, Reminders)`
- **P2 · M · Deps:** T17, T24, T19 (Q1)
- **Requirements:** new shell with 5 tabs; Fuel tab = fuel history across vehicles with vehicle filter and quick-add; Rentals stay hidden (T07 flag); Settings, Export and Backup in the Home drawer.
- **Acceptance:** all routes reachable; deep links unchanged where possible.

#### T28 · `VRF: Searchable history and quick-add`
- **P3 · M · Deps:** T27
- **Requirements:** search/filter fuel, maintenance, expenses by text/date/category; FAB quick-add menu (Fuel, Expense, Service, Reminder) with sensible defaults (last price, last station).

#### T29 · `VRF: Accessibility and deprecated API cleanup`
- **P3 · S · Deps:** T02
- **Requirements:** replace `withOpacity`, `RadioListTile.groupValue`, etc.; semantics labels on charts/icons; text scale 200 % without overflow.
- **Acceptance:** `flutter analyze` info count ↓ to 0 deprecations.

#### T30 · `VRF: Release checklist and integration tests`
- **P2 · M · Deps:** most of M0–M5
- **Requirements:** `integration_test/` happy paths (add vehicle → fuel → maintenance → reminder → stats → export → backup/restore); upgrade test from a v1 Hive fixture; `docs/RELEASE_CHECKLIST.md` (permissions, exact-alarm policy, iOS notification limits, version bump).

---

## 3. Suggested sequence

```
T01 → T02 → T04 → T03 → T05 → T06 → T07          (M0)
      T08 → T09 → T10 → T11                      (M1)
      T12                                         (M2)
      T13 → T14 → T15 → T16 → T17                 (M3)
      T18 → T19 → T20 → T21                       (M4)
      T22 → T23 → T24 → T25                       (M5)
      T26 → T27 → T28 → T29 → T30                 (M6)
```
**First ticket to implement:** T01 (merge PR #2), then **T04** (reminders currently fire at the wrong time for every non-UTC user).

## 4. Test strategy (applies to every ticket)
- Pure domain logic (calculators, due-state, ledger, migrations) → table-driven unit tests, no Flutter.
- Repositories → in-memory fakes (pattern in `test/features/fuel/add_fuel_entry_page_test.dart`).
- Screens → widget tests for empty / normal / error states.
- Notifications → fake `NotificationService`; manual emulator check in a non-UTC time zone.
- Every PR: format, analyze, test in CI (T02); UI tickets also an emulator run.
