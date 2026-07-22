package com.inventorymanagement.dto;

import com.inventorymanagement.constants.RoleName;
import lombok.*;

import java.util.Set;

/**
 * Data Transfer Object representing user account information returned from APIs.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserResponse {

    /**
     * Unique identifier of the user.
     */
    private Long id;

    /**
     * Email address of the user.
     */
    private String email;

    /**
     * Flag indicating if the account is active.
     */
    private boolean enabled;

    /**
     * Flag indicating if the account is unlocked.
     */
    private boolean accountNonLocked;

    /**
     * Set of authorization roles granted to this user.
     */
    private Set<RoleName> roles;
}
