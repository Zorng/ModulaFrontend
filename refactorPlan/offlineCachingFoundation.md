# Offline Caching Foundation Plan

Implementation progress now lives in:
- [offlineCachingImplementationTracker.md](/Users/mac/flutterProjects/modular/refactorPlan/offlineCachingImplementationTracker.md)

Goal: implement the **local read-cache foundation** required for offline-first support and better perceived performance, before building the offline command queue and sync replay layer.

## Why this comes first

Current frontend status:
- limited local persistence exists:
  - auth session snapshot
  - idempotency key records
  - printer preferences
  - sale cart recovery / receipt cache
- there is **no dedicated cached read model** for feature data
- there is **no sync checkpoint state**
- there is **no offline command queue**

Backend now supports:
- `POST /v0/sync/pull` for canonical read-model hydration/convergence
- `POST /v0/sync/push` for a limited set of replay-safe writes

Without a local cached read model, the app cannot:
- render useful state while offline
- converge read state correctly after reconnect
- benefit fully from pull-sync
- reduce perceived latency on staging/slow networks

So the correct frontend order is:
1. local read cache
2. sync checkpoint state
3. offline command queue
4. feature-by-feature offline rollout

---

## Scope lock

### In scope now
- local read-cache architecture
- sync checkpoint/cursor storage
- context partitioning rules
- first module rollout for read caching
- UI integration rule: cache-first render, background refresh second

### Explicitly out of scope for this plan
- offline command queue implementation
- `/v0/sync/push` replay engine
- KHQR offline behavior
- sale finalize offline replay
- notifications / SSE

---

## Product and architecture assumptions (locked)

1. Server remains source of truth.
2. `sync/pull` is the canonical convergence lane for local read state.
3. The frontend should render **local cached data first**, then refresh in background.
4. Cached data must be partitioned by working context:
   - tenant
   - branch
   - account where relevant
5. Features must not own their own ad-hoc storage engines.
6. A shared local storage layer must exist before multiple features start caching independently.

---

## Target architecture

### 1. Local read store
A local persisted read model per module, keyed by context.

Stored concepts:
- entities / records
- metadata
- last updated timestamps
- cache freshness metadata

Context partition examples:
- tenant-scoped:
  - menu
  - inventory
  - policy
- branch-scoped:
  - cash session
  - attendance
  - shift
- account-scoped:
  - auth-adjacent personal state if needed later

### 2. Sync checkpoint store
Persist latest pull cursor/checkpoint per:
- device
- tenant
- branch
- module-scope set

### 3. Read-sync orchestrator
A shared client service that:
- runs bootstrap pull
- runs incremental pull
- writes pull results into local read stores
- updates checkpoints
- exposes refresh status to the UI layer

### 4. Cache-first feature stores
Feature stores/controllers should move toward:
- load local cached state first
- then trigger background pull or direct refresh
- update UI through loading/error/data without blanking useful cached state

---

## Cache strategy by data shape (locked)

There is no single cache shape that fits every module. Strategy should depend on:
- data size
- relationship complexity
- update frequency
- stale-data tolerance
- whether the domain behaves like:
  - a single configuration document
  - a normalized entity graph
  - a historical/journaled list

### 1. Snapshot cache
Use for small, low-relationship, low-query-complexity module state.

Characteristics:
- one serialized object or bundle per context
- fast to load
- simple to invalidate
- not ideal for partial updates or heavy querying

Recommended modules:
- `policy`
- current active `cashSession` overview state

### 2. Normalized entity cache
Use for modules with lists, relations, filtering, or incremental updates.

Characteristics:
- records stored by id
- relations/indexes stored separately
- supports partial sync application better
- stronger long-term fit for pull-sync convergence

Recommended modules:
- `menu`
- `shift`
- `inventory` (later rollout)
- `saleOrder` read model (later rollout)

### 3. Append/list or journal-style cache
Use for operational history and event-like records.

Characteristics:
- newest-first lists or append-style record storage
- often needs secondary indexes for filtering/pagination
- pairs well with operational history UX

Recommended modules:
- `cashSession` movements
- `cashSession` history/sales lists
- `attendance` records
- `operationalNotification` later

### 4. Mixed strategy modules
Some modules should use more than one cache strategy internally.

Examples:
- `cashSession`
  - snapshot for active session state
  - list/journal cache for movements/history/sales
- `attendance`
  - snapshot for current attendance context
  - list cache for records/history

### Strategy rule for implementation
- Do **not** force every module into normalized storage if a snapshot is enough.
- Do **not** use snapshot blobs for modules that clearly need list/query/index behavior.
- Storage engine decision in Phase 1 must support **all 3 cache styles**, even if first-wave implementation starts simpler.

---

## Storage recommendation

### Recommended direction
Adopt a **single structured local storage engine** suitable for:
- web-first
- later mobile
- multiple module stores
- checkpoint persistence
- future queue persistence

### Working recommendation for implementation spike
Evaluate and lock one engine in Phase 1 using these criteria:
- durable persistence on web
- support for mobile later
- acceptable developer ergonomics
- ability to model normalized data + checkpoints + queue records

Candidates:
- `drift`
- `isar`

### Non-recommended direction
Do **not** continue extending `SharedPreferences` for feature read caches.
Reason:
- not suitable for normalized module data
- not suitable for scalable sync state
- will create fragmented ad-hoc persistence

---

## First rollout modules

### Phase-1 rollout candidates
Start with modules that:
- already have backend pull producers
- benefit immediately from cache-first UX
- support later offline-safe flows

Priority set:
1. `policy`
2. `cashSession`
3. `menu`
4. `attendance`
5. `shift`

Reasoning:
- `policy`, `cashSession`, `menu` improve boot/branch-switch responsiveness quickly
- `attendance` and `shift` support the later offline-safe rollout for staff workflows

### First-wave cache strategy recommendation

- `policy`
  - snapshot cache
- `cashSession`
  - snapshot for active session
  - list cache for movements/history/sales
- `menu`
  - normalized entity cache
- `attendance`
  - mixed snapshot + list cache
- `shift`
  - normalized entity cache

Deferred for later:
- inventory
- discount
- sale order read model

---

## Phase plan

## Phase 0 — Inventory and ownership
- [x] Document current persisted state already in the app
- [x] List feature stores that currently read directly from network
- [x] Map which backend pull producers exist per module
- [x] Identify which current providers/stores should become cache-first consumers

Output:
- current-state inventory
- first-wave module list

### Phase 0 findings

#### A. Current persisted state already in the app

Structured feature caching does **not** exist yet. Current persisted/local storage is limited to:

1. Auth session snapshot
- [lib/features/auth/data/auth_session_store.dart](/Users/mac/flutterProjects/modular/lib/features/auth/data/auth_session_store.dart)
- stores serialized `AuthSession` snapshot in `SharedPreferences`

2. Idempotency key records
- [lib/core/network/idempotency_key_store.dart](/Users/mac/flutterProjects/modular/lib/core/network/idempotency_key_store.dart)
- stores request idempotency records in `SharedPreferences`

3. Sale cart recovery / receipt recovery
- [lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
- stores serialized cart state in `SharedPreferences`
- also keeps printable receipt data in memory state

4. Printer preferences
- [lib/core/printing/thermal_printer_profile_store.dart](/Users/mac/flutterProjects/modular/lib/core/printing/thermal_printer_profile_store.dart)
- stores printer preferences in `SharedPreferences`

Conclusion:
- there is **no shared feature read-cache layer**
- there is **no sync checkpoint persistence**
- there is **no offline command queue persistence**

#### B. First-wave feature stores still reading directly from network

1. Policy
- [lib/features/policy/ui/viewmodels/policy_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/viewmodels/policy_viewmodel.dart)
- `load()` calls repository directly, repository fetches live via [remote_policy_repository.dart](/Users/mac/flutterProjects/modular/lib/features/policy/data/remote_policy_repository.dart)

2. Cash session
- [lib/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart)
- `load()` calls live repository methods (`getActiveSession`, movements, sales, sessions)

3. Menu
- [lib/features/menu/data/remote_menu_repository.dart](/Users/mac/flutterProjects/modular/lib/features/menu/data/remote_menu_repository.dart)
- menu state is hydrated in memory, but there is no durable local cache layer

4. Attendance
- [lib/features/staff_attendance/data/api_attendance_repository.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/data/api_attendance_repository.dart)
- attendance pages fetch context, records, and schedule directly from API-backed repository

5. Shift
- [lib/features/staff/data/repository/staff_shift_repository.dart](/Users/mac/flutterProjects/modular/lib/features/staff/data/repository/staff_shift_repository.dart)
- shift tab and attendance check pull schedule directly from live endpoints

Conclusion:
- these first-wave modules are still **network-first**, not cache-first
- current in-memory state should become a consumer of durable local cache, not the cache itself

#### C. Backend pull producers currently available

From the backend architecture clarification, current pull-sync producers are live for:
- `policy`
- `cashSession`
- `menu`
- `discount`
- `inventory`
- `saleOrder`
- `shift`
- `attendance`
- `operationalNotification`

Implication:
- the first-wave frontend caching rollout can start with `policy`, `cashSession`, `menu`, `attendance`, and `shift` without waiting on new backend producers

#### D. First-wave cache-first consumers

Priority modules for cache-first integration:

1. Policy
- small data surface
- branch-sensitive
- already centrally hydrated after auth/branch changes

2. Cash session
- operationally important
- benefits from branch bootstrap speed and stale-state recovery

3. Menu
- biggest visible performance win for sale flow
- should support cache-first render especially on slower staging networks

4. Attendance
- supports later offline-safe replay rollout

5. Shift
- paired with attendance and branch/account context

#### E. Phase 0 conclusion

The current app has **persistence**, but not **caching architecture**.
The first implementation milestone should therefore build:
- a shared durable read-cache layer
- sync checkpoint storage
- cache-first feature loading for the first-wave modules above

## Phase 1 — Storage engine decision spike
- [x] Compare `drift` vs `isar` for this repo’s needs
- [x] Lock one storage engine
- [x] Define local storage ownership boundaries:
  - shared storage core
  - feature-local cache adapters
- [x] Define migration policy from existing `SharedPreferences` persistence

Output:
- storage decision
- implementation constraints

### Phase 1 decision: use `drift`

#### Decision
Adopt **`drift`** as the structured local storage foundation for offline caching.

#### Why `drift` fits this repo better

This repo needs one storage foundation that can support all of the following:
- snapshot-style cache records
- normalized entity tables
- list/journal-style history records
- sync checkpoint storage
- future offline command queue storage
- browser-first deployment now, mobile later

For this app, the strongest reasons for choosing `drift` are:

1. **Relational modeling fits the planned cache shapes**
- we need:
  - normalized entity data (`menu`, `shift`, later `inventory`)
  - indexed lists/journal data (`cashSession` history/movements, `attendance`)
  - checkpoint records
  - future queue records with dependencies
- these are easier to model explicitly with tables, indexes, and joins than with ad-hoc object blobs

2. **Better long-term fit for pull-sync convergence**
- `sync/pull` implies incremental application of server changes to local read state
- explicit table structure is a stronger fit for:
  - upserts
  - pruning
  - per-context indexing
  - partial refreshes

3. **Stronger fit for mixed strategy modules**
- `cashSession` and `attendance` need both snapshot and list-style cache shapes
- `drift` can represent both cleanly inside one store

4. **Future queue support**
- once offline command queue work starts, queue records, retry metadata, and dependency chains will need structured persistence
- `drift` is a safer single engine for read cache + checkpoint + queue than continuing to mix persistence approaches

#### Clarification: why `drift` and not raw `IndexedDB`

This is not a direct apples-to-apples choice.

- `IndexedDB` is a browser storage primitive
- `drift` is an application-level structured persistence layer

For this repo, the real choice is:
- code directly against raw browser/device storage primitives
- or adopt one structured local database abstraction for all supported platforms

We are choosing `drift` because:

1. **We do not want raw storage logic spread across features**
- direct `IndexedDB` usage would force us to hand-roll:
  - schema conventions
  - query helpers
  - migrations
  - indexes
  - cache partition access patterns

2. **The app is not web-only long term**
- current target is browser-first
- later target includes Android/iOS/iPadOS
- we want one persistence architecture that can survive that transition

3. **Our cache model is relational enough to benefit from a structured DB layer**
- normalized entities
- journal/list records
- checkpoint rows
- future offline queue rows

So the decision is:
- **do not build the caching architecture directly on raw IndexedDB APIs**
- **use `drift` as the structured local database layer**

This does not reject browser-backed persistence.
It rejects raw browser-storage programming as the feature-level architecture.

#### Why `isar` is not the chosen direction

`isar` remains a viable general local database, but for this repo it is not the preferred fit because:
- current cache plan leans heavily toward relational/indexed query patterns
- future queue + checkpoint + normalized module data all benefit from more explicit table design
- we want the local sync model to be predictable for both teammates and agents

This does **not** mean `isar` is bad. It means `drift` is the better match for:
- this data model
- this roadmap
- this team handover requirement

#### Ownership boundaries (locked)

1. **Shared storage core**
- create one shared local database layer under `lib/core/storage/`
- this layer owns:
  - database bootstrap
  - schema registration
  - migrations
  - shared table definitions for sync checkpoint and future queue metadata

2. **Feature-local cache adapters**
- each feature should get cache adapters/repositories that read/write through the shared storage core
- feature UI/viewmodels must not talk to raw table code directly

3. **Feature stores remain cache consumers**
- feature stores/controllers should consume:
  - local cache adapter
  - remote API/repository
  - shared pull-sync orchestrator later

#### Migration policy from existing `SharedPreferences`

`SharedPreferences` stays only for lightweight app/device preferences and existing special cases:
- auth session snapshot
- idempotency key records
- printer preferences
- temporary sale cart recovery (until/unless intentionally migrated)

It should **not** be expanded for new feature read caches.

Migration rule:
- do not migrate existing `SharedPreferences` records to `drift` unless the specific feature gains clear architectural value from it
- keep current lightweight persistence where it is, and build new structured caching in `drift`

#### Phase 1 conclusion

The storage foundation is now locked:
- **`drift` for structured local cache / checkpoint / future queue**
- `SharedPreferences` remains for lightweight non-cache persistence only

## Phase 2 — Local cache schema design
- [x] Define cache record format per module
- [x] Define context partition keys:
  - tenant id
  - branch id
  - account id
- [x] Define freshness metadata shape
- [x] Define cache invalidation/clear rules for:
  - logout
  - tenant switch
  - branch switch

Output:
- schema and partition plan

### Phase 2 schema and partition design

#### A. Context partition model (locked)

Every cached record must be scoped by one of these context levels:

1. **Tenant-scoped**
- keyed by:
  - `tenant_id`
  - module-specific record key
- examples:
  - `menu`
  - tenant-level `shift` reference data if applicable

2. **Branch-scoped**
- keyed by:
  - `tenant_id`
  - `branch_id`
  - module-specific record key
- examples:
  - `policy`
  - `cashSession`
  - `attendance`
  - branch-level `shift` schedule views

3. **Account-scoped**
- keyed by:
  - `tenant_id`
  - `account_id`
  - module-specific record key
- examples:
  - future personalized read models
  - account-specific notifications later

4. **Mixed-scoped views**
- some modules need both context and record ids:
  - `cashSession` history rows:
    - `tenant_id`
    - `branch_id`
    - `session_id`
  - `attendance` records:
    - `tenant_id`
    - `branch_id`
    - `attendance_record_id`

Rule:
- do **not** store global unscoped feature caches for branch-sensitive modules
- partition must always reflect the actual working context of the data

#### B. Common cache metadata shape

Every cache family should carry metadata to support freshness and sync application.

Common metadata fields:
- `tenant_id`
- `branch_id` nullable where not applicable
- `account_id` nullable where not applicable
- `module_scope`
- `record_id` or logical cache key
- `updated_at_server`
- `updated_at_local`
- `sync_cursor_applied` nullable
- `is_stale`
- `last_pull_at` nullable

Meaning:
- `updated_at_server`
  - last known server timestamp/version for the record
- `updated_at_local`
  - when the local cache row was last written
- `sync_cursor_applied`
  - last pull cursor/version that touched this record family
- `is_stale`
  - indicates cache exists but may need refresh
- `last_pull_at`
  - useful for freshness heuristics and diagnostics

#### C. Cache shape by first-wave module

##### 1. Policy
Strategy:
- snapshot cache

Recommended table shape:
- one row per `(tenant_id, branch_id)`
- payload columns for resolved branch policy values
- metadata columns

##### 2. Cash Session
Strategy:
- mixed snapshot + list cache

Recommended table families:
- `cash_session_active_snapshot`
  - one row per `(tenant_id, branch_id)`
- `cash_session_movement_records`
  - keyed by `(tenant_id, branch_id, movement_id)`
- `cash_session_sales_records`
  - keyed by `(tenant_id, branch_id, sale_id)`
- `cash_session_history_records`
  - keyed by `(tenant_id, branch_id, session_id)`
- `cash_session_summary_records`
  - keyed by `(tenant_id, branch_id, session_id, summary_type)`

##### 3. Menu
Strategy:
- normalized entity cache

Recommended table families:
- `menu_items`
- `menu_categories`
- `modifier_groups`
- `modifier_options`
- join/visibility/index tables as needed

All partitioned at least by:
- `tenant_id`

##### 4. Attendance
Strategy:
- mixed snapshot + list cache

Recommended table families:
- `attendance_context_snapshot`
  - one row per `(tenant_id, branch_id, account_id?)` depending on use case
- `attendance_records`
  - keyed by attendance record id plus context

##### 5. Shift
Strategy:
- normalized entity cache

Recommended table families:
- `shift_patterns`
- `shift_instances`
- `shift_schedule_views` if a denormalized view is justified later

Partitioned by:
- `tenant_id`
- `branch_id` where relevant
- `membership_id` or `account_id` where needed for self schedule

#### D. Invalidation and clear rules

##### 1. Logout
- clear all auth-bound runtime state immediately
- mark all cached feature data inaccessible until next login context is established
- checkpoint rows may be retained only if they are safely partitioned and not user-sensitive
- simplest first implementation rule:
  - clear all account-bound and context-bound cache visibility in app state
  - keep physical rows only if schema supports safe partitioned reuse

##### 2. Tenant switch
- do **not** destroy cached data for other tenants
- switch active context to the selected tenant
- load cache only for the active tenant partition
- mark tenant-scoped and branch-scoped data under the new tenant as stale until pull/bootstrap completes

##### 3. Branch switch
- do **not** destroy cached data for other branches
- switch visible branch partition
- branch-scoped modules must read only the active branch partition
- active branch cache may render immediately if available, then refresh in background

#### E. UI consumption rule

Feature stores should follow this sequence:
1. resolve active context key
2. load local cached rows for that context
3. render cache if available
4. trigger refresh/pull in background
5. merge refreshed data back into the same partition

That means “cache-first” is a context-aware read rule, not a global cache lookup.

#### Phase 2 conclusion

The cache model is now locked around:
- explicit context partitions
- module-appropriate cache shapes
- shared metadata needed for freshness and sync convergence
- non-destructive tenant/branch switching with partitioned reads

## Phase 3 — Sync checkpoint design
- [x] Define checkpoint record structure
- [x] Define checkpoint ownership by module scope/context
- [x] Define bootstrap vs incremental pull rules
- [x] Define reset behavior on auth/context change

Output:
- checkpoint design

### Phase 3 checkpoint design

#### A. Purpose of checkpoint state

Checkpoint state exists so the frontend can:
- bootstrap local read models on first load
- resume from the latest known pull cursor
- keep tenant/branch/account scopes independent
- avoid treating every app start or branch switch like a cold sync

Checkpoint state is **not** user-facing data.
It is sync control metadata.

#### B. Checkpoint record structure (locked)

Each checkpoint record should contain:
- `device_id`
- `tenant_id`
- `branch_id` nullable where not applicable
- `account_id` nullable where not applicable
- `module_scope_set_key`
- `cursor`
- `last_pull_at`
- `last_successful_pull_at`
- `last_pull_status`
- `last_error_code` nullable

Meaning:
- `device_id`
  - ties the checkpoint to the client installation/device identity
- `module_scope_set_key`
  - stable key representing which module scopes were requested together
- `cursor`
  - backend cursor returned from the last successful pull
- `last_pull_at`
  - timestamp of the most recent pull attempt
- `last_successful_pull_at`
  - timestamp of the last successful pull completion
- `last_pull_status`
  - one of:
    - `idle`
    - `running`
    - `success`
    - `failed`
- `last_error_code`
  - diagnostic aid for sync failures

#### C. Ownership model for checkpoints

Checkpoint ownership must match the context of the pulled module scopes.

##### 1. Tenant-scoped pull set
Use one checkpoint per:
- `device_id`
- `tenant_id`
- `module_scope_set_key`

Examples:
- `menu`
- tenant-level `shift` reference data if later grouped that way

##### 2. Branch-scoped pull set
Use one checkpoint per:
- `device_id`
- `tenant_id`
- `branch_id`
- `module_scope_set_key`

Examples:
- `policy`
- `cashSession`
- `attendance`
- branch-level `shift`

##### 3. Account-scoped pull set
Use one checkpoint per:
- `device_id`
- `tenant_id`
- `account_id`
- `module_scope_set_key`

Examples:
- account-specific notification streams later
- other self-scoped read models later

Rule:
- checkpoint rows must never be shared across incompatible scope sets
- one branch’s cursor must not be reused for another branch
- one module combination must not silently reuse another combination’s cursor

#### D. Module scope set key strategy

Because `sync/pull` may request multiple module scopes together, checkpoint identity must include the requested set.

Recommended rule:
- sort the requested scopes alphabetically
- join them into a stable string key

Example:
- `attendance|cashSession|policy`

Why:
- ensures the same pull set reuses the same checkpoint
- avoids accidental cursor mixing between different pull bundles

#### E. Bootstrap vs incremental pull rules

##### Bootstrap pull
Use when:
- no checkpoint exists for the current context + module scope set
- user enters a tenant/branch/account scope for the first time on this device
- local cache exists but checkpoint is missing or invalid

Behavior:
- call `sync/pull` with `cursor = null`
- write returned records into local cache
- persist returned cursor as the new checkpoint

##### Incremental pull
Use when:
- a valid checkpoint exists for the current context + module scope set

Behavior:
- call `sync/pull` with the stored cursor
- merge deltas into local cache
- update checkpoint cursor on success

#### F. Reset rules on auth/context changes

##### Logout
- active runtime sync state must reset immediately
- checkpoint rows do not need physical deletion if safely partitioned by tenant/account/branch/device
- however, they must not be reused until a compatible authenticated context exists again

##### Tenant switch
- do not delete checkpoints for other tenants
- switch to the new tenant partition
- if checkpoint exists for that tenant + scope set, use incremental pull
- otherwise bootstrap

##### Branch switch
- do not delete checkpoints for other branches
- switch to the new branch partition
- if checkpoint exists for that branch + scope set, use incremental pull
- otherwise bootstrap

#### G. Failure behavior

On failed pull:
- keep existing cached data
- do not advance cursor
- update:
  - `last_pull_at`
  - `last_pull_status = failed`
  - `last_error_code`

On successful pull:
- update:
  - `cursor`
  - `last_pull_at`
  - `last_successful_pull_at`
  - `last_pull_status = success`
  - clear `last_error_code`

#### H. Relationship to future queue replay

Checkpoint design should remain independent of the future offline queue.

But the intended runtime sequence later will be:
1. replay queue through `sync/push`
2. on push completion, run `sync/pull`
3. update checkpoint after pull success

So checkpoint storage must be stable enough to survive later queue integration without redesign.

#### Phase 3 conclusion

Checkpoint state is now locked as:
- context-partitioned
- module-scope-set aware
- cursor-based
- non-destructive across tenant/branch switches
- safe for future queue + pull convergence flow

## Phase 4 — Shared read-sync orchestrator
- [x] Design a shared service for `sync/pull`
- [x] Define module registration pattern for pull producers/consumers
- [x] Define how pull results are written into local stores
- [x] Define failure handling / stale-cache behavior

Output:
- orchestrator contract

### Phase 4 orchestrator design

#### A. Role of the orchestrator

The shared read-sync orchestrator is the single client-side service responsible for:
- deciding whether a pull is bootstrap or incremental
- resolving the correct checkpoint for the current context + module scope set
- calling `POST /v0/sync/pull`
- dispatching pull results into local cache adapters
- updating checkpoint state
- surfacing sync status for the UI layer

This service should live under a shared core layer, not inside any feature.

Recommended location:
- `lib/core/sync/`

#### B. What the orchestrator must prevent

Without a shared orchestrator, likely failure modes are:
- each feature builds its own `sync/pull` logic
- cursor ownership becomes inconsistent
- multiple features race and overwrite checkpoint assumptions
- stale-cache handling differs per module
- cache-first behavior becomes fragmented

So the orchestrator is required to preserve one consistent sync model.

#### C. Core orchestrator responsibilities (locked)

1. Resolve active context
- tenant
- branch
- account where relevant
- module scope set

2. Resolve checkpoint
- load checkpoint for current context + scope set
- choose bootstrap vs incremental mode

3. Execute pull request
- call backend `sync/pull`
- pass:
  - `deviceId`
  - `cursor`
  - requested `moduleScopes`

4. Route module results
- take pull response sections
- send each section to the correct feature cache adapter

5. Persist sync control state
- update checkpoint on success
- update failure metadata on error

6. Surface sync status
- expose whether a sync is:
  - idle
  - running
  - success
  - failed
- allow UI/store layers to react without embedding transport logic

#### D. Registration pattern for feature consumers

Each cache-backed module should register a **sync consumer** with the orchestrator.

Recommended contract shape:
- module scope identifier
- cache adapter reference
- pull-result apply function
- clear/reset behavior if needed

Example conceptual contract:
- `moduleScope = policy`
- `applyPullResult(policyPayload, context)`
- `markStale(context)`

Why registration matters:
- keeps feature-specific data mapping out of the shared transport layer
- allows orchestrator to stay generic
- makes module rollout incremental

#### E. Pull result application rule

The orchestrator should not write directly to raw feature tables itself.

Instead:
- orchestrator decodes the pull envelope by module scope
- feature cache adapter applies records into local storage

So write flow becomes:
1. orchestrator receives pull payload
2. looks up registered consumer for each module scope
3. calls feature cache adapter to merge/apply data
4. only after successful apply does checkpoint advance

This is important:
- if local apply fails, we must not persist the new cursor as if sync succeeded

#### F. Failure handling rules

##### 1. Transport failure
- keep existing cache untouched
- checkpoint does not advance
- sync status becomes failed
- cached data may remain visible if available

##### 2. Partial module-apply failure
- treat the whole pull as not fully committed
- checkpoint must not advance unless pull application is considered successful under the chosen transactional policy

Recommended first implementation rule:
- per pull call, either:
  - all module applies succeed and cursor advances
  - or cursor does not advance

That is simpler and safer than partially advancing by module.

##### 3. Stale cache UX
- if cache exists and pull fails:
  - render stale cache
  - mark module state as stale/offline
- if cache does not exist and pull fails:
  - surface empty/error state

#### G. Orchestrator integration with feature stores

Feature stores should not call `sync/pull` directly long term.

Instead:
- feature store asks for:
  - local cached data
  - refresh via shared orchestrator for relevant scopes

Recommended load pattern:
1. store loads cache snapshot/list for current context
2. emits local data immediately
3. triggers orchestrator refresh in background
4. reacts when local cache is updated by the adapter

That is how we get:
- cache-first UX
- one sync transport model

#### H. Sync status visibility

The orchestrator should expose lightweight status so UI can show:
- initial loading
- background refresh
- stale cache warning
- last sync failure state

This does not mean every page shows full sync diagnostics.
It means the architecture supports consistent UX patterns later.

#### I. Relationship to current app hydration

Current cross-feature hydration in:
- [lib/core/hydration/app_hydration_listener.dart](/Users/mac/flutterProjects/modular/lib/core/hydration/app_hydration_listener.dart)

will remain relevant, but its role will evolve:
- today: trigger direct feature reloads
- later: trigger orchestrator refresh/bootstrap for the relevant cached modules

So the orchestrator should be designed to become the new backend-facing path that hydration invokes on:
- login
- tenant selection
- branch switch

#### Phase 4 conclusion

The shared read-sync model is now locked:
- one orchestrator under `core/sync`
- feature modules register cache consumers
- pull transport stays centralized
- cache writes stay feature-owned
- cursor advancement happens only after successful local apply

## Phase 5 — Feature integration rollout
- [x] Integrate `policy` into cache-first reads
- [x] Integrate `cashSession` into cache-first reads
- [x] Integrate `menu` into cache-first reads
- [x] Integrate `attendance`
- [x] Integrate `shift`

Output:
- first-wave cache-backed modules

### Phase 5 rollout strategy

This phase locks the **order and integration shape** for the first cache-backed modules.
It does **not** mean all five modules are implemented yet. It means the migration path is now defined.

#### A. Rollout order (locked)

1. `policy`
2. `cashSession`
3. `menu`
4. `attendance`
5. `shift`

Why this order:
- `policy`
  - smallest and safest snapshot cache to prove the architecture
  - already participates in app hydration
- `cashSession`
  - high operational value
  - visible staging performance improvement
  - exercises mixed snapshot + list cache design
- `menu`
  - biggest perceived performance win for sale flow
- `attendance`
  - benefits from cache-first reads and prepares later offline-safe replay rollout
- `shift`
  - closely coupled to attendance and benefits from the same context/scoping decisions

#### B. Integration rule for every first-wave module

Each module should transition from:
- direct network-first feature store

to:
- local cache adapter
- cache-first feature store
- background refresh through shared orchestrator

Target flow:
1. feature store resolves active context
2. reads local cache for that context
3. emits cached state immediately if present
4. triggers orchestrator refresh
5. cache adapter merges pulled results
6. feature store reacts to updated local cache

#### C. Module-specific integration targets

##### 1. Policy

Current owner:
- [lib/features/policy/ui/viewmodels/policy_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/viewmodels/policy_viewmodel.dart)

Target behavior:
- read cached branch policy first
- show branch policy immediately if cached
- background refresh through orchestrator for `policy`
- update local snapshot on successful pull or direct write convergence later

Why first:
- smallest surface
- easiest place to prove:
  - branch partitioning
  - snapshot cache
  - hydration-triggered cache-first load

##### 2. Cash Session

Current owner:
- [lib/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart)

Target behavior:
- cache-first active session state on branch entry
- cached movements/history/sales visible before background convergence
- branch switch loads the new branch partition immediately if cached

Why second:
- strongest operational impact
- exercises:
  - snapshot + list caches
  - branch partitioning
  - session/history screens

##### 3. Menu

Current owner:
- [lib/features/menu/ui/viewmodels/menu_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/menu/ui/viewmodels/menu_viewmodel.dart)

Target behavior:
- sale/menu screens render from cached menu entities first
- background refresh repopulates normalized entity cache
- hydrated modifier/item relationships come from local storage, not just in-memory state

Why third:
- likely the biggest visible performance improvement
- but more complex than `policy` and `cashSession`

##### 4. Attendance

Current owners:
- [lib/features/staff_attendance/data/staff_attendance_repository.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/data/staff_attendance_repository.dart)
- attendance pages under [lib/features/staff_attendance/ui/view/](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/ui/view/)

Target behavior:
- current attendance context can render from cache
- attendance records/history can render from cached list records
- check-in/out mutation rollout remains separate from read cache rollout

Why fourth:
- useful read-side win
- but mutation/offline replay concerns are deliberately deferred to the later queue phase

##### 5. Shift

Current owners:
- [lib/features/staff/data/repository/staff_shift_repository.dart](/Users/mac/flutterProjects/modular/lib/features/staff/data/repository/staff_shift_repository.dart)
- shift UI under [lib/features/staff/ui/](/Users/mac/flutterProjects/modular/lib/features/staff/ui/)

Target behavior:
- cached shift patterns/instances available by context
- self schedule and admin schedule both read through the same local cache foundation

Why fifth:
- needs normalized entity modeling
- should benefit from the earlier menu/attendance cache patterns

#### D. Explicitly deferred from first-wave rollout

These are **not** part of the first cache-backed rollout:
- offline command queue
- sync push replay
- KHQR
- sale finalize offline replay
- notification/SSE integration
- inventory and discount caching
- sale order read-model migration

#### E. Phase 5 conclusion

The first rollout path is now implementation-ready:
- start with the smallest branch-scoped snapshot module (`policy`)
- then prove mixed cache design in `cashSession`
- then move to larger normalized/list modules (`menu`, `attendance`, `shift`)

## Phase 6 — UX integration
- [x] Show cached state immediately where available
- [x] Add background refresh indicators where needed
- [x] Define stale/offline banners and wording
- [x] Ensure UI does not freeze while converging

Output:
- cache-first user experience rules

### Phase 6 UX integration rules

This phase locks the **user-facing behavior** of cache-first reads.
The goal is to make caching improve responsiveness without creating a confusing stale-data experience.

#### A. Screen state model (locked)

Every cache-first screen should behave according to one of these four states:

1. **No cache yet + loading**
- show normal initial loading UI
- no stale banner
- this is the only state where a full loading surface is acceptable

2. **Cache available + background refresh running**
- render cached data immediately
- show a subtle non-blocking refresh indicator
- do **not** blank the screen or replace content with a spinner

3. **Cache available + refresh failed or offline**
- keep showing cached data
- show a non-blocking stale/offline message
- allow safe read interactions to continue

4. **No cache + refresh failed**
- show normal error or empty state
- do not pretend cached data exists

Rule:
- once useful cached data exists, the UI should prefer **continuity** over loading interruption

#### B. Refresh indicator policy (locked)

Background refresh indicators should be **passive**, not dominant.

Recommended first-wave behavior:
- top-of-surface inline status text such as:
  - `Updating...`
  - `Refreshing data...`
- optional small progress indicator near the header/filter row

Avoid:
- full-screen blocking spinners when cached data is already visible
- modal loading dialogs for read convergence

First-wave module expectations:
- `policy`
  - small inline refresh status near the policy header
- `cashSession`
  - passive refresh indicator in the session screen header or tab header
- `menu`
  - passive refresh indicator near search/filter/catalog controls
- `attendance`
  - passive refresh indicator near page header
- `shift`
  - passive refresh indicator near schedule header/filter row

#### C. Stale and offline messaging (locked)

The first rollout should use explicit but calm wording.

Recommended copy patterns:
- when offline with cache:
  - `Offline. Showing saved data.`
- when refresh fails but cache exists:
  - `Couldn't refresh right now. Showing saved data.`
- when cached data may be outdated after reconnect delay:
  - `Showing saved data while updating.`

Avoid:
- technical sync jargon in primary UX
- messages that imply data is live when it may be stale

#### D. Action safety rule (locked)

Cache-first reads must not make unsafe write actions look offline-capable by accident.

Therefore:
- read surfaces may stay visible from cache while offline
- actions that are **online-only** or not yet replay-safe must still be gated by their own runtime rules
- cached state must never by itself imply:
  - KHQR is available offline
  - sale finalize can be completed offline
  - any unsupported mutation is safe offline

#### E. No-freeze interaction rule (locked)

While pull-sync convergence is running:
- keep visible cached data interactive where safe
- disable only the specific controls that are truly waiting on a required live mutation
- avoid full-page loading overlays on cache-backed screens

This is especially important for:
- branch switch landing
- app bootstrap after login
- returning to sale/menu after prior load
- cash session/history review surfaces

#### F. Phase 6 conclusion

The cache-first UX model is now locked:
- cached data should appear immediately when available
- refresh should be visible but non-blocking
- stale/offline state should be honest but calm
- convergence must not freeze the screen once cached data exists

## Phase 7 — Validation and rollout readiness
- [x] Unit tests for cache adapters
- [x] Unit tests for checkpoint logic
- [x] Unit tests for pull result application
- [x] Widget tests for cache-first render + background refresh
- [x] Manual QA checklist for:
  - login/bootstrap
  - tenant switch
  - branch switch
  - reconnect after stale cache

Output:
- validated caching foundation

### Phase 7 validation and rollout-readiness rules

This phase locks the **minimum validation bar** before cache-first implementation is considered ready for rollout.

#### A. Unit test requirements (locked)

The first implementation wave must include unit coverage for:

1. **Cache adapters**
- snapshot read/write behavior
- normalized entity upsert behavior
- list/journal merge behavior
- context partition isolation

2. **Checkpoint logic**
- bootstrap with `cursor = null`
- incremental pull using stored cursor
- cursor advancement only after successful local apply
- pull failure leaves previous cursor intact

3. **Pull result application**
- server records applied into the correct context partition
- newer data replaces older local rows correctly
- deleted or superseded records are handled by the module adapter rules
- cache metadata (`last_pull_at`, `sync_cursor_applied`, stale flag behavior) updates correctly

#### B. Widget test requirements (locked)

Widget coverage should prove the cache-first UX contract:

1. cached state renders immediately when available
2. background refresh does not blank the screen
3. stale/offline message appears when refresh fails but cache exists
4. normal error state appears when no cache exists and refresh fails
5. passive refresh indicators do not block safe read interactions

Priority first-wave widget surfaces:
- `policy`
- `cashSession`
- `menu`

#### C. Manual QA checklist (locked)

Before rollout, manual QA must cover:

1. **Login/bootstrap**
- first launch without cache shows normal loading
- second launch with cache shows useful data immediately
- background refresh updates visible data without full-screen blanking

2. **Tenant switch**
- switching tenant loads the correct tenant partition
- cached data from a previous tenant does not leak into the new tenant context

3. **Branch switch**
- switching branch loads the correct branch partition immediately when cached
- branch-sensitive modules (`policy`, `cashSession`, `attendance`, `shift`) do not cross-contaminate data

4. **Reconnect after stale cache**
- app can show saved data while offline
- reconnect triggers refresh
- refreshed data converges correctly after network returns

5. **Unsupported offline write paths**
- KHQR remains online-only
- sale finalize remains online-only
- cache-backed UI does not make unsupported writes appear replay-safe

#### D. Rollout safety rule (locked)

Implementation should ship in a controlled order:
- start with `policy`
- then `cashSession`
- expand only after the storage, checkpoint, and orchestrator layers prove stable

Recommended rollout discipline:
- land infrastructure first
- then one module at a time
- keep feature flags or guarded entry points available if rollout risk becomes high

#### E. Phase 7 conclusion

The caching foundation plan is now rollout-ready:
- architecture is defined
- storage and checkpoint model are locked
- UX rules are locked
- validation expectations are explicit

The next step is no longer planning.
It is implementation, starting with the shared storage layer and the `policy` cache-first pilot module.

---

## Non-negotiables for implementation

- UI/viewmodels must not import DTOs.
- Feature caches must go through shared storage abstractions.
- Cached UI must still expose loading/error/data.
- Cache-first must not become “cache-only”; server remains source of truth.
- Auth/context changes must clear or partition cached data correctly.
- No feature should invent its own local persistence approach once the storage engine is chosen.

---

## Key open decisions to resolve during implementation

1. Whether first-wave rollout should land module-by-module (`policy` first) or behind one hidden infrastructure flag until at least `policy` + `cashSession` are both ready?
2. Whether the passive refresh indicator should be implemented as one shared widget or feature-local UI in the first rollout?

---

## Success criteria

- The app can render useful last-known data for first-wave modules without immediate network dependence.
- Branch switch and login feel faster because cached state is shown before convergence completes.
- Pull-sync checkpoints exist and are persisted.
- The architecture is ready for the next step:
  - offline command queue and replay-safe write rollout.

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Current persistence inventory and first-wave consumers locked. |
| 1 | Completed | `drift` chosen as shared structured storage layer. |
| 2 | Completed | Cache schema and context partition rules locked. |
| 3 | Completed | Checkpoint model locked per device/context/module-scope set. |
| 4 | Completed | Shared read-sync orchestrator responsibilities locked. |
| 5 | Completed | First-wave rollout order and module-specific cache-first targets locked. |
| 6 | Completed | Cache-first screen-state, refresh, and stale/offline UX rules locked. |
| 7 | Completed | Validation matrix and rollout-readiness gates locked. |
