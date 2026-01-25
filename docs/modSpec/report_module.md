# Report Module

**Version:** 1.2  
**Status:** Locked (Capstone 1)  
**Module Type:** Feature Module  
**Depends on:**  
- Authentication & Authorization (Core)  
- Tenant & Branch Context (Core)  
- Policy & Configuration (Core) — branch-scoped resolution  
- Sale Module  
- Cash Session Module  
- Audit Logging (Core)

---

## 1. Purpose

The Report Module provides **accurate, auditable business insights** for administrators by aggregating operational data from sales and cash sessions.  
It ensures that **financial truth is preserved**, while clearly exposing provisional states such as pending voids without silently mutating historical records.

This module prioritizes:
- Accounting safety
- Operational transparency
- Auditability
- Clear separation between finalized and provisional data

---

## 2. Scope (Capstone 1)

Included:
- Branch-level sales summary reporting
- Branch-level item-level sales reporting
- Cash session (X / Z) reports
- Explicit handling of VOID_PENDING sales
- Branch-scoped policy interpretation for display only (when applicable)
- **Reporting remains accessible for frozen branches** (read-only history)

Excluded (Capstone 2+):
- Cross-branch aggregated reports (tenant-wide totals)
- Scheduled or automated reports
- Advanced analytics (trend, forecasting)
- Export automation (email, scheduled PDF)
- Real-time dashboards

---

## 3. Actors & Access Control

Access to reports is **restricted to Admin users only**.

- **Admin**
  - View reports for any branch within the tenant (including frozen branches)
  - View pending void exposure per branch
  - View X/Z cash session reports for a branch
- **Manager**
  - No reporting access in Capstone 1
- **Cashier**
  - No reporting access

---

## 4. Core Concepts

### 4.1 Final vs Provisional Data

Reports distinguish between:
- **Finalized data**: confirmed and immutable
- **Provisional data**: subject to approval or reversal

Pending voids are treated as **provisional** and are never silently excluded.

### 4.2 Branch-Scoped Policy vs Reporting Truth

Policies (VAT, FX, rounding, inventory behaviors) are **configured per branch**.

However, **reports must not recompute historical totals using “current policy”**.
- Sales reporting must aggregate **stored finalized amounts** (computed during sale finalization under the branch policy at that time).
- If UI formatting needs a branch context (e.g., showing “KHR rounding enabled”), the report UI may read the **branch policy** for display hints, but not to alter totals.

This prevents policy changes from retroactively changing financial history.

### 4.3 Frozen Branch Visibility (Read-Only History)

Branches may be **frozen** (inactive / billing-frozen / operationally disabled).  
Reporting must remain available for historical review:

- Frozen branches **must remain selectable in report filters**.
- Frozen branches must be clearly labeled (e.g., “Frozen” badge/status).
- Reports remain **read-only** and do not enable any operational actions.

---

## 5. Use Cases

### UC-1: View Sales Summary Report (Branch)

**Actor:** Admin  

**Preconditions:**
- User is authenticated as Admin
- Admin selects a branch context (**active or frozen**)
- At least one sale exists in that branch for the selected period (optional)

**Main Flow:**
1. Admin opens Sales Summary Report
2. Admin selects branch and date range
3. System aggregates sales by date (within the selected branch)
4. System displays:
   - Gross Sales (includes VOID_PENDING, excludes VOIDED)
   - Pending Void Amount (clearly labeled)
   - Confirmed Revenue (Gross − Pending Void)
5. If branch is frozen, system shows “Frozen” status label while rendering the same historical totals
6. Admin reviews totals

**Acceptance Criteria:**
- Pending voids are included but clearly marked
- Confirmed revenue excludes pending voids
- No historical data is mutated by pending states
- Aggregation is scoped to the selected branch
- **Frozen branch does not hide reporting history**
- **Frozen branch is visible and labeled in the reporting UI**

---

### UC-2: View Item-Level Sales Report (Branch)

**Actor:** Admin  

**Preconditions:**
- Admin selects a branch context (**active or frozen**)

**Main Flow:**
1. Admin selects Item Sales Report
2. Admin selects branch and period
3. System displays sold quantities per item
4. Items affected by pending voids are flagged
5. If branch is frozen, system shows “Frozen” status label

**Acceptance Criteria:**
- Item counts include pending voids
- Visual indicator warns that data includes provisional sales
- No silent exclusion of data
- Aggregation is scoped to the selected branch
- **Frozen branch remains selectable and labeled**

---

### UC-3: View Cash X Report (In-Session)

**Actor:** Admin  

**Preconditions:**
- An active cash session exists for the selected branch/session
- Branch may be active (**frozen branches are unlikely to have active sessions**, but if they do due to timing, the report is still viewable)

**Main Flow:**
1. Admin views X Report for an active session
2. System shows:
   - Opening float
   - Cash sales movements
   - Paid-in / paid-out
   - Expected cash
3. Report is marked as **non-final**

**Acceptance Criteria:**
- Report is clearly labeled “In Progress”
- Data updates live during the session

---

### UC-4: View Cash Z Report (Closed Session)

**Actor:** Admin  

**Preconditions:**
- Cash session is closed
- Branch may be active or frozen

**Main Flow:**
1. Admin opens Z Report
2. System displays:
   - Final cash totals
   - Counted cash
   - Variance
   - Session metadata

**Acceptance Criteria:**
- Z Report is immutable after generation
- Pending voids do not retroactively alter Z totals
- Corrections occur via explicit future movements/adjustments (if allowed)

---

### UC-5: View Pending Void Exposure (Branch)

**Actor:** Admin  

**Preconditions:**
- At least one sale is in VOID_PENDING state in the selected branch
- Branch may be active or frozen

**Main Flow:**
1. Admin views report summary for a branch
2. System highlights total value of pending voids
3. Admin understands financial exposure without data mutation

**Acceptance Criteria:**
- Pending void exposure is always visible
- Exposure does not change confirmed revenue totals
- Aggregation is scoped to the selected branch
- **Frozen branch does not hide pending-void exposure history**

---

## 6. Reporting Rules

- VOID_PENDING sales:
  - Included in reports
  - Clearly labeled as provisional
  - Excluded from confirmed revenue
- VOIDED sales:
  - Fully excluded from all totals
- Finalized monetary totals:
  - Must be aggregated from **stored finalized values**
  - Must not be recalculated from current branch policy
- Cash reports:
  - Never retroactively changed
  - Corrections occur through future movements only (subject to cash policy)
- Frozen branches:
  - Must remain visible/selectable in reporting filters
  - Must be labeled as frozen in UI
  - Do not block viewing historical reports

---

## 7. Non-Functional Requirements

- Reports must be:
  - Deterministic
  - Auditable
  - Role-restricted
- Performance must support:
  - Daily and monthly views
  - Branch-level aggregation
- All report access must be logged via Audit Module

---

## 8. Out of Scope (Explicit)

- Cross-branch totals (tenant-wide)
- Export automation
- Real-time analytics
- Manager-level reporting
- Financial forecasting

---

## 9. Design Rationale (Summary)

This module follows mature POS principles by:
- Separating operational state from accounting truth
- Avoiding retroactive mutation of financial records
- Making provisional risk visible instead of hidden
- Preserving reporting access even when branches are frozen

This ensures trust, auditability, and long-term system integrity.

---

## Audit Events Emitted

The following events MUST be written to the Audit Log when triggered (with tenant_id, branch_id where applicable, actor_id, and relevant entity IDs):

- `REPORT_VIEWED`
- `REPORT_EXPORTED`