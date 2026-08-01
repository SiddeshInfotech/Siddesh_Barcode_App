import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import 'supabase_service.dart';

// Custom exceptions for data-layer calls.
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class ProductNotFoundException implements Exception {
  final String message;
  ProductNotFoundException(this.message);
  @override
  String toString() => message;
}

class ServerErrorException implements Exception {
  final String message;
  ServerErrorException(this.message);
  @override
  String toString() => message;
}

/// Facade the screens call. It now delegates to [SupabaseService], so the phone reads
/// and writes the same Supabase project the desktop app uses (auth + RLS + the locked
/// `save_inward` / `save_outward` RPCs). Method names are kept so screens are unchanged.
class ApiService {
  final SupabaseService _db = SupabaseService();

  /// Kept for callers (e.g. Settings) that display the data source. Returns the Supabase
  /// project URL — there is no LAN backend to discover any more.
  Future<String> getBaseUrl({bool forceRefresh = false}) async {
    return SupabaseService.supabaseUrl;
  }

  /// Ensures a Supabase session exists so RLS grants access. Returns true on success.
  Future<bool> ensureAuthenticated() async {
    final ok = await _db.ensureSignedIn();
    debugPrint('[ApiService] Supabase auth ${ok ? "ready" : "FAILED"}');
    return ok;
  }

  /// Fetches a product by barcode from Supabase (the single source of truth).
  ///
  /// Throws [ProductNotFoundException] when the barcode isn't registered and
  /// [NetworkException] when Supabase can't be reached. Never fabricates a product.
  Future<Product> getProductByBarcode(String rawBarcode) async {
    final code = rawBarcode
        .trim()
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F​-‍﻿]'), '');
    final Product? product;
    try {
      product = await _db.lookupProductByCode(code);
    } catch (e) {
      debugPrint('[ApiService] Product lookup error: $e');
      throw NetworkException(
          'Could not reach Supabase. Check the internet connection and try again.');
    }
    if (product == null) {
      throw ProductNotFoundException('No product found for "$code".');
    }
    return product;
  }

  /// Fetches the active product catalogue with live stock. Throws [NetworkException]
  /// if Supabase is unreachable.
  Future<List<Product>> getAllProducts({int page = 0, int size = 100}) async {
    try {
      return await _db.fetchProducts();
    } catch (e) {
      debugPrint('[ApiService] Error loading products: $e');
      throw NetworkException('Could not reach Supabase to load products.');
    }
  }

  /// Live dashboard statistics from the real balances/ledger. Returns zeros on failure.
  Future<DashboardStats> getDashboardStats() async {
    try {
      final s = await _db.fetchDashboardStats();
      return DashboardStats(
        currentStock: s['currentStock'] ?? 0,
        todayInward: s['todayInward'] ?? 0,
        todayOutward: s['todayOutward'] ?? 0,
        lowStockItems: s['lowStockItems'] ?? 0,
      );
    } catch (e) {
      debugPrint('[ApiService] Error fetching dashboard stats: $e');
      return const DashboardStats();
    }
  }

  /// Receives the scanned barcode via the `scan_receive` RPC (scan-driven stock). The RPC
  /// decides the transition from the barcode's current status — GENERATED→INWARDED — and
  /// records the scan + ledger so the unit is counted in stock.
  Future<String> recordInward(
      {String? barcode, int quantity = 1, int? productId}) async {
    return _scan(barcode);
  }

  /// Dispatches the scanned barcode via the `scan_receive` RPC. On an already-received
  /// barcode this advances INWARDED→OUTWARDED. Same scan-driven path as [recordInward].
  Future<String> recordOutward(
      {String? barcode, int quantity = 1, int? productId}) async {
    return _scan(barcode);
  }

  /// Runs a scan through `scan_receive` and turns its result into a status string or a
  /// user-facing error. The DB advances the lifecycle based on the barcode's current
  /// status and records who/when/device.
  Future<String> _scan(String? barcode) async {
    final code = (barcode ?? '').trim();
    if (code.isEmpty) throw Exception('No barcode provided.');

    final Map<String, dynamic> res;
    try {
      res = await _db.scanReceive(code);
    } catch (e) {
      final text = e.toString();
      if (text.contains('NO_OFFICE')) {
        throw Exception('Your login has no office assigned. Contact the administrator.');
      }
      debugPrint('[ApiService] scan_receive error: $e');
      throw Exception('Could not reach Supabase. Check the connection and try again.');
    }

    if (res['found'] == false) throw Exception("This barcode isn't registered yet.");
    if (res['ok'] == false) {
      throw Exception((res['error'] ?? 'Scan could not be recorded.').toString());
    }
    // ok — return the confirmed new status (or the terminal status if already handled).
    return (res['status'] ?? 'DONE').toString();
  }

  /// Product creation is performed on the desktop app (it sets category/brand/unit and
  /// generates barcodes). Kept so the generator screen compiles and shows a clear message.
  Future<Product> createProduct({
    required String name,
    required String barcode,
    required double price,
    required int quantity,
    String? description,
    String? sku,
    String? category,
    String? brand,
    List<String>? barcodes,
  }) async {
    throw ServerErrorException(
        'Creating products from the mobile app is not supported yet — add products and generate barcodes on the desktop app.');
  }

  /// Verifies Supabase is reachable/authenticated. Returns the project URL on success,
  /// or null. Kept for the Settings "Test Connection" control.
  Future<String?> testConnection(String hostOrUrl) async {
    final ok = await _db.ensureSignedIn();
    return ok ? SupabaseService.supabaseUrl : null;
  }

  /// No manual backend override in the Supabase model. Kept so Settings compiles.
  static void setManualBaseUrl(String? hostOrUrl) {}

  /// Always null now — there is no manual LAN backend override.
  static String? get manualBaseUrl => null;
}

class DashboardStats {
  final int currentStock;
  final int todayInward;
  final int todayOutward;
  final int lowStockItems;

  const DashboardStats({
    this.currentStock = 0,
    this.todayInward = 0,
    this.todayOutward = 0,
    this.lowStockItems = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
      todayInward: (json['todayInward'] as num?)?.toInt() ?? 0,
      todayOutward: (json['todayOutward'] as num?)?.toInt() ?? 0,
      lowStockItems: (json['lowStockItems'] as num?)?.toInt() ?? 0,
    );
  }
}
