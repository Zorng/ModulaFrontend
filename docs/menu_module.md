# Menu & Category Module – Frontend Context (Capstone 1)

This document provides a **frontend-focused interpretation** of the Menu & Category module.  
It is meant for Flutter developers and AI coding assistants (VS Code Codex/GPT), so they can implement UI, state management, and flows consistent with backend rules.

Backend rules, quotas, and data models come from:  
- “Menu & Category Management (Phase 1)” :contentReference[oaicite:2]{index=2}  
- “Menu & Category – Revised Extended Spec” :contentReference[oaicite:3]{index=3}  

The frontend does **not** enforce deep validation logic; backend does.  
Frontend ensures **correct UX** aligned with Modula’s product vision.

---

# 1. Mental Model

The **Menu** is the tenant’s catalog of:
- Categories  
- Menu items  
- Modifier groups (sugar, ice, toppings)  
- Modifier options (Normal, Less Sugar, etc.)  
- Optional inventory mapping (item ↔ stock item)

The **Menu is global** to the tenant.  
Branches can have:
- Per-branch visibility (available/unavailable)  
- Per-branch item order  
- Optional custom pricing (if the Admin enables that capability)

The cashier sees a **branch-filtered snapshot** of the menu, cached offline.

---

# 2. Roles (Frontend Behavior)

### **Admin (Tenant-level)**
Can manage everything:
- CRUD categories
- CRUD menu items
- Upload item images (max 300KB JPEG/WEBP)  
- Attach modifiers to items  
- Create/edit modifier groups + options  
- Set price in USD  
- Set item visibility per branch  
- Branch-level item reorder  
- Set inventory mapping (1 stock item + qty_per_sale) ✦ :contentReference[oaicite:4]{index=4}  

### **Manager (Branch-level)**
Depending on capability:
- View category & item list for their branch  
- Toggle availability (if allowed)  
- Reorder items for their branch  
- Cannot create/delete items or categories  
- Cannot upload images  
- Cannot change modifiers  
- Cannot change inventory mapping

### **Cashier**
- Read-only  
- Uses menu in Sales  
- Sees modifiers when adding an item  
- Sees discount flags if Discount module marks items as discounted  
- Must work offline with cached menu

---

# 3. Screens to Build

## 3.1 Menu Home (Admin Portal)

Tabs/sections:

- **Categories**
- **Menu Items**
- **Modifiers**
- **Branch Menu** (optional depending on capability)

Counts should be shown with quotas:
- Categories: `7 / 8` (soft limit 8, hard limit 12)  
- Items: `70 / 75` (soft limit 75, hard limit 120)  

Backend enforces caps; frontend shows warnings.

---

# 4. Category UI

### 4.1 Category List
Columns / info:
- Name  
- Active toggle  
- Display order  
- (Optional) number of items inside it  

### 4.2 Create/Edit Form
Fields based on spec: :contentReference[oaicite:5]{index=5}  
- Name (required)  
- Optional description  
- Active toggle  
- Display order (or drag handle in list)

Frontend behaviors:
- Prevent user from exceeding category limits (show warning from backend)
- When deactivating, items still remain but become invisible in POS

---

# 5. Menu Item UI

### 5.1 Items List
Columns/cards:
- Item image thumbnail  
- Item name  
- Category pill  
- Base price (USD)  
- Active toggle  
- “Inventory linked” icon (if mapped)  
- “Discounted” badge (if discount module marks it so)

Filters:
- Category filter  
- Active / inactive filter  
- Search by name  

### 5.2 Create/Edit Item Form
Backend required fields:  


**Basic Info**
- Name  
- Category  
- Price USD (numeric)  
- Description (optional)  
- Image upload (JPEG/WEBP ≤ 300KB)  
- Active toggle  

**Modifiers section**
- Multi-select reusable modifier groups  
- Show limits:
  - ≤ 5 groups per item  
  - ≤ 12 options per group  
  - ≤ 30 options total across all groups  

**Inventory mapping section** (from extended spec) :contentReference[oaicite:7]{index=7}  
- Stock item dropdown  
- qty_per_sale (number > 0 if mapped)  
- Info text:
  > When a sale finalizes, inventory deducts automatically if policy is enabled.

**Branch assignment section**
- Select which branches show this item  
- Default: all branches checked  
- Branch list with availability toggles  

---

# 6. Modifier UI

Modifer groups are global to tenant.

### 6.1 Modifier Group List
Each row:
- Name (“Sugar Level”)  
- Type (single/multi)  
- Options count (e.g., 4 options)  
- Active toggle  

### 6.2 Create/Edit Modifier Group
Fields:
- Name  
- Selection type (single / multi)  
- A list of options:
  - label (string)
  - price delta (USD)
  - is_default (checkbox)

Constraints (UI hint; backend enforced) :contentReference[oaicite:8]{index=8}  
- ≤ 12 options per group  
- Total options across all groups attached to an item ≤ 30  
- ≤ 5 groups per item

---

# 7. Branch Menu UI (Optional Capability)

Based on spec: per-branch ordering and availability. :contentReference[oaicite:9]{index=9}  

### Screen:
- Branch selector  
- Display categories in correct order  
- Within each category:
  - Items with toggles:
    - Available / unavailable
  - Drag handle to reorder
- Optional: custom price input per item (if capability enabled)

This allows branch-level customization without altering global data.

---

# 8. Offline Behavior (Cashier)

Cashier uses **cached menu snapshot** (IndexedDB or local DB):

- On login or sync:
  - Pull full snapshot:
    - categories  
    - items  
    - modifiers  
    - branch availability  
    - display order  
- Cache it  
- When offline:
  - Normal browsing of menu works  
  - Adding items with modifiers works  
- When online again:
  - Delta sync updates local cache

This is directly from spec (“Offline Menu Access”). :contentReference[oaicite:10]{index=10}  

---

# 9. Sales Integration (Frontend Impact)

### 9.1 When cashier taps a menu item
- If item has modifiers:
  - Show modifier selection flow:
    - Single-select groups: radio buttons
    - Multi-select groups: checkboxes
    - Display price deltas visibly
- If no modifiers:
  - Add directly to cart

### 9.2 Line item pricing
Order:
1. base price  
2. + modifier price deltas  
3. (apply discounts — handled by Sale module)  
4. (apply VAT — handled by Policy)  
5. (apply rounding — handled by Policy)

Modifiers **do not** affect inventory in Capstone 1.  
Only `qty_per_sale` mapping triggers inventory deduction.

---

# 10. Guardrails (UI-level)

Frontend should:

- Validate image type/size before uploading (≤300KB).  
- Disable buttons temporarily when hitting soft/hard limits; show error message from backend.  
- Prevent editing category of inactive item unless reactivated.  
- Make it very clear that **deactivating** ≠ deleting (item stays in DB for reporting).  
- Focus on mobile-first layouts for cashiers.

---

# 11. UX Scenarios (Designer Reference)

### Scenario A — Cold Drink with Sugar + Ice  
(Core flow from spec) :contentReference[oaicite:11]{index=11}  
Admin sets up:
- Category “Coffee (Cold)”  
- Modifiers Sugar Level + Ice Level  
- Items: Iced Latte, Iced Americano  

Cashier sees:
> Coffee (Cold) → Iced Latte  
→ Sugar Level + Ice Level selection  

### Scenario B — Bubble Milk Tea  
(Extended spec) :contentReference[oaicite:12]{index=12}  

Admin:
- Category: Milk Tea  
- Modifiers: Sugar, Ice, Toppings (multi-select w/ price deltas)  
- Item: Bubble Milk Tea  

Cashier sees:
> Sugar Level (single)  
> Ice Level (single)  
> Toppings (multi: +0.30, +0.40, etc.)  

---

# 12. Summary for Frontend Developers

- The Menu module is **global catalog management**.  
- Branch behavior is a **view/filter layer** on top of it.  
- Admin manages everything; Manager has limited rights; Cashier is read-only.  
- Offline-readiness is mandatory for Cashier UI.  
- Modifiers determine the **configuration flow** when adding items in Sales.  
- Inventory mapping is **optional** but must be supported in item edit UI.  
- Quotas should be displayed clearly and enforced with backend error messages.

Use this document as **foundation** when implementing catalog screens, modifier pickers, offline menu cache, and branch-level views.

