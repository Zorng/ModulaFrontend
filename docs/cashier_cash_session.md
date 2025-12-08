Cash Session & Reconciliation Module – Frontend Development Context (Capstone 1)

This document defines how the Cash Session & Reconciliation module should behave from a frontend / UX perspective.
The backend supports per-register sessions, cash movements, manager takeovers, variance calculations, and reporting.
Frontend must ensure smooth cashier workflow, strict audit behavior, and clear per-register state.

1. Concept & Mental Model
1.1 What Cash Session Does (UI Perspective)

This module:

Manages per-register cash sessions (one session per register at a time).

Requires cashiers to open a session before accepting cash sales.

Tracks:

Opening float

Cash sales

Refunds

Paid Ins

Paid Outs

Adjustments (if enabled)

Helps users close sessions with counted cash.

Computes expected vs counted → variance.

Provides X (live) and Z (closure) reports.

Supports Manager Take Over if a previous session was left open.

The frontend must always show the current session state per register and guide the cashier through correct flows.

2. Roles & What They Can Do (UI)
Admin

Manage any register for any branch

Start/close/take over sessions

Approve/refuse large Paid Outs or refunds

View all reports (X, Z, daily summaries)

Record adjustments (if enabled)

Export summaries

Manager

Manage sessions within assigned branch

Start/close/take over sessions

Approve Paid Outs over limit

Approve refunds

View reports

Cashier

Start own session

Perform Paid In / Paid Out (within limit)

Close their session

Cannot approve over-limit Paid Outs

Cannot approve refunds

Cannot view sessions from other registers

System

Auto-assign cash sales and refunds to active session

Auto-compute expected cash values

3. Main Screens (Frontend)
3.1 Cashier Home / Register Dashboard

Shows the register status:

Register name

Session status (Open / Closed)

Actor (who opened it)

Opening float (USD/KHR)

Live expected cash amounts

Buttons:

Start Session (if none open)

Sale

Paid In

Paid Out

X Report

Close Session

Depending on role:

Cashiers see only their register

Managers/Admins can switch registers (branch scope)

3.2 Start Session Modal

Triggered when:

Cashier taps “Sale” with no open session

Cashier selects register directly

Fields:

Opening float USD

Opening float KHR

Optional note

Actions:

Start Session

Behavior:

After session starts → redirect to Sale screen

Activity log event: CASH_SESSION_OPENED

3.3 Manager Take Over Flow

Triggered when a new user opens the register and an existing session is still open.

UI Prompt:

“Previous session left open by [Name]. Enter reason to take over.”

Fields:

Reason (required)

Actions:

Take Over Session

Flow:

Manager submits reason

Backend auto-closes old session

Opens new session for Manager

Activity: CASH_SESSION_TAKEN_OVER

3.4 Cash Movements (Paid In / Paid Out / Adjustment)
Movement Types

Paid In (Cash added)

Paid Out (Petty cash)

Adjustment (if enabled by policy; off for Capstone 1)

All movements require:

Amount (USD or KHR)

Reason (3–120 chars)

Paid Out Over Limit

If cashier exceeds limit:

Show modal:

“Manager approval required”

Manager inputs PIN/password or approval action

Movement marked PENDING or APPROVED

UI Placement

Buttons visible only when session is OPEN.

3.5 Close Session Flow

Accessed from:

Dashboard

Auto-reminders

Fields:

Counted cash (USD & KHR)

Optional note

System shows:

Expected cash

Variance (auto-calculated)

Possible statuses:

CLOSED

PENDING_REVIEW (needs manager review)

Actions:

Submit closure

Activity: CASH_SESSION_CLOSED

After closing:

Show Z Report summary screen.
![alt text](image.png)
3.6 Gentle Shift Reminder (Optional UX)

After shift end:

“Your shift ended at 18:00. Close the register when you're done.”

Buttons:

Close Now

Remind Later

(Not a hard blocker.)

3.7 Reports (Internal Only)
X Report (Live Summary)

Available while session is OPEN.

Displays:

Opening float

Cash sales

Refunds

Paid In / Paid Out

Expected cash (USD/KHR)

No counted cash (not closed yet)

Z Report (Closure Summary)

After session closes:

Opening float

All cash movements

Variance

Closed by + timestamp

Actor breakdown (per user)

Daily Cash Summary

Admin/Manager view:

All registers for branch

All Z reports

Total cash in/out

Variances

4. Register Selection Behavior

Cashiers typically see one assigned register.

Managers/Admins can select from a list:

Name

Branch

Status (Open/Closed)

Active session owner

If a register has an OPEN session under a different user → show Take Over prompt.

5. API Integration (Frontend View)
Sessions
POST   /cash-sessions/start
POST   /cash-sessions/take-over
POST   /cash-sessions/close
GET    /cash-sessions/current?register_id=

Movements (Paid In/Out/Adjustments)
POST /cash-movements/paid-in
POST /cash-movements/paid-out
POST /cash-movements/adjustment

Reports
GET /cash-sessions/{id}/x-report
GET /cash-sessions/{id}/z-report
GET /cash-reports/daily?branch_id=&date=

Register Info
GET /cash-registers?branch_id=

System Behavior

Frontend must not compute:

Expected cash

Variance

Approval logic

All logic comes from backend.

6. Frontend Guardrails

The UI should enforce and visualize:

Single OPEN session per register

Never show multiple active sessions

Always prompt for Take Over if needed

Required inputs

Movement reasons (3–120 chars)

Opening floats cannot be negative

Counted cash cannot be negative

Policy-dependent behavior

Require open session for cash sales (default ON)

Manager approval for:

Over-limit Paid Out

Cash refunds

Adjustments (if enabled)

Variance visibility

Show variance clearly at closure

Highlight if out of expected bounds

Offline mode

Queue movements and session operations in IndexedDB

Prevent duplicate submission on sync

Handle server-detected duplicates gracefully

7. UI/UX Components
Session Components

SessionStatusPill

StartSessionModal

TakeOverSessionModal

CloseSessionForm

ShiftReminderBanner

Movement Components

PaidInForm

PaidOutForm

RefundApprovalDialog

ReasonInputModal

Report Components

XReportCard

ZReportScreen

DailyCashSummaryTable

Register Components

RegisterSelector

RegisterStatusCard

8. Out of Scope (Capstone 1)

These features are explicitly not expected in the frontend now:

Cash drawer hardware integration

Multiple concurrent sessions per register

Partial handovers

Auto anomaly detection

Photo receipts for cash movements

Multi-step approval chains

9. Summary for Frontend Developers

This module requires tight UX design focused on:

Cashier speed (fast actions)

Manager oversight (takeovers & approvals)

Accuracy (expected vs counted cash)

Audit trail consistency

Most important frontend workflows:

Start Session → Sell → Close Session

Manager Take Over for abandoned sessions

Paid In / Paid Out with policy rules

Daily summaries for admin/manager reporting

This module ensures all branches maintain proper cash-handling integrity with minimal friction on the checkout flow.