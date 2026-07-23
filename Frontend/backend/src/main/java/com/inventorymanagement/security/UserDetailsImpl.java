package com.inventorymanagement.security;

import com.inventorymanagement.entity.User;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;
import java.util.stream.Collectors;

/**
 * Custom UserDetails implementation mapping our User entity to Spring Security's core interface.
 */
public class UserDetailsImpl implements UserDetails {

    private final User user;

    /**
     * Constructor wrapping the User entity.
     *
     * @param user the User database entity
     */
    public UserDetailsImpl(User user) {
        this.user = user;
    }

    /**
     * Retrieves the wrapped User entity.
     *
     * @return the User entity
     */
    public User getUser() {
        return user;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return user.getRoles().stream()
                .map(role -> new SimpleGrantedAuthority(role.getName().name()))
                .collect(Collectors.toList());
    }

    @Override
    public String getPassword() {
        return user.getPassword();
    }

    @Override
    public String getUsername() {
        return user.getEmail();
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return user.isAccountNonLocked();
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return user.isEnabled();
    }
}
