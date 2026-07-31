package com.inventorymanagement.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;
import com.inventorymanagement.dto.LoginRequest;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
    "spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect"
})
public class AuthControllerIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void testLogin() {
        LoginRequest request = new LoginRequest("SiddeshERP78@gmail.com", "SiddeshERP78@@!!##");
        ResponseEntity<Object> response = restTemplate.postForEntity(
            "http://localhost:" + port + "/api/auth/login",
            request,
            Object.class
        );
        System.out.println("==================================================");
        System.out.println("RESPONSE BODY: " + response.getBody());
        System.out.println("==================================================");
        assertEquals(200, response.getStatusCode().value());
    }

    @Test
    public void testLoginSiddesh() {
        LoginRequest request = new LoginRequest("SiddeshERP78@gmail.com", "SiddeshERP78@@!!##");
        ResponseEntity<Object> response = restTemplate.postForEntity(
            "http://localhost:" + port + "/api/auth/login",
            request,
            Object.class
        );
        System.out.println("==================================================");
        System.out.println("SIDDESH RESPONSE BODY: " + response.getBody());
        System.out.println("==================================================");
        assertEquals(200, response.getStatusCode().value());
    }

    @Test
    public void testGetUsersWithToken() {
        // 1. Login to get token
        LoginRequest loginRequest = new LoginRequest("SiddeshERP78@gmail.com", "SiddeshERP78@@!!##");
        ResponseEntity<java.util.Map> loginResponse = restTemplate.postForEntity(
            "http://localhost:" + port + "/api/auth/login",
            loginRequest,
            java.util.Map.class
        );
        assertEquals(200, loginResponse.getStatusCode().value());
        String token = (String) loginResponse.getBody().get("token");
        assertNotNull(token);

        // 2. Access protected GET /api/products endpoint with Bearer token
        org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        org.springframework.http.HttpEntity<Void> entity = new org.springframework.http.HttpEntity<>(headers);

        ResponseEntity<Object> productsResponse = restTemplate.exchange(
            "http://localhost:" + port + "/api/products",
            org.springframework.http.HttpMethod.GET,
            entity,
            Object.class
        );

        System.out.println("==================================================");
        System.out.println("PRODUCTS RESPONSE STATUS: " + productsResponse.getStatusCode());
        System.out.println("PRODUCTS RESPONSE BODY: " + productsResponse.getBody());
        System.out.println("==================================================");

        assertEquals(200, productsResponse.getStatusCode().value());
    }
}
