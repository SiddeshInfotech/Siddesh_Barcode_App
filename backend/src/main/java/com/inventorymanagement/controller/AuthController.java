package com.inventorymanagement.controller;

import com.inventorymanagement.dto.LoginRequest;
import com.inventorymanagement.dto.LoginResponse;
import com.inventorymanagement.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller class handling REST endpoints for user authentication.
 */
@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "Endpoints for user authentication and authorization")
public class AuthController {

    private final AuthService authService;

    /**
     * Constructs a new AuthController.
     *
     * @param authService the AuthService dependency
     */
    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /**
     * Authenticates a user email and password, returning a JWT token on success.
     *
     * @param loginRequest the credentials payload
     * @return a ResponseEntity containing the LoginResponse
     */
    @PostMapping("/login")
    @Operation(summary = "Authenticate user and get JWT token", description = "Validates the user credentials and returns a JWT access token.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully authenticated",
            content = @Content(schema = @Schema(implementation = LoginResponse.class))),
        @ApiResponse(responseCode = "400", description = "Invalid validation constraints or payload format"),
        @ApiResponse(responseCode = "401", description = "Invalid email or password credentials"),
        @ApiResponse(responseCode = "403", description = "Account is disabled or locked")
    })
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest loginRequest) {
        LoginResponse response = authService.login(loginRequest);
        return ResponseEntity.ok(response);
    }
}
