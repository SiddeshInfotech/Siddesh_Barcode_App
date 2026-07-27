class Product {
  final String id;
  final String barcode;
  final String name;
  final String category;
  final String brand;
  final String model;
  final int currentStock;
  final int minimumStock;
  final int availableStock;
  final String imageUrl;
  final String supplier;
  final double price;
  final String sku;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get quantity => currentStock;

  const Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.brand,
    required this.model,
    required this.currentStock,
    required this.minimumStock,
    required this.availableStock,
    required this.imageUrl,
    required this.supplier,
    this.price = 0.0,
    this.sku = '',
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      currentStock: json['currentStock'] as int? ?? 0,
      minimumStock: json['minimumStock'] as int? ?? 0,
      availableStock: json['availableStock'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      supplier: json['supplier'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      sku: json['sku'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  factory Product.fromBackendJson(Map<String, dynamic> json) {
    final barcodeVal = json['barcode'] as String? ?? '';
    final qty = json['quantity'] as int? ?? 0;
    return Product(
      id: (json['id'] ?? '').toString(),
      barcode: barcodeVal,
      name: json['name'] as String? ?? 'No Name',
      category: json['category'] as String? ?? 'General Merchandise',
      brand: json['brand'] as String? ?? 'Siddesh',
      model: json['sku'] as String? ?? 'Standard',
      currentStock: qty,
      minimumStock: 5,
      availableStock: qty,
      imageUrl: 'https://picsum.photos/seed/$barcodeVal/300/300',
      supplier: 'Siddesh Infotech',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      sku: json['sku'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'category': category,
      'brand': brand,
      'model': model,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'availableStock': availableStock,
      'imageUrl': imageUrl,
      'supplier': supplier,
      'price': price,
      'sku': sku,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
