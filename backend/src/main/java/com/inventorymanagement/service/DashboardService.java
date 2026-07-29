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
     * Records an inward inventory movement transaction.
     *
     * @param request transaction details (productId, barcode, quantity)
     */
    void recordInward(TransactionRequest request);

    /**
     * Records an outward inventory movement transaction.
     *
     * @param request transaction details (productId, barcode, quantity)
     */
    void recordOutward(TransactionRequest request);
}
