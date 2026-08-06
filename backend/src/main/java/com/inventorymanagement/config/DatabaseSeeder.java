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
        createScanReceiveRpc();
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
        String adminEmail = "SiddeshERP78@gmail.com";
        String adminPassword = "SiddeshERP78@@!!##";
        Role adminRole = roleRepository.findByName(RoleName.ROLE_ADMIN)
                .orElseThrow(() -> new IllegalStateException("Admin role not initialized"));

        var existingUserOpt = userRepository.findByEmail(adminEmail);
        if (existingUserOpt.isPresent()) {
            User existingAdmin = existingUserOpt.get();
            existingAdmin.setPassword(passwordEncoder.encode(adminPassword));
            userRepository.save(existingAdmin);
            log.info("Updated password for admin user: {}", adminEmail);
        } else {
            User admin = User.builder()
                    .email(adminEmail)
                    .password(passwordEncoder.encode(adminPassword))
                    .enabled(true)
                    .accountNonLocked(true)
                    .roles(Set.of(adminRole))
                    .build();

            userRepository.save(admin);
            log.info("Seeded default admin user: {}", adminEmail);
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

    private void createScanReceiveRpc() {
        if (jdbcTemplate == null) return;
        try {
            log.info("Checking/Creating PostgreSQL scan_receive RPC function...");

            jdbcTemplate.execute("""
                CREATE OR REPLACE FUNCTION public.scan_receive(
                  p_code          text,
                  p_client_txn_id uuid,
                  p_device_source public.scan_source default 'CAMERA'
                ) RETURNS jsonb
                  LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, app AS
                $$
                DECLARE
                  v_office_id      uuid;
                  v_bc             public.product_barcodes;
                  v_existing       public.barcode_scans;
                  v_next_status    public.barcode_status;
                  v_scan_action    public.scan_action;
                  v_txn_type       public.stock_txn_type;
                  v_qty_delta      integer;
                  v_ledger         public.stock_ledger;
                  v_clean_code     text;
                  v_prod_id        uuid;
                BEGIN
                  RAISE NOTICE '[TIMING 0ms] Starting scan_receive RPC execution for code %', p_code;

                  -- 1. Resolve Office ID with robust fallback
                  v_office_id := app.current_office_id();
                  IF v_office_id IS NULL THEN
                    SELECT office_id INTO v_office_id FROM public.profiles WHERE office_id IS NOT NULL LIMIT 1;
                  END IF;
                  IF v_office_id IS NULL THEN
                    SELECT id INTO v_office_id FROM public.offices ORDER BY created_at LIMIT 1;
                  END IF;
                  IF v_office_id IS NULL THEN
                    INSERT INTO public.offices (name, code) VALUES ('Main Office', 'MAIN') RETURNING id INTO v_office_id;
                  END IF;
                  RAISE NOTICE '[STEP 1 COMPLETE] Office ID resolved: %', v_office_id;

                  -- 2. Clean input barcode
                  v_clean_code := TRIM(p_code);
                  IF v_clean_code IS NULL OR LENGTH(v_clean_code) = 0 THEN
                    RETURN jsonb_build_object('ok', false, 'found', false, 'error', 'INVALID_CODE', 'message', 'Barcode code cannot be empty');
                  END IF;
                  RAISE NOTICE '[STEP 2 COMPLETE] Clean barcode: %', v_clean_code;

                  -- 3. Idempotency check (prevent duplicate scans with same client_txn_id)
                  SELECT * INTO v_existing FROM public.barcode_scans WHERE client_txn_id = p_client_txn_id;
                  IF FOUND THEN
                    SELECT status INTO v_next_status FROM public.product_barcodes WHERE id = v_existing.barcode_id;
                    RAISE NOTICE '[STEP 3 REPLAY] Idempotency match found for txn %', p_client_txn_id;
                    RETURN jsonb_build_object(
                      'ok', true,
                      'replayed', true,
                      'barcode_id', v_existing.barcode_id,
                      'status', v_next_status,
                      'code', v_clean_code
                    );
                  END IF;
                  RAISE NOTICE '[STEP 3 COMPLETE] Idempotency check passed';

                  -- 4. Find barcode record in product_barcodes (or auto-insert if new barcode)
                  SELECT * INTO v_bc FROM public.product_barcodes WHERE LOWER(code) = LOWER(v_clean_code);
                  IF NOT FOUND THEN
                    SELECT id INTO v_prod_id FROM public.products ORDER BY created_at LIMIT 1;
                    IF v_prod_id IS NULL THEN
                      INSERT INTO public.products (name, sku_barcode, price) VALUES ('Scanned Item ' || v_clean_code, v_clean_code, 0.00) RETURNING id INTO v_prod_id;
                    END IF;
                    INSERT INTO public.product_barcodes (product_id, code, status, symbology)
                    VALUES (v_prod_id, v_clean_code, 'GENERATED'::public.barcode_status, 'CODE128')
                    RETURNING * INTO v_bc;
                    RAISE NOTICE '[STEP 4 AUTO-INSERTED] Created barcode row in product_barcodes for code %', v_clean_code;
                  END IF;
                  RAISE NOTICE '[STEP 4 COMPLETE] Found barcode ID %, product_id %, current status %', v_bc.id, v_bc.product_id, v_bc.status;

                  -- 5. Determine lifecycle status transition & scan action
                  -- Lifecycle: GENERATED -> INWARDED -> OUTWARDED
                  IF v_bc.status = 'GENERATED' THEN
                    v_next_status := 'INWARDED'::public.barcode_status;
                    v_scan_action := 'RECEIVE'::public.scan_action;
                    v_txn_type    := 'INWARD'::public.stock_txn_type;
                    v_qty_delta   := 1;
                  ELSIF v_bc.status IN ('INWARDED', 'IN_STOCK') THEN
                    v_next_status := 'OUTWARDED'::public.barcode_status;
                    v_scan_action := 'ISSUE'::public.scan_action;
                    v_txn_type    := 'OUTWARD'::public.stock_txn_type;
                    v_qty_delta   := -1;
                  ELSIF v_bc.status IN ('OUTWARDED', 'OUTWARD') THEN
                    RETURN jsonb_build_object(
                      'ok', false,
                      'found', true,
                      'already', true,
                      'barcode_id', v_bc.id,
                      'status', v_bc.status,
                      'code', v_bc.code,
                      'message', 'Barcode is already OUTWARDED'
                    );
                  ELSE
                    RETURN jsonb_build_object(
                      'ok', false,
                      'found', true,
                      'already', true,
                      'barcode_id', v_bc.id,
                      'status', v_bc.status,
                      'code', v_bc.code,
                      'message', 'Barcode status ' || v_bc.status || ' cannot be scanned'
                    );
                  END IF;
                  RAISE NOTICE '[STEP 5 COMPLETE] Transition: % -> % (Action: %, Qty: %)', v_bc.status, v_next_status, v_scan_action, v_qty_delta;

                  -- 6. Create stock_ledger entry
                  RAISE NOTICE '[STEP 6 START] Invoking app.post_ledger...';
                  v_ledger := app.post_ledger(
                    p_client_txn_id := p_client_txn_id,
                    p_office_id     := v_office_id,
                    p_product_id    := v_bc.product_id,
                    p_unit_id       := null,
                    p_txn_type      := v_txn_type,
                    p_qty_delta     := v_qty_delta,
                    p_ref_type      := (CASE WHEN v_txn_type = 'INWARD' THEN 'INWARD'::public.doc_ref_type ELSE 'OUTWARD'::public.doc_ref_type END),
                    p_ref_id        := v_bc.id,
                    p_notes         := 'Scan transition ' || v_bc.status || ' -> ' || v_next_status || ' (' || v_scan_action || ')',
                    p_batch_id      := v_bc.batch_id
                  );
                  RAISE NOTICE '[STEP 6 COMPLETE] stock_ledger inserted with ID %', v_ledger.id;

                  -- 7. Update product_barcodes.status
                  RAISE NOTICE '[STEP 7 START] Updating product_barcodes.status...';
                  UPDATE public.product_barcodes
                     SET status = v_next_status,
                         updated_at = now()
                   WHERE id = v_bc.id;
                  RAISE NOTICE '[STEP 7 COMPLETE] product_barcodes updated to %', v_next_status;

                  -- 8. Create barcode_scans audit log entry
                  RAISE NOTICE '[STEP 8 START] Inserting barcode_scans...';
                  INSERT INTO public.barcode_scans (
                    barcode_id, product_id, batch_id, office_id, action, device_source, client_txn_id, ledger_id, scanned_by, scanned_at
                  ) VALUES (
                    v_bc.id, v_bc.product_id, v_bc.batch_id, v_office_id, v_scan_action, p_device_source, p_client_txn_id, v_ledger.id, auth.uid(), now()
                  );
                  RAISE NOTICE '[STEP 8 COMPLETE] barcode_scans audit entry inserted';

                  -- 9. Return latest status and details
                  RETURN jsonb_build_object(
                    'ok', true,
                    'found', true,
                    'already', false,
                    'replayed', false,
                    'barcode_id', v_bc.id,
                    'product_id', v_bc.product_id,
                    'batch_id', v_bc.batch_id,
                    'previous_status', v_bc.status,
                    'status', v_next_status,
                    'code', v_bc.code,
                    'ledger_id', v_ledger.id
                  );
                END;
                $$;
            """);

            jdbcTemplate.execute("REVOKE ALL ON FUNCTION public.scan_receive(text, uuid, public.scan_source) FROM public, anon;");
            jdbcTemplate.execute("GRANT EXECUTE ON FUNCTION public.scan_receive(text, uuid, public.scan_source) TO authenticated;");
            jdbcTemplate.execute("GRANT EXECUTE ON FUNCTION public.scan_receive(text, uuid, public.scan_source) TO service_role;");

            log.info("PostgreSQL scan_receive RPC function created/updated successfully!");
        } catch (Exception e) {
            log.warn("PostgreSQL scan_receive RPC creation skipped: {}", e.getMessage());
        }
    }
}
