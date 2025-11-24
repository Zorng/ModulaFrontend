## Inventory Unit Model Extension (Option B — pcs + leftover)

This section extends the existing Inventory frontend context.  
Backend stores all stock quantities in **base units** (ml, g, or pcs).  
Frontend displays quantities in a human-friendly format: **pcs + leftover base unit**.

---

### 1. Base Concept

Each stock item is defined with:

- **base_unit**:  
  - `ml` for liquids  
  - `g` for solids  
  - `pcs` for purely countable items  

- **piece_size** (integer):  
  - How many base units make up 1 “piece” of this item.  
  - Examples:  
    - Milk carton (1000ml) → `base_unit = ml`, `piece_size = 1000`  
    - Coffee beans bag (1000g) → `base_unit = g`, `piece_size = 1000`  
    - Cup → `base_unit = pcs`, `piece_size = 1`

Backend always stores `on_hand` as a **single integer in base units**.

Examples:
- 3 milk cartons + 600ml = `3600 ml`  
- 2 coffee bags + 400g = `2400 g`  
- 280 cups = `280 pcs`

---

### 2. Display Rules (List + Detail Views)

Frontend converts base unit values into:

- **pcs = on_hand // piece_size**  
- **remainder = on_hand % piece_size**

Display logic:

| Condition | UI Display |
|----------|------------|
| piece_size == 1 | `<on_hand> pcs` |
| pcs > 0 AND remainder > 0 | `X pcs + Y ml/g` |
| pcs > 0 AND remainder == 0 | `X pcs` |
| pcs == 0 AND remainder > 0 | `Y ml/g` |

Examples:

- Milk 1000ml carton, `on_hand = 3600` → **3 pcs + 600ml**  
- Coffee beans 1kg bag, `on_hand = 2400` → **2 pcs + 400g**  
- Tea base, `on_hand = 500ml` → **500ml**  
- Cups, `on_hand = 280` → **280 pcs**

---

### 3. Input for Receive / Waste / Correction

For items with `piece_size > 1`:

Show two input fields:
- **pcs** (integer)
- **extra** (ml/g)

Frontend converts to base unit:
base_qty = pcs * piece_size + extra
API always receives **base_qty** only.

Examples:
- Receive 5 pcs + 200ml → send `5200 ml`
- Waste 1 pc → send `1000 ml`
- Correct +300ml → send `300 ml`

For items with `piece_size == 1`:

- Show a single **pcs** field
- Send as-is (`base_qty = pcs`)

---

### 4. Sales Deduction Behavior (Frontend View)

Menu items define their inventory usage as `qty_per_sale` in **base units**.

Examples:
- Hot latte uses **100ml** milk  
- Large latte uses **150ml** milk  

When a sale finalizes:
- Sales module triggers inventory deduction in **base units**
- Frontend does no conversions for sales
- Frontend simply refreshes stock when needed

---

### 5. Aggregated “All Branches” View (Admin Only)

When showing stock across all branches:

1. Backend returns total in base units (sum of each branch)
2. Frontend applies pcs + leftover logic

Example (Milk 1000ml carton):

- Branch A: 3600ml  
- Branch B: 1800ml  
- Branch C: 500ml  
- Total = **5900 ml**  
- UI: **5 pcs + 900ml**

(Optional) Item detail may show per-branch breakdown.

---

### 6. Implementation Notes (Frontend)

Helper (example):

```dart
class StockQuantityDisplay {
  final int baseQty;   // e.g. 3600
  final int pieceSize; // e.g. 1000

  int get pcs => baseQty ~/ pieceSize;
  int get remainder => baseQty % pieceSize;

  String format(String unit) {
    if (pieceSize == 1) return '$baseQty pcs';
    if (pcs > 0 && remainder > 0) return '$pcs pcs + $remainder $unit';
    if (pcs > 0) return '$pcs pcs';
    return '$remainder $unit';
  }
}
//Conversion for inputs:

int toBaseQty(int pcs, int extra, int pieceSize) {
  return pcs * pieceSize + extra;
}
```

### 7. UX Notes
- Staff think in pcs, recipes consume ml/g.
- This system keeps backend simple and frontend intuitive.
- Works consistently for all inventory types (liquids, solids, pcs).
- No batch tracking or expiry enforcement in Capstone 1.