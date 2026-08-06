package com.inventorymanagement.repository;

import com.inventorymanagement.constants.RoleName;
import com.inventorymanagement.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

/**
 * Spring Data JPA repository for Role entity database operations.
 */
public interface RoleRepository extends JpaRepository<Role, Long> {

    /**
     * Finds a Role by its unique name.
     *
     * @param name the Enum value of the role name
     * @return an Optional containing the Role if found, or empty otherwise
     */
    Optional<Role> findByName(RoleName name);
}
