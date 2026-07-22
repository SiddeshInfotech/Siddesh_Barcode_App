package com.inventorymanagement.controller;

import com.inventorymanagement.dto.CreateUserRequest;
import com.inventorymanagement.dto.UpdateMeRequest;
import com.inventorymanagement.dto.UpdateUserRequest;
import com.inventorymanagement.dto.UserResponse;
import com.inventorymanagement.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

/**
 * Controller class handling REST endpoints for user account and profile management.
 */
@RestController
@RequestMapping("/api/users")
@Tag(name = "User Management", description = "Endpoints for managing user accounts and profiles")
@SecurityRequirement(name = "bearerAuth")
public class UserController {

    private final UserService userService;

    /**
     * Constructs a new UserController.
     *
     * @param userService the UserService dependency
     */
    public UserController(UserService userService) {
        this.userService = userService;
    }

    /**
     * Creates a new user account (Admin only).
     *
     * @param request the CreateUserRequest payload
     * @return a ResponseEntity containing the created UserResponse
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Create a new user account", description = "Allows administrators to provision new user accounts with specific security roles.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "201", description = "User successfully created",
            content = @Content(schema = @Schema(implementation = UserResponse.class))),
        @ApiResponse(responseCode = "400", description = "Invalid payload constraints or email already in use"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires Admin role")
    })
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        UserResponse response = userService.createUser(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * Updates an existing user account's details (Admin only).
     *
     * @param id      the identifier of the user to update
     * @param request the UpdateUserRequest payload
     * @return a ResponseEntity containing the updated UserResponse
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Update an existing user's details", description = "Allows administrators to update user email, password, roles, and status.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "User successfully updated",
            content = @Content(schema = @Schema(implementation = UserResponse.class))),
        @ApiResponse(responseCode = "400", description = "Invalid payload constraints or email already in use"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires Admin role"),
        @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<UserResponse> updateUser(
            @Parameter(description = "ID of the user to update", required = true)
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRequest request) {
        UserResponse response = userService.updateUser(id, request);
        return ResponseEntity.ok(response);
    }

    /**
     * Gets user details by ID (Admin only).
     *
     * @param id the user identifier
     * @return a ResponseEntity containing the UserResponse
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get user details by ID", description = "Allows administrators to retrieve a user account's details by its ID.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "User details found",
            content = @Content(schema = @Schema(implementation = UserResponse.class))),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires Admin role"),
        @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<UserResponse> getUserById(
            @Parameter(description = "ID of the user to retrieve", required = true)
            @PathVariable Long id) {
        UserResponse response = userService.getUserById(id);
        return ResponseEntity.ok(response);
    }

    /**
     * Gets all users paginated (Admin only).
     *
     * @param page    zero-based page index
     * @param size    number of records per page
     * @param sortBy  property to sort by
     * @param sortDir sorting direction ("asc" or "desc")
     * @return a ResponseEntity containing a Page of UserResponse
     */
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Get all user accounts paginated", description = "Allows administrators to retrieve a pageable list of all user accounts.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Page of user accounts retrieved successfully"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires Admin role")
    })
    public ResponseEntity<Page<UserResponse>> getAllUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {

        Sort sort = sortDir.equalsIgnoreCase(Sort.Direction.DESC.name())
                ? Sort.by(sortBy).descending()
                : Sort.by(sortBy).ascending();

        Pageable pageable = PageRequest.of(page, size, sort);
        Page<UserResponse> response = userService.getAllUsers(pageable);
        return ResponseEntity.ok(response);
    }

    /**
     * Deletes a user account (Admin only).
     *
     * @param id the user identifier
     * @return a ResponseEntity indicating success
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Delete a user account", description = "Allows administrators to permanently remove a user account from the system.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "204", description = "User successfully deleted"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT"),
        @ApiResponse(responseCode = "403", description = "Forbidden - Requires Admin role"),
        @ApiResponse(responseCode = "404", description = "User not found")
    })
    public ResponseEntity<Void> deleteUser(
            @Parameter(description = "ID of the user to delete", required = true)
            @PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Retrieves the current logged-in user's profile details.
     *
     * @param principal security principal of the current user
     * @return a ResponseEntity containing the UserResponse profile details
     */
    @GetMapping("/me")
    @Operation(summary = "Get current user profile", description = "Retrieves profile details of the currently authenticated session user.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Profile details retrieved successfully",
            content = @Content(schema = @Schema(implementation = UserResponse.class))),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT")
    })
    public ResponseEntity<UserResponse> getMyProfile(Principal principal) {
        UserResponse response = userService.getMyProfile(principal.getName());
        return ResponseEntity.ok(response);
    }

    /**
     * Updates the current logged-in user's profile details.
     *
     * @param principal security principal of the current user
     * @param request   the UpdateMeRequest payload
     * @return a ResponseEntity containing the updated UserResponse profile details
     */
    @PutMapping("/me")
    @Operation(summary = "Update current user profile", description = "Allows the currently authenticated user to update their email and change their password.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Profile details successfully updated",
            content = @Content(schema = @Schema(implementation = UserResponse.class))),
        @ApiResponse(responseCode = "400", description = "Invalid payload constraints or email already in use"),
        @ApiResponse(responseCode = "401", description = "Unauthorized - Missing or invalid JWT")
    })
    public ResponseEntity<UserResponse> updateMyProfile(
            @Valid @RequestBody UpdateMeRequest request,
            Principal principal) {
        UserResponse response = userService.updateMyProfile(principal.getName(), request);
        return ResponseEntity.ok(response);
    }
}
