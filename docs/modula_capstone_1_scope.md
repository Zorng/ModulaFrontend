# Modula – Capstone Phase 1 Scope

This document defines the complete functional and non-functional scope of **Modula Capstone Phase 1**, focusing on delivering a fully functional F&B POS system with modular architecture and essential operational features.

---

# 1. Objective of Capstone Phase 1
Build the **core Modula POS Service** for single-branch and multi-branch F&B businesses, including:
- Sales operations
- Menu & category management
- Basic inventory management
- Ingredient mapping
- Sale deduction logic (configurable)
- Reporting (sales + basic inventory)
- Activity logs
- Cash session & reconciliation
- Multi-branch module
- Basic staff attendance module

The goal is to deliver a **working POS prototype** that demonstrates Modula’s modular design, multi-role access, and real business workflows.

---

# 2. Deliverable: Modula POS (Phase 1)
A fully functional, web-based POS service usable on mobile phones, tablets, and computers.

## **2.1 Modules included in Phase 1**
### **A. Sales Module**
- Fast item selection
- Auto-draft sale on item tap
- Apply VAT policy (if enabled)
- Apply discount policy (from Store Policy module)
- Sale type selection: *Takeaway, Dine-in, Delivery*
- Multi-currency display: USD + KHR
- Rounding policy for KHR cash payments
- eReceipt generation + view
- Order lifecycle: draft → pre-checkout → checkout → in-prep → complete
- Sale void (admin/manager)

### **B. Menu & Category Module**
- Create categories (max 8)
- Create items (max 75)
- Add modifiers: sugar, ice, size, toppings
- Price rules: per-item & per-modifier
- Ingredient mapping (via Inventory module)
- Auto-apply branch-specific discount policy

### **C. Inventory Module**
- Create stock items
- Categorize stock items
- Track quantity in each branch
- Restock journal entries
- Ingredient deduction per sale (if policy enabled)
- Expiry date tracking via batch-level restocks

### **D. Reporting Module**
- Sales reports (daily, monthly, item ranking)
- Inventory reports (stock quantity, usage, expiry)
- Cash reports via Z/X reports (from Cash Session)

### **E. Activity Log Module**
Records essential actions for transparency and audit:
- Sale created / voided
- Session opened / closed
- Paid-in / paid-out
- Inventory restocked
- Menu item created/updated
- Attendance check-in/out

### **F. Cash Session & Reconciliation Module**
- Cashier must start session before selling
- Opening float
- Auto-capture cash tenders
- Manual movements: Paid-in, Paid-out
- Session close with counted vs expected
- Variance calculation
- X-report, Z-report generation

### **G. Multi-branch Module (Growth Add-on)**
- Create & manage multiple branches
- Per-branch menu, inventory, and sales segregation
- Admin can view all branches
- Staff assigned to specific branches
- Branch-level reporting

### **H. Staff Attendance (Basic)**
- Fixed shifts per branch
- Manual check-in/check-out within shift time
- Guard-rails for early/late check-in
- Auto-attendance generation from cash session (if policy is on)
- Manager can override attendance within their branch

---

# 3. Authentication & Authorization Module (Phase 1)
Modula includes a complete authentication and authorization module as part of Phase 1, providing secure access control and user onboarding.

## **3.1 Authentication**
- Login using **phone number + password** (secure, simple, no SMS cost)
- Password hashing using bcrypt
- Password reset handled manually by Admin (Phase 1)

## **3.2 User Types**
- **Admin** (tenant owner)
- **Manager** (branch-level supervisor)
- **Cashier** (frontline staff)

## **3.3 Staff Onboarding Flow**
Admins can create staff accounts with:
- First name, last name
- Phone number (used as username)
- Role (Manager or Cashier)
- Assigned branch

Admin can set or reset staff passwords.

## **3.4 Role-Based Access Control (RBAC)**
### **Admin**
- Full tenant access
- Manage branches, menu, inventory
- Manage staff
- Override attendance
- View all reports & logs

### **Manager**
- Manage staff in assigned branch
- Approve paid-out and session close (per policy)
- Approve attendance corrections
- View branch-level reports
- Perform sales

### **Cashier**
- Operate POS in assigned branch
- Open/close cash sessions
- Perform sales
- View X-report

## **3.5 Enforcement**
RBAC enforced by tenant, role, and branch ID on every backend route.

---

# 4. Deliverable: Minimal Backend Infrastructure
- Modular backend structure using Node.js + TypeScript
- PostgreSQL schema for all Phase 1 modules
- Basic migration runner
- Clean repository structure (platform + modules)
- Capability-based config system for roles
- Role-based access control (Admin / Manager / Cashier)

---

# 5. Out of Scope (Phase 2+)
The following will *not* be developed in Phase 1:

- Public website for subscription purchase
- Provider dashboard (tenant management)
- Automated subscription & billing system
- Hardware integration (thermal printers, barcode scanners, drawers)
- GPS verification for attendance
- Automated anomaly detection
- Offline-first PWA & IndexedDB sync layer
- Advanced reporting dashboards

---

# 5. Definition of Done for Phase 1
- All functional modules implemented
- All modules integrated and usable via shared UI
- Database schema stable and migration system working
- End-to-end sales flow fully operational
- Multi-branch and attendance modules functional
- Manual tests for all flows completed
- Basic mobile-first UX ready
- Ready for demonstration & evaluation

---
This document defines the complete scope of Modula Capstone Phase 1. Future documents will detail UX flows, module data models, and frontend architecture.

