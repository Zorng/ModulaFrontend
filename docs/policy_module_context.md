# Policy Module – Frontend Context (Capstone 1)

This document explains how the **Policy Module** should behave from a **frontend / UX** point of view.

## 1. Concept

In Modula, **Policy is like “Settings” on iOS**:

- The tenant does **not** “create a policy”.
- Modula ships with a **fixed list of policy options** with default values.
- The tenant **adjusts these settings** to match how their store operates.
- Policy is a **configuration layer** that influences other modules (Sales, Inventory, Attendance, Cash Sessions, etc.).

From the frontend side:
- There is a **single “Settings / Policy” area**, mainly for **Admin**.
- The UI is **read-only** for some roles (e.g., Manager can sometimes view, Cashier never touches it).
- There is **no concept of “Add Policy” or “Policy list CRUD”**.

---

## 2. Roles & Access

### Admin (Tenant)
- Full access to **view and modify** all policy settings.
- Uses Policy to control behavior of:
  - Sales
  - Tax / VAT
  - Currency display & rounding
  - Inventory deduction
  - Attendance behavior (where applicable)
  - Cash session behavior (where applicable)

### Manager (Branch)
- Optional (depending on final decision):  
  - Can **view effective policies** for their branch (read-only).
  - Cannot change policies in Capstone 1 unless explicitly allowed.

### Cashier
- **No direct access** to Policy.
- Only sees the **effects** of Policy (prices, rounding, inventory behavior, attendance rules, cash session requirements).

---

## 3. UX Pattern: iOS Settings Style

The Policy screen should feel like **iOS Settings**:

### 3.1 Main Policy Screen Layout

- At top: **Search bar**
  - Allows filtering by policy name/label (e.g., “VAT”, “rounding”, “attendance”).

- Below: **Sections (grouped settings)**. In Capstone 1 we expose:

  1. **Tax & Currency**
  2. **Inventory Behavior**
  3. **Attendance & Shifts**
  4. **Cash Sessions Control**

Each section:
- Has a header label (e.g., “Sales & Tax”).
- Contains rows (cells), each representing **one policy item**:
  - Label (e.g., “Apply VAT”)
  - Current value (e.g., “On (10%)”, “Off”, “Round to 100 KHR”)
  - Accessory: `>` indicating tap for details, or direct toggles.

### 3.2 Interaction

- Tap on a row:
  - Navigates to a **Detail Screen** for that policy or small group of related fields.
- Some simple policies can be changed **inline** with a toggle or segmented control.

Example row types:
- **Toggle**: `Inventory subtract on sale` → On/Off switch.
- **Selector**: `KHR rounding step` → open detail page with choices (50, 100, 500, etc.).
- **Numeric input**: `VAT rate` → detail page with number field and explanation.

---

## 4. Policy Sections & Example Items (Phase 1)

> Note: The exact list of policies depends on the backend spec. Below is a frontend view of how they should be grouped and presented, based on current design.

### 4.1 Section: Tax & Currency

Purpose: Settings that affect **checkout behavior**, VAT, and dual currency totals.

Example items:

- **Apply VAT**
  - Type: Toggle + detail page.
  - Detail screen lets admins enable the toggle and edit the VAT rate (%). Validation prevents zero/negative rates.
- **KHR per USD rate**
  - Type: Selector with preset options (4000 / 4100 / 4150 / 4200).
- **Rounding mode**
  - Type: Selector (Nearest / Up / Down) controlling KHR rounding in receipts and payment dialogs.

UX Behavior:
- Cashiers never see these toggles; POS reads the policy and computes the correct values automatically.
- Detail pages follow the iOS Settings pattern (search → card → detail) and require tapping “Edit” before changes are allowed.

### 4.3 Section: Inventory Behavior

Purpose: Controls whether sales affect inventory and how strictly.

Example items:

- **Subtract stock on sale**
  - Type: Toggle + detail page.
  - Detail screen also exposes **Use recipes for items**, which only becomes editable when subtraction is ON.
- **Expiry tracking**
  - Type: Toggle (simple on/off policy).

From cashier UI:
- No direct indication; inventory is updated in the background.

From Admin / Inventory UI:
- Admin expects stock to change only where this is switched ON.

---

### 4.4 Section: Attendance & Shifts (if within Capstone 1 Policy)

> If some attendance behaviors are policy-driven (e.g., auto-check from cash session), represent them as settings here.

Example items:

- **Cash Session Attendance**
  - Type: Toggle.
  - When ON: Opening/closing a cash session checks staff in/out automatically.

- **Out of shift approval**
  - Type: Toggle.
  - Requires manager approval when punching outside scheduled shift.

- **Early check-in buffer**
  - Type: Toggle + detail page.
  - Detail screen allows picking the buffer duration (15 min, 30 min, 1 hour). Duration selector is disabled unless the toggle is ON.

- **Manager edit permission**
  - Type: Info placeholder (shows “Coming soon”).

Managers:
- See the effect only in Attendance module; cannot change these settings if restricted.

---

### 4.5 Section: Cash Sessions Control

Purpose: Controls required behavior for cash handling.

Example items:

- **Require cash session to sell** (toggle)
- **Allow paid-out** (toggle)
- **Cash refund approval** (toggle)
- **Manual cash adjustment** (toggle)

These settings affect:
- What the cashier can do on the sale & cash session UI.
- When error dialogs appear (e.g., “Open session required”).

---

## 5. Not in Policy (Capstone 1)

To avoid confusion in frontend:

- **Discounts**
  - Now a separate module.
  - Will have its **own screens** and navigation (e.g., Promotions / Discounts module).
  - Should not appear inside Policy screen.

- **Receipt Configuration**
  - Also a separate module.
  - Controls:
    - Logo
    - Store name
    - Address
    - Contact info
  - That module has its own “eReceipt Settings” page, separate from Policy.

The **Policy screen should only contain behaviors**, not content design.

---

## 6. Patterns for Flutter Implementation

### 6.1 Main Policy Screen
- `Scaffold` with:
  - `AppBar(title: Text('Settings'))`
  - Body:
    - Column:
      - Search field (TextField)
      - ListView with section headers + rows

Each row:
- `ListTile` or custom tile with:
  - `title` = policy title
  - `subtitle` = current value / short description
  - `trailing` = toggle / value / chevron icon
  - `onTap` → navigate to detail page if needed.

### 6.2 State Management
- Policy data fetched from backend as a single **Policy DTO** or per-group endpoints.
- Use Riverpod (or your chosen state management) to:
  - Store policy state.
  - Update specific fields on submission.
  - Optimistically update UI or reload after save.

### 6.3 Save/Update Behavior
- For each detail screen:
  - Show current values.
  - Allow modifying fields.
  - On “Save”:
    - Call backend PUT/PATCH.
    - On success → show toast/snackbar + pop back.
    - On failure → show error, keep values in form.

---

## 7. Summary for Frontend Team

- **Policy is not CRUD**; it’s a **fixed Settings UI**, like iOS Settings.
- Tenants **edit values**, they don’t create policies.
- Group policies into clear sections:
  - Tax & Currency
  - Inventory Behavior
  - Attendance & Shifts
  - Cash Sessions Control
- **Discounts and eReceipt configuration are separate modules**, not part of this screen.
- Cashiers never see or change policies; they only see the effects in Sales, Inventory, Attendance, etc.

This doc should be used as **UI/UX context** when building:
- The **Settings/Policy screen** in the Tenant Admin Portal.
- Any detail pages for each setting group.
