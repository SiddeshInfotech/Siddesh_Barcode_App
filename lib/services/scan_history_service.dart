import 'package:flutter/foundation.dart';

class ScanHistoryItem {
  final String id;
  final String barcode;
  final String productName;
  final String category;
  final String entryType; // 'Inward', 'Outward', or 'Scan'
  final DateTime timestamp;
  final int quantity;

  ScanHistoryItem({
    required this.id,
    required this.barcode,
    required this.productName,
    required this.category,
    required this.entryType,
    required this.timestamp,
    this.quantity = 1,
  });
}

class ScanHistoryService {
  static final ScanHistoryService _instance = ScanHistoryService._internal();
  factory ScanHistoryService() => _instance;
  ScanHistoryService._internal();

  final List<ScanHistoryItem> _scans = [
    ScanHistoryItem(
      id: 'scan_001',
      barcode: '8901030678901',
      productName: 'Ergonomic Wireless Mouse',
      category: 'Electronics',
      entryType: 'Inward',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      quantity: 12,
    ),
    ScanHistoryItem(
      id: 'scan_002',
      barcode: '8901234567890',
      productName: 'Mechanical Gaming Keyboard',
      category: 'Peripherals',
      entryType: 'Outward',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      quantity: 5,
    ),
    ScanHistoryItem(
      id: 'scan_003',
      barcode: '8909876543210',
      productName: 'UltraWide Curved Monitor 34"',
      category: 'Displays',
      entryType: 'Inward',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      quantity: 8,
    ),
    ScanHistoryItem(
      id: 'scan_004',
      barcode: '8901122334455',
      productName: 'USB-C Docking Station',
      category: 'Accessories',
      entryType: 'Outward',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      quantity: 2,
    ),
    ScanHistoryItem(
      id: 'scan_005',
      barcode: '8905544332211',
      productName: 'Noise Cancelling Headphones',
      category: 'Audio',
      entryType: 'Inward',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      quantity: 15,
    ),
  ];

  final ValueNotifier<List<ScanHistoryItem>> historyNotifier = ValueNotifier([]);

  List<ScanHistoryItem> get history {
    if (historyNotifier.value.isEmpty) {
      historyNotifier.value = List.from(_scans);
    }
    return historyNotifier.value;
  }

  void addScan({
    required String barcode,
    required String productName,
    required String category,
    required String entryType,
    int quantity = 1,
  }) {
    final newItem = ScanHistoryItem(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      barcode: barcode,
      productName: productName,
      category: category,
      entryType: entryType,
      timestamp: DateTime.now(),
      quantity: quantity,
    );
    _scans.insert(0, newItem);
    historyNotifier.value = List.from(_scans);
  }

  void clearHistory() {
    _scans.clear();
    historyNotifier.value = [];
  }
}
