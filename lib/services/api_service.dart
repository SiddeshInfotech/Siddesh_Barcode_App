import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Product {
  final int id;
  final String name;
  final String description;
  final String barcode;
  final double price;
  final int quantity;
  final String sku;
  final String category;
  final String brand;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.barcode,
    required this.price,
    required this.quantity,
    required this.sku,
    required this.category,
    required this.brand,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Not Available',
      description: json['description'] as String? ?? 'Not Available',
      barcode: json['barcode'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 0,
      sku: json['sku'] as String? ?? 'Not Available',
      category: json['category'] as String? ?? 'Not Available',
      brand: json['brand'] as String? ?? 'Not Available',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}

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
  
  // Base URL pointing directly to the PC local network IP for physical device debugging
  final String baseUrl = 'http://192.168.1.103:8080';
  
  // Timeout for requests - increased to 30 seconds
  final Duration timeoutDuration = const Duration(seconds: 30);

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
    final url = '$baseUrl/api/auth/login';
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
        return _token != null;
      }
      return false;
    } catch (e) {
      _logError('POST', url, e);
      debugPrint('API Error - Silent Authentication failed: $e');
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
    // 1. Silent login if token is missing
    if (_token == null) {
      debugPrint('API Info - Stored token is missing. Initiating silent login...');
      final authenticated = await _login();
      if (!authenticated) {
        throw UnauthorizedException('Authentication failed. Please verify credentials or server status.');
      }
    }

    final url = '$baseUrl/api/products/barcode/$barcode';

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

      // 4. Handle status codes
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Product.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ProductNotFoundException('Product not found (404) for barcode: $barcode');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized access (401). Check user privileges.');
      } else if (response.statusCode >= 500) {
        throw ServerErrorException('Server returned an internal error (Status: ${response.statusCode}).');
      } else {
        throw ServerErrorException('Request failed with status code ${response.statusCode}.');
      }
    } on SocketException catch (e) {
      _logError('GET', url, e);
      throw NetworkException('Network unreachable. Please check your internet connection and verify if the backend is running at $baseUrl.');
    } on http.ClientException catch (e) {
      _logError('GET', url, e);
      throw NetworkException('Network communication failed: ${e.message}');
    } catch (e) {
      _logError('GET', url, e);
      if (e is ProductNotFoundException || e is UnauthorizedException || e is ServerErrorException || e is NetworkException) {
        rethrow;
      }
      throw ServerErrorException('Unexpected error: $e');
    }
  }
}
