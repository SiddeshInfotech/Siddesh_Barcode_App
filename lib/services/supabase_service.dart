import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/product_model.dart';

/// Direct Supabase data layer — the phone talks to the same Supabase project the
/// desktop app writes to, using the anon key + an authenticated user (so RLS grants
/// access) and the locked RPC contract (`save_inward` / `save_outward`).
///
/// Product lookup goes through table reads (the `scan_lookup` RPC is currently broken
/// in the database — it references a missing `v_stock_balances` view).
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Correct project (matches the desktop app's .env) + publishable anon key.
  static const String supabaseUrl = 'https://hrgdanwvxjevwnpzgheo.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhyZ2Rhbnd2eGpldnducHpnaGVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxNzI4MjgsImV4cCI6MjA5OTc0ODgyOH0.S4bXnz5yBVJRXHMiA4YSPlinTC-0elMCNBMfD7JP6nQ';

  // Built-in service account used to authenticate to Supabase (so RLS applies).
  static const String _authEmail = 'SiddeshERP78@gmail.com';
  static const String _authPassword = 'SiddeshERP78@@!!##';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      _initialized = true;
      debugPrint('[SupabaseService] Initialized: $supabaseUrl');
    } catch (e) {
      debugPrint('[SupabaseService] init info: $e');
    }
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Ensures there is a signed-in Supabase user so RLS grants access to inventory data.
  /// Returns true when a session is active. Safe to call repeatedly.
  Future<bool> ensureSignedIn() async {
    if (_client.auth.currentSession != null) return true;
    try {
      final res = await _client.auth
          .signInWithPassword(email: _authEmail, password: _authPassword);
      final ok = res.session != null;
      debugPrint('[SupabaseService] signIn ok=$ok user=${res.user?.id}');
      return ok;
    } catch (e) {
      debugPrint('[SupabaseService] signIn failed: $e');
      return false;
    }
  }

  /// Resolves the product UUID for a scanned barcode, or null if it isn't registered.
  Future<String?> resolveProductIdByCode(String code) async {
    await ensureSignedIn();
    final row = await _client
        .from('product_barcodes')
        .select('product_id')
        .eq('code', code.trim())
        .maybeSingle();
    return row?['product_id'] as String?;
  }

  /// Looks up a product by one of its barcodes, with its live available stock.
  /// Returns null when the barcode is not registered in the database.
  Future<Product?> lookupProductByCode(String rawCode) async {
    final code = rawCode.trim();
    await ensureSignedIn();

    final row = await _client
        .from('product_barcodes')
        .select(
            'product_id, products(id,name,model_number,min_stock,description,categories(name),brands(name),uoms(name))')
        .eq('code', code)
        .maybeSingle();

    if (row == null || row['products'] == null) return null;

    final product = row['products'] as Map<String, dynamic>;
    final productId = product['id'] as String;
    final available = await _availableStockFor(productId);
    return _toProduct(code, productId, product, available);
  }

  /// Fetches the active product catalogue with live stock and a representative barcode.
  Future<List<Product>> fetchProducts() async {
    await ensureSignedIn();

    final products = await _client
        .from('products')
        .select(
            'id,name,model_number,min_stock,description,categories(name),brands(name),uoms(name)')
        .eq('is_active', true)
        .order('name', ascending: true);

    final stockByProduct = await _stockByProduct();
    final codeByProduct = await _firstCodeByProduct();

    return (products as List).map((raw) {
      final p = raw as Map<String, dynamic>;
      final pid = p['id'] as String;
      final available = stockByProduct[pid] ?? 0;
      return _toProduct(codeByProduct[pid] ?? '', pid, p, available);
    }).toList();
  }

  /// Live dashboard metrics computed from the real balances/ledger.
  Future<Map<String, int>> fetchDashboardStats() async {
    await ensureSignedIn();

    final stockByProduct = await _stockByProduct();
    final currentStock = stockByProduct.values.fold<int>(0, (sum, q) => sum + q);

    final products = await _client
        .from('products')
        .select('id,min_stock')
        .eq('is_active', true);
    var lowStock = 0;
    for (final raw in products as List) {
      final p = raw as Map<String, dynamic>;
      final min = (p['min_stock'] as num?)?.toInt() ?? 0;
      final avail = stockByProduct[p['id'] as String] ?? 0;
      if (min > 0 && avail < min) lowStock++;
    }

    final today = await _todayMovements();

    return {
      'currentStock': currentStock,
      'todayInward': today['inward'] ?? 0,
      'todayOutward': today['outward'] ?? 0,
      'lowStockItems': lowStock,
    };
  }

  /// Records an inward movement via the `save_inward` RPC. Returns the new balance.
  Future<int> saveInward({
    required String productId,
    required int qty,
    required String supplierName,
    required String clientTxnId,
  }) async {
    await ensureSignedIn();
    final res = await _client.rpc('save_inward', params: {
      'p_client_txn_id': clientTxnId,
      'p_product_id': productId,
      'p_qty': qty,
      'p_supplier_name': supplierName,
    });
    return _balanceAfter(res, qty);
  }

  /// Records an outward movement via the `save_outward` RPC. Returns the new balance.
  /// Throws (PostgrestException) with an INSUFFICIENT_STOCK message when stock is too low.
  Future<int> saveOutward({
    required String productId,
    required int qty,
    required String outwardType,
    String? partyName,
    required String clientTxnId,
  }) async {
    await ensureSignedIn();
    final res = await _client.rpc('save_outward', params: {
      'p_client_txn_id': clientTxnId,
      'p_product_id': productId,
      'p_qty': qty,
      'p_outward_type': outwardType,
      if (partyName != null && partyName.isNotEmpty) 'p_party_name': partyName,
    });
    return _balanceAfter(res, 0);
  }

  /// Runs the `scan_receive` RPC for a scanned code — the proper scan-driven path.
  ///
  /// It advances the barcode's status (GENERATED→INWARDED, INWARDED→OUTWARDED), writes a
  /// `barcode_scans` row (which carries the office + device + who/when the desktop shows),
  /// and posts the stock ledger — so the unit is counted in current stock. Returns the RPC
  /// JSON: `{ ok, found, already, status, code, ... }`. Idempotent via `client_txn_id`.
  Future<Map<String, dynamic>> scanReceive(String code,
      {String deviceSource = 'CAMERA'}) async {
    await ensureSignedIn();
    final res = await _client.rpc('scan_receive', params: {
      'p_code': code.trim(),
      'p_client_txn_id': const Uuid().v4(),
      'p_device_source': deviceSource,
    });
    return res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
  }

  /// Sets a barcode's lifecycle status on `product_barcodes` (barcode_status enum).
  /// Valid values: GENERATED, INWARDED, OUTWARDED. Best-effort — the stock movement is
  /// the source of truth, so a failed status flip is logged, not fatal. Returns whether
  /// the update succeeded.
  Future<bool> updateBarcodeStatus(String code, String status) async {
    final clean = code.trim();
    if (clean.isEmpty) return false;
    await ensureSignedIn();
    try {
      await _client
          .from('product_barcodes')
          .update({'status': status})
          .eq('code', clean);
      debugPrint('[SupabaseService] barcode "$clean" status -> $status');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] status update failed for "$clean": $e');
      return false;
    }
  }

  // ---- helpers -------------------------------------------------------------

  Future<int> _availableStockFor(String productId) async {
    final rows = await _client
        .from('stock_balances')
        .select('qty_available')
        .eq('product_id', productId);
    var total = 0;
    for (final r in rows as List) {
      total += ((r as Map)['qty_available'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  Future<Map<String, int>> _stockByProduct() async {
    final rows =
        await _client.from('stock_balances').select('product_id,qty_available');
    final map = <String, int>{};
    for (final raw in rows as List) {
      final r = raw as Map<String, dynamic>;
      final pid = r['product_id'] as String?;
      if (pid == null) continue;
      map[pid] = (map[pid] ?? 0) + ((r['qty_available'] as num?)?.toInt() ?? 0);
    }
    return map;
  }

  Future<Map<String, String>> _firstCodeByProduct() async {
    final rows = await _client.from('product_barcodes').select('product_id,code');
    final map = <String, String>{};
    for (final raw in rows as List) {
      final r = raw as Map<String, dynamic>;
      final pid = r['product_id'] as String?;
      final code = r['code'] as String?;
      if (pid != null && code != null && !map.containsKey(pid)) {
        map[pid] = code;
      }
    }
    return map;
  }

  Future<Map<String, int>> _todayMovements() async {
    try {
      final now = DateTime.now().toUtc();
      final start = DateTime.utc(now.year, now.month, now.day).toIso8601String();
      final rows = await _client
          .from('stock_ledger')
          .select('txn_type,qty_delta,created_at')
          .gte('created_at', start);
      var inward = 0;
      var outward = 0;
      for (final raw in rows as List) {
        final r = raw as Map<String, dynamic>;
        final type = (r['txn_type'] as String?)?.toUpperCase() ?? '';
        final delta = (r['qty_delta'] as num?)?.toInt() ?? 0;
        if (type.contains('INWARD') || delta > 0) {
          inward += delta.abs();
        } else if (type.contains('OUTWARD') || delta < 0) {
          outward += delta.abs();
        }
      }
      return {'inward': inward, 'outward': outward};
    } catch (e) {
      debugPrint('[SupabaseService] today movements unavailable: $e');
      return {'inward': 0, 'outward': 0};
    }
  }

  int _balanceAfter(dynamic res, int fallback) {
    if (res is Map && res['balance_after'] != null) {
      return (res['balance_after'] as num).toInt();
    }
    return fallback;
  }

  Product _toProduct(String barcode, String productId,
      Map<String, dynamic> product, int available) {
    final category = (product['categories'] as Map?)?['name'] as String? ?? '';
    final brand = (product['brands'] as Map?)?['name'] as String? ?? '';
    final unit = (product['uoms'] as Map?)?['name'] as String? ?? '';
    return Product(
      id: productId,
      barcode: barcode,
      name: product['name'] as String? ?? 'Unnamed product',
      category: category.isEmpty ? 'Uncategorised' : category,
      brand: brand.isEmpty ? '—' : brand,
      model: product['model_number'] as String? ?? (unit.isEmpty ? '' : unit),
      currentStock: available,
      minimumStock: (product['min_stock'] as num?)?.toInt() ?? 0,
      availableStock: available,
      imageUrl: '',
      supplier: '',
      description: product['description'] as String? ?? '',
    );
  }
}
