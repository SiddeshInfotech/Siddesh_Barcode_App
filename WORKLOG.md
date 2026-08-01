# Development Worklog

## 21/07/2026 - Batch Management & Inward History
- Added database migration `12_batches.sql` to introduce `product_batches` table and modified inward/outward schema.
- Updated `database.types.ts` manually to represent the new typing changes from the schema.
- Developed the frontend `BatchPicker` React component.
- Upgraded the `Inward.tsx` screen to support:
  - Batch creation directly inside the form.
  - Uploading invoice PDFs direct to the Supabase storage bucket (`invoices`).
  - Rendering an Inward History DataTable with "All" and "Selected Product" toggle.
- Upgraded the `Outward.tsx` screen to support:
  - Specifying the chosen Batch during dispatch.
  - Entering the Delivery Method (e.g. Courier, By Road).
- Updated the RPC contracts strictly within `Document/Contract.md`.

## 31/07/2026 14:05 — Fix barcode status changes failing across laptop + mobile — Ram
**Status:** Done
**What:** The mobile app could not change barcode status (GENERATED→INWARDED→OUTWARDED)
when the laptop backend's IP changed on the shared mobile hotspot. `ApiService.getBaseUrl()`
was hardcoded to `http://192.168.1.111:8080`, so inward/outward POSTs timed out and the
status was never written.
**How:** Replaced the hardcoded URL with runtime resolution — reachable manual override →
auto-discovery of the backend on the phone's own /24 subnet (via `NetworkInterface`, probing
the permit-all `/api/test/db-info` health endpoint in bounded concurrent batches) → last-resort
fallback IP. Result is cached per session with a `forceRefresh` path. Also removed the
`scanReceive` fallback that fabricated a fake `INWARDED` status when the server was
unreachable; it now returns an honest `BACKEND_UNREACHABLE` failure so the UI never shows a
status change the database did not record.
**Verify:** `dart analyze lib/services/api_service.dart` → No issues found. Full app run
blocked locally by Windows Developer Mode (Flutter plugin symlinks) — unrelated to this change.
**Files:** lib/services/api_service.dart

## 31/07/2026 16:20 — Settings backend config + status-confirmed messages — Ram
**Status:** Done
**What:** (1) Added a "Backend Server" tile in Settings with an editable laptop IP field, a
"Test Connection" button (probes `/api/test/db-info`), Save, and "Use automatic detection"
— wired to `ApiService.setManualBaseUrl` / `ApiService.testConnection`. (2) Made the
inward/outward success message strictly follow a committed DB status change: the backend now
returns the confirmed status, the client returns it from `recordInward`/`recordOutward`, and
the "Entry Saved" sheet + scan-history entry are only produced after that confirmation. Removed
the scanner's premature `INWARDED`/`OUTWARDED` history write (it logged before any DB update and
used a casing the history filter didn't match).
**How:** Backend `DashboardService.recordInward/recordOutward` now return `String` (the
post-commit status); `DashboardController` returns `{status, code, quantity}` with 200 (still
`Void`-compatible for the acceptance test). Flutter `recordInward/recordOutward` return the
confirmed status; entry screens record history (`entryType: Inward/Outward`) only on success.
**Verify:** `dart analyze` on all changed Dart files → only pre-existing warnings in
barcode_scanner_screen.dart (deprecated withOpacity, dead _showScanSuccessModal), none from
this change. Backend not compiled locally (Maven not installed); edits are signature/return
changes with no new deps.
**Files:** lib/screens/settings_screen.dart, lib/services/api_service.dart,
lib/screens/inward_entry_screen.dart, lib/screens/outward_entry_screen.dart,
lib/screens/barcode_scanner_screen.dart,
backend/.../service/DashboardService.java,
backend/.../service/impl/DashboardServiceImpl.java,
backend/.../controller/DashboardController.java

## 31/07/2026 17:40 — Friendly re-scan messages + fully DB-driven app — Ram
**Status:** Done
**What:** (1) Replaced the blunt inward/outward guard errors with friendly, human messages
(e.g. "This item is already in stock — it was inwarded earlier.", "Please inward this item
before dispatching it."). (2) Removed all fabricated/static stock data so the app shows only
what's in the database:
  - Dashboard now loads real `getDashboardStats()` (current stock, today's inward/outward)
    with a loading placeholder and pull-to-refresh; removed hardcoded 1246/28/17 and the fake
    "12.5% vs last month" trend (HeroStockCard trend is now optional).
  - Products hub loads the real catalog via new `ApiService.getAllProducts()` with
    loading / error+retry / empty states; deleted the 5-item mock database
    (`product_lookup_service.dart`).
  - Scan history starts empty (removed 5 seeded fake scans); entries added only on confirmed
    inward/outward.
  - `getProductByBarcode` no longer fabricates a product; the scanner routes unknown barcodes
    to the "not found" screen and shows an honest error on network failure.
  - Backend `getProductByBarcode` no longer auto-registers unknown barcodes — returns 404
    (DB is the single source of truth). Updated the corresponding unit test.
**Verify:** `dart analyze lib` → no new issues (only pre-existing withOpacity / dead
_showScanSuccessModal / supabase anonKey warnings). Backend not compiled locally (no Maven);
updated `ProductServiceImplTest` to expect 404 instead of auto-create.
**Files:** lib/screens/dashboard_screen.dart, lib/screens/products_hub_screen.dart,
lib/widgets/hero_stock_card.dart, lib/services/scan_history_service.dart,
lib/services/api_service.dart, lib/screens/barcode_scanner_screen.dart,
lib/services/product_lookup_service.dart (deleted),
backend/.../service/impl/DashboardServiceImpl.java,
backend/.../service/impl/ProductServiceImpl.java,
backend/.../test/.../service/ProductServiceImplTest.java

## 31/07/2026 23:20 — Ran backend+app on device; 400→Not Found edge; status flow proven — Ram
**Status:** Done
**What:** Ran the updated backend (Maven 3.9.6 from the wrapper cache, on 0.0.0.0:8080,
after stopping a stale old-code instance holding the port) and the Flutter app on a physical
Android 14 phone. Auto-discovery found the backend by itself at http://10.183.113.198:8080
(hotspot) with no hardcoded IP. Verified the full barcode status lifecycle live via API:
create→GENERATED, inward→INWARDED, outward→OUTWARDED, and the friendly re-scan blocks. Fixed
the scan edge where the server rejects a garbled scan with HTTP 400: `getProductByBarcode`
now treats 400 the same as 404 → the friendly "Product Not Found" screen instead of a
transient error.
**Build fixes (Windows/env, saved):** added `kotlin.incremental=false` to
android/gradle.properties (project on E:, pub cache on C: — Kotlin incremental compiler can't
do cross-root relative paths); cleared stale plugin build dirs + stopped a Gradle daemon after
a crashed first build left locked resource folders.
**Verify:** `dart analyze` clean; backend API lifecycle demo passed end to end; app rebuilt
(34MB) and reinstalled on device 2406ERN9CI.
**Files:** lib/services/api_service.dart, android/gradle.properties

## 01/08/2026 00:20 — Mobile app switched to direct Supabase (real data) — Ram
**Status:** Done
**What:** Root cause of "barcode exists but Not Found": the Spring backend couldn't
authenticate to Supabase (wrong DB password) and silently fell back to an empty in-memory
H2 DB; also its bigint/varchar schema didn't match the real UUID/enum schema. Switched the
mobile app to talk to Supabase directly, like the desktop app.
**How:** Rewrote `SupabaseService` to the correct project (hrgdanwvxjevwnpzgheo) + real anon
key, sign in via Supabase Auth (RLS then applies), and read/write real data:
  - Lookup: `product_barcodes` → `products` (+ categories/brands/uoms joins) → `stock_balances`
    for live qty (the `scan_lookup` RPC is broken in the DB — references a missing
    `v_stock_balances` view — so direct table reads are used).
  - Movements: `save_inward` / `save_outward` RPCs (idempotent via client_txn_id).
  - Dashboard/products lists computed from `stock_balances` + `products`.
  `ApiService` now delegates to `SupabaseService` (same method names, screens unchanged).
  `main.dart` initializes + signs in at startup.
**Verified live:** authenticated REST calls return the real product ("Cabels", qty_available
3) for barcode CABE-260731-0053; on-device log shows `signIn ok=true user=dbf5dcd8…`.
**Caveats:** inward uses default supplier "Mobile Inward"; outward uses type INTERNAL_USE
(forms don't collect supplier/party yet) — both write real stock. Product creation from
mobile is disabled (desktop only). `dart analyze lib` clean (pre-existing warnings only).
**Files:** lib/services/supabase_service.dart, lib/services/api_service.dart, lib/main.dart

## 01/08/2026 10:05 — Flip product_barcodes.status on inward/outward — Ram
**Status:** Done
**What:** On a committed inward the scanned barcode's `product_barcodes.status`
(barcode_status enum) now flips GENERATED→INWARDED, and →OUTWARDED on outward. Verified RLS
allows the authenticated user to update the column (PATCH 200) and the enum accepts
GENERATED/INWARDED/OUTWARDED.
**How:** Added `SupabaseService.updateBarcodeStatus(code, status)` (best-effort — stock
movement stays the source of truth); `ApiService.recordInward/recordOutward` call it after
`save_inward`/`save_outward`. Built from the ROOT project (E:\Siddesh_Barcode_App, AGP 8.11.1);
note `Frontend\` is a stale duplicate (AGP 8.3.2, no Supabase changes) and must not be built.
**Files:** lib/services/supabase_service.dart, lib/services/api_service.dart
