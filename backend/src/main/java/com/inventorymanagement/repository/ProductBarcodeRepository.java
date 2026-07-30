package com.inventorymanagement.repository;

import com.inventorymanagement.entity.ProductBarcode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Repository interface for managing ProductBarcode entities.
 */
@Repository
public interface ProductBarcodeRepository extends JpaRepository<ProductBarcode, UUID> {

    Optional<ProductBarcode> findByCodeIgnoreCase(String code);

    long countByProductId(UUID productId);

    List<ProductBarcode> findByProductId(UUID productId);

    boolean existsByCode(String code);
}
