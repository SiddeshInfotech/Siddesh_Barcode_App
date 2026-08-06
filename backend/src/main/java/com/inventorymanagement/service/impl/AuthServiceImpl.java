package com.inventorymanagement.service.impl;

import com.inventorymanagement.dto.LoginRequest;
import com.inventorymanagement.dto.LoginResponse;
import com.inventorymanagement.security.JwtTokenProvider;
import com.inventorymanagement.security.UserDetailsImpl;
import com.inventorymanagement.service.AuthService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service implementation handling Spring Security authentication and JWT token issuance.
 */
@Slf4j
@Service
public class AuthServiceImpl implements AuthService {

    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider tokenProvider;

    /**
     * Constructs a new AuthServiceImpl.
     *
     * @param authenticationManager the Spring Security authentication manager
     * @param tokenProvider        the utility class generating access tokens
     */
    public AuthServiceImpl(AuthenticationManager authenticationManager, JwtTokenProvider tokenProvider) {
        this.authenticationManager = authenticationManager;
        this.tokenProvider = tokenProvider;
    }

    @Override
    public LoginResponse login(LoginRequest loginRequest) {
        log.info("Attempting authentication for user: {}", loginRequest.getEmail());

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        loginRequest.getEmail(),
                        loginRequest.getPassword()
                )
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = tokenProvider.generateToken(authentication);

        UserDetailsImpl userPrincipal = (UserDetailsImpl) authentication.getPrincipal();
        List<String> roles = userPrincipal.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());

        log.info("Authentication successful for user: {}", loginRequest.getEmail());

        return LoginResponse.builder()
                .token(jwt)
                .type("Bearer")
                .id(userPrincipal.getUser().getId())
                .email(userPrincipal.getUser().getEmail())
                .roles(roles)
                .build();
    }
}
