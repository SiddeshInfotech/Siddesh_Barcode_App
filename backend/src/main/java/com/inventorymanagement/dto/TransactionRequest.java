package com.inventorymanagement.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
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

    private String id;
    private Long productId;

    @JsonAlias({"code", "barcode"})
    private String barcode;

    @JsonAlias({"barcode", "code"})
    private String code;

    private int quantity;

    public String getEffectiveBarcode() {
        if (barcode != null && !barcode.trim().isEmpty()) {
            return barcode.trim();
        }
        if (code != null && !code.trim().isEmpty()) {
            return code.trim();
        }
        return "";
    }
}
