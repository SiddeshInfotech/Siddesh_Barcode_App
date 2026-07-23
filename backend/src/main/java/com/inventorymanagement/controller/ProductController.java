package com.inventorymanagement.controller;

import com.inventorymanagement.dto.CreateProductRequest;
import com.inventorymanagement.dto.ProductResponse;
import com.inventorymanagement.dto.UpdateProductRequest;
import com.inventorymanagement.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller class defining endpoints for product catalog operations.
 */
@RestController
@RequestMapping("/api/products")
@Tag(name = "Product Management", description = "Endpoints for managing inventory products")
@SecurityRequirement(name = "bearerAuth")
public class ProductController {

    private final ProductService productService;

    /**
     * Constructs a new ProductController.
     *
     * @param productService the ProductService dependency
     */
    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    /**
     * Creates a new product catalog record (Admin & Store Manager only).
     *
     * @param request the CreateProductRequest payload
     * @return a ResponseEntity containing the created ProductResponse details
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER')")
    @Operation(summary = "Create a new product", description = "Allows administrators and store managers to add a new product to the inventory.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "201", description = "Product successfully created",
            content = @Content(schema = @Schema(implementation = ProductResponse.class))),
        @ApiResponse(responseCode = "400", description = "Invalid request payload or duplicate name/barcode/SKU"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires Admin or Store Manager role")
    })
    public ResponseEntity<ProductResponse> createProduct(@Valid @RequestBody CreateProductRequest request) {
        ProductResponse response = productService.createProduct(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * Updates an existing product's catalog details (Admin & Store Manager only).
     *
     * @param id      the product identifier to update
     * @param request the UpdateProductRequest payload
     * @return a ResponseEntity containing the updated ProductResponse details
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER')")
    @Operation(summary = "Update an existing product", description = "Allows administrators and store managers to update product details by ID.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Product successfully updated",
            content = @Content(schema = @Schema(implementation = ProductResponse.class))),
        @ApiResponse(responseCode = "400", description = "Invalid request payload or constraint violations"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires Admin or Store Manager role"),
        @ApiResponse(responseCode = "404", description = "Product not found")
    })
    public ResponseEntity<ProductResponse> updateProduct(
            @Parameter(description = "ID of the product to update", required = true)
            @PathVariable Long id,
            @Valid @RequestBody UpdateProductRequest request) {
        ProductResponse response = productService.updateProduct(id, request);
        return ResponseEntity.ok(response);
    }

    /**
     * Retrieves product details by ID (All authenticated roles).
     *
     * @param id the product identifier to retrieve
     * @return a ResponseEntity containing the ProductResponse details
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER', 'SALES_EXECUTIVE')")
    @Operation(summary = "Get product by ID", description = "Retrieves details of a product using its ID.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Product details retrieved successfully",
            content = @Content(schema = @Schema(implementation = ProductResponse.class))),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires appropriate authentication"),
        @ApiResponse(responseCode = "404", description = "Product not found")
    })
    public ResponseEntity<ProductResponse> getProductById(
            @Parameter(description = "ID of the product to retrieve", required = true)
            @PathVariable Long id) {
        ProductResponse response = productService.getProductById(id);
        return ResponseEntity.ok(response);
    }

    /**
     * Retrieves product details by barcode (All authenticated roles).
     *
     * @param barcode the product barcode to search for
     * @return a ResponseEntity containing the ProductResponse details
     */
    @GetMapping("/barcode/{barcode}")
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER', 'SALES_EXECUTIVE')")
    @Operation(summary = "Get product by Barcode", description = "Retrieves details of a product using its unique barcode identifier.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Product details retrieved successfully",
            content = @Content(schema = @Schema(implementation = ProductResponse.class))),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires appropriate authentication"),
        @ApiResponse(responseCode = "404", description = "Product not found")
    })
    public ResponseEntity<ProductResponse> getProductByBarcode(
            @Parameter(description = "Barcode of the product to retrieve", required = true)
            @PathVariable String barcode) {
        ProductResponse response = productService.getProductByBarcode(barcode);
        return ResponseEntity.ok(response);
    }

    /**
     * Lists all products in the inventory catalog (All authenticated roles).
     *
     * @param page    zero-based page index
     * @param size    number of records per page
     * @param sortBy  property to sort by
     * @param sortDir sorting direction ("asc" or "desc")
     * @return a ResponseEntity containing a Page of ProductResponse elements
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER', 'SALES_EXECUTIVE')")
    @Operation(summary = "Get all products paginated", description = "Retrieves a pageable list of all products in the catalog.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Page of products retrieved successfully"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires appropriate authentication")
    })
    public ResponseEntity<Page<ProductResponse>> getAllProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {

        Sort sort = sortDir.equalsIgnoreCase(Sort.Direction.DESC.name())
                ? Sort.by(sortBy).descending()
                : Sort.by(sortBy).ascending();

        Pageable pageable = PageRequest.of(page, size, sort);
        Page<ProductResponse> response = productService.getAllProducts(pageable);
        return ResponseEntity.ok(response);
    }

    /**
     * Deletes a product from the catalog (Admin only).
     *
     * @param id the product identifier to delete
     * @return a ResponseEntity indicating success (No Content)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Delete product", description = "Permanently deletes a product from the catalog. Restricted to administrators only.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "204", description = "Product successfully deleted"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires Admin role"),
        @ApiResponse(responseCode = "404", description = "Product not found")
    })
    public ResponseEntity<Void> deleteProduct(
            @Parameter(description = "ID of the product to delete", required = true)
            @PathVariable Long id) {
        productService.deleteProduct(id);
        return ResponseEntity.noContent().build();
    }
}
