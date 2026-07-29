package com.inventorymanagement.dto;

import lombok.*;

/**
 * Data transfer object representing dashboard metrics and stock statistics.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardStatsResponse {

    private long currentStock;
    private long todayInward;
    private long todayOutward;
    private long lowStockItems;
}
