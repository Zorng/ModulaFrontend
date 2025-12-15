# Sale Module – Frontend Context (Capstone 1)

This document describes how the **Sale** module should behave in the frontend (Flutter app) based on the backend Sale spec.  
It is for Modula’s **F&B Capstone 1** POS and is meant to guide UI, state, and interactions for cashiers, managers, and admins.  [oai_citation:0‡Sale.pdf](sediment://file_000000002a5872099d8946bec2e1abc5)  

The backend spec is the source of truth for rules and calculations; this document focuses on **screens, flows, and responsibilities** on the client side.

---

## 1. Mental Model

The Sale module is responsible for:

- Building a **cart** (items + modifiers).
- Running the **pricing pipeline** (discounts, VAT, FX).
- Handling **Pre-Checkout** and **Finalize** (Checkout).
- Tracking **Sale Type** and **Payment Method**.
- Handling **dual-currency totals** (USD & KHR) and **KHR rounding**.
- Updating **order state** (Draft → Finalized → Fulfillment states).
- Supporting **void** and **reopen** flows (Manager/Admin only).
- Working **offline** and syncing later.

Key states:

- **Draft** – cart being built, not yet finalized.
- **Finalized** – sale saved, can move through fulfillment.
- **Voided** – cancelled sale (logged, excluded from revenue).
- **Reopened** – original locked, corrected copy created.

Fulfillment states (for active orders):

- **In-Prep** → **Ready** → **Delivered** (or Cancelled).

---

## 2. Roles & What They See

### Cashier (Branch)

**Landing Screen: Cashier Portal — NOT the Sale screen.**  
When the cashier logs into Modula, they see the **Cashier Portal**, which includes cards/buttons for modules they have permission to access:

- **Sale**
- **Active Orders**
- **Attendance (if enabled)**
- **Cash Session (Start Session / End Session)**
- **Today’s Sales**
- **Profile / Logout**

From this portal, the cashier **enters the Sale module manually** by tapping the **“Sale”** card.

Cashier capabilities inside the Sale module:

- Add/remove items to cart; adjust quantity; pick modifiers.
- Perform **Pre-Checkout**.
- Perform **Checkout** (Finalize).
- Update fulfillment states for orders in their own branch (In-Prep → Ready → Delivered).
- View “Today’s Sales” (read-only for non-manager).

Cashier **cannot**:
- Configure discount/VAT/rounding policies.
- Void or reopen sales.
- Access branch-wide sales history (Managers/Admin only).
- Edit sale metadata after finalization (except fulfillment steps).

---

### Manager (Branch)

- Landing screen: **Manager Portal** (not Sale screen).
- Access modules:
  - Sale
  - Active Orders
  - Today’s Sales (for entire branch)
  - Staff Attendance (view/review)
  - Inventory (branch-level, if allowed)
  - Cash Sessions & Reports
- Inside Sale module:
  - All cashier abilities.
  - **Void** and **Reopen** same-day sales.
  - Edit fulfillment state with corrections.

### Admin (Tenant)

- Admin portal is separate from cashier POS client.
- If Admin opens the POS client:
  - They see the Manager-level portal.
  - They can use Sale module for testing and operations.

## 3. Main Screens

### 3.1 Sale Screen (Menu + Cart)

**Purpose:** Fast checkout. Cashier doesn’t choose “New Sale”; the **first tap** on a menu item implicitly starts a Draft.

Layout (tablet/phone):

- **Top**: Branch name, user name, connection status, unsynced badge if needed.
- **Left / main area**: Menu catalog
  - Category tabs or chips
  - Items as cards/buttons
  - Discounted items show **badge** (e.g., “-15%”).
- **Right / bottom panel**: Cart panel
  - List of items (with modifiers summary)
  - Quantity +/- controls
  - Line totals and discount indicators
  - Cart subtotal, VAT, total summary preview
  - **Pre-Checkout** button

Behavior:

- First item tap:
  - Creates a **Draft sale** client-side (client_uuid stored offline).
- Cart updates in real time:
  - Show line total per item.
  - Show discount per line (if applied).
- Clear Cart:
  - Resets current Draft sale on client side.
  - No server write until finalize or explicit sync.

Offline:

- Cart exists fully on client (IndexedDB / local store).
- Draft sale has `client_sale_uuid` and is queued for sync after finalize.

---

### 3.2 Pre-Checkout Screen / Panel

**Triggered:** Cashier taps **Pre-Checkout** on the Sale screen.

Fields required (from spec):  [oai_citation:1‡Sale.pdf](sediment://file_000000002a5872099d8946bec2e1abc5)  

- **Sale Type**
  - Dine-In / Take Away / Delivery
- **Payment Method**
  - Cash / QR/Transfer / Other
- **Tender Currency**
  - KHR or USD  
  - Influences rounding policy:
    - If KHR → rounding applied (nearest 100 by default).
    - If USD → no KHR rounding.

**Totals Panel:**

- Shows the pricing pipeline:
  - Subtotal
  - Item-level discount total (from discount policies)
  - Branch-level discount total (if any)
  - VAT amount
  - Grand Total in **USD & KHR exact**:
    - `Total (Exact): $X.XX (≈ Y KHR)`
- If Tender Currency = KHR:
  - Show KHR rounding details:
    - `Rounding: +/− N KHR`
    - `Final Total (KHR): RoundedTotal`
- Input for **Received amount**:
  - If Payment Method = Cash:
    - Accepts either USD or KHR based on tender currency.
    - Auto-calc Change.
  - If Payment Method ≠ Cash:
    - Received/Change may be skipped or informational.

UX Goals:

- Minimal typing:
  - Numeric pad for Received amount.
  - Buttons for common amounts (e.g., 10,000; 20,000; 50,000… KHR).
- Clear visuals for:
  - Discount applied (labels/badges).
  - VAT line.
  - Rounding line when KHR tender.

---

### 3.3 Checkout (Finalize)

**Triggered:** Cashier taps **Checkout** on the Pre-Checkout screen.

Frontend responsibilities:

- Validate:
  - Cart not empty.
  - Required fields (sale type, payment method, tender currency).
- Freeze UI:
  - Disable double-tap Checkout.
  - Show short loading indicator (“Finalizing…”).

Data included in finalize request:

- Cart items + modifiers snapshot.
- Sale type.
- Payment method, tender currency.
- Computed totals (USD exact, KHR exact, KHR rounded, rounding delta).
- Policies used (discount IDs).
- VAT & FX snapshot.

On success:

- Mark sale as **Finalized** locally.
- Clear current cart.
- Create an **Active Order** entry in local state:
  - `In-Prep` by default.
- Update local and server caches for reports.

Offline behavior:

- If offline:
  - Mark sale as **Finalized (unsynced)** locally.
  - Queue a sync job with all finalize data.
  - Show subtle “Unsynced” badge somewhere on history/active orders.
- When online:
  - Sync finalize:
    - Use `client_sale_uuid` to ensure **idempotency** and avoid duplicates.

---

### 3.4 Active Orders / Fulfillment Screen

**Purpose:** Allow kitchen/cashier to see current orders and track status.

Content:

- List of **non-delivered** sales:
  - Order ID / Code (e.g., #A000312)
  - Sale type (Dine-In, Take Away, Delivery)
  - Time since order
  - Items summary (2× Iced Latte, 1× Boba Milk Tea…)
  - Current fulfillment status:
    - In-Prep / Ready / Delivered / Cancelled

Actions (Cashier):

- Tap order → order detail panel:
  - Full item list and notes
  - Buttons:
    - In-Prep → Ready
    - Ready → Delivered
- If Manager/Admin:
  - May also revert status (e.g., Delivered → Ready) **same-day only** with reason popup.

Notes:

- Fulfillment actions must:
  - Update local state instantly.
  - Call backend to update `fulfillment_status` and timestamps.
  - Write to audit log (server-side) with actor & reason if revert.

---

### 3.5 Sales History / Today’s Sales

**Purpose:** Viewing recent sales and supporting void/reopen flows.

View modes:

- **Today’s Sales** (for Cashier):
  - Their own finalized, voided, reopened sales (depending on permissions).
- **Branch Sales (date range)** (for Manager/Admin):
  - Filter by date, sale type, payment method, cashier.

Columns:

- Sale ID
- Time
- Sale Type
- Total (USD & KHR)
- Payment Method
- State (Finalized / Voided / Reopened)
- Fulfillment status (Delivered / Cancelled)

Row actions:

- Tap to open **Sale Detail**:
  - Items, totals, VAT, discounts, rounding info.
  - For Manager/Admin on same-day:
    - Buttons: **Void**, **Reopen** (depending on state).

---

## 4. Voiding & Reopening (Frontend Behavior)

### 4.1 Void Sale (Manager/Admin only)

From Sale Detail screen:

1. Manager taps **Void Sale**.
2. Confirm dialog:
   - “Are you sure you want to void this sale?”
   - Text-area for **reason** (required).
3. On confirm:
   - Call backend `void` endpoint with reason.
   - On success:
     - Mark sale as **Voided** in UI.
     - Show clearly:
       - “Status: VOIDED”
       - Reason
       - Actor & timestamp
     - Remove sale from revenue totals in local reporting view (backend is source of truth).

Constraints (UI level hints):

- Void is **same-day only** (if backend returns error, show message from server).
- Voided sales cannot be edited or reopened.

### 4.2 Reopen Sale (Manager/Admin only)

From Sale Detail screen (Finalized sale, same-day):

1. Manager taps **Reopen Sale**.
2. System shows warning:
   - “Reopening will lock this sale and create a corrected version. Continue?”
   - Reason field is required.
3. On confirm:
   - Backend:
     - Marks original as `reopened`.
     - Returns a new draft sale ID with copied data.
4. Frontend:
   - Navigates to **Sale screen** populated with this new Draft:
     - Pre-filled with original items and context.
     - Marked as “Reopened from [original ID]”.
5. Cashier edits the new Draft as needed (e.g., change Americano to Latte).
6. Pre-Checkout & Checkout again:
   - New sale finalizes with new ID (e.g., `#A000478-R1`).
   - UI shows it as “Reopened” in history.

Constraints:

- Reopen is **same-day only**.
- If backend denies (date mismatch, etc.), show error message and keep sale intact.

---

## 5. Dual Currency & Rounding (Frontend View)

Core rules (from spec):  [oai_citation:2‡Sale.pdf](sediment://file_000000002a5872099d8946bec2e1abc5)  

- System always computes and records:
  - `total_usd_exact`
  - `total_khr_exact` (via FX rate)
- Cashier never chooses “sale currency”; they only choose **Tender Currency** at Pre-Checkout:
  - Determines **how the customer pays** and whether to apply KHR rounding.

### UI Requirements:

- Totals panel always shows **both currencies**:
  - E.g., `Total (Exact): $8.53 (≈ 34,952 KHR)`
- When Tender Currency = KHR:
  - Show:
    - Rounded KHR total:
      - Nearest 100 by default, but policy may change (Off / Nearest 100 / Always up).
    - Rounding delta line (e.g., `Rounding: +48 KHR`).
  - Change calculation uses **rounded** KHR total for Cash payments.

- VAT:
  - Computed on exact totals.
  - Rounding delta is purely settlement; do not show as tax.

---

## 6. Discount Policy – Frontend Impact

From spec: discounts are **policy-driven only**, no manual discounts for Phase 1.  [oai_citation:3‡Sale.pdf](sediment://file_000000002a5872099d8946bec2e1abc5)  

Types:

- **Per Item** (line-level).
- **Per Branch** (order-level).

Frontend behavior:

- **Menu:** Items that have an active item discount for this branch show a **promo badge** (e.g., “-15%”).
- **Cart line:** Show:
  - Original unit price struck-through (optional).
  - Discounted line total.
  - Small label like `Promo: Iced Latte 15%`.

- **Totals panel:** Show:
  - “Item Discount Total”
  - “Branch Discount Total”
- No “enter discount” or custom discount fields for cashier.

Stacking:

- Cashier does not choose which policy; server determines best combination.
- Frontend just displays data from server response (e.g., list of applied policy IDs, discount amounts).

---

## 7. Offline Behavior & Sync

Key requirements:  [oai_citation:4‡Sale.pdf](sediment://file_000000002a5872099d8946bec2e1abc5)  

- Draft & finalized sales are stored locally with `client_sale_uuid`.
- All finalize/void/reopen operations must be **idempotent** when synced.

Frontend must:

- Clearly differentiate:
  - **Synced** vs **Unsynced** states.
- In offline mode:
  - Allow building cart and finalizing (mark as unsynced).
  - Queue operations (finalize, void, reopen) with idempotency keys.
- On reconnect:
  - Try sync:
    - Show a small sync status (e.g., “3 sales pending sync”).
  - On sync success:
    - Remove unsynced badge.
  - On sync error:
    - Mark sale row with an error icon and message (tap to see details).

UI hints:

- A small “cloud” icon near sale ID:
  - Filled (synced).
  - Outlined or with cross (unsynced).
- Offline banner when network is lost.

---

## 8. Reporting Hooks (Frontend Scope)

Sale module supplies data that Reporting and dashboards use:

- Sale type (dine-in/take-away/delivery).
- VAT flag & amount.
- Payment method, tender currency.
- FX rate used.
- Totals (USD exact, KHR exact, KHR rounded, rounding delta).
- Discount policies applied.
- Fulfillment timestamps.

Frontend responsibilities for Capstone 1:

- Ensure **these fields are captured and sent** during finalize.
- Use them for **basic on-device views** (e.g., Today’s total sales, simple stats).
- Full analytics and exports handled in Reporting module later.

---

## 9. UX Summary (for Designers & Devs)

- Landing = **Menu**, not a blank screen.
- First item tap instantly starts a Draft → no “New Sale” friction.
- **Pre-Checkout** is the only place where sale metadata is chosen:
  - Sale Type, Payment Method, Tender Currency.
- Totals are **always dual-currency**, but cashier only decides how the customer pays (Tender Currency).
- Discounts are **automatic**, not manual.
- KHR rounding is visible, explicit, and tied to Tender = KHR.
- Fulfillment tracking is **lightweight but real**:
  - In-Prep → Ready → Delivered with clear buttons.
- Error handling:
  - Clear messages on void/reopen failures (e.g., “same-day only”).
  - Offline “unsynced” badge reduces confusion.

---

## 10. Implementation Notes (Flutter)

High-level guidance:

- Use a **stateful SaleController** (e.g., Riverpod/Notifier) to manage:
  - Current Draft sale.
  - Cart items and modifiers.
  - Pre-Checkout selections.
  - Active orders.
  - Sync status.

- Keep **price and discount calculations** server-driven:
  - Frontend may do optimistic calculations, but always trust server on finalize.
  - Display server-returned totals after finalize.

- Design Sale UI to be **mobile-first**, but scale to tablet:
  - On phone: Menu and Cart may stack; Pre-Checkout in a full-screen sheet.
  - On tablet: Split view with Menu on left, Cart on right.

This document should be used alongside the backend Sale spec when implementing the Sale screens and flows in Modula’s POS client.