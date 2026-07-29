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

import org.springframework.beans.factory.annotation.Autowired;

/**
 * Component to seed roles and sample user records in the database at startup.
 */
@Slf4j
@Component
public class DatabaseSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final com.inventorymanagement.repository.ProductRepository productRepository;
    private final com.inventorymanagement.repository.ProductBarcodeRepository productBarcodeRepository;

    @Autowired(required = false)
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    public DatabaseSeeder(
            UserRepository userRepository,
            RoleRepository roleRepository,
            PasswordEncoder passwordEncoder,
            com.inventorymanagement.repository.ProductRepository productRepository,
            com.inventorymanagement.repository.ProductBarcodeRepository productBarcodeRepository) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.productRepository = productRepository;
        this.productBarcodeRepository = productBarcodeRepository;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        seedRoles();
        seedUsers();
        seedProducts();
        createPostgresTrigger();
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
        String defaultBarcode = "ST00012345";
        if (!productRepository.existsByBarcode(defaultBarcode)) {
            com.inventorymanagement.entity.Product defaultProduct = com.inventorymanagement.entity.Product.builder()
                    .name("Siddesh Sample Product")
                    .description("Sample barcode product for testing scanner")
                    .barcode(defaultBarcode)
                    .price(new java.math.BigDecimal("199.99"))
                    .quantity(50)
                    .sku("SKU-ST-00012345")
                    .category("General")
                    .brand("SiddeshInfotech")
                    .build();

            com.inventorymanagement.entity.Product saved = productRepository.save(defaultProduct);
            log.info("Seeded default product: {} with barcode: {}", saved.getName(), defaultBarcode);

            java.util.UUID productUuid = new java.util.UUID(0L, saved.getId());
            if (!productBarcodeRepository.existsByCode(defaultBarcode)) {
                productBarcodeRepository.save(com.inventorymanagement.entity.ProductBarcode.builder()
                        .productId(productUuid)
                        .code(defaultBarcode)
                        .build());
                log.info("Seeded product_barcodes entry for: {}", defaultBarcode);
            }
        }
    }

    private void createPostgresTrigger() {
        if (jdbcTemplate == null) return;
        try {
            log.info("Checking/Creating PostgreSQL trigger for automatic product_barcodes status updates...");
            
            jdbcTemplate.execute("""
                CREATE OR REPLACE FUNCTION update_product_barcode_status_trigger_fn()
                RETURNS TRIGGER AS $$
                BEGIN
                    IF NEW.barcode IS NOT NULL AND TRIM(NEW.barcode) <> '' THEN
                        IF UPPER(TRIM(NEW.type)) = 'INWARD' THEN
                            UPDATE public.product_barcodes 
                            SET status = 'INWARDED' 
                            WHERE LOWER(TRIM(code)) = LOWER(TRIM(NEW.barcode));
                        ELSIF UPPER(TRIM(NEW.type)) = 'OUTWARD' THEN
                            UPDATE public.product_barcodes 
                            SET status = 'OUTWARDED' 
                            WHERE LOWER(TRIM(code)) = LOWER(TRIM(NEW.barcode));
                        END IF;
                    END IF;
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;
            """);

            jdbcTemplate.execute("DROP TRIGGER IF EXISTS trg_update_product_barcode_status ON stock_transactions;");

            jdbcTemplate.execute("""
                CREATE TRIGGER trg_update_product_barcode_status
                AFTER INSERT ON stock_transactions
                FOR EACH ROW
                EXECUTE FUNCTION update_product_barcode_status_trigger_fn();
            """);

            log.info("PostgreSQL trigger trg_update_product_barcode_status installed successfully!");
        } catch (Exception e) {
            log.warn("PostgreSQL trigger creation skipped (non-PostgreSQL dialect or permission constraint): {}", e.getMessage());
        }
    }
}
