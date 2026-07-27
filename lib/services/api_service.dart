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
  
  // Timeout for requests
  final Duration timeoutDuration = const Duration(seconds: 30);

  // Helper method to automatically select correct backend URL based on platform
  Future<String> getBaseUrl() async {
    if (_resolvedBaseUrl != null) {
      return _resolvedBaseUrl!;
    }

    if (kIsWeb) {
      _resolvedBaseUrl = 'http://localhost:8080';
      return _resolvedBaseUrl!;
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _resolvedBaseUrl = 'http://localhost:8080';
      return _resolvedBaseUrl!;
    }

    if (Platform.isAndroid) {
      try {
        // Try connecting to Android emulator loopback gateway
        await http.get(Uri.parse('http://10.0.2.2:8080/api/test/db-info'))
            .timeout(const Duration(milliseconds: 600));
        _resolvedBaseUrl = 'http://10.0.2.2:8080';
        return _resolvedBaseUrl!;
      } catch (_) {}
    }

    // Try target IP 192.168.1.103 (User requested IP)
    try {
      await http.get(Uri.parse('http://192.168.1.103:8080/api/test/db-info'))
          .timeout(const Duration(milliseconds: 600));
      _resolvedBaseUrl = 'http://192.168.1.103:8080';
      return _resolvedBaseUrl!;
    } catch (_) {}

    // Try target IP 192.168.1.105 (Verified active Wi-Fi IP fallback)
    try {
      await http.get(Uri.parse('http://192.168.1.105:8080/api/test/db-info'))
          .timeout(const Duration(milliseconds: 600));
      _resolvedBaseUrl = 'http://192.168.1.105:8080';
      return _resolvedBaseUrl!;
    } catch (_) {}

    // Default fallback
    _resolvedBaseUrl = 'http://192.168.1.103:8080';
    return _resolvedBaseUrl!;
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
        errorMessage: 'Silent authentication request timed out: ${e.message ?? "Future not completed"}',
      );
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
  Future<Product> getProductByBarcode(String barcode) async {
    final activeBaseUrl = await getBaseUrl();
    
    // 1. Silent login if token is missing
    if (_token == null) {
      debugPrint('API Info - Stored token is missing. Initiating silent login...');
      final authenticated = await _login();
      if (!authenticated) {
        throw UnauthorizedException('Authentication failed. Please verify credentials or server status.');
      }
    }

    final url = '$activeBaseUrl/api/products/barcode/$barcode';

    try {
      // 2. Perform barcode lookup request
      _logRequest('GET', url, headers: _getHeaders());
      var response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(timeoutDuration);

      _logResponse('GET', url, response.statusCode, response.body);

      // 3. Retry on 401 Unauthorized once
      if (response.statusCode == 401) {
        debugPrint('API Warn - Token expired or invalid, attempting silent login retry...');
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

      // Connection logging matching required format
      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: '${response.statusCode}',
        errorMessage: response.statusCode == 200 ? 'None' : 'Barcode query returned status code ${response.statusCode}',
      );

      // Print debug logs
      debugPrint('SCANNED BARCODE: $barcode');
      debugPrint('GET /api/products/barcode/$barcode');
      debugPrint('HTTP STATUS: ${response.statusCode}');
      debugPrint('RESPONSE BODY: ${response.body}');

      // 4. Handle status codes
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Product.fromBackendJson(data);
      } else if (response.statusCode == 404) {
        throw ProductNotFoundException('Product not found (404) for barcode: $barcode');
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
      throw NetworkException('Connection timed out. Please check if your PC server is running and reachable at $activeBaseUrl.');
    } on SocketException catch (e) {
      _logError('GET', url, e);
      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: 'SOCKET_ERROR',
        errorMessage: e.toString(),
      );
      throw NetworkException('Network unreachable. Please check your internet connection and verify if the backend is running at $activeBaseUrl.');
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
      _logConnection(
        baseUrl: activeBaseUrl,
        requestUrl: url,
        responseStatus: 'UNEXPECTED_ERROR',
        errorMessage: e.toString(),
      );
      if (e is ProductNotFoundException || e is UnauthorizedException || e is ServerErrorException || e is NetworkException) {
        rethrow;
      }
      throw ServerErrorException('Unexpected error: $e');
    }
  }
}
