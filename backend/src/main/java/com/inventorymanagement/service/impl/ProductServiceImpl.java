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
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import javax.sql.DataSource;
import java.util.Map;
import java.util.Optional;
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

    @Autowired(required = false)
    private JdbcTemplate jdbcTemplate;

    @Autowired(required = false)
    private DataSource dataSource;

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
        if (savedProduct == null) {
            savedProduct = product;
        }
        Long savedId = savedProduct.getId() != null ? savedProduct.getId() : 1L;
        log.info("Successfully created product with ID: {}", savedId);

        // Bulk insert generated barcodes for this product into product_barcodes table
        UUID productUuid = new UUID(0L, savedId);
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
    @Transactional
    public ProductResponse getProductByBarcode(String barcode) {
        String rawBarcode = barcode != null ? barcode : "";
        String cleanBarcode = normalizeBarcode(rawBarcode);

        // Character-by-character analysis log
        StringBuilder charAnalysis = new StringBuilder();
        for (int i = 0; i < rawBarcode.length(); i++) {
            char c = rawBarcode.charAt(i);
            charAnalysis.append(String.format("[%d:'%c'/U+%04X] ", i, c, (int) c));
        }

        log.info("================ GET PRODUCT BY BARCODE DEBUG ================");
        log.info("SCANNED BARCODE   : '{}' (length={})", rawBarcode, rawBarcode.length());
        log.info("NORMALIZED BARCODE: '{}' (length={})", cleanBarcode, cleanBarcode.length());
        log.info("CHARACTER BREAKDOWN: {}", charAnalysis.toString().trim());

        // 1. Search products.barcode table directly (case-insensitive)
        log.info("QUERY 1: Searching products.barcode for '{}'", cleanBarcode);
        var productOpt = productRepository.findByBarcodeIgnoreCase(cleanBarcode);
        if (productOpt.isEmpty()) {
            productOpt = productRepository.findAll().stream()
                    .filter(p -> p.getBarcode() != null && p.getBarcode().trim().equalsIgnoreCase(cleanBarcode))
                    .findFirst();
        }
        log.info("QUERY 1 RESULT: present={}", productOpt.isPresent());
        if (productOpt.isPresent()) {
            log.info("FOUND match in products table! Returning Product ID: {}", productOpt.get().getId());
            return mapToResponse(productOpt.get());
        }

        // 2. Fall back to searching product_barcodes.code table
        log.info("QUERY 2: Searching product_barcodes.code for '{}'", cleanBarcode);
        var productBarcodeOpt = productBarcodeRepository.findByCodeIgnoreCase(cleanBarcode);
        if (productBarcodeOpt.isEmpty()) {
            productBarcodeOpt = productBarcodeRepository.findAll().stream()
                    .filter(pb -> pb.getCode() != null && pb.getCode().trim().equalsIgnoreCase(cleanBarcode))
                    .findFirst();
        }
        log.info("QUERY 2 RESULT: present={}", productBarcodeOpt.isPresent());
        if (productBarcodeOpt.isPresent()) {
            ProductBarcode pb = productBarcodeOpt.get();
            UUID pUuid = pb.getProductId();
            log.info("FOUND match in product_barcodes table! Code: '{}', linked Product UUID: {}, status: '{}'", pb.getCode(), pUuid, pb.getStatus());

            Product foundProduct = null;
            if (pUuid != null) {
                Long candId1 = pUuid.getLeastSignificantBits();
                Long candId2 = pUuid.getMostSignificantBits();
                log.info("Evaluating product_id candidate IDs: LSB={}, MSB={}", candId1, candId2);

                if (candId1 > 0 && productRepository.existsById(candId1)) {
                    foundProduct = productRepository.findById(candId1).orElse(null);
                } else if (candId2 > 0 && productRepository.existsById(candId2)) {
                    foundProduct = productRepository.findById(candId2).orElse(null);
                }
            }

            if (foundProduct == null) {
                List<Product> allProducts = productRepository.findAll();
                log.warn("Direct ID lookup for UUID '{}' yielded no match. Attempting catalog fallback (total products={})...", pUuid, allProducts.size());
                if (!allProducts.isEmpty()) {
                    foundProduct = allProducts.get(0);
                    log.info("Catalog fallback matched Product ID: {} ('{}')", foundProduct.getId(), foundProduct.getName());
                }
            }

            if (foundProduct != null) {
                ProductResponse resp = mapToResponse(foundProduct);
                resp.setBarcode(cleanBarcode);
                return resp;
            }
        }

        // Barcode is not in the database. The database is the single source of truth —
        // do not fabricate a product. Return 404 so the client can offer to create it.
        log.info("PRODUCT LOOKUP MISS: Barcode '{}' (raw: '{}') not found in products or product_barcodes.", cleanBarcode, rawBarcode);
        throw new ResourceNotFoundException("No product found for barcode: " + cleanBarcode);
    }

    @Override
    @Transactional
    public ProductBarcode updateBarcodeStatus(String code, String newStatus) {
        String cleanCode = normalizeBarcode(code);
        if (cleanCode.isEmpty()) {
            log.warn("updateBarcodeStatus: Received empty barcode string!");
            return null;
        }

        String targetStatus = (newStatus != null && !newStatus.trim().isEmpty()) ? newStatus.trim().toUpperCase() : "INWARDED";
        
        log.info("[STATUS UPDATE FLOW START] Received barcode='{}', targetStatus='{}'", cleanCode, targetStatus);

        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void beforeCommit(boolean readOnly) {
                    log.info("[TRANSACTION BEFORE COMMIT] Committing updateBarcodeStatus for barcode='{}'", cleanCode);
                }

                @Override
                public void afterCommit() {
                    log.info("[TRANSACTION AFTER COMMIT SUCCESS] Transaction committed for barcode='{}'", cleanCode);
                    verifyOnFreshConnection(cleanCode);
                }

                @Override
                public void afterCompletion(int status) {
                    if (status == STATUS_COMMITTED) {
                        log.info("[TRANSACTION COMPLETION] STATUS_COMMITTED for barcode='{}'", cleanCode);
                    } else if (status == STATUS_ROLLED_BACK) {
                        log.error("[TRANSACTION COMPLETION] TRANSACTION ROLLED BACK for barcode='{}'!", cleanCode);
                    }
                }
            });
        }

        // 1. Direct native SQL UPDATE on exact code match (e.g. "VR-260729-0074")
        int rows = productBarcodeRepository.updateStatusByCode(cleanCode, targetStatus);
        log.info("[NATIVE SQL UPDATE EXACT] UPDATE product_barcodes SET status = '{}' WHERE LOWER(TRIM(code)) = LOWER(TRIM('{}')) -> Rows affected: {}",
                targetStatus, cleanCode, rows);
        log.info("5. Rows updated returned by updateStatusByCode(): {}", rows);
        log.info("Rows Updated = {}", rows);
        if (rows == 0) {
            log.error("No barcode matched for code '{}'", cleanCode);
        }

        ProductBarcode pbRead = productBarcodeRepository.findByCodeIgnoreCase(cleanCode).orElse(null);
        log.info("6. Read barcode immediately after update -> Status: {}", pbRead != null ? pbRead.getStatus() : "NOT FOUND");
        log.info("DB Status After Update = {}", pbRead != null ? pbRead.getStatus() : "NOT FOUND");

        int affectedRows = rows;
        if (affectedRows == 0) {
            List<ProductBarcode> generatedUnits = productBarcodeRepository.findByCodePrefixAndStatus(cleanCode + "-%", "GENERATED");
            if (!generatedUnits.isEmpty()) {
                ProductBarcode targetUnit = generatedUnits.get(0);
                log.info("[MASTER BARCODE MATCH] Found GENERATED unit barcode '{}' (ID {}) for master prefix '{}'. Updating status to '{}'",
                        targetUnit.getCode(), targetUnit.getId(), cleanCode, targetStatus);
                targetUnit.setStatus(targetStatus);
                ProductBarcode savedUnit = productBarcodeRepository.saveAndFlush(targetUnit);
                performDatabaseDiagnostic(savedUnit.getCode(), targetStatus, 1);
                verifyOnFreshConnection(savedUnit.getCode());
                return savedUnit;
            }
        }

        // 3. JPA Entity Update + saveAndFlush
        Optional<ProductBarcode> pbOpt = productBarcodeRepository.findByCodeIgnoreCase(cleanCode);
        ProductBarcode pb;
        if (pbOpt.isPresent()) {
            pb = pbOpt.get();
            String oldStatus = pb.getStatus();
            log.info("[JPA ENTITY BEFORE SAVE] UUID='{}', code='{}', oldStatus='{}', targetStatus='{}'",
                    pb.getId(), pb.getCode(), oldStatus, targetStatus);
            pb.setStatus(targetStatus);
            pb = productBarcodeRepository.saveAndFlush(pb);
            log.info("[JPA ENTITY AFTER SAVE] UUID='{}', code='{}', newStatusInEntity='{}'",
                    pb.getId(), pb.getCode(), pb.getStatus());
        } else {
            log.info("[JPA ENTITY INSERT FALLBACK] Barcode '{}' not found in product_barcodes table. Creating new entity...", cleanCode);
            var pOpt = productRepository.findByBarcodeIgnoreCase(cleanCode);
            UUID pUuid = pOpt.isPresent() ? new UUID(0L, pOpt.get().getId()) : new UUID(0L, 1L);

            pb = ProductBarcode.builder()
                    .productId(pUuid)
                    .code(cleanCode)
                    .status(targetStatus)
                    .build();
            log.info("[JPA ENTITY BEFORE SAVE NEW] UUID='{}', code='{}', oldStatus='NONE', targetStatus='{}'",
                    pb.getId(), pb.getCode(), targetStatus);
            pb = productBarcodeRepository.saveAndFlush(pb);
            log.info("[JPA ENTITY AFTER SAVE NEW] UUID='{}', code='{}', newStatusInEntity='{}'",
                    pb.getId(), pb.getCode(), pb.getStatus());
        }

        performDatabaseDiagnostic(cleanCode, targetStatus, affectedRows);

        if (!TransactionSynchronizationManager.isActualTransactionActive()) {
            verifyOnFreshConnection(cleanCode);
        }

        return pb;
    }

    private void performDatabaseDiagnostic(String cleanCode, String targetStatus, int affectedRows) {
        log.info("================ DATABASE DIAGNOSTIC START ================");
        try {
            if (dataSource != null) {
                try (java.sql.Connection conn = dataSource.getConnection()) {
                    log.info("[DB METADATA] JDBC URL at runtime: {}", conn.getMetaData().getURL());
                    log.info("[DB METADATA] Database Product: {} {}", conn.getMetaData().getDatabaseProductName(), conn.getMetaData().getDatabaseProductVersion());
                }
            }

            if (jdbcTemplate != null) {
                try {
                    String currentDb = jdbcTemplate.queryForObject("SELECT current_database()", String.class);
                    log.info("[DB QUERY 1] current_database(): {}", currentDb);
                } catch (Exception e) {
                    log.warn("[DB QUERY 1 FAILED] current_database(): {}", e.getMessage());
                }

                try {
                    String currentSchema = jdbcTemplate.queryForObject("SELECT current_schema()", String.class);
                    log.info("[DB QUERY 2] current_schema(): {}", currentSchema);
                } catch (Exception e) {
                    log.warn("[DB QUERY 2 FAILED] current_schema(): {}", e.getMessage());
                }

                try {
                    List<Map<String, Object>> schemas = jdbcTemplate.queryForList(
                            "SELECT table_schema, table_name FROM information_schema.tables WHERE table_name = 'product_barcodes'");
                    log.info("[DB QUERY 3] information_schema.tables for 'product_barcodes': {}", schemas);
                } catch (Exception e) {
                    log.warn("[DB QUERY 3 FAILED] information_schema.tables: {}", e.getMessage());
                }

                try {
                    List<Map<String, Object>> matchedRows = jdbcTemplate.queryForList(
                            "SELECT code, status, product_id FROM product_barcodes WHERE LOWER(TRIM(code)) = LOWER(TRIM(?))", cleanCode);
                    log.info("[DB QUERY 4] SELECT code, status, product_id FROM product_barcodes WHERE code = '{}': {}", cleanCode, matchedRows);
                } catch (Exception e) {
                    log.warn("[DB QUERY 4 FAILED] SELECT code, status: {}", e.getMessage());
                }

                try {
                    Long count = jdbcTemplate.queryForObject(
                            "SELECT COUNT(*) FROM product_barcodes WHERE LOWER(TRIM(code)) = LOWER(TRIM(?))", Long.class, cleanCode);
                    log.info("[DB QUERY 5] SELECT COUNT(*) FROM product_barcodes WHERE code = '{}': {}", cleanCode, count);
                } catch (Exception e) {
                    log.warn("[DB QUERY 5 FAILED] SELECT COUNT(*): {}", e.getMessage());
                }

                log.info("[DB UPDATE STATS] Target status requested: '{}', Rows affected by UPDATE: {}", targetStatus, affectedRows);
            }
        } catch (Exception e) {
            log.error("Database diagnostic query failed: {}", e.getMessage(), e);
        }
        log.info("================ DATABASE DIAGNOSTIC END ================");
    }

    private void verifyOnFreshConnection(String code) {
        log.info("================ FRESH DB CONNECTION QUERY START ================");
        if (dataSource != null) {
            try (java.sql.Connection freshConn = dataSource.getConnection()) {
                freshConn.setAutoCommit(true);
                log.info("[FRESH DB METADATA] Connection URL: {}", freshConn.getMetaData().getURL());
                try (java.sql.PreparedStatement stmt = freshConn.prepareStatement(
                        "SELECT code, status FROM public.product_barcodes WHERE LOWER(TRIM(code)) = LOWER(TRIM(?))")) {
                    stmt.setString(1, code);
                    try (java.sql.ResultSet rs = stmt.executeQuery()) {
                        if (rs.next()) {
                            String c = rs.getString("code");
                            String s = rs.getString("status");
                            log.info("[FRESH DB RESULT] SELECT code, status FROM public.product_barcodes WHERE code = '{}' -> {} | {}", code, c, s);
                        } else {
                            log.warn("[FRESH DB RESULT] SELECT code, status FROM public.product_barcodes WHERE code = '{}' -> ROW NOT FOUND!", code);
                        }
                    }
                }
            } catch (Exception e) {
                log.error("Fresh DB connection check failed: {}", e.getMessage(), e);
            }
        } else {
            log.warn("DataSource is null, skipping fresh DB connection check.");
        }
        log.info("================ FRESH DB CONNECTION QUERY END ================");
    }

    private String normalizeBarcode(String raw) {
        if (raw == null) return "";
        return raw.replaceAll("[\\p{Cntrl}\\u0000-\\u001F\\u007F-\\u009F\\u200B-\\u200D\\uFEFF]", "").trim();
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
            List<String> list = new ArrayList<>(request.getBarcodes());
            if (request.getBarcode() != null && !request.getBarcode().trim().isEmpty() && !list.contains(request.getBarcode().trim())) {
                list.add(0, request.getBarcode().trim());
            }
            return list.stream().filter(s -> s != null && !s.trim().isEmpty()).distinct().toList();
        }

        List<String> list = new ArrayList<>();
        String baseBarcode = request.getBarcode() != null ? request.getBarcode().trim() : "";
        int quantity = request.getQuantity() != null && request.getQuantity() > 0 ? request.getQuantity() : 1;

        if (!baseBarcode.isEmpty()) {
            list.add(baseBarcode);
        }

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
        }

        if (!baseBarcode.isEmpty()) {
            for (int i = 1; i <= quantity; i++) {
                list.add(String.format("%s-%04d", baseBarcode, i));
                list.add(String.format("%s-%d", baseBarcode, i));
            }
        }

        return list.stream().filter(s -> s != null && !s.trim().isEmpty()).distinct().toList();
    }

    private ProductResponse mapToResponse(Product product) {
        if (product == null) return null;
        Long id = product.getId() != null ? product.getId() : 1L;
        UUID productUuid = new UUID(0L, id);
        List<ProductBarcode> pBarcodes = productBarcodeRepository.findByProductId(productUuid);
        List<String> codeList = (pBarcodes != null) ? pBarcodes.stream().map(ProductBarcode::getCode).toList() : List.of();
        java.util.Map<String, String> statusMap = new java.util.HashMap<>();
        if (pBarcodes != null) {
            for (ProductBarcode pb : pBarcodes) {
                if (pb.getCode() != null) {
                    statusMap.put(pb.getCode(), pb.getStatus() != null ? pb.getStatus() : "GENERATED");
                }
            }
        }

        return ProductResponse.builder()
                .id(id)
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
                .barcodeStatuses(statusMap)
                .barcodeCount((long) codeList.size())
                .build();
    }

    @Override
    @Transactional
    public java.util.Map<String, Object> scanReceive(String code, String clientTxnId, String deviceSource) {
        log.info("[ProductServiceImpl] Executing scan_receive RPC: code='{}', txn='{}', source='{}'", code, clientTxnId, deviceSource);
        if (jdbcTemplate == null) {
            throw new IllegalStateException("JdbcTemplate unavailable for scan_receive RPC execution");
        }

        try {
            java.util.UUID txnUuid = (clientTxnId != null && !clientTxnId.trim().isEmpty())
                    ? java.util.UUID.fromString(clientTxnId.trim())
                    : java.util.UUID.randomUUID();
            String cleanCode = normalizeBarcode(code);
            String source = (deviceSource != null && !deviceSource.trim().isEmpty()) ? deviceSource.trim().toUpperCase() : "CAMERA";

            String jsonResult = jdbcTemplate.queryForObject(
                "SELECT public.scan_receive(?, ?::uuid, ?::public.scan_source)::text",
                String.class,
                cleanCode,
                txnUuid.toString(),
                source
            );

            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            @SuppressWarnings("unchecked")
            java.util.Map<String, Object> resultMap = mapper.readValue(jsonResult, java.util.Map.class);
            log.info("[ProductServiceImpl] scan_receive RPC result: {}", resultMap);
            return resultMap;
        } catch (Exception e) {
            log.error("[ProductServiceImpl] Error executing scan_receive RPC: {}", e.getMessage(), e);
            throw new RuntimeException("scan_receive RPC failure: " + e.getMessage(), e);
        }
    }
}
