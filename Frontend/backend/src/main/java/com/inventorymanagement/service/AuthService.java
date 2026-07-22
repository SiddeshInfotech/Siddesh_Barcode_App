package com.inventorymanagement.service;

import com.inventorymanagement.dto.LoginRequest;
import com.inventorymanagement.dto.LoginResponse;

/**
 * Service interface defining authentication actions.
 */
public interface AuthService {

    /**
     * Authenticates a user based on the provided LoginRequest credentials.
     *
     * @param loginRequest the credentials payload
     * @return a LoginResponse containing details of the user and their JWT token
     */
    LoginResponse login(LoginRequest loginRequest);
}
