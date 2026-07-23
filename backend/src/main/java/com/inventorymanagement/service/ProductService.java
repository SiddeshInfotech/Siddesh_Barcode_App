package com.inventorymanagement.service;

import com.inventorymanagement.dto.CreateProductRequest;
import com.inventorymanagement.dto.ProductResponse;
import com.inventorymanagement.dto.UpdateProductRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

/**
 * Service interface defining business contracts for Product management.
 */
public interface ProductService {

    /**
     * Creates a new Product in the system.
     *
     * @param request the product details
     * @return the created product details
     */
    ProductResponse createProduct(CreateProductRequest request);

    /**
     * Updates an existing Product.
     *
     * @param id      the identifier of the product to update
     * @param request the product update details
     * @return the updated product details
     */
    ProductResponse updateProduct(Long id, UpdateProductRequest request);

    /**
     * Fetches details of a Product by its ID.
     *
     * @param id the product identifier
     * @return the product details
     */
    ProductResponse getProductById(Long id);

    /**
     * Fetches details of a Product by its unique Barcode.
     *
     * @param barcode the unique barcode
     * @return the product details
     */
    ProductResponse getProductByBarcode(String barcode);

    /**
     * Lists all Products in a pageable format.
     *
     * @param pageable pagination options
     * @return a page of products
     */
    Page<ProductResponse> getAllProducts(Pageable pageable);

    /**
     * Deletes a Product from the system.
     *
     * @param id the product identifier
     */
    void deleteProduct(Long id);
}
