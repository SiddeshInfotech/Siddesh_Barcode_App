package com.inventorymanagement.repository;

import com.inventorymanagement.entity.StockTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

/**
 * Repository interface for managing StockTransaction entities.
 */
@Repository
public interface StockTransactionRepository extends JpaRepository<StockTransaction, Long> {

    @Query("SELECT COALESCE(SUM(t.quantity), 0) FROM StockTransaction t WHERE t.type = 'INWARD'")
    long sumTotalInward();

    @Query("SELECT COALESCE(SUM(t.quantity), 0) FROM StockTransaction t WHERE t.type = 'OUTWARD'")
    long sumTotalOutward();

    @Query("SELECT COALESCE(SUM(t.quantity), 0) FROM StockTransaction t WHERE t.type = 'INWARD' AND t.createdAt >= :startDate")
    long sumTodayInward(@Param("startDate") LocalDateTime startDate);

    @Query("SELECT COALESCE(SUM(t.quantity), 0) FROM StockTransaction t WHERE t.type = 'OUTWARD' AND t.createdAt >= :startDate")
    long sumTodayOutward(@Param("startDate") LocalDateTime startDate);
}
