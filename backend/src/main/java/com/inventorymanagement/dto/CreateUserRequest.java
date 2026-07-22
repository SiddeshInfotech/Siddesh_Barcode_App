package com.inventorymanagement.dto;

import com.inventorymanagement.constants.RoleName;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.util.Set;

/**
 * Data Transfer Object representing the payload to create a new user account.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateUserRequest {

    /**
     * User's email address. Must be a valid email format.
     */
    @NotBlank(message = "Email is required")
    @Email(message = "Please provide a valid email address")
    @Size(max = 100, message = "Email must not exceed 100 characters")
    private String email;

    /**
     * User's password. Must be at least 6 characters.
     */
    @NotBlank(message = "Password is required")
    @Size(min = 6, max = 120, message = "Password must be between 6 and 120 characters")
    private String password;

    /**
     * Set of authorization roles granted to this user.
     */
    @NotEmpty(message = "At least one role is required")
    private Set<RoleName> roles;

    /**
     * Whether the account is active.
     */
    @Builder.Default
    private boolean enabled = true;

    /**
     * Whether the account is unlocked.
     */
    @Builder.Default
    private boolean accountNonLocked = true;
}
