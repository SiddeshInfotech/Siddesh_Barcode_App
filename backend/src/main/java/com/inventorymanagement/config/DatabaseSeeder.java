package com.inventorymanagement.config;

import com.inventorymanagement.constants.RoleName;
import com.inventorymanagement.entity.Role;
import com.inventorymanagement.entity.User;
import com.inventorymanagement.repository.RoleRepository;
import com.inventorymanagement.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.Set;

/**
 * Component to seed roles and sample user records in the database at startup.
 */
@Slf4j
@Component
public class DatabaseSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * Constructs a new DatabaseSeeder.
     *
     * @param userRepository   the UserRepository dependency
     * @param roleRepository   the RoleRepository dependency
     * @param passwordEncoder the PasswordEncoder to hash user passwords
     */
    public DatabaseSeeder(
            UserRepository userRepository,
            RoleRepository roleRepository,
            PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        seedRoles();
        seedUsers();
    }

    private void seedRoles() {
        for (RoleName roleName : RoleName.values()) {
            if (roleRepository.findByName(roleName).isEmpty()) {
                Role role = Role.builder().name(roleName).build();
                roleRepository.save(role);
                log.info("Seeded role: {}", roleName);
            }
        }
    }

    private void seedUsers() {
        // Seed default admin user
        String adminEmail = "admin@inventory.com";
        if (userRepository.findByEmail(adminEmail).isEmpty()) {
            Role adminRole = roleRepository.findByName(RoleName.ROLE_ADMIN)
                    .orElseThrow(() -> new IllegalStateException("Admin role not initialized"));

            User admin = User.builder()
                    .email(adminEmail)
                    .password(passwordEncoder.encode("AdminPassword123!"))
                    .enabled(true)
                    .accountNonLocked(true)
                    .roles(Set.of(adminRole))
                    .build();

            userRepository.save(admin);
            log.info("Seeded default admin user: {}", adminEmail);
        }

        // Seed additional admin user
        String siddeshAdminEmail = "SiddeshERP78@gmail.com";
        if (userRepository.findByEmail(siddeshAdminEmail).isEmpty()) {
            Role adminRole = roleRepository.findByName(RoleName.ROLE_ADMIN)
                    .orElseThrow(() -> new IllegalStateException("Admin role not initialized"));

            User siddeshAdmin = User.builder()
                    .email(siddeshAdminEmail)
                    .password(passwordEncoder.encode("SiddeshERP78@@!!##"))
                    .enabled(true)
                    .accountNonLocked(true)
                    .roles(Set.of(adminRole))
                    .build();

            userRepository.save(siddeshAdmin);
            log.info("Seeded default admin user: {}", siddeshAdminEmail);
        }

        // Seed default manager user
        String managerEmail = "manager@inventory.com";
        if (userRepository.findByEmail(managerEmail).isEmpty()) {
            Role managerRole = roleRepository.findByName(RoleName.ROLE_STORE_MANAGER)
                    .orElseThrow(() -> new IllegalStateException("Store Manager role not initialized"));

            User manager = User.builder()
                    .email(managerEmail)
                    .password(passwordEncoder.encode("ManagerPassword123!"))
                    .enabled(true)
                    .accountNonLocked(true)
                    .roles(Set.of(managerRole))
                    .build();

            userRepository.save(manager);
            log.info("Seeded default manager user: {}", managerEmail);
        }

        // Seed default sales user
        String salesEmail = "sales@inventory.com";
        if (userRepository.findByEmail(salesEmail).isEmpty()) {
            Role salesRole = roleRepository.findByName(RoleName.ROLE_SALES_EXECUTIVE)
                    .orElseThrow(() -> new IllegalStateException("Sales Executive role not initialized"));

            User sales = User.builder()
                    .email(salesEmail)
                    .password(passwordEncoder.encode("SalesPassword123!"))
                    .enabled(true)
                    .accountNonLocked(true)
                    .roles(Set.of(salesRole))
                    .build();

            userRepository.save(sales);
            log.info("Seeded default sales user: {}", salesEmail);
        }
    }
}
