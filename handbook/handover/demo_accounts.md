# Modula Demo Accounts (from `_seed_dev.sql`)

> Source of truth: `migrations/_seed_dev.sql`  
> Password for all accounts: `Test123!`

## Tenant: X Cafe
**Tenant ID:** `11111111-1111-4111-8111-111111111111`

### Branch: Sen Sok
**Branch ID:** `10000000-0000-4000-8000-000000000001`

- **Admin** — Zorng Lim  
  - Phone: `+1234567890`

- **Cashier** — John Smith  
  - Phone: `+1234567891`  
  - Default branch: Sen Sok

### Branch: Olympic
**Branch ID:** `10000000-0000-4000-8000-000000000002`

- **Admin** — Zorng Lim  
  - Phone: `+1234567890` (same admin account; assigned to both branches)

- **Cashier** — Adam Love  
  - Phone: `+1234567892`  
  - Default branch: Olympic

- **Cashier** — Joan Dune  
  - Phone: `+1234567893`  
  - Default branch: Olympic

---

## Tenant: Nodepresso
**Tenant ID:** `22222222-2222-4222-8222-222222222222`

### Branch: Nodepresso Main
**Branch ID:** `20000000-0000-4000-8000-000000000001`

- **Admin** — Nika Chhun  
  - Phone: `+0123456789`

- **Cashier** — Justin Bieber  
  - Phone: `+1123456789`

- **Cashier** — Justin Cook  
  - Phone: `+2123456789`

---

## Tenant: Posgres Cafe
**Tenant ID:** `33333333-3333-4333-8333-333333333333`

### Branch: Posgres Main
**Branch ID:** `30000000-0000-4000-8000-000000000001`

- **Admin** — Nika Chhun  
  - Phone: `+0123456789` *(same phone as Nodepresso admin; separate tenant membership)*

- **Cashier** — Elon Zuckerberg  
  - Phone: `+4123456789`

---

## Notes
- **All logins use phone + password**.
- Some people (e.g., **Nika Chhun**) are members of **multiple tenants** using the same phone.
- Cashiers have weekday shifts (Mon–Fri) seeded as `08:00–17:00` in `staff_shift_assignments`.

