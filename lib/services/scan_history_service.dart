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

  // Starts empty. Real entries are added only after a committed inward/outward.
  final List<ScanHistoryItem> _scans = [];

  final ValueNotifier<List<ScanHistoryItem>> historyNotifier = ValueNotifier([]);

  List<ScanHistoryItem> get history => historyNotifier.value;

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
