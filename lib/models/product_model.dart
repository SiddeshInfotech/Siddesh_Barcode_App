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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      currentStock: json['currentStock'] as int,
      minimumStock: json['minimumStock'] as int,
      availableStock: json['availableStock'] as int,
      imageUrl: json['imageUrl'] as String,
      supplier: json['supplier'] as String,
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
    };
  }
}
