package com.inventorymanagement.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for testing security configurations and role-based permissions.
 */
@RestController
@RequestMapping("/api/test")
@Tag(name = "Testing Security", description = "Endpoints for verifying role-based authorization rules")
@SecurityRequirement(name = "bearerAuth")
public class TestController {

    /**
     * Endpoint restricted to ADMIN role.
     *
     * @return a message confirming access
     */
    @GetMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin only endpoint", description = "Verifies access for users with ROLE_ADMIN.")
    public ResponseEntity<String> adminEndpoint() {
        return ResponseEntity.ok("Success: You have accessed the Admin endpoint!");
    }

    /**
     * Endpoint restricted to ADMIN and STORE_MANAGER roles.
     *
     * @return a message confirming access
     */
    @GetMapping("/manager")
    @PreAuthorize("hasAnyRole('ADMIN', 'STORE_MANAGER')")
    @Operation(summary = "Manager or Admin only endpoint", description = "Verifies access for users with ROLE_ADMIN or ROLE_STORE_MANAGER.")
    public ResponseEntity<String> managerEndpoint() {
        return ResponseEntity.ok("Success: You have accessed the Store Manager / Admin endpoint!");
    }

    /**
     * Endpoint restricted to ADMIN and SALES_EXECUTIVE roles.
     *
     * @return a message confirming access
     */
    @GetMapping("/sales")
    @PreAuthorize("hasAnyRole('ADMIN', 'SALES_EXECUTIVE')")
    @Operation(summary = "Sales or Admin only endpoint", description = "Verifies access for users with ROLE_ADMIN or ROLE_SALES_EXECUTIVE.")
    public ResponseEntity<String> salesEndpoint() {
        return ResponseEntity.ok("Success: You have accessed the Sales Executive / Admin endpoint!");
    }

    /**
     * Endpoint accessible by any authenticated user.
     *
     * @return a message confirming access
     */
    @GetMapping("/user")
    @Operation(summary = "Authenticated users endpoint", description = "Verifies access for any logged-in user.")
    public ResponseEntity<String> authenticatedEndpoint() {
        return ResponseEntity.ok("Success: You are logged in!");
    }
}
