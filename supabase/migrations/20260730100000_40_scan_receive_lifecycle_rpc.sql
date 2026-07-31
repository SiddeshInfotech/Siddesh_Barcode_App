-- =============================================================================
-- 40 — SCAN RECEIVE OFFICIAL BARCODE LIFECYCLE RPC WITH TIMING & NOTICE LOGGING
-- =============================================================================

create or replace function public.scan_receive(
  p_code          text,
  p_client_txn_id uuid,
  p_device_source public.scan_source default 'CAMERA'
) returns jsonb
  language plpgsql security definer set search_path = public, app as
$$
declare
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
begin
  raise notice '[TIMING 0ms] Starting scan_receive RPC execution for code %', p_code;

  -- 1. Resolve Office ID with robust fallback
  v_office_id := app.current_office_id();
  if v_office_id is null then
    select office_id into v_office_id from public.profiles where office_id is not null limit 1;
  end if;
  if v_office_id is null then
    select id into v_office_id from public.offices order by created_at limit 1;
  end if;
  if v_office_id is null then
    insert into public.offices (name, code) values ('Main Office', 'MAIN') returning id into v_office_id;
  end if;
  raise notice '[STEP 1 COMPLETE] Office ID resolved: %', v_office_id;

  -- 2. Clean input barcode
  v_clean_code := trim(p_code);
  if v_clean_code is null or length(v_clean_code) = 0 then
    return jsonb_build_object('ok', false, 'found', false, 'error', 'INVALID_CODE', 'message', 'Barcode code cannot be empty');
  end if;
  raise notice '[STEP 2 COMPLETE] Clean barcode: %', v_clean_code;

  -- 3. Idempotency check (prevent duplicate scans with same client_txn_id)
  select * into v_existing from public.barcode_scans where client_txn_id = p_client_txn_id;
  if found then
    select status into v_next_status from public.product_barcodes where id = v_existing.barcode_id;
    raise notice '[STEP 3 REPLAY] Idempotency match found for txn %', p_client_txn_id;
    return jsonb_build_object(
      'ok', true,
      'replayed', true,
      'barcode_id', v_existing.barcode_id,
      'status', v_next_status,
      'code', v_clean_code
    );
  end if;
  raise notice '[STEP 3 COMPLETE] Idempotency check passed';

  -- 4. Find barcode record in product_barcodes (or auto-insert if new barcode)
  select * into v_bc from public.product_barcodes where lower(code) = lower(v_clean_code);
  if not found then
    select id into v_prod_id from public.products order by created_at limit 1;
    if v_prod_id is null then
      insert into public.products (name, sku_barcode, price) values ('Scanned Item ' || v_clean_code, v_clean_code, 0.00) returning id into v_prod_id;
    end if;
    insert into public.product_barcodes (product_id, code, status, symbology)
    values (v_prod_id, v_clean_code, 'GENERATED'::public.barcode_status, 'CODE128')
    returning * into v_bc;
    raise notice '[STEP 4 AUTO-INSERTED] Created barcode row in product_barcodes for code %', v_clean_code;
  end if;
  raise notice '[STEP 4 COMPLETE] Found barcode ID %, product_id %, current status %', v_bc.id, v_bc.product_id, v_bc.status;

  -- 5. Determine lifecycle status transition & scan action
  -- Lifecycle: GENERATED -> INWARDED -> OUTWARDED
  if v_bc.status = 'GENERATED' then
    v_next_status := 'INWARDED'::public.barcode_status;
    v_scan_action := 'RECEIVE'::public.scan_action;
    v_txn_type    := 'INWARD'::public.stock_txn_type;
    v_qty_delta   := 1;
  elsif v_bc.status in ('INWARDED', 'IN_STOCK') then
    v_next_status := 'OUTWARDED'::public.barcode_status;
    v_scan_action := 'ISSUE'::public.scan_action;
    v_txn_type    := 'OUTWARD'::public.stock_txn_type;
    v_qty_delta   := -1;
  elsif v_bc.status in ('OUTWARDED', 'OUTWARD') then
    return jsonb_build_object(
      'ok', false,
      'found', true,
      'already', true,
      'barcode_id', v_bc.id,
      'status', v_bc.status,
      'code', v_bc.code,
      'message', 'Barcode is already OUTWARDED'
    );
  else
    return jsonb_build_object(
      'ok', false,
      'found', true,
      'already', true,
      'barcode_id', v_bc.id,
      'status', v_bc.status,
      'code', v_bc.code,
      'message', 'Barcode status ' || v_bc.status || ' cannot be scanned'
    );
  end if;
  raise notice '[STEP 5 COMPLETE] Transition: % -> % (Action: %, Qty: %)', v_bc.status, v_next_status, v_scan_action, v_qty_delta;

  -- 6. Create stock_ledger entry
  raise notice '[STEP 6 START] Invoking app.post_ledger...';
  v_ledger := app.post_ledger(
    p_client_txn_id := p_client_txn_id,
    p_office_id     := v_office_id,
    p_product_id    := v_bc.product_id,
    p_unit_id       := null,
    p_txn_type      := v_txn_type,
    p_qty_delta     := v_qty_delta,
    p_ref_type      := (case when v_txn_type = 'INWARD' then 'INWARD'::public.doc_ref_type else 'OUTWARD'::public.doc_ref_type end),
    p_ref_id        := v_bc.id,
    p_notes         := 'Scan transition ' || v_bc.status || ' -> ' || v_next_status || ' (' || v_scan_action || ')',
    p_batch_id      := v_bc.batch_id
  );
  raise notice '[STEP 6 COMPLETE] stock_ledger inserted with ID %', v_ledger.id;

  -- 7. Update product_barcodes.status
  raise notice '[STEP 7 START] Updating product_barcodes.status...';
  update public.product_barcodes
     set status = v_next_status,
         updated_at = now()
   where id = v_bc.id;
  raise notice '[STEP 7 COMPLETE] product_barcodes updated to %', v_next_status;

  -- 8. Create barcode_scans audit log entry
  raise notice '[STEP 8 START] Inserting barcode_scans...';
  insert into public.barcode_scans (
    barcode_id, product_id, batch_id, office_id, action, device_source, client_txn_id, ledger_id, scanned_by, scanned_at
  ) values (
    v_bc.id, v_bc.product_id, v_bc.batch_id, v_office_id, v_scan_action, p_device_source, p_client_txn_id, v_ledger.id, auth.uid(), now()
  );
  raise notice '[STEP 8 COMPLETE] barcode_scans audit entry inserted';

  -- 9. Return latest status and details
  return jsonb_build_object(
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
end;
$$;
