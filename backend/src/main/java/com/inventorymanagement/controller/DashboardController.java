package com.inventorymanagement.controller;

import com.inventorymanagement.dto.DashboardStatsResponse;
import com.inventorymanagement.dto.TransactionRequest;
import com.inventorymanagement.service.DashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Controller exposing REST endpoints for dashboard inventory metrics and stock transactions.
 */
@Slf4j
@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@Tag(name = "Dashboard", description = "Endpoints for real-time inventory dashboard statistics and transactions")
public class DashboardController {

    private final DashboardService dashboardService;

    /**
     * Fetches live dashboard inventory statistics.
     *
     * @return ResponseEntity containing DashboardStatsResponse.
     */
    @GetMapping("/stats")
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER', 'SALES_EXECUTIVE')")
    @Operation(summary = "Get Dashboard Statistics", description = "Retrieves live metrics: current stock, today's inward count, today's outward count, and low stock item count.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Dashboard stats calculated successfully"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires appropriate authentication")
    })
    public ResponseEntity<DashboardStatsResponse> getDashboardStats() {
        return ResponseEntity.ok(dashboardService.getDashboardStats());
    }

    /**
     * Records an inward stock entry transaction.
     *
     * @param request the transaction details
     * @return ResponseEntity with 200 OK
     */
    @PostMapping("/inward")
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER', 'SALES_EXECUTIVE')")
    @Operation(summary = "Record Inward Transaction", description = "Records inward inventory transaction and updates total stock metrics.")
    public ResponseEntity<Void> recordInward(@RequestBody TransactionRequest request) {
        log.info("[STEP 3] Controller entered: POST /api/dashboard/inward | Barcode: '{}', Quantity: {}, ProductId: {}",
                request != null ? request.getBarcode() : "NULL",
                request != null ? request.getQuantity() : 0,
                request != null ? request.getProductId() : "NULL");
        dashboardService.recordInward(request);
        return ResponseEntity.ok().build();
    }

    /**
     * Records an outward stock entry transaction.
     *
     * @param request the transaction details
     * @return ResponseEntity with 200 OK
     */
    @PostMapping("/outward")
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER', 'SALES_EXECUTIVE')")
    @Operation(summary = "Record Outward Transaction", description = "Records outward inventory transaction and updates total stock metrics.")
    public ResponseEntity<Void> recordOutward(@RequestBody TransactionRequest request) {
        log.info("[STEP 3] Controller entered: POST /api/dashboard/outward | Barcode: '{}', Quantity: {}, ProductId: {}",
                request != null ? request.getBarcode() : "NULL",
                request != null ? request.getQuantity() : 0,
                request != null ? request.getProductId() : "NULL");
        dashboardService.recordOutward(request);
        return ResponseEntity.ok().build();
    }
}
