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

- Below: **Sections (grouped settings)**, for example:

  1. **Sales & Tax**
  2. **Currency & Rounding**
  3. **Inventory Behavior**
  4. **Attendance & Shifts**
  5. **Cash Sessions & Drawer Behavior**
  6. **Multi-branch Behavior** (if applicable in Capstone 1)

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

### 4.1 Section: Sales & Tax

Purpose: Settings that affect **checkout behavior** and tax.

Example items:

- **Apply VAT**
  - Type: Toggle
  - Default: Off
  - Effect:
    - If ON → Sales screens and receipts show VAT line.
  - Detail screen:
    - Toggle: On/Off
    - VAT rate (%): numeric field (e.g., 10%)

- **VAT applies after discount**
  - (If supported in backend; otherwise this is implied behavior and can be explanatory text only.)

UX Behavior:
- Cashier never sees a VAT toggle.
- The Sales / eReceipt UI **reads** and follows this policy; changes only happen in Admin’s Policy screen.

---

### 4.2 Section: Currency & Rounding

Purpose: Controls how totals are shown in USD and KHR and how KHR is rounded for payment.

Example items:

- **KHR per USD rate**
  - Type: Numeric input (e.g., 4100)
  - Used to compute KHR display for all sales.

- **KHR rounding step**
  - Type: Selector
  - Options: 50, 100, 500, etc.
  - Example preview: “Round to nearest 100 KHR”

- **Rounding mode**
  - Type: Selector
  - Options: Nearest, Up, Down
  - Example preview:
    - “10.23 USD → 41,943 KHR → 41,900 KHR (Nearest 100)”

Effects:
- Checkout screen displays:
  - Exact USD total
  - Rounded KHR total for **cash** payment.
- eReceipt for customers shows both USD and KHR (rounded).

---

### 4.3 Section: Inventory Behavior

Purpose: Controls whether sales affect inventory and how strictly.

Example items:

- **Subtract inventory on sale finalize**
  - Type: Toggle
  - Default: On (or Off depending on spec)
  - If ON → a finalized sale reduces branch inventory according to recipe mapping.

- **Apply inventory deduction only for mapped items**
  - Can be just explanatory text (if it’s always true) or extra toggle, depending on backend.

- Possibly a note: 
  - “Inventory for some branches may not be tracked if this is off.”

From cashier UI:
- No direct indication; inventory is updated in the background.

From Admin / Inventory UI:
- Admin expects stock to change only where this is switched ON.

---

### 4.4 Section: Attendance & Shifts (if within Capstone 1 Policy)

> If some attendance behaviors are policy-driven (e.g., auto-check from cash session), represent them as settings here.

Example items:

- **Auto-attendance from cash session**
  - Type: Toggle
  - Behavior:
    - When ON: Starting a cash session counts as check-in; closing counts as check-out.

- **Allow manager to edit attendance time**
  - Type: Toggle (if this is kept in Capstone 1)
  - If ON: Manager can manually adjust check-in/check-out times in Attendance UI.

Managers:
- See the effect only in Attendance module; cannot change these settings if restricted.

---

### 4.5 Section: Cash Sessions & Drawer

Purpose: Controls required behavior for cash handling.

Example items: (depending on final backend spec)

- **Require session before cash sale**
  - Type: Toggle
  - If ON: Cashier must start a cash session before they can accept cash payment.

- **Allow paid-out**
  - Type: Toggle
  - If ON: Paid-out actions are allowed during a cash session.

- **Require manager approval for over-limit paid-out**
  - Type: Toggle
  - If ON: Over-limit paid-out must be approved by Manager.

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
  - Sales & Tax
  - Currency & Rounding
  - Inventory Behavior
  - Attendance & Shifts
  - Cash Sessions & Drawer
- **Discounts and eReceipt configuration are separate modules**, not part of this screen.
- Cashiers never see or change policies; they only see the effects in Sales, Inventory, Attendance, etc.

This doc should be used as **UI/UX context** when building:
- The **Settings/Policy screen** in the Tenant Admin Portal.
- Any detail pages for each setting group.