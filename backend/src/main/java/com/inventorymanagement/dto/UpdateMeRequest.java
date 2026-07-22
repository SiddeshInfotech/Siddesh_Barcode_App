package com.inventorymanagement.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

/**
 * Data Transfer Object representing the payload to update the current user's profile.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateMeRequest {

    /**
     * Updated email address. Must be a valid email format.
     */
    @NotBlank(message = "Email is required")
    @Email(message = "Please provide a valid email address")
    @Size(max = 100, message = "Email must not exceed 100 characters")
    private String email;

    /**
     * User's current password. Required if changing password.
     */
    private String currentPassword;

    /**
     * Optional new password. Must be at least 6 characters.
     */
    @Size(min = 6, max = 120, message = "New password must be between 6 and 120 characters")
    private String newPassword;
}
