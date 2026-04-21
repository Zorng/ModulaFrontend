# Mobile Bluetooth Printer Support

Goal: assess the current hardware-support state in `modulaFront`, lock the viable path for iPad/mobile receipt printing, and create an implementation tracker before code work begins.

Primary pilot target:
- native Flutter app on iPad
- receipt printing to a Bluetooth printer from the Sale flow

Secondary goal:
- preserve the current web printer path for desktop/laptop browser usage

---

## Why this exists

We have now moved beyond the web-first stage for pilot readiness.

The main blocker is real:
- current receipt printing support in `modulaFront` depends on **Web Serial**
- Web Serial is not supported on iPad/iOS Safari
- therefore the current web printer path cannot be the foundation for the iPad pilot

This document locks the current-state assessment and the recommended mobile path so implementation can proceed in controlled slices.

---

## Current Status Assessment

### Current hardware-related support in repo

| Area | Current status | Evidence | Notes |
|---|---|---|---|
| Receipt formatting | Implemented and reusable | `lib/core/printing/esc_pos_receipt_formatter.dart` | Generates ESC/POS bytes; not web-specific |
| Printer controller/state | Implemented | `lib/core/printing/thermal_printer_controller.dart`, `thermal_printer_state.dart` | Current controller is transport-aware but effectively web-only |
| Printer transport | Web-only | `lib/core/printing/web_serial_printer_service*.dart`, `web/thermal_printer_bridge.js` | Hard-coupled to Web Serial |
| Sale printer UI | Implemented | `lib/features/sale/ui/view/sale_shell/widgets/sale_printer_status_action.dart` | Status dialog and test print live in Sale |
| Receipt print entry points | Implemented | `lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart` | Checkout/reprint already call printer controller |
| Mobile-native printer transport | Not implemented | no iOS/Android printer transport layer present | No BLE/native bridge or platform plugin in repo |
| iOS Bluetooth app permissions | Not configured | `ios/Runner/Info.plist` currently lacks Bluetooth usage keys | Required for CoreBluetooth-based printer access |
| Printer profiles | Minimal | `lib/core/printing/thermal_printer_profiles.dart` | Only `BT-583 58mm` profile exists today |
| Device-agnostic session support | Implemented | `docs/DEVICE_AGNOSTIC_SESSIONS.md` | Good fit for mobile pilot; removes register dependence |
| Other mobile-adjacent hardware | Partially implemented | `geolocator`, `google_maps_flutter`, `image_picker` | Not the main blocker for pilot printing |

### Current printer-stack conclusion

1. The app already knows how to build printable ESC/POS receipts.
2. The app already exposes printer actions in Sale.
3. The missing piece for iPad is **transport**, not receipt composition.
4. The current transport is web-specific and cannot be reused as-is for iPad.

---

## Locked Platform Facts

These facts are treated as locked constraints for this work unless new vendor documentation proves otherwise.

### 1. iPad web printing via the current stack is not a viable pilot path

Reason:
- current code uses `navigator.serial` through `web/thermal_printer_bridge.js`
- iPad/iOS browsers do not support Web Serial

Implication:
- we should not spend time trying to “fix” the current web path for iPad
- we should build a **native mobile printer transport**

### 2. iOS Bluetooth support is split by transport type

On Apple platforms:
- **Bluetooth Low Energy (BLE)** accessories are accessed via **CoreBluetooth**
- **classic/MFi accessory-style Bluetooth** access uses **ExternalAccessory**
- ExternalAccessory access requires the accessory to be **MFi-compatible**

Implication:
- generic “Bluetooth printer support” is not enough as a requirement
- we must first classify the pilot printer as one of:
  - BLE printer with usable GATT characteristics
  - MFi-compatible accessory with vendor protocol / SDK

### 3. Generic Bluetooth Classic / serial assumptions are unsafe for iPad

Implication:
- if the pilot printer only behaves like a generic serial/classic Bluetooth ESC/POS printer with no BLE path and no MFi path, it is **not** a safe iPad target

### 4. Existing ESC/POS formatting should be preserved

Implication:
- we should not replace the receipt formatter unless the printer protocol forces it
- the main refactor should happen at the transport seam

---

## Recommended Path

### Decision

Recommended implementation path:
- keep the current ESC/POS receipt formatter
- replace the current web-specific printer transport seam with a **platform-neutral transport abstraction**
- implement a **native mobile BLE printer transport** for the iPad pilot
- keep the current web serial transport as a separate web implementation

### Why this path

This gives us:
- minimal disruption to Sale checkout and receipt flows
- reuse of existing receipt byte generation
- clear separation between:
  - receipt formatting
  - printer transport
  - feature UI
- a future path for:
  - web serial on desktop web
  - BLE on mobile
  - possibly network printing later

---

## Recommended Hardware Rule For The Pilot

The pilot printer should satisfy **one** of these:

### Preferred
- **BLE printer**
- documented or discoverable GATT write characteristic
- accepts raw ESC/POS bytes directly, or vendor documents the byte/packet contract

### Acceptable fallback
- **MFi-compatible printer**
- vendor provides iOS protocol details or SDK usable from Flutter/native bridge

### Not acceptable for the iPad pilot without proof
- generic Bluetooth Classic / SPP-only printer
- “works with iOS” marketing claims without protocol documentation

Reason:
- iPad support depends on the actual Bluetooth transport and protocol, not on generic product copy

---

## App Architecture Recommendation

### Target structure

Introduce a transport seam that is no longer web-named:

- current:
  - `WebSerialPrinterService`
- target:
  - `ThermalPrinterTransport`

Suggested shape:

```text
lib/core/printing/
  thermal_printer_transport.dart
  thermal_printer_transport_stub.dart
  thermal_printer_transport_web_serial.dart
  thermal_printer_transport_mobile_ble.dart
```

### Controller direction

`ThermalPrinterController` should depend on the platform-neutral transport, not on a web-specific service name.

That lets the controller keep ownership of:
- connection state
- printer label
- print queueing
- last event / error handling
- profile selection

while the transport handles:
- capability detection
- discovery / connect / disconnect
- raw byte writes

### Profile direction

`ThermalPrinterProfile` likely needs expansion beyond paper width and baud rate.

Expected additions for mobile BLE:
- transport type
- service UUID
- characteristic UUID
- write mode (`withResponse` / `withoutResponse`)
- packet size / chunk size
- optional pacing delay

---

## Plugin / Implementation Direction

### Recommended base for BLE path

Recommended BLE foundation:
- `flutter_reactive_ble`

Reason:
- actively maintained
- supports Android and iOS
- exposes the BLE primitives we actually need:
  - scan
  - connect
  - discover services/characteristics
  - write characteristic with/without response
  - MTU handling/status observation

### Why not make the first step a full printer-stack swap

We already have:
- receipt formatting
- Sale print entry points
- printer state UX

So replacing the whole stack would introduce unnecessary risk.

The lower-risk move is:
- keep existing formatter + feature flow
- swap only the transport layer

### Candidate shortcut package

A generic all-in-one plugin such as `thermal_printer_flutter` may be worth a short evaluation spike, but it should **not** be the locked foundation yet.

Reason:
- we have not validated it against our exact pilot printer
- we do not yet know whether it matches the printer protocol we need
- a transport abstraction keeps us from being trapped by a package swap if the first plugin fails

---

## Scope Lock

### In scope

- assess current printer/hardware support status
- lock the mobile iPad printer direction
- refactor the printer stack around a transport abstraction
- add native mobile Bluetooth printing support for the pilot path
- preserve current sale printing UX unless changes are required by implementation
- add iOS Bluetooth permission/configuration required for BLE access

### Out of scope

- redesigning receipts
- redesigning the Sale page
- full branch-scope printer/device management UX
- Android-specific optimization beyond keeping the architecture compatible
- cash drawer/scanner integration
- AirPrint-specific implementation
- replacing all hardware workflows in one pass

---

## Phased Rollout

## Phase 0 — Hardware Gate

- [ ] Confirm the exact pilot printer model(s)
- [ ] Classify each printer as:
  - BLE with writable GATT characteristic
  - MFi accessory with vendor SDK/protocol
  - unsupported/unknown
- [ ] Capture vendor documentation or characteristic UUID findings
- [ ] Lock the pilot hardware target in this document

Output:
- one approved printer path for the pilot

Gate:
- do not start app-side Bluetooth implementation until the pilot printer class is confirmed

---

## Phase 1 — Transport Refactor

- [ ] Replace the web-specific service seam with `ThermalPrinterTransport`
- [ ] Move current web serial logic behind the new transport interface
- [ ] Keep `ThermalPrinterController` API stable where possible
- [ ] Preserve current Sale printing flows during the refactor

Output:
- transport is platform-neutral
- web path still works on desktop/laptop browsers

---

## Phase 2 — Mobile BLE Support

- [ ] Add BLE dependency and basic transport wiring
- [ ] Add iOS Bluetooth usage descriptions to `Info.plist`
- [ ] Implement scan/connect/disconnect/write flow for the pilot printer
- [ ] Add printer profile metadata needed for BLE writes
- [ ] Support test print from the existing printer dialog

Output:
- iPad app can discover, connect, and send a test page to the pilot printer

---

## Phase 3 — Sale Flow Validation

- [ ] Validate receipt printing after checkout
- [ ] Validate receipt reprint flow
- [ ] Validate printer reconnect behavior after app restart
- [ ] Validate error messaging for:
  - Bluetooth unavailable
  - permission denied
  - printer disconnected
  - write failure

Output:
- end-to-end Sale print flow works on iPad with the pilot printer

---

## Phase 4 — Device Management Follow-up

- [ ] Decide whether printer management stays sale-local for pilot
- [ ] Or move discovery/status/config into a branch-scope device tools surface
- [ ] Add saved-printer recall behavior if pilot usage proves it necessary

Output:
- post-pilot UX cleanup direction

---

## Risks

### Risk 1 — Printer protocol mismatch

The printer may expose BLE but not accept raw ESC/POS bytes on a simple write characteristic.

Mitigation:
- lock hardware first
- require protocol proof before implementation

### Risk 2 — Existing BT-583 profile may not be a safe iPad target

The current code assumes `BT-583 58mm`, but the repo does not contain verified iOS BLE protocol data for it.

Mitigation:
- treat the current profile as formatting metadata only
- do not assume it is mobile-compatible until verified

### Risk 3 — Package shortcut may not fit the pilot printer

A generic printing plugin may look faster but fail on real hardware.

Mitigation:
- keep a transport abstraction so package choice stays reversible

### Risk 4 — Web and mobile paths diverge without a clean seam

Mitigation:
- lock the transport abstraction before feature changes

---

## Validation Plan

### Technical validation

- `flutter analyze`
- focused tests for:
  - transport selection
  - printer controller state transitions
  - profile persistence
  - receipt formatter regression

### Manual validation

On iPad pilot hardware:
- [ ] app requests Bluetooth permission correctly
- [ ] printer scan lists the pilot device
- [ ] connect succeeds
- [ ] test print succeeds
- [ ] checkout receipt prints
- [ ] reprint receipt succeeds
- [ ] disconnect/reconnect succeeds
- [ ] app restart preserves selected printer/profile as intended

### Regression validation

On desktop web:
- [ ] web serial path still reports supported/unsupported correctly
- [ ] existing web printer connect/test print still works where Web Serial is available

---

## Open Questions

1. What is the exact printer model intended for the pilot?
2. Does that model expose BLE GATT directly, or does it require a vendor iOS SDK / MFi path?
3. Do we need printer discovery in the first pilot slice, or is manual pairing/selection enough?
4. Should we add network printing as a contingency path for the pilot if Bluetooth proves unreliable?

---

## Initial Conclusion

The current hardware-support state is good enough to avoid a full rewrite:
- receipt generation is already in place
- Sale printing entry points already exist

But the current transport is not pilot-ready for iPad:
- it is web serial only

The recommended path is therefore:
- **BLE-first native mobile printer support**
- behind a new platform-neutral transport abstraction
- with a hard hardware gate before implementation begins

---

## References

Apple:
- External Accessory overview: https://developer.apple.com/documentation/externalaccessory/
- Apple QA1657 on Bluetooth + External Accessory: https://developer.apple.com/library/archive/qa/qa1657/_index.html
- Core Bluetooth overview: https://developer.apple.com/documentation/corebluetooth/

Flutter package references:
- `flutter_reactive_ble`: https://pub.dev/packages/flutter_reactive_ble
- `thermal_printer_flutter`: https://pub.dev/packages/thermal_printer_flutter

Browser support:
- MDN Web Serial API: https://developer.mozilla.org/en-US/docs/Web/API/Web_Serial_API
- Can I Use Web Serial: https://caniuse.com/web-serial
