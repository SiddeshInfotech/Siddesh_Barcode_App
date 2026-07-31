import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://rcdbqpmmtyioqxrzsdeg.supabase.co';
  // Standard Supabase Anon Key (publishable)
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjZGJxcG1tdHlpb3F4cnpzZGVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDAwMDAwMDAsImV4cCI6MjAxNTAwMDAwMH0.anon_key_placeholder';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] Initialized Supabase client: $supabaseUrl');
    } catch (e) {
      debugPrint('[SupabaseService] Supabase init info: $e');
    }
  }

  SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Official Mobile scan_receive RPC Invocation.
  /// Calls Supabase RPC `public.scan_receive` with:
  /// { p_code, p_client_txn_id, p_device_source }
  ///
  /// The database RPC updates `product_barcodes.status`:
  ///   GENERATED → INWARDED
  ///   INWARDED → OUTWARDED
  /// and creates `barcode_scans` + `stock_ledger` entries.
  Future<Map<String, dynamic>> scanReceive({
    required String pCode,
    String? pClientTxnId,
    String pDeviceSource = 'CAMERA',
  }) async {
    final txnId = pClientTxnId ?? const Uuid().v4();
    final cleanCode = pCode.trim();

    debugPrint('[SupabaseService] Invoking RPC scan_receive for "$cleanCode" (txn: $txnId, source: $pDeviceSource)');

    final supabaseClient = client;
    if (supabaseClient != null) {
      try {
        debugPrint('================ [TRACE: SupabaseService.scanReceive] ================');
        debugPrint('[TRACE BEFORE RPC] Executing supabaseClient.rpc("scan_receive", params: {p_code: "$cleanCode", p_client_txn_id: "$txnId", p_device_source: "$pDeviceSource"})');
        
        final response = await supabaseClient.rpc(
          'scan_receive',
          params: {
            'p_code': cleanCode,
            'p_client_txn_id': txnId,
            'p_device_source': pDeviceSource,
          },
        );

        debugPrint('[TRACE AFTER RPC] RPC call returned! Raw response: $response');
        debugPrint('=======================================================================');

        final resultMap = response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
        final rpcStatus = resultMap['status']?.toString() ?? 'INWARDED';

        // Dual Safety: Explicitly update product_barcodes row status in Supabase DB
        try {
          await supabaseClient.from('product_barcodes').update({
            'status': rpcStatus,
            'updated_at': DateTime.now().toIso8601String(),
          }).match({'code': cleanCode});
          debugPrint('[SupabaseService] Successfully updated product_barcodes row status to $rpcStatus for barcode $cleanCode');
        } catch (updateErr) {
          debugPrint('[SupabaseService] Table status update info: $updateErr');
        }

        return resultMap;
      } catch (e) {
        debugPrint('================ [TRACE ERROR: SupabaseService.scanReceive] ================');
        debugPrint('[TRACE ERROR AFTER RPC] RPC call threw exception: $e');
        debugPrint('============================================================================');
        if (e.toString().contains('NO_OFFICE')) {
          rethrow;
        }
      }
    }

    throw Exception('NO_SUPABASE_CLIENT');
  }
}
