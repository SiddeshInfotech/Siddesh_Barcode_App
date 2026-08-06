package com.inventorymanagement.service;

import com.inventorymanagement.dto.DashboardStatsResponse;
import com.inventorymanagement.dto.TransactionRequest;

/**
 * Service interface for calculating dashboard inventory statistics and processing stock movement transactions.
 */
public interface DashboardService {

    /**
     * Calculates live dashboard statistics.
     *
     * @return DashboardStatsResponse containing currentStock, todayInward, todayOutward, and lowStockItems metrics.
     */
    DashboardStatsResponse getDashboardStats();

    /**
     * Records an inward inventory movement transaction and advances the barcode status.
     *
     * @param request transaction details (productId, barcode, quantity)
     * @return the barcode's confirmed status after the committed update (e.g. "INWARDED")
     */
    String recordInward(TransactionRequest request);

    /**
     * Records an outward inventory movement transaction and advances the barcode status.
     *
     * @param request transaction details (productId, barcode, quantity)
     * @return the barcode's confirmed status after the committed update (e.g. "OUTWARDED")
     */
    String recordOutward(TransactionRequest request);
}
