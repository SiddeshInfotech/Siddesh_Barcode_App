package com.inventorymanagement.service.impl;

import com.inventorymanagement.dto.CreateProductRequest;
import com.inventorymanagement.dto.ProductResponse;
import com.inventorymanagement.dto.UpdateProductRequest;
import com.inventorymanagement.entity.Product;
import com.inventorymanagement.exception.ResourceNotFoundException;
import com.inventorymanagement.repository.ProductRepository;
import com.inventorymanagement.service.ProductService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service implementation offering transactional business operations on Product entity resources.
 */
@Slf4j
@Service
@Transactional
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;

    /**
     * Constructs a new ProductServiceImpl.
     *
     * @param productRepository the ProductRepository dependency
     */
    public ProductServiceImpl(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    @Override
    public ProductResponse createProduct(CreateProductRequest request) {
        log.info("Attempting to create product with name: {}, barcode: {}", request.getName(), request.getBarcode());

        if (productRepository.existsByName(request.getName())) {
            log.warn("Product creation failed: name {} already exists", request.getName());
            throw new IllegalArgumentException("Product name already exists: " + request.getName());
        }

        if (productRepository.existsByBarcode(request.getBarcode())) {
            log.warn("Product creation failed: barcode {} already exists", request.getBarcode());
            throw new IllegalArgumentException("Product barcode already exists: " + request.getBarcode());
        }

        if (request.getSku() != null && !request.getSku().trim().isEmpty() && productRepository.existsBySku(request.getSku())) {
            log.warn("Product creation failed: SKU {} already exists", request.getSku());
            throw new IllegalArgumentException("Product SKU already exists: " + request.getSku());
        }

        Product product = Product.builder()
                .name(request.getName())
                .description(request.getDescription())
                .barcode(request.getBarcode())
                .price(request.getPrice())
                .quantity(request.getQuantity())
                .sku(request.getSku())
                .category(request.getCategory())
                .brand(request.getBrand())
                .build();

        Product savedProduct = productRepository.save(product);
        log.info("Successfully created product with ID: {}", savedProduct.getId());
        return mapToResponse(savedProduct);
    }

    @Override
    public ProductResponse updateProduct(Long id, UpdateProductRequest request) {
        log.info("Attempting to update product ID: {}", id);

        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with id: " + id));

        if (!product.getName().equalsIgnoreCase(request.getName()) && productRepository.existsByNameAndIdNot(request.getName(), id)) {
            log.warn("Product update failed: name {} already in use by another product", request.getName());
            throw new IllegalArgumentException("Product name already exists: " + request.getName());
        }

        if (!product.getBarcode().equalsIgnoreCase(request.getBarcode()) && productRepository.existsByBarcodeAndIdNot(request.getBarcode(), id)) {
            log.warn("Product update failed: barcode {} already in use by another product", request.getBarcode());
            throw new IllegalArgumentException("Product barcode already exists: " + request.getBarcode());
        }

        if (request.getSku() != null && !request.getSku().trim().isEmpty() && 
            (product.getSku() == null || !product.getSku().equalsIgnoreCase(request.getSku())) && 
            productRepository.existsBySkuAndIdNot(request.getSku(), id)) {
            log.warn("Product update failed: SKU {} already in use by another product", request.getSku());
            throw new IllegalArgumentException("Product SKU already exists: " + request.getSku());
        }

        product.setName(request.getName());
        product.setDescription(request.getDescription());
        product.setBarcode(request.getBarcode());
        product.setPrice(request.getPrice());
        product.setQuantity(request.getQuantity());
        product.setSku(request.getSku());
        product.setCategory(request.getCategory());
        product.setBrand(request.getBrand());

        Product updatedProduct = productRepository.save(product);
        log.info("Successfully updated product with ID: {}", updatedProduct.getId());
        return mapToResponse(updatedProduct);
    }

    @Override
    @Transactional(readOnly = true)
    public ProductResponse getProductById(Long id) {
        log.info("Fetching product details for ID: {}", id);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with id: " + id));
        return mapToResponse(product);
    }

    @Override
    @Transactional(readOnly = true)
    public ProductResponse getProductByBarcode(String barcode) {
        log.info("Fetching product details for Barcode: {}", barcode);
        Product product = productRepository.findByBarcode(barcode)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with barcode: " + barcode));
        return mapToResponse(product);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ProductResponse> getAllProducts(Pageable pageable) {
        log.info("Fetching all products with pagination: {}", pageable);
        return productRepository.findAll(pageable).map(this::mapToResponse);
    }

    @Override
    public void deleteProduct(Long id) {
        log.info("Attempting to delete product with ID: {}", id);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with id: " + id));
        productRepository.delete(product);
        log.info("Successfully deleted product with ID: {}", id);
    }

    private ProductResponse mapToResponse(Product product) {
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .description(product.getDescription())
                .barcode(product.getBarcode())
                .price(product.getPrice())
                .quantity(product.getQuantity())
                .sku(product.getSku())
                .category(product.getCategory())
                .brand(product.getBrand())
                .createdAt(product.getCreatedAt())
                .updatedAt(product.getUpdatedAt())
                .build();
    }
}
