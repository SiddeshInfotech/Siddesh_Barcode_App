package com.inventorymanagement.service.impl;

import com.inventorymanagement.dto.DashboardStatsResponse;
import com.inventorymanagement.dto.TransactionRequest;
import com.inventorymanagement.entity.Product;
import com.inventorymanagement.entity.StockTransaction;
import com.inventorymanagement.repository.ProductRepository;
import com.inventorymanagement.repository.StockTransactionRepository;
import com.inventorymanagement.service.DashboardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Service implementation for inventory dashboard statistics calculation and transaction recording.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class DashboardServiceImpl implements DashboardService {

    private final ProductRepository productRepository;
    private final StockTransactionRepository transactionRepository;
    private final com.inventorymanagement.service.ProductService productService;
    private final com.inventorymanagement.repository.ProductBarcodeRepository productBarcodeRepository;

    @Override
    @Transactional(readOnly = true)
    public DashboardStatsResponse getDashboardStats() {
        long totalInward = transactionRepository.sumTotalInward();
        long totalOutward = transactionRepository.sumTotalOutward();

        // Formula: Current Stock = Total Inward Quantity - Total Outward Quantity
        long calculatedStock = totalInward - totalOutward;

        // If no stock transactions recorded yet, fallback to sum of quantities in products table
        if (calculatedStock <= 0) {
            long productStockSum = productRepository.findAll().stream()
                    .mapToLong(p -> p.getQuantity() != null ? p.getQuantity() : 0)
                    .sum();
            if (productStockSum > 0) {
                calculatedStock = productStockSum;
            } else {
                calculatedStock = 0;
            }
        }

        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        long todayInward = transactionRepository.sumTodayInward(startOfDay);
        long todayOutward = transactionRepository.sumTodayOutward(startOfDay);

        // Low stock calculation: products with quantity < 25 (minimum threshold)
        long lowStockItems = productRepository.findAll().stream()
                .filter(p -> p.getQuantity() != null && p.getQuantity() < 25)
                .count();

        log.info("CALCULATED DASHBOARD STATS: currentStock={}, todayInward={}, todayOutward={}, lowStockItems={}",
                calculatedStock, todayInward, todayOutward, lowStockItems);

        return DashboardStatsResponse.builder()
                .currentStock(Math.max(0, calculatedStock))
                .todayInward(todayInward)
                .todayOutward(todayOutward)
                .lowStockItems(lowStockItems)
                .build();
    }

    @Override
    @Transactional
    public void recordInward(TransactionRequest request) {
        int qty = Math.max(1, request.getQuantity());
        String code = request.getBarcode() != null ? request.getBarcode().trim() : "";

        log.info("[TRANSACTION LOG] recordInward STARTED: barcode='{}', quantity={}", code, qty);

        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    log.info("[TRANSACTION LOG] recordInward COMMITTED SUCCESSFULLY for barcode='{}'", code);
                }

                @Override
                public void afterCompletion(int status) {
                    if (status == STATUS_ROLLED_BACK) {
                        log.error("[TRANSACTION LOG] recordInward ROLLED BACK for barcode='{}'!", code);
                    }
                }
            });
        }

        StockTransaction tx = StockTransaction.builder()
                .productId(request.getProductId())
                .barcode(code)
                .type("INWARD")
                .quantity(qty)
                .build();
        transactionRepository.save(tx);

        // Update product quantity in products table if present
        if (!code.isEmpty()) {
            var productOpt = productRepository.findByBarcodeIgnoreCase(code);
            if (productOpt.isEmpty()) {
                var pbOpt = productBarcodeRepository.findByCodeIgnoreCase(code);
                if (pbOpt.isPresent() && pbOpt.get().getProductId() != null) {
                    long pid = pbOpt.get().getProductId().getLeastSignificantBits();
                    productOpt = productRepository.findById(pid);
                }
            }
            if (productOpt.isPresent()) {
                Product p = productOpt.get();
                p.setQuantity((p.getQuantity() != null ? p.getQuantity() : 0) + qty);
                productRepository.save(p);
                log.info("Updated product '{}' (ID {}) stock quantity to {}", p.getName(), p.getId(), p.getQuantity());
            }

            // Update status of unit barcode in product_barcodes table to INWARDED
            productService.updateBarcodeStatus(code, "INWARDED");
        }
    }

    @Override
    @Transactional
    public void recordOutward(TransactionRequest request) {
        int qty = Math.max(1, request.getQuantity());
        String code = request.getBarcode() != null ? request.getBarcode().trim() : "";

        log.info("[TRANSACTION LOG] recordOutward STARTED: barcode='{}', quantity={}", code, qty);

        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    log.info("[TRANSACTION LOG] recordOutward COMMITTED SUCCESSFULLY for barcode='{}'", code);
                }

                @Override
                public void afterCompletion(int status) {
                    if (status == STATUS_ROLLED_BACK) {
                        log.error("[TRANSACTION LOG] recordOutward ROLLED BACK for barcode='{}'!", code);
                    }
                }
            });
        }

        StockTransaction tx = StockTransaction.builder()
                .productId(request.getProductId())
                .barcode(code)
                .type("OUTWARD")
                .quantity(qty)
                .build();
        transactionRepository.save(tx);

        // Update product quantity in products table if present
        if (!code.isEmpty()) {
            var productOpt = productRepository.findByBarcodeIgnoreCase(code);
            if (productOpt.isEmpty()) {
                var pbOpt = productBarcodeRepository.findByCodeIgnoreCase(code);
                if (pbOpt.isPresent() && pbOpt.get().getProductId() != null) {
                    long pid = pbOpt.get().getProductId().getLeastSignificantBits();
                    productOpt = productRepository.findById(pid);
                }
            }
            if (productOpt.isPresent()) {
                Product p = productOpt.get();
                int currentQty = p.getQuantity() != null ? p.getQuantity() : 0;
                p.setQuantity(Math.max(0, currentQty - qty));
                productRepository.save(p);
                log.info("Updated product '{}' (ID {}) stock quantity to {}", p.getName(), p.getId(), p.getQuantity());
            }

            // Update status of unit barcode in product_barcodes table to OUTWARDED
            productService.updateBarcodeStatus(code, "OUTWARDED");
        }
    }
}
