# Expense & cost rules

Every money event is stored exactly once, in the record type that owns it.
Analytics adds the owners together; it never re-derives one from another.

| Money event | Stored as | Counted in |
|---|---|---|
| Fuel fill | `FuelEntry.totalCost` | Fuel |
| Service / repair invoice | `MaintenanceEntry.cost` (labour **and** parts on that invoice as one amount) | Maintenance |
| Insurance, registration, tax, parking, toll, wash, other | `Expense.amount` | Other expenses |

- **Total cost** = Fuel + Maintenance + Other expenses, for the selected period
  and vehicle(s). It is never negative: income and rentals are not part of it.
- **Period** filtering uses each record's own date (fill date, service date,
  expense date), inclusive of both ends.
- **Cost per distance** = total cost ÷ distance driven by fills inside the
  same period (see `AnalyticsCubit`).
- **No double counting:** a part bought as part of a service invoice is already
  inside that invoice's cost, so it must not also be recorded as an `Expense`.
  When standalone Parts records land (plan T16), a part linked to a maintenance
  invoice carries the invoice id and is excluded from separate part spend.
- Currency and distance units are display-only (`AppSettings`); stored values
  stay in the base unit and the single configured currency.
