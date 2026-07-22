package com.inventorymanagement.service.impl;

import com.inventorymanagement.constants.RoleName;
import com.inventorymanagement.dto.CreateUserRequest;
import com.inventorymanagement.dto.UpdateMeRequest;
import com.inventorymanagement.dto.UpdateUserRequest;
import com.inventorymanagement.dto.UserResponse;
import com.inventorymanagement.entity.Role;
import com.inventorymanagement.entity.User;
import com.inventorymanagement.exception.ResourceNotFoundException;
import com.inventorymanagement.repository.RoleRepository;
import com.inventorymanagement.repository.UserRepository;
import com.inventorymanagement.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Service implementation containing business logic for user management operations.
 */
@Slf4j
@Service
@Transactional
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * Constructs a new UserServiceImpl.
     *
     * @param userRepository   the UserRepository dependency
     * @param roleRepository   the RoleRepository dependency
     * @param passwordEncoder the PasswordEncoder to hash passwords
     */
    public UserServiceImpl(
            UserRepository userRepository,
            RoleRepository roleRepository,
            PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public UserResponse createUser(CreateUserRequest request) {
        log.info("Attempting to create a new user account with email: {}", request.getEmail());

        if (userRepository.existsByEmail(request.getEmail())) {
            log.warn("User creation failed: email {} already exists", request.getEmail());
            throw new IllegalArgumentException("Email is already in use: " + request.getEmail());
        }

        Set<Role> roles = resolveRoles(request.getRoles());

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .enabled(request.isEnabled())
                .accountNonLocked(request.isAccountNonLocked())
                .roles(roles)
                .build();

        User savedUser = userRepository.save(user);
        log.info("Successfully created user account with ID: {}", savedUser.getId());
        return mapToResponse(savedUser);
    }

    @Override
    public UserResponse updateUser(Long id, UpdateUserRequest request) {
        log.info("Attempting to update user details for user ID: {}", id);

        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));

        if (!user.getEmail().equalsIgnoreCase(request.getEmail()) && userRepository.existsByEmail(request.getEmail())) {
            log.warn("User update failed: email {} already in use by another user", request.getEmail());
            throw new IllegalArgumentException("Email is already in use: " + request.getEmail());
        }

        user.setEmail(request.getEmail());
        user.setEnabled(request.isEnabled());
        user.setAccountNonLocked(request.isAccountNonLocked());

        if (request.getPassword() != null && !request.getPassword().trim().isEmpty()) {
            log.info("Password update requested for user ID: {}", id);
            user.setPassword(passwordEncoder.encode(request.getPassword()));
        }

        Set<Role> roles = resolveRoles(request.getRoles());
        user.setRoles(roles);

        User updatedUser = userRepository.save(user);
        log.info("Successfully updated user details for user ID: {}", updatedUser.getId());
        return mapToResponse(updatedUser);
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getUserById(Long id) {
        log.info("Fetching user details for user ID: {}", id);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
        return mapToResponse(user);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<UserResponse> getAllUsers(Pageable pageable) {
        log.info("Fetching all user accounts with pagination: {}", pageable);
        return userRepository.findAll(pageable).map(this::mapToResponse);
    }

    @Override
    public void deleteUser(Long id) {
        log.info("Attempting to delete user account with ID: {}", id);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
        userRepository.delete(user);
        log.info("Successfully deleted user account with ID: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getMyProfile(String email) {
        log.info("Fetching profile details for current user email: {}", email);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User profile not found with email: " + email));
        return mapToResponse(user);
    }

    @Override
    public UserResponse updateMyProfile(String email, UpdateMeRequest request) {
        log.info("Attempting to update profile details for current user email: {}", email);

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User profile not found with email: " + email));

        // Email update
        if (!user.getEmail().equalsIgnoreCase(request.getEmail())) {
            if (userRepository.existsByEmail(request.getEmail())) {
                log.warn("Profile update failed: email {} already in use by another user", request.getEmail());
                throw new IllegalArgumentException("Email is already in use: " + request.getEmail());
            }
            user.setEmail(request.getEmail());
        }

        // Password change
        if (request.getNewPassword() != null && !request.getNewPassword().trim().isEmpty()) {
            if (request.getCurrentPassword() == null || request.getCurrentPassword().trim().isEmpty()) {
                log.warn("Password change failed: current password not provided");
                throw new IllegalArgumentException("Current password is required to change password");
            }
            if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
                log.warn("Password change failed: current password incorrect");
                throw new IllegalArgumentException("Invalid current password");
            }
            user.setPassword(passwordEncoder.encode(request.getNewPassword()));
            log.info("Password successfully updated for user: {}", email);
        }

        User updatedUser = userRepository.save(user);
        log.info("Successfully updated profile details for user: {}", email);
        return mapToResponse(updatedUser);
    }

    private Set<Role> resolveRoles(Set<RoleName> roleNames) {
        Set<Role> roles = new HashSet<>();
        if (roleNames != null) {
            for (RoleName roleName : roleNames) {
                Role role = roleRepository.findByName(roleName)
                        .orElseThrow(() -> new IllegalArgumentException("Role not found in database: " + roleName));
                roles.add(role);
            }
        }
        return roles;
    }

    private UserResponse mapToResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .enabled(user.isEnabled())
                .accountNonLocked(user.isAccountNonLocked())
                .roles(user.getRoles().stream()
                        .map(Role::getName)
                        .collect(Collectors.toSet()))
                .build();
    }
}
