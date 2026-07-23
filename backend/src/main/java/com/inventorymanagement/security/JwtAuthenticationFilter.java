package com.inventorymanagement.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

/**
 * Filter to intercept all HTTP requests, extract and validate JWT tokens,
 * and populate Spring Security Context when authentication is valid.
 */
@Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;
    private final CustomUserDetailsService userDetailsService;

    /**
     * Constructs a new JwtAuthenticationFilter.
     *
     * @param tokenProvider      the JwtTokenProvider to decode tokens
     * @param userDetailsService the CustomUserDetailsService to load user details
     */
    public JwtAuthenticationFilter(JwtTokenProvider tokenProvider, CustomUserDetailsService userDetailsService) {
        this.tokenProvider = tokenProvider;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String requestURI = request.getRequestURI();
        String authorizationHeader = request.getHeader("Authorization");
        log.info("JWT Filter: Request URI = {}, Authorization Header = {}", requestURI, authorizationHeader);

        try {
            String jwt = getJwtFromRequest(request);
            log.info("JWT Filter: Parsed JWT Token = {}", jwt);

            if (StringUtils.hasText(jwt)) {
                boolean isValid = tokenProvider.validateToken(jwt);
                log.info("JWT Filter: Token validation result = {}", isValid);

                if (isValid) {
                    String username = tokenProvider.getUsernameFromJwt(jwt);
                    log.info("JWT Filter: Token username = {}", username);

                    UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                    log.info("JWT Filter: Loaded UserDetails for {}, authorities = {}", username, userDetails.getAuthorities());

                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    log.info("JWT Filter: Successfully authenticated user '{}' and set SecurityContext", username);
                } else {
                    log.warn("JWT Filter: Token is not valid");
                }
            } else {
                log.info("JWT Filter: No JWT token found in request headers");
            }
        } catch (Exception ex) {
            log.error("JWT Filter: Could not set user authentication in security context", ex);
        }

        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken)) {
            String token = bearerToken.trim();
            if (token.toLowerCase().startsWith("bearer ")) {
                token = token.substring(7).trim();
            }
            // Double check if the user mistakenly prefixed it again (e.g. Bearer Bearer <token>)
            if (token.toLowerCase().startsWith("bearer ")) {
                token = token.substring(7).trim();
            }
            // Strip surrounding double quotes if present
            if (token.startsWith("\"") && token.endsWith("\"") && token.length() > 1) {
                token = token.substring(1, token.length() - 1).trim();
            }
            // Strip surrounding single quotes if present
            if (token.startsWith("'") && token.endsWith("'") && token.length() > 1) {
                token = token.substring(1, token.length() - 1).trim();
            }
            return token;
        }
        return null;
    }
}
