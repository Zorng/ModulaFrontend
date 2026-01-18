# Cash Session & Reconciliation Module (Feature Module)

**Version:** 1.5  
**Status:** Patched (Branch system-provisioning alignment)  
**Module Type:** Feature Module  
**Depends on:** Auth & Authorization (Core), Tenant & Branch Context (Core), Policy & Configuration (Core), Audit Logging (Core), Sync & Offline Support (Core)  
**Related Modules:** Sale (cash tender), Reporting (X/Z), Staff Attendance (independent), Branch Management (Core concept; system-provisioned branches)

---

## Purpose

The Cash Session module ensures **cash integrity per shift** by tracking:
- opening float → cash movements (cash sales, paid out, refunds, adjustments) → closing count → variance

It provides operational control via:
- **X Report** (in-session snapshot)
- **Z Report** (final session close report)

Cash Session is **not an attendance mechanism** and is **not shift-gated**. Shift rules belong to the Staff Attendance module.

---

## Scope (Capstone I)

Included:
- Start/Open cash session (opening float)
- End/Close cash session (counted cash, variance)
- Policy-controlled cash movements:
  - Cash Sale tender attachment (system)
  - Paid Out (on/off)
  - Cash Refund approval (on/off)
  - Manual Cash Adjustment (on/off)
- X / Z reporting
- Offline-first staging + sync
- Audit logging for all actions
- **Force-close** by Manager/Admin (no takeover)

Excluded (Future Work):
- Register/device-owned sessions
- Cash drawer hardware control
- Multiple terminals linked to one drawer/hardware hub
- Safe drop / cash lift workflows
- Automated anomaly detection

---

## Key Concepts

- **Branch (System-Provisioned):** Branches are created by the system when a tenant is provisioned (e.g., initial subscription creates tenant + first branch; adding branches via subscription creates additional branches).  
  - Users **cannot** create branches manually in Capstone I.  
  - Cash Sessions always operate within an existing **branch context**.
- **Cash Session:** A time-bounded record representing cash handling for a branch shift by a user (Capstone I).
- **Cash Movements:** Append-only entries affecting expected cash.
- **Force Close:** Manager/Admin closes an active session when the opener cannot (e.g., left, forgot, device lost), without editing history.

---

## Session Ownership Model

### Capstone I (Current)
- Sessions are **owned by user context** (who opened it).
- Intended for **phone/tablet/web usage** where the business may not have dedicated hardware.

### Future Work (Hardware Integration)
- Introduce **register/device/hardware hub** concepts.
- Sessions become **register-owned** when a cash drawer or dedicated terminal exists.

> This spec intentionally keeps the Capstone I model simple while leaving space for future register-based evolution.

---

## Policy Scope Clarification

All cash-session-related policies are **branch-scoped**.

That means:
- Policy values are resolved using **(tenant_id, branch_id)**.
- Two branches under the same tenant may legally have different cash-session rules (e.g., Branch A requires session for sales, Branch B does not).

The policy keys remain the same (see “Policies Used”), but **their values must be fetched for the active branch**.

---

## Use Cases

### UC-1: Start Cash Session (Open)

**Actors:** Cashier, Manager, Admin

**Preconditions:**
- User is authenticated
- **Branch context is resolved** (branch exists and is accessible to the actor)
- Branch is **ACTIVE** (not frozen/suspended)
- No active cash session exists for the user at this branch (per current scope rules)

**Main Flow:**
1. User navigates to Sale or taps “Start Cash Session”.
2. System prompts for opening float (USD/KHR).
3. User confirms.
4. System creates an OPEN cash session.
5. Audit log records session opened.

**Postconditions:**
- An OPEN cash session exists and is active for the user at the branch.

---

### UC-2: Continue Active Cash Session

**Actors:** Cashier, Manager, Admin

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE
- An OPEN cash session exists for the user at the branch

**Main Flow:**
1. User opens Sale.
2. System attaches eligible cash activity to the active session.

**Postconditions:**
- No state change.

---

### UC-3: Record Cash Tender From Sale (System)

**Actors:** System (triggered by Sale module)

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE
- Sale finalized with payment method = Cash
- **Branch-scoped policy** `cashRequireSessionForSales = true` implies:
  - An OPEN cash session must exist for that user at that branch

**Main Flow:**
1. Sale finalizes with cash tender.
2. System records a CASH_SALE movement linked to the sale.
3. Expected cash increases.

**Postconditions:**
- Session expected cash updated.
- Movement visible in X/Z reports.
- Audit log records cash tender attachment.

**Error Flow:**
- If `cashRequireSessionForSales = true` for this branch and no session exists → Sale checkout is blocked (Sale module behavior).

---

### UC-4: Cash Paid In (Optional Capability)

**Actors:** Cashier (if allowed by role rules), Manager, Admin

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE
- Session is OPEN

**Main Flow:**
1. User selects “Add Cash / Paid In”.
2. Inputs amount (USD or KHR) and reason.
3. System records PAID_IN movement.

**Postconditions:**
- Expected cash increases.
- Action is audit logged.

> Note: There is **no** backend policy key for “allow paid in” in the current policy schema. If you want it policy-controlled later, it must be added explicitly (and would be branch-scoped).

---

### UC-5: Paid Out

**Actors:** Cashier (if allowed), Manager, Admin

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE
- Session OPEN
- **Branch-scoped policy** `cashAllowPaidOut = true`

**Main Flow:**
1. User selects “Paid Out”.
2. Inputs amount and reason.
3. System records PAID_OUT movement.

**Postconditions:**
- Expected cash decreases.
- Action is audit logged.

---

### UC-6: Cash Refund (Approval-Controlled)

**Actors:** Manager, Admin

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE
- Session OPEN
- **Branch-scoped policy** `cashRequireRefundApproval = true`
- A refund/void approval exists (triggered by void/refund flow)

**Main Flow:**
1. Manager/Admin reviews refund/void approval request.
2. Approves or rejects.
3. If approved:
   - System records REFUND_CASH movement linked to sale.
   - Expected cash decreases.

**Postconditions:**
- Refund decision is recorded and auditable.
- No editing of past cash sale movements.

---

### UC-7: Manual Cash Adjustment

**Actors:** Manager, Admin

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE
- Session OPEN
- **Branch-scoped policy** `cashAllowManualAdjustment = true`

**Main Flow:**
1. Actor inputs adjustment (+/-) and reason.
2. System records ADJUSTMENT movement.

**Postconditions:**
- Expected cash updated.
- Action is audit logged.

---

### UC-8: Close Cash Session (Normal Close)

**Actors:** Cashier, Manager, Admin

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE
- Session OPEN
- Actor has permission to close their session

**Main Flow:**
1. Actor taps “Close Session”.
2. Inputs counted cash (USD/KHR).
3. System computes expected cash and variance.
4. Session marked CLOSED.
5. Z report generated.

**Postconditions:**
- Session status = CLOSED
- Variance stored
- Z report available
- Action is audit logged

**Notes:**
- System does not auto-close sessions.
- Shift timing does not gate closing.

---

### UC-9: Force Close Cash Session (Manager/Admin Only)

**Actors:** Manager, Admin

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE
- A session exists in OPEN state (opened by another user or abandoned)
- Manager/Admin is authorized in branch scope

**Main Flow:**
1. Manager/Admin selects the OPEN session.
2. System requires a force-close reason (required) and optional note.
3. Manager/Admin inputs counted cash (or marks “not counted” if supported).
4. System closes the session as FORCE_CLOSED (or CLOSED with `closure_type`).
5. System computes variance.
6. Audit log records force-close action.

**Postconditions:**
- Session is no longer OPEN.
- Closure is traceable (who, when, why).
- Z report available (with force-close flag).

**Key Rule:**
- Force-close does **not** edit any prior movements or timestamps. It is an operational override only.

---

### UC-10: View X Report

**Actors:** Cashier, Manager, Admin

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE
- Session OPEN

**Main Flow:**
1. Actor opens X report.
2. System shows opening float, movement totals, expected cash.

**Postconditions:**
- Read-only.

---

### UC-11: View Z Report

**Actors:** Cashier, Manager, Admin

**Preconditions:**
- Branch context is resolved
- Branch is ACTIVE (or recently frozen; read-only access still allowed if tenant rules permit)
- Session CLOSED / FORCE_CLOSED

**Main Flow:**
1. Actor opens Z report.
2. System shows final totals, counted cash, variance, closure metadata.

**Postconditions:**
- Read-only.

---

### UC-12: Offline Operation & Sync

**Actors:** System

**Preconditions:**
- Network unavailable or unstable
- Branch context is known locally (cached)

**Main Flow:**
1. Open/close and movements can be staged locally.
2. On reconnect, system syncs idempotently.
3. Conflicts resolve by server truth, with clear user feedback.

**Postconditions:**
- No duplicate sessions/movements.
- Totals remain consistent.

---

## Policies Used (Read-only from Policy Module)

All policy keys below must match the backend schema exactly.  
**Policy values are resolved per (tenant_id, branch_id).**

- `cashRequireSessionForSales` (boolean)
- `cashAllowPaidOut` (boolean)
- `cashRequireRefundApproval` (boolean)
- `cashAllowManualAdjustment` (boolean)

> No shift policy is enforced here. Shift enforcement belongs to Staff Attendance.

---

## Requirements

- R1: Sessions operate only within an existing, system-provisioned branch (no user-created branches in Capstone I)
- R2: Only one OPEN session per user per branch (Capstone I model)
- R3: Cash sales must attach to an OPEN session when policy requires it (`cashRequireSessionForSales`) for that branch
- R4: Movements are append-only; no edits or deletes
- R5: Managers/Admins can force-close sessions with required reason
- R6: X/Z reports must reflect movements and variance
- R7: Offline-first with idempotent sync
- R8: All actions logged via Audit Logging
- R9: Branch frozen/suspended blocks creating/updating sessions and movements (read-only access may remain)

---

## Acceptance Criteria

- AC1: User can open a session with opening float in an ACTIVE branch.
- AC2: Cash sale increases expected cash via recorded movement.
- AC3: User can close session and system computes variance.
- AC4: Manager/Admin can force-close an abandoned session; reason is required.
- AC5: No role can edit historical movement amounts or timestamps.
- AC6: X report works during open session; Z report works after close.
- AC7: Offline-staged actions sync without duplication.
- AC8: If branch is frozen, session creation/movements are blocked.

---

## Audit Events Emitted

The following events MUST be written to the Audit Log when triggered (with tenant_id, branch_id where applicable, actor_id, and relevant entity IDs):

- `CASH_SESSION_OPENED`
- `CASH_SESSION_CLOSED`
- `CASH_SESSION_FORCE_CLOSED`
- `CASH_MOVEMENT_RECORDED`
- `CASH_TENDER_ATTACHED_TO_SALE`
- `CASH_REFUND_APPROVED`
- `CASH_REFUND_REJECTED`