package com.inventorymanagement.repository;

import com.inventorymanagement.entity.ProductBarcode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = "UPDATE product_barcodes SET status = :status WHERE LOWER(TRIM(code)) = LOWER(TRIM(:code))", nativeQuery = true)
    int updateStatusByCode(@Param("code") String code, @Param("status") String status);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = "UPDATE product_barcodes SET status = :status WHERE LOWER(TRIM(code)) LIKE LOWER(TRIM(:prefix))", nativeQuery = true)
    int updateStatusByCodePrefix(@Param("prefix") String prefix, @Param("status") String status);

    @Query(value = "SELECT * FROM product_barcodes WHERE LOWER(TRIM(code)) LIKE LOWER(TRIM(:prefix)) AND status = :status ORDER BY created_at ASC", nativeQuery = true)
    List<ProductBarcode> findByCodePrefixAndStatus(@Param("prefix") String prefix, @Param("status") String status);
}
