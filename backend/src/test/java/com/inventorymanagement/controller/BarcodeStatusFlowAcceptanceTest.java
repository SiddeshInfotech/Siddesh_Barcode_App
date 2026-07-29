package com.inventorymanagement.controller;

import com.inventorymanagement.dto.CreateProductRequest;
import com.inventorymanagement.dto.LoginRequest;
import com.inventorymanagement.dto.ProductResponse;
import com.inventorymanagement.dto.TransactionRequest;
import com.inventorymanagement.entity.ProductBarcode;
import com.inventorymanagement.repository.ProductBarcodeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
    "spring.datasource.url=jdbc:h2:mem:barcodetestdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect"
})
public class BarcodeStatusFlowAcceptanceTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ProductBarcodeRepository productBarcodeRepository;

    private String token;

    @BeforeEach
    void setUp() {
        LoginRequest loginRequest = new LoginRequest("admin@inventory.com", "AdminPassword123!");
        ResponseEntity<Map> response = restTemplate.postForEntity(
                "http://localhost:" + port + "/api/auth/login",
                loginRequest,
                Map.class
        );
        assertEquals(HttpStatus.OK, response.getStatusCode());
        token = (String) response.getBody().get("token");
    }

    @Test
    void testCompleteBarcodeStatusLifecycle_Generated_Inwarded_Outwarded() {
        assertNotNull(token, "Authentication token must be present");

        String targetBarcode = "LAPT-260728-0001";

        // 1. Create product with initial barcode sequence
        CreateProductRequest createReq = CreateProductRequest.builder()
                .name("Test Laptop Unit")
                .barcode("LAPT-260728")
                .price(new BigDecimal("1200.00"))
                .quantity(1)
                .description("Laptop test unit")
                .category("Electronics")
                .brand("TechBrand")
                .barcodes(List.of(targetBarcode))
                .build();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(token);

        HttpEntity<CreateProductRequest> createEntity = new HttpEntity<>(createReq, headers);
        ResponseEntity<ProductResponse> createResponse = restTemplate.postForEntity(
                "http://localhost:" + port + "/api/products",
                createEntity,
                ProductResponse.class
        );

        assertEquals(HttpStatus.CREATED, createResponse.getStatusCode());
        assertNotNull(createResponse.getBody());
        Long productId = createResponse.getBody().getId();

        // Verify initial state in DB: status = GENERATED
        Optional<ProductBarcode> pbInitial = productBarcodeRepository.findByCodeIgnoreCase(targetBarcode);
        assertTrue(pbInitial.isPresent(), "Barcode row must exist in product_barcodes table");
        assertEquals("GENERATED", pbInitial.get().getStatus(), "Initial status in DB must be GENERATED");
        System.out.println(">>> VERIFIED DB INITIAL STATUS: " + pbInitial.get().getCode() + " = " + pbInitial.get().getStatus());

        // 2. Perform INWARD via Dashboard API
        TransactionRequest inwardReq = TransactionRequest.builder()
                .productId(productId)
                .barcode(targetBarcode)
                .quantity(1)
                .build();

        HttpEntity<TransactionRequest> inwardEntity = new HttpEntity<>(inwardReq, headers);
        ResponseEntity<Void> inwardResponse = restTemplate.postForEntity(
                "http://localhost:" + port + "/api/dashboard/inward",
                inwardEntity,
                Void.class
        );
        assertEquals(HttpStatus.OK, inwardResponse.getStatusCode());

        // Verify DB state after INWARD: status = INWARDED
        Optional<ProductBarcode> pbInwarded = productBarcodeRepository.findByCodeIgnoreCase(targetBarcode);
        assertTrue(pbInwarded.isPresent());
        assertEquals("INWARDED", pbInwarded.get().getStatus(), "Database status after Inward MUST be INWARDED");
        System.out.println(">>> VERIFIED DB STATUS AFTER INWARD: " + pbInwarded.get().getCode() + " = " + pbInwarded.get().getStatus());

        // 3. Perform OUTWARD via Dashboard API
        TransactionRequest outwardReq = TransactionRequest.builder()
                .productId(productId)
                .barcode(targetBarcode)
                .quantity(1)
                .build();

        HttpEntity<TransactionRequest> outwardEntity = new HttpEntity<>(outwardReq, headers);
        ResponseEntity<Void> outwardResponse = restTemplate.postForEntity(
                "http://localhost:" + port + "/api/dashboard/outward",
                outwardEntity,
                Void.class
        );
        assertEquals(HttpStatus.OK, outwardResponse.getStatusCode());

        // Verify DB state after OUTWARD: status = OUTWARDED
        Optional<ProductBarcode> pbOutwarded = productBarcodeRepository.findByCodeIgnoreCase(targetBarcode);
        assertTrue(pbOutwarded.isPresent());
        assertEquals("OUTWARDED", pbOutwarded.get().getStatus(), "Database status after Outward MUST be OUTWARDED");
        System.out.println(">>> VERIFIED DB STATUS AFTER OUTWARD: " + pbOutwarded.get().getCode() + " = " + pbOutwarded.get().getStatus());

        // 4. Test explicit PUT update endpoint as well
        HttpEntity<Void> putEntity = new HttpEntity<>(headers);
        String putUrl = org.springframework.web.util.UriComponentsBuilder
                .fromHttpUrl("http://localhost:" + port + "/api/products/barcodes/" + targetBarcode + "/status")
                .queryParam("status", "INWARDED")
                .toUriString();

        ResponseEntity<ProductBarcode> putResponse = restTemplate.exchange(
                putUrl,
                HttpMethod.PUT,
                putEntity,
                ProductBarcode.class
        );
        assertEquals(HttpStatus.OK, putResponse.getStatusCode());
        assertNotNull(putResponse.getBody());
        assertEquals("INWARDED", putResponse.getBody().getStatus());

        Optional<ProductBarcode> pbFinal = productBarcodeRepository.findByCodeIgnoreCase(targetBarcode);
        assertTrue(pbFinal.isPresent());
        assertEquals("INWARDED", pbFinal.get().getStatus());
        System.out.println(">>> VERIFIED EXPLICIT PUT STATUS UPDATE: " + pbFinal.get().getCode() + " = " + pbFinal.get().getStatus());
    }
}
