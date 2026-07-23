package com.inventorymanagement.config;

import com.inventorymanagement.constants.RoleName;
import com.inventorymanagement.entity.Role;
import com.inventorymanagement.entity.User;
import com.inventorymanagement.entity.Product;
import com.inventorymanagement.repository.RoleRepository;
import com.inventorymanagement.repository.UserRepository;
import com.inventorymanagement.repository.ProductRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
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
    private final ProductRepository productRepository;

    /**
     * Constructs a new DatabaseSeeder.
     *
     * @param userRepository    the UserRepository dependency
     * @param roleRepository    the RoleRepository dependency
     * @param passwordEncoder   the PasswordEncoder to hash user passwords
     * @param productRepository the ProductRepository dependency
     */
    public DatabaseSeeder(
            UserRepository userRepository,
            RoleRepository roleRepository,
            PasswordEncoder passwordEncoder,
            ProductRepository productRepository) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.productRepository = productRepository;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        seedRoles();
        seedUsers();
        seedProducts();
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

    private void seedProducts() {
        log.info("Seeding realistic product records from the uploaded PDF...");

        List<ProductSeed> seeds = List.of(
            new ProductSeed(
                "128-260723-0009",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD09)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. Reliable file storage and transfer.",
                new BigDecimal("1200.00"),
                85,
                "SD-128GB-0009",
                "Storage Devices",
                "SanDisk"
            ),
            new ProductSeed(
                "128-260723-0010",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD10)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. Durable metal casing design.",
                new BigDecimal("1200.00"),
                120,
                "SD-128GB-0010",
                "Storage Devices",
                "SanDisk"
            ),
            new ProductSeed(
                "128-260723-0011",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD11)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. Compact shape for ultimate convenience.",
                new BigDecimal("1200.00"),
                12,
                "SD-128GB-0011",
                "Storage Devices",
                "SanDisk"
            ),
            new ProductSeed(
                "128-260723-0012",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD12)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. Secure access file encryption software.",
                new BigDecimal("1200.00"),
                0,
                "SD-128GB-0012",
                "Storage Devices",
                "SanDisk"
            ),
            new ProductSeed(
                "128-260723-0013",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD13)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. Keyring loop design for active lifestyles.",
                new BigDecimal("1200.00"),
                90,
                "SD-128GB-0013",
                "Storage Devices",
                "SanDisk"
            ),
            new ProductSeed(
                "128-260723-0014",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD14)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. Lightweight plastic construction.",
                new BigDecimal("1200.00"),
                5,
                "SD-128GB-0014",
                "Storage Devices",
                "SanDisk"
            ),
            new ProductSeed(
                "128-260723-0015",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD15)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. Plug and play support for universal OS.",
                new BigDecimal("1200.00"),
                75,
                "SD-128GB-0015",
                "Storage Devices",
                "SanDisk"
            ),
            new ProductSeed(
                "128-260723-0016",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD16)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. Backwards compatible with legacy USB ports.",
                new BigDecimal("1200.00"),
                0,
                "SD-128GB-0016",
                "Storage Devices",
                "SanDisk"
            ),
            new ProductSeed(
                "128-260723-0017",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD17)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. High write and read speed performance.",
                new BigDecimal("1200.00"),
                110,
                "SD-128GB-0017",
                "Storage Devices",
                "SanDisk"
            ),
            new ProductSeed(
                "128-260723-0018",
                "SanDisk 128GB Ultra USB 3.0 Flash Drive (SD18)",
                "High-speed USB 3.0 pen drive by SanDisk with 128GB storage capacity. Ideal backup drive for crucial files.",
                new BigDecimal("1200.00"),
                8,
                "SD-128GB-0018",
                "Storage Devices",
                "SanDisk"
            )
        );

        for (ProductSeed seed : seeds) {
            Optional<Product> existingOpt = productRepository.findByBarcode(seed.barcode);
            if (existingOpt.isPresent()) {
                Product p = existingOpt.get();
                p.setName(seed.name);
                p.setDescription(seed.description);
                p.setPrice(seed.price);
                p.setQuantity(seed.quantity);
                p.setSku(seed.sku);
                p.setCategory(seed.category);
                p.setBrand(seed.brand);
                productRepository.save(p);
                log.info("Successfully updated seeded product: {} ({})", seed.name, seed.barcode);
            } else {
                Product p = Product.builder()
                        .barcode(seed.barcode)
                        .name(seed.name)
                        .description(seed.description)
                        .price(seed.price)
                        .quantity(seed.quantity)
                        .sku(seed.sku)
                        .category(seed.category)
                        .brand(seed.brand)
                        .build();
                productRepository.save(p);
                log.info("Successfully inserted seeded product: {} ({})", seed.name, seed.barcode);
            }
        }
    }

    private static class ProductSeed {
        String barcode;
        String name;
        String description;
        BigDecimal price;
        int quantity;
        String sku;
        String category;
        String brand;

        ProductSeed(String barcode, String name, String description, BigDecimal price, int quantity, String sku, String category, String brand) {
            this.barcode = barcode;
            this.name = name;
            this.description = description;
            this.price = price;
            this.quantity = quantity;
            this.sku = sku;
            this.category = category;
            this.brand = brand;
        }
    }
}
