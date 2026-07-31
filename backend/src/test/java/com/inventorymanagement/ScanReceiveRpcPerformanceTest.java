package com.inventorymanagement;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
public class ScanReceiveRpcPerformanceTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void testScanReceivePerformanceAndSteps() {
        assertNotNull(jdbcTemplate, "JdbcTemplate must be initialized");

        String testBarcode = "PERF-TEST-" + System.currentTimeMillis();
        UUID clientTxnId = UUID.randomUUID();

        // 1. Ensure test product exists
        Long productId = jdbcTemplate.queryForObject("SELECT id FROM public.products LIMIT 1", Long.class);
        if (productId == null) {
            productId = 101L;
        }

        // 2. Insert test barcode with status GENERATED
        UUID barcodeId = UUID.randomUUID();
        jdbcTemplate.update(
            "INSERT INTO public.product_barcodes (id, product_id, code, status, symbology) VALUES (?::uuid, ?::uuid, ?, 'GENERATED'::public.barcode_status, 'CODE128')",
            barcodeId.toString(),
            UUID.nameUUIDFromBytes(productId.toString().getBytes()).toString(),
            testBarcode
        );

        System.out.println("================================================================");
        System.out.println("EXECUTING scan_receive RPC DIRECTLY IN POSTGRESQL DATABASE");
        System.out.println("Barcode Code: " + testBarcode);
        System.out.println("Client Txn ID: " + clientTxnId);
        System.out.println("================================================================");

        long startTime = System.currentTimeMillis();

        String jsonResult = jdbcTemplate.queryForObject(
            "SELECT public.scan_receive(?, ?::uuid, 'CAMERA'::public.scan_source)::text",
            String.class,
            testBarcode,
            clientTxnId.toString()
        );

        long durationMs = System.currentTimeMillis() - startTime;

        System.out.println("================================================================");
        System.out.println("REAL RPC EXECUTION TIME: " + durationMs + " ms");
        System.out.println("RPC RESULT PAYLOAD:\n" + jsonResult);
        System.out.println("================================================================");

        assertTrue(durationMs < 1000, "RPC execution MUST complete in under 1000 ms (1 second), actual: " + durationMs + " ms");
        assertNotNull(jsonResult);
        assertTrue(jsonResult.contains("\"ok\": true"));
        assertTrue(jsonResult.contains("\"status\": \"INWARDED\""));
    }
}
