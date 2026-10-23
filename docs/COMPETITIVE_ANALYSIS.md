# Drivometry — Competitive Analysis

Date: 2026-10-23. Compares Drivometry with popular fuel-log, maintenance and
reminder apps and lists what to add **without changing the core concept**:

> An offline-first, private, per-vehicle log of fuel, maintenance, parts,
> expenses and reminders, with accurate Fuelio-style consumption.

Competitor features come from public store listings and vendor pages (see
Sources). They may change; check the current listing before relying on a detail.

Drivometry status assumes PR #44 (stacked VRF-18…30 work landed in `dev`) and
PR #42 (edit/delete fuel) are merged.

## 1. Apps compared

| App | Focus | Model |
|---|---|---|
| **Fuelio** | Fuel log and costs, fuel prices | Free, local data + optional Drive/Dropbox |
| **Drivvo** | Personal and fleet vehicle management | Freemium, cloud account |
| **Fuelly** | Fuel economy plus community MPG comparison | Free, cloud account |
| **Simply Auto** | Fuel, service, mileage (trip) log | Freemium, cloud backup |
| **CARFAX Car Care** | Service schedules and service history (US) | Free, VIN-based, online |

## 2. Feature matrix

✅ has it · 🟡 partial / planned · ❌ missing · — out of scope

| Area | Feature | Fuelio | Drivvo | Fuelly | Simply Auto | Drivometry |
|---|---|---|---|---|---|---|
| Vehicles | Multiple vehicles | ✅ | ✅ | ✅ | ✅ | ✅ |
| | Quick odometer update (no fill-up) | 🟡 | ✅ | ❌ | ✅ | ❌ → **T31** |
| | Fuel types incl. CNG / LPG / EV (kg, m³, kWh) | ✅ | ✅ | 🟡 | ✅ (kWh) | ❌ → **T33** |
| | Bi-fuel vehicles (petrol + CNG) | ✅ | 🟡 | ❌ | ❌ | ❌ → **T33** |
| Fuel | Full / partial / missed fill consumption | ✅ | ✅ | ✅ | ✅ | ✅ (also fuel-gauge estimate) |
| | Edit and delete fills | ✅ | ✅ | ✅ | ✅ | ✅ (PR #42) |
| | Price per litre prefilled from last fill | ✅ | ✅ | 🟡 | ✅ | ❌ → **T32** |
| | Fuel type, station, time of day | ✅ | ✅ | 🟡 | ✅ | 🟡 T11 |
| | Station suggestions / price history | ✅ | ✅ | ❌ | ❌ | 🟡 T11 |
| | Receipt photo | ✅ | ✅ | ✅ | ✅ | ✅ |
| | Odometer sanity checks | 🟡 | 🟡 | ❌ | 🟡 | ✅ (OdometerValidator) |
| Maintenance | Service log with cost and odometer | ✅ | ✅ | ✅ | ✅ | ✅ |
| | Interval schedules (date and/or km) | 🟡 | ✅ | ❌ | ✅ | 🟡 T13–T14 |
| | Preset service templates (oil, filters, tyres) | ❌ | 🟡 | ❌ | 🟡 | ❌ → **T34** |
| | Parts with lifespan and warranty | ❌ | ❌ | ❌ | ❌ | ✅ (**differentiator**) |
| Costs | Expense categories (insurance, tax, parking, tolls) | ✅ | ✅ | 🟡 | ✅ | ✅ (toll: issue #32) |
| | Recurring expenses (yearly insurance, monthly parking) | ❌ | ✅ | ❌ | 🟡 | ❌ → **T35** |
| | Income (rideshare) | ❌ | ✅ | ❌ | ❌ | — (Rentals module, hidden) |
| Reminders | By date or odometer | ✅ | ✅ | 🟡 | ✅ | ✅ |
| | Document expiry (insurance, registration, fitness) | 🟡 | ✅ | ❌ | 🟡 | 🟡 T20 |
| | Snooze / complete / history | 🟡 | ✅ | ❌ | 🟡 | 🟡 T19 |
| Stats | Charts, cost/km, monthly spend | ✅ | ✅ | ✅ | ✅ | ✅ |
| | Trip cost estimate (distance × avg consumption × price) | ✅ | ✅ | ❌ | ❌ | ❌ → **T36** |
| | Community comparison | ❌ | ❌ | ✅ | ❌ | — (needs a server) |
| Data | CSV export / PDF report | ✅ | ✅ | ✅ | ✅ | 🟡 T25 |
| | Import from other apps (CSV) | ✅ | 🟡 | 🟡 | ✅ | ❌ → **T37** |
| | Backup / restore | ✅ (Drive, Dropbox) | ✅ (cloud) | ✅ (cloud) | ✅ | 🟡 T26 (local file) |
| | Works fully offline, no account | ✅ | ❌ | ❌ | 🟡 | ✅ (**differentiator**) |
| UX | Quick add from home | ✅ | ✅ | ✅ | ✅ | 🟡 T28 |
| | Home-screen widget / app shortcuts | ✅ | 🟡 | ❌ | ❌ | ❌ → **T38** |
| | Multi-driver sharing, fleet | ❌ | ✅ | ❌ | ✅ | — (needs a server) |
| | GPS trip logging, business vs personal | ❌ | ✅ | ❌ | ✅ | — (different product) |

## 3. Where Drivometry already wins
1. **Consumption accuracy.** Full-to-full with a partial-fill queue, chain breaks,
   and a fuel-gauge estimate for owners who never fill up completely. This is
   rarer than it looks: most apps show nothing until two full tanks.
2. **Parts lifecycle** (install, lifespan, warranty, replacement). None of the
   compared apps track individual parts.
3. **Private and offline.** No account and no cloud dependency, unlike Drivvo
   and Fuelly.
4. **Odometer validation** shared by fuel and maintenance forms.

## 4. Gaps worth closing (keep the core concept)
Ranked by value ÷ effort for a personal, offline log:

| Rank | Ticket | Why |
|---|---|---|
| 1 | **T32** Smart fuel form defaults | Every competitor prefills the last price. Saves typing on each fill. XS. |
| 2 | **T31** Quick odometer update | Km-based reminders are only as good as the odometer. Today it only moves on a fill-up. S. |
| 3 | **T33** Fuel types and units (CNG/LPG/EV, bi-fuel) | CNG cars are common where the default currency (৳) is used. Without kg/m³ the economy figures are wrong for them. L. |
| 4 | **T37** CSV import (Fuelio, Drivvo, generic) | Removes the main barrier to switching apps. M. |
| 5 | **T35** Recurring expenses | Insurance, tax and parking repeat; pairs with T20 document reminders. S. |
| 6 | **T34** Service templates | One tap for "oil change every 5,000 km / 6 months". Feeds T13. S. |
| 7 | **T36** Trip cost estimate | Small calculator that reuses the existing stats. XS. |
| 8 | **T38** App shortcuts / widget | Fastest path to "log fuel". M. |

Deliberately **not** proposed: GPS trip logging, multi-driver/fleet sync,
community comparison, crowd-sourced fuel prices. They need a server or change
what the app is.

## Sources
- Fuelio: [App Store](https://apps.apple.com/app/id1487753318), [Softpedia](https://mobile.softpedia.com/apk/fuelio/), [APKMirror release notes](https://apkmirror.com/apk/sygic/fuelio-gas-log-costs/fuelio-gas-log-costs-8-2-2-release)
- Drivvo: [App Store](https://apps.apple.com/app/id1206041425), [drivvo.com](https://drivvo.com/en/personal-use/), [FAQ](https://drivvo.com/en/faq/), [Capterra](https://www.capterra.co.uk/software/219368/drivvo)
- Simply Auto: [App Store](https://apps.apple.com/us/app/id893278325), [AAA comparison](https://www.acg.aaa.com/connect/blogs/4c/auto/best-car-maintenance-apps)
- Fuelly and CARFAX Car Care: public store listings (general knowledge; not re-checked for this document)
