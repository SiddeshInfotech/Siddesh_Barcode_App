package com.inventorymanagement.dto;

import lombok.*;

/**
 * Data transfer object for recording inward or outward transactions.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransactionRequest {

    private Long productId;
    private String barcode;
    private int quantity;
}
