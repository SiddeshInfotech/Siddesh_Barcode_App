import '../models/product_model.dart';

class ProductLookupService {
  static final List<Product> _mockDatabase = [
    const Product(
      id: 'PRD-890123',
      barcode: '8901234567890',
      name: 'Wireless Industrial Barcode Scanner X1',
      category: 'Electronics & Scanners',
      brand: 'ZebraTech',
      model: 'ZT-9000-HD',
      currentStock: 142,
      minimumStock: 25,
      availableStock: 130,
      imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500',
      supplier: 'Apex Tech Solutions Ltd.',
    ),
    const Product(
      id: 'PRD-123456',
      barcode: '123456789012',
      name: 'Heavy Duty Thermal Label Printer 400',
      category: 'Printers & Supplies',
      brand: 'PrintPro',
      model: 'PP-400T',
      currentStock: 86,
      minimumStock: 15,
      availableStock: 80,
      imageUrl: 'https://images.unsplash.com/photo-1589492477829-5e65395b66cc?w=500',
      supplier: 'OmniLogistics Hardware Inc.',
    ),
    const Product(
      id: 'PRD-001',
      barcode: 'PROD-001',
      name: 'High Performance Handheld Scanner',
      category: 'Barcode Scanners',
      brand: 'Honeywell',
      model: 'Voyager 1200g',
      currentStock: 54,
      minimumStock: 10,
      availableStock: 50,
      imageUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=500',
      supplier: 'Global Tech Distributors',
    ),
    const Product(
      id: 'PRD-002',
      barcode: 'PROD-002',
      name: 'Industrial QR & Barcode Reader Pro',
      category: 'Barcode Scanners',
      brand: 'Datalogic',
      model: 'Matrix 320',
      currentStock: 38,
      minimumStock: 8,
      availableStock: 35,
      imageUrl: 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=500',
      supplier: 'Precision Components Corp',
    ),
    const Product(
      id: 'PRD-BAR123',
      barcode: 'BARCODE123',
      name: 'Premium Warehouse Shipping Labels (Roll of 1000)',
      category: 'Packaging Supplies',
      brand: 'PackShield',
      model: 'PS-100x150',
      currentStock: 310,
      minimumStock: 50,
      availableStock: 295,
      imageUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=500',
      supplier: 'Siddesh Packaging Solutions',
    ),
  ];

  /// Simulates network product lookup by barcode.
  static Future<Product?> getProductByBarcode(String barcode) async {
    // Artificial network delay for realistic SaaS loading behavior
    await Future.delayed(const Duration(milliseconds: 600));

    final normalized = barcode.trim().toUpperCase();
    try {
      return _mockDatabase.firstWhere(
        (p) => p.barcode.toUpperCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns all available products in mock database.
  static List<Product> getAllProducts() {
    return List.unmodifiable(_mockDatabase);
  }
}
