package com.inventorymanagement.dto;

import lombok.*;
import java.util.List;

/**
 * Data Transfer Object representing successful login response data including JWT access token.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponse {

    /**
     * Signed JWT access token.
     */
    private String token;

    /**
     * Authorization scheme prefix (typically "Bearer").
     */
    @Builder.Default
    private String type = "Bearer";

    /**
     * User's unique identifier.
     */
    private Long id;

    /**
     * User's registered email address.
     */
    private String email;

    /**
     * List of roles assigned to the user.
     */
    private List<String> roles;
}
