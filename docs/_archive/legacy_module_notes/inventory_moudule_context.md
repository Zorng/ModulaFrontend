# Inventory Module – Frontend Context (Capstone 1)

This document explains how the **Inventory module** should behave from a **frontend / UX** point of view.  
The backend is based on an **append-only inventory journal** and branch-scoped stock tracking with optional categories.   

The frontend should **never manage stock by “editing quantities directly”**.  
Instead, users interact via **simple forms**: *Receive*, *Waste*, *Correction*, and the UI shows **computed on-hand** per item/branch.

---

## 1. Concept & Mental Model

### 1.1 What Inventory does (from UI perspective)

- Tracks **stock items** (Milk, Cups, Straws, Oranges, etc.) per tenant.
- Links stock items to **branches** with **min thresholds** for low-stock alerts.  [oai_citation:0‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  
- Records stock movements via **journal entries**:
  - Receive (stock in)
  - Sale (auto, from Sales service)
  - Waste (spoil, spill)
  - Correction (manual count adjustment)
  - Void / reopen reversals (auto, from Sales service)
- Shows **On-hand** quantity and **Low-stock** warnings per branch.  [oai_citation:1‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  
- Organizes stock into **simple categories** (Dairy, Packaging, Produce, etc.) for filtering and reporting.  [oai_citation:2‡Inventory extended.pdf](sediment://file_0000000091187208af4e2c6e23387217)  

### 1.2 On-hand definition (for designers & devs)

> **On-hand** = Σ(receive) − Σ(sale) − Σ(waste) ± Σ(correction) ± Σ(void/reopen)  

- It is **not stored** as a mutable column; backend computes it from the journal.
- Frontend just calls `/inventory/onhand` and `/inventory/low-stock` endpoints.  [oai_citation:3‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

---

## 2. Roles & What They Can Do (UI)

### Admin (Tenant level)
- Manage **Stock Items**:
  - Create, edit, activate/deactivate.   
- Manage **Inventory Categories**:
  - Create, rename, activate/deactivate, delete (with guard).  [oai_citation:4‡Inventory extended.pdf](sediment://file_0000000091187208af4e2c6e23387217)  
- Link items to branches and set **min thresholds**.
- View **all branches’** inventory, on-hand, low-stock, and journal.
- Configure menu ↔ stock mapping (integrated with Menu module).
- See Exceptions (negative stock, unmapped sales).

### Manager (Branch level)
- View **branch stock** list (with on-hand + threshold).
- Record:
  - Receive
  - Waste
  - Correction
- Set **min threshold** for their branch’s items.
- View **low-stock** list for their branch.
- View journal (movements) for their branch.
- View categories & filter by category.

### Cashier
- No direct access to inventory UI.
- Their Sales finalize (POS) will **automatically** deduct inventory when inventory policy `inventory_subtract_on_finalize` is ON.  [oai_citation:5‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

---

## 3. Main Screens (Frontend)

### 3.1 Inventory Home – Branch View (Admin / Manager)

**Purpose:** Show stock status per branch with on-hand and low-stock highlighting.

**Key elements:**
- Branch selector (if Admin; Manager sees only their branch).
- Search bar (item name / barcode).
- Category filter (dropdown or chips).  [oai_citation:6‡Inventory extended.pdf](sediment://file_0000000091187208af4e2c6e23387217)  
- Table/cards showing:

  - Item name (e.g., “Milk 1000ml”)
  - Category pill (e.g., “Dairy”)
  - Unit (e.g., “pcs”)
  - On-hand quantity
  - Min threshold
  - Low-stock indicator (badge or red text)

Data source:
- `/inventory/onhand?branch_id=...`  
  Returns items with on_hand, min_threshold, and low_stock flag.  [oai_citation:7‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

**Actions:**
- Click/tap an item row → go to **Item Detail** (for branch).
- “Low stock only” toggle/filter.

---

### 3.2 Low-Stock View

Can be:

- A tab on Inventory Home, or
- A separate screen.

Shows list from `/inventory/low-stock?branch_id=...`  [oai_citation:8‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

Columns:
- Item name
- Category
- On-hand
- Min threshold

Purpose: quick view for restocking decisions.

---

### 3.3 Stock Items Master (Admin)

**Navigation:**
Tenant Admin Portal → Inventory → “Stock Items”.

**List view:**
- Search by name or barcode.
- Filters:
  - Active / Inactive
  - Category
- Columns:

  - Item name  
  - Unit text (pcs, kg, L…)  
  - Category (pill; e.g., “Dairy”, “Uncategorized”)  [oai_citation:9‡Inventory extended.pdf](sediment://file_0000000091187208af4e2c6e23387217)  
  - Active status toggle

**Actions:**
- Create Stock Item
- Edit item
- Deactivate item (soft off, never hard-delete)

**Create/Edit form:**
- Name (required)
- Unit text (required)
- Barcode (optional)
- Default cost (optional, Phase 1 mostly ignored)
- Category dropdown (optional)  [oai_citation:10‡Inventory extended.pdf](sediment://file_0000000091187208af4e2c6e23387217)  
- Active toggle

On save:
- POST or PATCH `/inventory/stock-items` as per backend.   

---

### 3.4 Categories Management (Admin)

**Navigation:**
Tenant Admin Portal → Inventory → “Categories”.

**List view:**
- Name
- Active toggle
- Drag handle to change `display_order` (optional)
- “Uncategorized” is implicit; not a row.

**Actions:**
- Create category
- Rename
- Deactivate
- Delete (if allowed; strict mode: block delete while items assigned).  [oai_citation:11‡Inventory extended.pdf](sediment://file_0000000091187208af4e2c6e23387217)  

Backend endpoints: `/inventory/categories` CRUD.  [oai_citation:12‡Inventory extended.pdf](sediment://file_0000000091187208af4e2c6e23387217)  

**Integration with Items:**
- Category can be set from:
  - Item form
  - Bulk assign category action (if implemented).

---

### 3.5 Branch Stock Setup (Admin / Manager)

**Purpose:** Link Stock Items to branches and set minimum thresholds.

**UI options:**

- Mode A (per-branch view):
  - Select branch.
  - Show list of items assigned to that branch.
  - For each:
    - Item name
    - Min threshold input (number)
  - “Add item to branch” button: search existing items and link with default threshold.

- Mode B (from item detail):
  - On item detail page, show which branches it is assigned to + thresholds.

Backend:
- PUT `/inventory/branches/{branch_id}/stock-items/{stock_item_id}` for threshold upsert.  [oai_citation:13‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

---

### 3.6 Journal View (Movements)

**Navigation:**
Inventory → “Movements” or per-item detail → “View history”.

**Purpose:** Display **inventory_journal** entries for transparency & debugging.  [oai_citation:14‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

**Filters:**
- Branch (required for Manager; optional for Admin)
- Item (optional)
- Reason (receive, waste, correction, sale, void, reopen)
- Date range
- Maybe category filter (optional, extended spec mentions tying into reports).  [oai_citation:15‡Inventory extended.pdf](sediment://file_0000000091187208af4e2c6e23387217)  

**Columns:**
- Timestamp
- Item name
- Reason
- Delta (positive or negative)
- Note (e.g., supplier/invoice/expiry, reason for correction)
- Actor (if available)

No editing from this screen. Journal is **append-only**.

---

### 3.7 Receive / Waste / Correction Forms

For branch-level adjustments (Admin or Manager).  [oai_citation:16‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

Common UI pattern:
- Entry point:
  - Buttons from Inventory Home:
    - “Receive”
    - “Waste”
    - “Correction”
  - Optionally accessible from item detail.

- Shared fields:
  - Branch (pre-selected for Manager)
  - Stock item (searchable dropdown)
  - Quantity (positive number for input; backend determines sign)
  - Note (required for waste & correction; optional for receive)

#### Receive form
- Action: “Add stock”
- Backend: POST `/inventory/journal/receive`  
  - UI sends positive `qty`, backend records `delta > 0`.  [oai_citation:17‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  
- Example note format:
  - “DairyCo | INV-0021 | EXP 2025-11-15”

#### Waste form
- Action: “Record waste/spill”
- Backend: POST `/inventory/journal/waste`  
  - UI sends positive qty; backend stores as `delta = -abs(qty)`.  [oai_citation:18‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  
- Note is **required**.

#### Correction form
- Action: “Adjust count”
- Backend: POST `/inventory/journal/correction` with `delta` (signed).  [oai_citation:19‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  
- Example:
  - Counted +2 extra → delta = +2
  - Missing 3 → delta = -3
- Note is **required** (“Counted extra 2”, etc.).

On success:
- Show toast/snackbar.
- Optionally refresh On-hand or Movements list.

---

### 3.8 Exceptions View (Admin / Manager)

**Purpose:** Help diagnose inventory problems (negative stock, unmapped sales).  [oai_citation:20‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

**Data source:**
- GET `/inventory/exceptions?branch_id=...&type=...`

**Display:**
- Negative Stock:
  - Item name
  - On-hand (negative)
  - Category
- Unmapped Sales:
  - Sale ID
  - Menu item
  - Occurred at

This view is mostly read-only and for debugging or process improvement.

---

## 4. Integration with Sales & Menu (Frontend Perspective)

### 4.1 Menu ↔ Stock Mapping

In Admin UI (likely from Menu module):

- On a menu item edit screen:
  - Section: “Inventory Mapping”
  - Fields:
    - Stock Item (dropdown; optional)
    - `Qty per sale` (e.g., -1 cup per drink)  [oai_citation:21‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

Backend:
- PUT `/inventory/menu-map/{menu_item_id}` with `stock_item_id` and `qty_per_sale`.  [oai_citation:22‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

In Capstone 1:
- Mapping is **0..1** (a menu item maps to at most one stock item).  [oai_citation:23‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

### 4.2 Automatic Sale Deduction (no extra UI for cashier)

- When `inventory_subtract_on_finalize` policy is ON:
  - Finalizing a sale triggers internal calls to Inventory journal (Sale reason).  [oai_citation:24‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  
- Frontend Sales UI **does not need** special inventory controls.

---

## 5. Constraints & Guardrails (for Frontend)

Frontend should respect these constraints (enforced by backend, but good to reflect):

- Waste and Correction **require notes**.  [oai_citation:25‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  
- Qty cannot be zero.
- Category deletion:
  - Block delete if items still assigned (strict mode), or confirm “move to Uncategorized” if safe-mode is implemented.  [oai_citation:26‡Inventory extended.pdf](sediment://file_0000000091187208af4e2c6e23387217)  
- Negative stock is allowed (the system doesn’t block sales), but flagged in Exceptions.  [oai_citation:27‡Inventory  (Capstone 1 – Journal-Only).pdf](sediment://file_00000000fe447208a9d6c04502a9b5bc)  

---

## 6. What Inventory is NOT in Capstone 1

Out of scope for frontend & backend now (but future-friendly):   

- No batch-level receiving UI (no separate “Receive Batch” screen).
- No FEFO (First Expiry First Out) or expiry enforcement.
- No Purchase Orders or supplier management.
- No inter-branch transfer UI.
- No stocktake sessions with counts & approvals.
- No multi-SKU recipes (one menu item → many ingredients).

The current design is **journal-only** with **simple categories** and is intentionally minimal so Capstone 1 remains achievable.

---

## 7. Summary for Frontend Developers

- Think in terms of:
  - **Stock Items** (master data)
  - **Branch Stock** (which items exist at each branch + thresholds)
  - **On-hand & Low-stock** views (computed, not editable)
  - **Journal-based movements** (Receive, Waste, Correction)
  - **Categories** (for organizing and filtering items)
  - **Exceptions** (negative stock & unmapped sales)

- Admin and Manager workflows are:
  1. Create stock items and categories.
  2. Assign items to branches and thresholds.
  3. Record receives, waste, and corrections.
  4. Monitor on-hand, low stock, and exceptions.

- Cashiers never directly touch inventory screens; their sales go through Sales module, which triggers inventory updates automatically when policy allows.

Use this document as context when building:
- Inventory screens in the Tenant Admin Portal / Branch Manager view.
- Inventory-related filters and reports.
- Menu → Stock mapping interface.