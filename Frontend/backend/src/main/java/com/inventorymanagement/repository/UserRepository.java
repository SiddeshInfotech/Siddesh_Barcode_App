package com.inventorymanagement.repository;

import com.inventorymanagement.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

/**
 * Spring Data JPA repository for User entity database operations.
 */
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * Finds a user account by their unique email.
     *
     * @param email the user email address
     * @return an Optional containing the User if found, or empty otherwise
     */
    Optional<User> findByEmail(String email);

    /**
     * Checks if a user account exists with the specified email.
     *
     * @param email the user email address
     * @return true if the email is already in use, false otherwise
     */
    boolean existsByEmail(String email);
}
