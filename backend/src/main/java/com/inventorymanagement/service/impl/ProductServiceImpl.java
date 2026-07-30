package com.inventorymanagement.service.impl;

import com.inventorymanagement.dto.CreateProductRequest;
import com.inventorymanagement.dto.ProductResponse;
import com.inventorymanagement.dto.UpdateProductRequest;
import com.inventorymanagement.entity.Product;
import com.inventorymanagement.entity.ProductBarcode;
import com.inventorymanagement.exception.ResourceNotFoundException;
import com.inventorymanagement.repository.ProductBarcodeRepository;
import com.inventorymanagement.repository.ProductRepository;
import com.inventorymanagement.service.ProductService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Service implementation offering transactional business operations on Product entity resources.
 */
@Slf4j
@Service
@Transactional
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;
    private final ProductBarcodeRepository productBarcodeRepository;

    /**
     * Constructs a new ProductServiceImpl.
     *
     * @param productRepository        the ProductRepository dependency
     * @param productBarcodeRepository the ProductBarcodeRepository dependency
     */
    public ProductServiceImpl(
            ProductRepository productRepository,
            ProductBarcodeRepository productBarcodeRepository) {
        this.productRepository = productRepository;
        this.productBarcodeRepository = productBarcodeRepository;
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

        // Bulk insert generated barcodes for this product into product_barcodes table
        UUID productUuid = new UUID(0L, savedProduct.getId());
        List<String> barcodeStrings = determineBarcodeList(request);
        List<ProductBarcode> barcodesToSave = new ArrayList<>();

        for (String code : barcodeStrings) {
            if (code != null && !code.trim().isEmpty() && !productBarcodeRepository.existsByCode(code.trim())) {
                barcodesToSave.add(ProductBarcode.builder()
                        .productId(productUuid)
                        .code(code.trim())
                        .build());
            }
        }

        if (!barcodesToSave.isEmpty()) {
            productBarcodeRepository.saveAll(barcodesToSave);
            log.info("Bulk inserted {} barcodes for Product ID: {}", barcodesToSave.size(), savedProduct.getId());
        }

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
        String cleanBarcode = barcode != null ? barcode.trim() : "";
        log.info("Fetching product details for Barcode: {}", cleanBarcode);

        // 1. Try finding in products table directly by primary barcode
        var productOpt = productRepository.findByBarcodeIgnoreCase(cleanBarcode);
        if (productOpt.isPresent()) {
            return mapToResponse(productOpt.get());
        }

        // 2. Fall back to finding in product_barcodes table
        var productBarcodeOpt = productBarcodeRepository.findByCodeIgnoreCase(cleanBarcode);
        if (productBarcodeOpt.isPresent()) {
            UUID pUuid = productBarcodeOpt.get().getProductId();
            Long numericProductId = pUuid.getLeastSignificantBits();
            Product product = productRepository.findById(numericProductId)
                    .orElseThrow(() -> new ResourceNotFoundException("Product not found with barcode: " + cleanBarcode));
            return mapToResponse(product);
        }

        throw new ResourceNotFoundException("Product not found with barcode: " + cleanBarcode);
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
        
        // Also remove linked barcodes in product_barcodes table
        UUID productUuid = new UUID(0L, id);
        List<ProductBarcode> barcodes = productBarcodeRepository.findByProductId(productUuid);
        if (!barcodes.isEmpty()) {
            productBarcodeRepository.deleteAll(barcodes);
        }

        productRepository.delete(product);
        log.info("Successfully deleted product with ID: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public long getBarcodeCountByProductId(Long id) {
        UUID productUuid = new UUID(0L, id);
        return productBarcodeRepository.countByProductId(productUuid);
    }

    private List<String> determineBarcodeList(CreateProductRequest request) {
        if (request.getBarcodes() != null && !request.getBarcodes().isEmpty()) {
            return request.getBarcodes();
        }

        List<String> list = new ArrayList<>();
        String baseBarcode = request.getBarcode() != null ? request.getBarcode().trim() : "";
        int quantity = request.getQuantity() != null && request.getQuantity() > 0 ? request.getQuantity() : 1;

        Pattern pattern = Pattern.compile("^(.*-)(\\d+)$");
        Matcher matcher = pattern.matcher(baseBarcode);

        if (matcher.matches()) {
            String prefix = matcher.group(1);
            String numberStr = matcher.group(2);
            int startIdx = Integer.parseInt(numberStr);
            int digits = numberStr.length();
            String format = "%0" + digits + "d";

            for (int i = 0; i < quantity; i++) {
                list.add(prefix + String.format(format, startIdx + i));
            }
        } else if (quantity > 1) {
            for (int i = 1; i <= quantity; i++) {
                list.add(String.format("%s-%04d", baseBarcode, i));
            }
        } else {
            list.add(baseBarcode);
        }

        if (!list.contains(baseBarcode)) {
            list.add(0, baseBarcode);
        }

        return list;
    }

    private ProductResponse mapToResponse(Product product) {
        UUID productUuid = new UUID(0L, product.getId());
        List<ProductBarcode> pBarcodes = productBarcodeRepository.findByProductId(productUuid);
        List<String> codeList = pBarcodes.stream().map(ProductBarcode::getCode).toList();

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
                .barcodes(codeList)
                .barcodeCount((long) codeList.size())
                .build();
    }
}
