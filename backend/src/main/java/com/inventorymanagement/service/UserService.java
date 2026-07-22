package com.inventorymanagement.service;

import com.inventorymanagement.dto.CreateUserRequest;
import com.inventorymanagement.dto.UpdateMeRequest;
import com.inventorymanagement.dto.UpdateUserRequest;
import com.inventorymanagement.dto.UserResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

/**
 * Service interface defining user management operations.
 */
public interface UserService {

    /**
     * Creates a new user account with validated details.
     *
     * @param request the CreateUserRequest payload
     * @return the created UserResponse details
     */
    UserResponse createUser(CreateUserRequest request);

    /**
     * Updates details of an existing user account.
     *
     * @param id      the identifier of the user to update
     * @param request the UpdateUserRequest payload
     * @return the updated UserResponse details
     */
    UserResponse updateUser(Long id, UpdateUserRequest request);

    /**
     * Retrieves details of a user by their unique identifier.
     *
     * @param id the user identifier
     * @return the UserResponse details if found
     */
    UserResponse getUserById(Long id);

    /**
     * Retrieves all user accounts with pagination support.
     *
     * @param pageable pagination and sorting parameters
     * @return a page of UserResponse objects
     */
    Page<UserResponse> getAllUsers(Pageable pageable);

    /**
     * Deletes a user account from the database.
     *
     * @param id the identifier of the user to delete
     */
    void deleteUser(Long id);

    /**
     * Retrieves profile details of the current authenticated user by email.
     *
     * @param email the email address of the current user
     * @return the UserResponse profile details
     */
    UserResponse getMyProfile(String email);

    /**
     * Updates profile details of the current authenticated user.
     *
     * @param email   the email address of the current user
     * @param request the UpdateMeRequest payload
     * @return the updated UserResponse profile details
     */
    UserResponse updateMyProfile(String email, UpdateMeRequest request);
}
