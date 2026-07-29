package com.inventorymanagement.controller;

import com.inventorymanagement.dto.CreateProductRequest;
import com.inventorymanagement.dto.LoginRequest;
import com.inventorymanagement.dto.ProductResponse;
import com.inventorymanagement.dto.UpdateProductRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import java.math.BigDecimal;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
    "spring.datasource.url=jdbc:h2:mem:producttestdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect"
})
public class ProductControllerIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    private String adminToken;
    private String managerToken;
    private String salesToken;

    @BeforeEach
    public void setUp() {
        adminToken = getLoginToken("admin@inventory.com", "AdminPassword123!");
        managerToken = getLoginToken("manager@inventory.com", "ManagerPassword123!");
        salesToken = getLoginToken("sales@inventory.com", "SalesPassword123!");
    }

    private String getLoginToken(String email, String password) {
        LoginRequest loginRequest = new LoginRequest(email, password);
        ResponseEntity<Map> response = restTemplate.postForEntity(
            "http://localhost:" + port + "/api/auth/login",
            loginRequest,
            Map.class
        );
        assertEquals(HttpStatus.OK, response.getStatusCode());
        return (String) response.getBody().get("token");
    }

    private HttpHeaders getHeaders(String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        return headers;
    }

    @Test
    public void testProductLifecycle_Admin_Success() {
        // 1. Create a Product
        CreateProductRequest createRequest = CreateProductRequest.builder()
                .name("Admin Product")
                .description("Created by Admin")
                .barcode("BAR-ADMIN-1")
                .price(new BigDecimal("10.00"))
                .quantity(100)
                .sku("SKU-ADMIN-1")
                .category("Office")
                .build();

        HttpHeaders adminHeaders = getHeaders(adminToken);
        HttpEntity<CreateProductRequest> createEntity = new HttpEntity<>(createRequest, adminHeaders);

        ResponseEntity<ProductResponse> createResponse = restTemplate.postForEntity(
            "http://localhost:" + port + "/api/products",
            createEntity,
            ProductResponse.class
        );

        assertEquals(HttpStatus.CREATED, createResponse.getStatusCode());
        assertNotNull(createResponse.getBody());
        Long productId = createResponse.getBody().getId();
        assertEquals("Admin Product", createResponse.getBody().getName());

        // 2. Read Product by ID
        HttpEntity<Void> getEntity = new HttpEntity<>(adminHeaders);
        ResponseEntity<ProductResponse> getResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/" + productId,
            HttpMethod.GET,
            getEntity,
            ProductResponse.class
        );
        assertEquals(HttpStatus.OK, getResponse.getStatusCode());
        assertEquals("Admin Product", getResponse.getBody().getName());

        // 3. Read Product by Barcode
        ResponseEntity<ProductResponse> getBarcodeResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/barcode/BAR-ADMIN-1",
            HttpMethod.GET,
            getEntity,
            ProductResponse.class
        );
        assertEquals(HttpStatus.OK, getBarcodeResponse.getStatusCode());
        assertEquals("Admin Product", getBarcodeResponse.getBody().getName());

        // 4. Update Product
        UpdateProductRequest updateRequest = UpdateProductRequest.builder()
                .name("Admin Product Updated")
                .description("Updated by Admin")
                .barcode("BAR-ADMIN-1")
                .price(new BigDecimal("12.50"))
                .quantity(80)
                .sku("SKU-ADMIN-1")
                .category("Office Goods")
                .build();

        HttpEntity<UpdateProductRequest> updateEntity = new HttpEntity<>(updateRequest, adminHeaders);
        ResponseEntity<ProductResponse> updateResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/" + productId,
            HttpMethod.PUT,
            updateEntity,
            ProductResponse.class
        );
        assertEquals(HttpStatus.OK, updateResponse.getStatusCode());
        assertEquals("Admin Product Updated", updateResponse.getBody().getName());
        assertEquals(new BigDecimal("12.50"), updateResponse.getBody().getPrice());

        // 5. Delete Product
        ResponseEntity<Void> deleteResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/" + productId,
            HttpMethod.DELETE,
            getEntity,
            Void.class
        );
        assertEquals(HttpStatus.NO_CONTENT, deleteResponse.getStatusCode());

        // 6. Verify Deleted
        ResponseEntity<Object> verifyDeletedResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/" + productId,
            HttpMethod.GET,
            getEntity,
            Object.class
        );
        assertEquals(HttpStatus.NOT_FOUND, verifyDeletedResponse.getStatusCode());
    }

    @Test
    public void testProductAccessControl_StoreManager_SuccessAndForbidden() {
        // 1. Store Manager can create products
        CreateProductRequest createRequest = CreateProductRequest.builder()
                .name("Manager Product")
                .description("Created by Manager")
                .barcode("BAR-MGR-1")
                .price(new BigDecimal("20.00"))
                .quantity(50)
                .sku("SKU-MGR-1")
                .category("Tools")
                .build();

        HttpHeaders managerHeaders = getHeaders(managerToken);
        HttpEntity<CreateProductRequest> createEntity = new HttpEntity<>(createRequest, managerHeaders);

        ResponseEntity<ProductResponse> createResponse = restTemplate.postForEntity(
            "http://localhost:" + port + "/api/products",
            createEntity,
            ProductResponse.class
        );

        assertEquals(HttpStatus.CREATED, createResponse.getStatusCode());
        Long productId = createResponse.getBody().getId();

        // 2. Store Manager can update products
        UpdateProductRequest updateRequest = UpdateProductRequest.builder()
                .name("Manager Product Updated")
                .description("Updated by Manager")
                .barcode("BAR-MGR-1")
                .price(new BigDecimal("25.00"))
                .quantity(40)
                .sku("SKU-MGR-1")
                .category("Heavy Tools")
                .build();

        HttpEntity<UpdateProductRequest> updateEntity = new HttpEntity<>(updateRequest, managerHeaders);
        ResponseEntity<ProductResponse> updateResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/" + productId,
            HttpMethod.PUT,
            updateEntity,
            ProductResponse.class
        );
        assertEquals(HttpStatus.OK, updateResponse.getStatusCode());

        // 3. Store Manager CANNOT delete products (Forbidden 403)
        HttpEntity<Void> managerGetEntity = new HttpEntity<>(managerHeaders);
        ResponseEntity<Void> deleteResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/" + productId,
            HttpMethod.DELETE,
            managerGetEntity,
            Void.class
        );
        assertEquals(HttpStatus.FORBIDDEN, deleteResponse.getStatusCode());
    }

    @Test
    public void testProductAccessControl_SalesExecutive_Forbidden() {
        HttpHeaders salesHeaders = getHeaders(salesToken);

        // 1. Sales Executive CANNOT create products (Forbidden 403)
        CreateProductRequest createRequest = CreateProductRequest.builder()
                .name("Sales Product")
                .description("Sales Create Attempt")
                .barcode("BAR-SALES-1")
                .price(new BigDecimal("5.00"))
                .quantity(10)
                .sku("SKU-SALES-1")
                .category("Stationery")
                .build();

        HttpEntity<CreateProductRequest> createEntity = new HttpEntity<>(createRequest, salesHeaders);
        ResponseEntity<Object> createResponse = restTemplate.postForEntity(
            "http://localhost:" + port + "/api/products",
            createEntity,
            Object.class
        );
        assertEquals(HttpStatus.FORBIDDEN, createResponse.getStatusCode());

        // 2. Sales Executive CANNOT update products (Forbidden 403)
        UpdateProductRequest updateRequest = UpdateProductRequest.builder()
                .name("Sales Product Update")
                .description("Sales Update Attempt")
                .barcode("BAR-SALES-1")
                .price(new BigDecimal("5.00"))
                .quantity(10)
                .sku("SKU-SALES-1")
                .category("Stationery")
                .build();

        HttpEntity<UpdateProductRequest> updateEntity = new HttpEntity<>(updateRequest, salesHeaders);
        ResponseEntity<Object> updateResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/1", // using a placeholder ID
            HttpMethod.PUT,
            updateEntity,
            Object.class
        );
        assertEquals(HttpStatus.FORBIDDEN, updateResponse.getStatusCode());
    }

    @Test
    public void testBarcodeGenerationAndScanningWorkflow() {
        CreateProductRequest createRequest = CreateProductRequest.builder()
                .name("Wireless Optical Mouse Batch 1")
                .description("Batch of 100 wireless mice with sequence barcodes")
                .barcode("MOUS-260727-0081")
                .price(new BigDecimal("29.99"))
                .quantity(100)
                .sku("SKU-MOUS-260727")
                .category("Peripherals")
                .brand("LogiTech")
                .build();

        HttpHeaders adminHeaders = getHeaders(adminToken);
        HttpEntity<CreateProductRequest> createEntity = new HttpEntity<>(createRequest, adminHeaders);

        ResponseEntity<ProductResponse> createResponse = restTemplate.postForEntity(
            "http://localhost:" + port + "/api/products",
            createEntity,
            ProductResponse.class
        );

        assertEquals(HttpStatus.CREATED, createResponse.getStatusCode());
        assertNotNull(createResponse.getBody());
        Long productId = createResponse.getBody().getId();
        assertTrue(createResponse.getBody().getBarcodeCount() >= 100);

        HttpEntity<Void> getEntity = new HttpEntity<>(adminHeaders);
        ResponseEntity<Long> countResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/" + productId + "/barcode-count",
            HttpMethod.GET,
            getEntity,
            Long.class
        );

        assertEquals(HttpStatus.OK, countResponse.getStatusCode());
        assertTrue(countResponse.getBody() >= 100);

        ResponseEntity<ProductResponse> scanFirstResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/barcode/MOUS-260727-0081",
            HttpMethod.GET,
            getEntity,
            ProductResponse.class
        );
        assertEquals(HttpStatus.OK, scanFirstResponse.getStatusCode());
        assertNotNull(scanFirstResponse.getBody());
        assertEquals("Wireless Optical Mouse Batch 1", scanFirstResponse.getBody().getName());

        ResponseEntity<ProductResponse> scanLastResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products/barcode/MOUS-260727-0180",
            HttpMethod.GET,
            getEntity,
            ProductResponse.class
        );
        assertEquals(HttpStatus.OK, scanLastResponse.getStatusCode());
        assertNotNull(scanLastResponse.getBody());
        assertEquals("Wireless Optical Mouse Batch 1", scanLastResponse.getBody().getName());
    }
}
