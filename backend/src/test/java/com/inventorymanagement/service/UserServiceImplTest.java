package com.inventorymanagement.service;

import com.inventorymanagement.constants.RoleName;
import com.inventorymanagement.dto.CreateUserRequest;
import com.inventorymanagement.dto.UpdateMeRequest;
import com.inventorymanagement.dto.UserResponse;
import com.inventorymanagement.entity.Role;
import com.inventorymanagement.entity.User;
import com.inventorymanagement.exception.ResourceNotFoundException;
import com.inventorymanagement.repository.RoleRepository;
import com.inventorymanagement.repository.UserRepository;
import com.inventorymanagement.service.impl.UserServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Collections;
import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class UserServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserServiceImpl userService;

    private User sampleUser;
    private Role salesRole;

    @BeforeEach
    public void setUp() {
        salesRole = Role.builder()
                .id(1L)
                .name(RoleName.ROLE_SALES_EXECUTIVE)
                .build();

        sampleUser = User.builder()
                .id(10L)
                .email("test@example.com")
                .password("encodedPassword")
                .enabled(true)
                .accountNonLocked(true)
                .roles(Set.of(salesRole))
                .build();
    }

    @Test
    public void createUser_success() {
        CreateUserRequest request = CreateUserRequest.builder()
                .email("new@example.com")
                .password("rawPassword")
                .roles(Set.of(RoleName.ROLE_SALES_EXECUTIVE))
                .enabled(true)
                .accountNonLocked(true)
                .build();

        when(userRepository.existsByEmail(request.getEmail())).thenReturn(false);
        when(roleRepository.findByName(RoleName.ROLE_SALES_EXECUTIVE)).thenReturn(Optional.of(salesRole));
        when(passwordEncoder.encode(request.getPassword())).thenReturn("encodedPassword");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User userToSave = invocation.getArgument(0);
            userToSave.setId(11L);
            return userToSave;
        });

        UserResponse response = userService.createUser(request);

        assertNotNull(response);
        assertEquals(11L, response.getId());
        assertEquals("new@example.com", response.getEmail());
        assertTrue(response.isEnabled());
        assertTrue(response.isAccountNonLocked());
        assertTrue(response.getRoles().contains(RoleName.ROLE_SALES_EXECUTIVE));

        verify(userRepository, times(1)).save(any(User.class));
    }

    @Test
    public void createUser_duplicateEmail_throwsException() {
        CreateUserRequest request = CreateUserRequest.builder()
                .email("test@example.com")
                .password("rawPassword")
                .roles(Set.of(RoleName.ROLE_SALES_EXECUTIVE))
                .build();

        when(userRepository.existsByEmail(request.getEmail())).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> userService.createUser(request));

        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    public void getUserById_success() {
        when(userRepository.findById(10L)).thenReturn(Optional.of(sampleUser));

        UserResponse response = userService.getUserById(10L);

        assertNotNull(response);
        assertEquals(10L, response.getId());
        assertEquals("test@example.com", response.getEmail());
    }

    @Test
    public void getUserById_notFound_throwsException() {
        when(userRepository.findById(99L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> userService.getUserById(99L));
    }

    @Test
    public void updateMyProfile_passwordChange_success() {
        UpdateMeRequest request = UpdateMeRequest.builder()
                .email("test@example.com")
                .currentPassword("currentRawPassword")
                .newPassword("newRawPassword")
                .build();

        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("currentRawPassword", sampleUser.getPassword())).thenReturn(true);
        when(passwordEncoder.encode("newRawPassword")).thenReturn("newEncodedPassword");
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);

        UserResponse response = userService.updateMyProfile("test@example.com", request);

        assertNotNull(response);
        assertEquals("test@example.com", response.getEmail());
        verify(passwordEncoder, times(1)).encode("newRawPassword");
        verify(userRepository, times(1)).save(sampleUser);
    }
}
