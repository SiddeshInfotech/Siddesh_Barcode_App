import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

import 'dart:async';

// Custom exceptions for API calls
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

class ApiService {
  static String? _token;
  static String? _resolvedBaseUrl;
  
  // Primary PC LAN IP address for backend running on developer PC
  static const String pcLanIp = '10.97.198.106';
  static const String defaultPort = '8080';

  // Timeout for standard requests (10 seconds)
  final Duration timeoutDuration = const Duration(seconds: 10);
  // Probe timeout for active IP detection (1.5 seconds)
  final Duration probeTimeout = const Duration(milliseconds: 1500);

  // Helper method to automatically select correct backend URL based on platform
  Future<String> getBaseUrl({bool forceRefresh = false}) async {
    if (!forceRefresh && _resolvedBaseUrl != null) {
      return _resolvedBaseUrl!;
    }

    if (kIsWeb) {
      _resolvedBaseUrl = 'http://localhost:$defaultPort';
      debugPrint('[ApiService] Platform is Web. Backend Base URL: $_resolvedBaseUrl');
      return _resolvedBaseUrl!;
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _resolvedBaseUrl = 'http://localhost:$defaultPort';
      debugPrint('[ApiService] Platform is Desktop. Backend Base URL: $_resolvedBaseUrl');
      return _resolvedBaseUrl!;
    }

    if (Platform.isAndroid) {
      // Android Physical Device & Emulator Resolution:
      // 1. Try ADB Reverse Tunnel Loopback (127.0.0.1:8080) for USB connected physical Android device
      const adbLoopbackUrl = 'http://127.0.0.1:$defaultPort';
      debugPrint('[ApiService] Probing ADB reverse tunnel loopback ($adbLoopbackUrl)...');
      try {
        final res = await http.get(Uri.parse('$adbLoopbackUrl/api/test/db-info'))
            .timeout(probeTimeout);
        if (res.statusCode >= 200 && res.statusCode < 600) {
          _resolvedBaseUrl = adbLoopbackUrl;
          debugPrint('[ApiService] Successfully connected via ADB reverse tunnel: $_resolvedBaseUrl');
          return _resolvedBaseUrl!;
        }
      } catch (e) {
        debugPrint('[ApiService] ADB reverse tunnel probe failed ($adbLoopbackUrl): $e');
      }

      // 2. Try Android emulator gateway 10.0.2.2 for Android Emulators
      const emulatorUrl = 'http://10.0.2.2:$defaultPort';
      debugPrint('[ApiService] Probing Android Emulator gateway: $emulatorUrl...');
      try {
        final res = await http.get(Uri.parse('$emulatorUrl/api/test/db-info'))
            .timeout(probeTimeout);
        if (res.statusCode >= 200 && res.statusCode < 600) {
          _resolvedBaseUrl = emulatorUrl;
          debugPrint('[ApiService] Connected via Android Emulator Gateway: $_resolvedBaseUrl');
          return _resolvedBaseUrl!;
        }
      } catch (e) {
        debugPrint('[ApiService] Emulator probe failed ($emulatorUrl): $e');
      }

      // 3. Try PC LAN IP address 192.168.1.102 (Physical Android Phone connected via local Wi-Fi)
      final lanUrl = 'http://$pcLanIp:$defaultPort';
      debugPrint('[ApiService] Probing PC LAN IP backend URL: $lanUrl...');
      try {
        final res = await http.get(Uri.parse('$lanUrl/api/test/db-info'))
            .timeout(probeTimeout);
        if (res.statusCode >= 200 && res.statusCode < 600) {
          _resolvedBaseUrl = lanUrl;
          debugPrint('[ApiService] Successfully connected to PC LAN IP: $_resolvedBaseUrl');
          return _resolvedBaseUrl!;
        }
      } catch (e) {
        debugPrint('[ApiService] LAN IP probe failed ($lanUrl): $e');
      }

      // Default fallback: Try Android emulator gateway 10.0.2.2 first for emulators
      _resolvedBaseUrl = emulatorUrl;
      debugPrint('[ApiService] Defaulting to Android Emulator Gateway: $_resolvedBaseUrl');
      return _resolvedBaseUrl!;
    }

    // Default fallback
    _resolvedBaseUrl = 'http://$pcLanIp:$defaultPort';
    debugPrint('[ApiService] Backend Base URL: $_resolvedBaseUrl');
    return _resolvedBaseUrl!;
  }

  // Ensure user is authenticated before barcode scanning or operations start
  Future<bool> ensureAuthenticated() async {
    final baseUrl = await getBaseUrl();
    debugPrint('[ApiService] Verifying authentication before barcode scanning...');
    debugPrint('[ApiService] Backend Base URL in use: $baseUrl');
    
    if (_token != null && _token!.isNotEmpty) {
      debugPrint('[ApiService] Auth token already present. Pre-auth verified.');
      return true;
    }

    final success = await _login();
    if (success) {
      debugPrint('[ApiService] Silent authentication successful! Auth token acquired.');
    } else {
      debugPrint('[ApiService] Silent authentication failed. Backend at $baseUrl unreachable or credentials invalid.');
    }
    return success;
  }

  // Connection logging helper
  void _logConnection({
    required String baseUrl,
    required String requestUrl,
    required String responseStatus,
    required String errorMessage,
  }) {
    debugPrint('================ CONNECTION LOG ================');
    debugPrint('BASE URL: $baseUrl');
    debugPrint('REQUEST URL: $requestUrl');
    debugPrint('RESPONSE STATUS: $responseStatus');
    debugPrint('ERROR MESSAGE: $errorMessage');
    debugPrint('================================================');
  }

  // Helper method to log requests, responses, and errors
  void _logRequest(String method, String url, {Map<String, String>? headers, String? body}) {
    debugPrint('================ HTTP REQUEST ================');
    debugPrint('Method: $method');
    debugPrint('URL: $url');
    if (headers != null) {
      debugPrint('Headers: $headers');
    }
    if (body != null) {
      debugPrint('Body: $body');
    }
    debugPrint('==============================================');
  }

  void _logResponse(String method, String url, int statusCode, String body) {
    debugPrint('================ HTTP RESPONSE ================');
    debugPrint('URL: $url ($method)');
    debugPrint('Status Code: $statusCode');
    debugPrint('Body: $body');
    debugPrint('===============================================');
  }

  void _logError(String method, String url, dynamic error) {
    debugPrint('================ HTTP ERROR ================');
    debugPrint('URL: $url ($method)');
    debugPrint('Error: $error');
    debugPrint('============================================');
  }

  // Silent login with seeded admin credentials
  Future<bool> _login() async {
    final activeBaseUrl = await getBaseUrl();
    final url = '$activeBaseUrl/api/auth/login';
    final requestBody = jsonEncode({
      'email': 'admin@inventory.com',
      'password': 'AdminPassword123!',
    });

    debugPrint('[ApiService] Attempting Silent Authentication POST request to: $url');
    _logRequest('POST', url, headers: {'Content-Type': 'application/json'}, body: requestBody);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(timeoutDuration);

      _logResponse('POST', url, response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'] as String?;
        _logConnection(
          baseUrl: activeBaseUrl,
          requestUrl: url,
          responseStatus: '${response.statusCode} OK',
          errorMessage: 'None',
        );
        debugPrint('[ApiService] Auth Success! Token length: ${_token?.length ?? 0}');
        return _token != null;
      }

      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: '${response.statusCode}',
        errorMessage: 'Authentication failed: ${response.body}',
      );
      return false;
    } on TimeoutException catch (e) {
      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: 'TIMEOUT',
        errorMessage: 'Silent authentication request timed out (10s): ${e.message ?? "Future not completed"}',
      );
      debugPrint('[ApiService] AUTH ERROR: Silent authentication request timed out to $url');
      return false;
    } catch (e) {
      _logError('POST', url, e);
      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: 'ERROR',
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Get authorization headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Fetch product details by barcode
  Future<Product> getProductByBarcode(String rawBarcode) async {
    final activeBaseUrl = await getBaseUrl();
    
    // Sanitize raw barcode string: trim whitespace & remove control characters
    final String cleanBarcode = rawBarcode.trim().replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F\u200B-\u200D\uFEFF]'), '');

    // 1. Silent login if token is missing
    if (_token == null) {
      debugPrint('[ApiService] Info - Token missing. Initiating pre-auth before barcode query...');
      final authenticated = await _login();
      if (!authenticated) {
        throw UnauthorizedException('Authentication failed. Please verify credentials or server status.');
      }
    }

    final encodedBarcode = Uri.encodeComponent(cleanBarcode);
    final url = '$activeBaseUrl/api/products/barcode/$encodedBarcode';

    try {
      // 2. Perform barcode lookup request
      _logRequest('GET', url, headers: _getHeaders());
      var response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(timeoutDuration);

      _logResponse('GET', url, response.statusCode, response.body);

      // Print explicit requirement debug logs
      debugPrint('================ REAL SCAN REQUEST LOG ================');
      debugPrint('SCANNED BARCODE: "$rawBarcode"');
      debugPrint('NORMALIZED BARCODE: "$cleanBarcode"');
      debugPrint('BARCODE CHAR CODES: ${cleanBarcode.codeUnits}');
      debugPrint('REQUEST URL: $url');
      debugPrint('RESPONSE STATUS: ${response.statusCode}');
      debugPrint('RESPONSE BODY: ${response.body}');
      debugPrint('========================================================');

      // 3. Retry on 401 Unauthorized once
      if (response.statusCode == 401) {
        debugPrint('[ApiService] Warn - Token expired or invalid (401), attempting silent login retry...');
        final authenticated = await _login();
        if (authenticated) {
          _logRequest('GET', url, headers: _getHeaders());
          response = await http.get(
            Uri.parse(url),
            headers: _getHeaders(),
          ).timeout(timeoutDuration);
          _logResponse('GET', url, response.statusCode, response.body);
        } else {
          throw UnauthorizedException('Session expired and re-authentication failed (401).');
        }
      }

      // Connection logging
      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: '${response.statusCode}',
        errorMessage: response.statusCode == 200 ? 'None' : 'Barcode query returned status code ${response.statusCode}',
      );

      // 4. Handle status codes
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Product.fromBackendJson(data);
      } else if (response.statusCode == 404) {
        throw ProductNotFoundException('Product not found (404) for barcode: "$cleanBarcode"');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access (401). Check user privileges.');
      } else if (response.statusCode >= 500) {
        throw ServerErrorException('Server returned an internal error (Status: ${response.statusCode}).');
      } else {
        throw ServerErrorException('Request failed with status code ${response.statusCode}.');
      }
    } on TimeoutException catch (e) {
      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: 'TIMEOUT',
        errorMessage: 'Request timed out: ${e.message ?? "Future not completed"}',
      );
      throw NetworkException('Connection timed out. Please check if your PC Spring Boot server is running and reachable at $activeBaseUrl.');
    } on SocketException catch (e) {
      _logError('GET', url, e);
      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: 'SOCKET_ERROR',
        errorMessage: e.toString(),
      );
      throw NetworkException('Network unreachable. Please check your internet connection and verify if backend is running at $activeBaseUrl.');
    } on http.ClientException catch (e) {
      _logError('GET', url, e);
      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: 'CLIENT_ERROR',
        errorMessage: e.toString(),
      );
      throw NetworkException('Network communication failed: ${e.message}');
    } catch (e) {
      _logError('GET', url, e);
      rethrow;
    }
  }

  // Update status of specific barcode record in product_barcodes table
  Future<bool> updateBarcodeStatus(String rawCode, {String status = 'INWARDED'}) async {
    final activeBaseUrl = await getBaseUrl();
    final String cleanCode = rawCode.trim().replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F\u200B-\u200D\uFEFF]'), '');

    if (_token == null) {
      await _login();
    }

    final encodedCode = Uri.encodeComponent(cleanCode);
    final url = '$activeBaseUrl/api/products/barcodes/$encodedCode/status?status=${Uri.encodeComponent(status)}';

    try {
      _logRequest('PUT', url, headers: _getHeaders());
      final response = await http.put(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(timeoutDuration);

      _logResponse('PUT', url, response.statusCode, response.body);
      debugPrint('[ApiService] Updated barcode status for "$cleanCode" to "$status" -> Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Failed to update barcode status: $e');
      return false;
    }
  }

  // Create product on backend server
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
    final activeBaseUrl = await getBaseUrl();
    
    if (_token == null) {
      final authenticated = await _login();
      if (!authenticated) {
        throw UnauthorizedException('Authentication failed before creating product.');
      }
    }

    final url = '$activeBaseUrl/api/products';
    final payload = jsonEncode({
      'name': name,
      'barcode': barcode,
      'price': price,
      'quantity': quantity,
      'description': description ?? 'Product created for barcode $barcode',
      'sku': sku ?? 'SKU-${DateTime.now().millisecondsSinceEpoch}',
      'category': category ?? 'General',
      'brand': brand ?? 'Generic',
      if (barcodes != null && barcodes.isNotEmpty) 'barcodes': barcodes,
    });

    _logRequest('POST', url, headers: _getHeaders(), body: payload);

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: payload,
      ).timeout(timeoutDuration);

      _logResponse('POST', url, response.statusCode, response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Product.fromBackendJson(data);
      } else {
        throw ServerErrorException('Failed to create product on server (Status: ${response.statusCode}).');
      }
    } catch (e) {
      _logError('POST', url, e);
      rethrow;
    }
  }

  // Fetch real-time Dashboard Statistics
  Future<DashboardStats> getDashboardStats() async {
    final activeBaseUrl = await getBaseUrl();

    if (_token == null) {
      await _login();
    }

    final url = '$activeBaseUrl/api/dashboard/stats';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return DashboardStats.fromJson(data);
      }
      return const DashboardStats();
    } catch (e) {
      debugPrint('[ApiService] Error fetching dashboard stats: $e');
      return const DashboardStats();
    }
  }

  // Record Inward inventory transaction
  Future<bool> recordInward({String? barcode, int quantity = 1, int? productId}) async {
    final activeBaseUrl = await getBaseUrl();
    if (_token == null) await _login();

    final url = '$activeBaseUrl/api/dashboard/inward';
    final payload = jsonEncode({
      if (barcode != null) 'barcode': barcode,
      if (productId != null) 'productId': productId,
      'quantity': quantity,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: payload,
      ).timeout(timeoutDuration);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Error recording inward transaction: $e');
      return false;
    }
  }

  // Record Outward inventory transaction
  Future<bool> recordOutward({String? barcode, int quantity = 1, int? productId}) async {
    final activeBaseUrl = await getBaseUrl();
    if (_token == null) await _login();

    final url = '$activeBaseUrl/api/dashboard/outward';
    final payload = jsonEncode({
      if (barcode != null) 'barcode': barcode,
      if (productId != null) 'productId': productId,
      'quantity': quantity,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: payload,
      ).timeout(timeoutDuration);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Error recording outward transaction: $e');
      return false;
    }
  }
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
