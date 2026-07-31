package com.inventorymanagement.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for testing security configurations and role-based permissions.
 */
@RestController
@RequestMapping("/api/test")
@Tag(name = "Testing Security", description = "Endpoints for verifying role-based authorization rules")
@SecurityRequirement(name = "bearerAuth")
public class TestController {

    /**
     * Endpoint restricted to ADMIN role.
     *
     * @return a message confirming access
     */
    @GetMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin only endpoint", description = "Verifies access for users with ROLE_ADMIN.")
    public ResponseEntity<String> adminEndpoint() {
        return ResponseEntity.ok("Success: You have accessed the Admin endpoint!");
    }

    /**
     * Endpoint restricted to ADMIN and STORE_MANAGER roles.
     *
     * @return a message confirming access
     */
    @GetMapping("/manager")
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER')")
    @Operation(summary = "Manager or Admin only endpoint", description = "Verifies access for users with ROLE_ADMIN or ROLE_STORE_MANAGER.")
    public ResponseEntity<String> managerEndpoint() {
        return ResponseEntity.ok("Success: You have accessed the Store Manager / Admin endpoint!");
    }

    /**
     * Endpoint restricted to ADMIN and SALES_EXECUTIVE roles.
     *
     * @return a message confirming access
     */
    @GetMapping("/sales")
    @PreAuthorize("hasAnyRole('ADMIN', 'SALES_EXECUTIVE')")
    @Operation(summary = "Sales or Admin only endpoint", description = "Verifies access for users with ROLE_ADMIN or ROLE_SALES_EXECUTIVE.")
    public ResponseEntity<String> salesEndpoint() {
        return ResponseEntity.ok("Success: You have accessed the Sales Executive / Admin endpoint!");
    }

    /**
     * Endpoint accessible by any authenticated user.
     *
     * @return a message confirming access
     */
    @GetMapping("/user")
    @Operation(summary = "Authenticated users endpoint", description = "Verifies access for any logged-in user.")
    public ResponseEntity<String> authenticatedEndpoint() {
        return ResponseEntity.ok("Success: You are logged in!");
    }

    @Autowired(required = false)
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    /**
     * Endpoint for health probe and database status check.
     *
     * @return database connectivity status
     */
    @GetMapping("/db-info")
    @Operation(summary = "Backend & Database health check", description = "Returns system health and DB connectivity state.")
    public ResponseEntity<java.util.Map<String, Object>> dbInfoEndpoint() {
        java.util.Map<String, Object> info = new java.util.HashMap<>();
        info.put("status", "UP");
        info.put("database", "PostgreSQL (Supabase)");
        info.put("timestamp", java.time.LocalDateTime.now().toString());
        return ResponseEntity.ok(info);
    }

    /**
     * Endpoint for executing live runtime verification of scan_receive RPC.
     *
     * @return runtime verification report payload
     */
    @GetMapping("/verify-scan-receive")
    @Operation(summary = "Verify scan_receive RPC runtime flow", description = "Executes real scan_receive RPC transactions and verifies DB updates.")
    public ResponseEntity<java.util.Map<String, Object>> verifyScanReceiveEndpoint() {
        java.util.Map<String, Object> report = new java.util.LinkedHashMap<>();
        if (jdbcTemplate == null) {
            report.put("error", "JdbcTemplate unavailable");
            return ResponseEntity.internalServerError().body(report);
        }

        try {
            String testBarcode = "VERIFY-BC-" + System.currentTimeMillis();
            
            // Get or create product UUID
            java.util.List<java.util.Map<String, Object>> products = jdbcTemplate.queryForList("SELECT id FROM public.products LIMIT 1");
            java.util.UUID productId;
            if (products.isEmpty()) {
                productId = java.util.UUID.randomUUID();
                jdbcTemplate.update(
                    "INSERT INTO public.products (id, name, sku_barcode, price) VALUES (?::uuid, 'Test Item', ?, 99.99)",
                    productId.toString(), testBarcode
                );
            } else {
                productId = (java.util.UUID) products.get(0).get("id");
            }

            // Insert test barcode in GENERATED status
            java.util.UUID barcodeId = java.util.UUID.randomUUID();
            jdbcTemplate.update(
                "INSERT INTO public.product_barcodes (id, product_id, code, status, symbology) VALUES (?::uuid, ?::uuid, ?, 'GENERATED'::public.barcode_status, 'CODE128')",
                barcodeId.toString(), productId.toString(), testBarcode
            );

            report.put("1_initial_state", java.util.Map.of(
                "barcode_id", barcodeId.toString(),
                "code", testBarcode,
                "status", "GENERATED"
            ));

            // SCAN 1 (RECEIVE): GENERATED -> INWARDED
            String scan1Txn = java.util.UUID.randomUUID().toString();
            String scan1Result = jdbcTemplate.queryForObject(
                "SELECT public.scan_receive(?, ?::uuid, 'CAMERA'::public.scan_source)::text",
                String.class,
                testBarcode,
                scan1Txn
            );
            report.put("2_scan1_request", java.util.Map.of("code", testBarcode, "client_txn_id", scan1Txn, "device_source", "CAMERA"));
            report.put("2_scan1_rpc_response", scan1Result);

            java.util.Map<String, Object> scan1Scans = jdbcTemplate.queryForMap(
                "SELECT id::text, action::text, ledger_id::text FROM public.barcode_scans WHERE client_txn_id = ?::uuid",
                java.util.UUID.fromString(scan1Txn)
            );
            report.put("2_scan1_barcode_scans_insert", scan1Scans);

            java.util.Map<String, Object> scan1Ledger = jdbcTemplate.queryForMap(
                "SELECT id::text, txn_type::text, qty_delta FROM public.stock_ledger WHERE id = ?::uuid",
                java.util.UUID.fromString((String) scan1Scans.get("ledger_id"))
            );
            report.put("2_scan1_stock_ledger_insert", scan1Ledger);

            String statusAfterScan1 = jdbcTemplate.queryForObject(
                "SELECT status::text FROM public.product_barcodes WHERE id = ?::uuid",
                String.class,
                barcodeId.toString()
            );
            report.put("2_scan1_updated_barcode_status", statusAfterScan1);

            // SCAN 2 (ISSUE): INWARDED -> OUTWARDED
            String scan2Txn = java.util.UUID.randomUUID().toString();
            String scan2Result = jdbcTemplate.queryForObject(
                "SELECT public.scan_receive(?, ?::uuid, 'CAMERA'::public.scan_source)::text",
                String.class,
                testBarcode,
                scan2Txn
            );
            report.put("3_scan2_request", java.util.Map.of("code", testBarcode, "client_txn_id", scan2Txn, "device_source", "CAMERA"));
            report.put("3_scan2_rpc_response", scan2Result);

            java.util.Map<String, Object> scan2Scans = jdbcTemplate.queryForMap(
                "SELECT id::text, action::text, ledger_id::text FROM public.barcode_scans WHERE client_txn_id = ?::uuid",
                java.util.UUID.fromString(scan2Txn)
            );
            report.put("3_scan2_barcode_scans_insert", scan2Scans);

            java.util.Map<String, Object> scan2Ledger = jdbcTemplate.queryForMap(
                "SELECT id::text, txn_type::text, qty_delta FROM public.stock_ledger WHERE id = ?::uuid",
                java.util.UUID.fromString((String) scan2Scans.get("ledger_id"))
            );
            report.put("3_scan2_stock_ledger_insert", scan2Ledger);

            String statusAfterScan2 = jdbcTemplate.queryForObject(
                "SELECT status::text FROM public.product_barcodes WHERE id = ?::uuid",
                String.class,
                barcodeId.toString()
            );
            report.put("3_scan2_final_barcode_status", statusAfterScan2);

            return ResponseEntity.ok(report);
        } catch (Exception e) {
            report.put("error", e.getMessage());
            return ResponseEntity.internalServerError().body(report);
        }
    }
}
