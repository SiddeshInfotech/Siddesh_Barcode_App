package com.inventorymanagement.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * Data Transfer Object representing a product creation request.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateProductRequest {

    @NotBlank(message = "Product name is required")
    @Size(max = 100, message = "Product name must not exceed 100 characters")
    private String name;

    @Size(max = 500, message = "Description must not exceed 500 characters")
    private String description;

    @NotBlank(message = "Barcode is required")
    @Size(max = 50, message = "Barcode must not exceed 50 characters")
    private String barcode;

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.0", message = "Price must be equal to or greater than 0.0")
    private BigDecimal price;

    @NotNull(message = "Quantity is required")
    @Min(value = 0, message = "Quantity must be equal to or greater than 0")
    private Integer quantity;

    @Size(max = 50, message = "SKU must not exceed 50 characters")
    private String sku;

    @Size(max = 100, message = "Category must not exceed 100 characters")
    private String category;

    @Size(max = 100, message = "Brand name must not exceed 100 characters")
    private String brand;
}
