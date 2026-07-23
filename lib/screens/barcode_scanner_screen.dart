import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../constants/app_constants.dart';
import '../models/product_model.dart';
import '../services/product_lookup_service.dart';
import '../widgets/scanner_overlay.dart';
import 'inward_entry_screen.dart';
import 'outward_entry_screen.dart';

enum ScannerMode { inward, outward }

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({
    super.key,
    required this.mode,
  });

  final ScannerMode mode;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.qrCode,
    ],
  );

  bool _isScanning = true;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  bool _showSuccessCheck = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  Future<void> _handleBarcodeDetected(String barcode) async {
    if (!_isScanning || _isProcessing) return;

    setState(() {
      _isScanning = false;
      _isProcessing = true;
      _showSuccessCheck = true;
    });

    // Stop camera scanning
    await _scannerController.stop();

    // Haptic Feedback (Vibrate)
    HapticFeedback.mediumImpact();

    // Show success checkmark briefly then look up product
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final product = await ProductLookupService.getProductByBarcode(barcode);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _showSuccessCheck = false;
    });

    if (product != null) {
      _navigateToEntryScreen(product);
    } else {
      _showProductNotFoundBottomSheet(barcode);
    }
  }

  void _navigateToEntryScreen(Product product) {
    if (widget.mode == ScannerMode.inward) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => InwardEntryScreen(product: product),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OutwardEntryScreen(product: product),
        ),
      );
    }
  }

  void _showProductNotFoundBottomSheet(String barcode) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon Container
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.orangeIconBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Product Not Found',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 8),

              Text(
                'No product found in inventory for barcode:\n"$barcode"',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  // Scan Again Button
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _resetScanner();
                      },
                      child: const Text(
                        'Scan Again',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Create Product Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // Mock fallback creation product
                        final newMockProduct = Product(
                          id: 'PRD-NEW-${DateTime.now().millisecondsSinceEpoch}',
                          barcode: barcode,
                          name: 'New Product ($barcode)',
                          category: 'Uncategorized',
                          brand: 'Generic',
                          model: 'Standard',
                          currentStock: 0,
                          minimumStock: 5,
                          availableStock: 0,
                          imageUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=500',
                          supplier: 'Default Supplier',
                        );
                        _navigateToEntryScreen(newMockProduct);
                      },
                      child: const Text(
                        'Create Product',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ).then((_) {
      if (!mounted) return;
      if (!_isScanning && !_isProcessing) {
        _resetScanner();
      }
    });
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _isProcessing = false;
      _showSuccessCheck = false;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    const scanWindowSize = Size(270, 270);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Mobile Scanner Camera Preview
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  _handleBarcodeDetected(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 2. Custom Scanner Overlay (Blueprint grid, corners, laser, particles)
          ScannerOverlay(
            scanWindowSize: scanWindowSize,
            isScanning: _isScanning,
          ),

          // 3. Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  _AppBarSquareButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),

                  // Title Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Text(
                      widget.mode == ScannerMode.inward
                          ? 'Inward Scanner'
                          : 'Outward Scanner',
                      style: AppTextStyles.appBarPill,
                    ),
                  ),

                  // Flash Torch Toggle Button
                  _AppBarSquareButton(
                    icon: _isTorchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    iconColor: _isTorchOn ? AppColors.orange : AppColors.textPrimary,
                    onTap: _toggleTorch,
                  ),
                ],
              ),
            ),
          ),

          // 4. Quick Demo Barcode Chips (Ensures instant 100% testability on emulators/desktop)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const Text(
                    'Quick Test: ',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  _DemoBarcodeChip(
                    label: '8901234567890 (Scanner X1)',
                    onTap: () => _handleBarcodeDetected('8901234567890'),
                  ),
                  _DemoBarcodeChip(
                    label: '123456789012 (Printer 400)',
                    onTap: () => _handleBarcodeDetected('123456789012'),
                  ),
                  _DemoBarcodeChip(
                    label: 'PROD-001 (Voyager)',
                    onTap: () => _handleBarcodeDetected('PROD-001'),
                  ),
                  _DemoBarcodeChip(
                    label: 'UNKNOWN-999',
                    onTap: () => _handleBarcodeDetected('UNKNOWN-999'),
                  ),
                ],
              ),
            ),
          ),

          // 5. Success Checkmark & Loading Overlay
          if (_showSuccessCheck || _isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(
                        color: AppColors.secondary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Searching Product Database...',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Bottom Controls Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(30),
                boxShadow: AppShadows.nav,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Gallery Pick Button
                  _BottomControlButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () {
                      _handleBarcodeDetected('8901234567890');
                    },
                  ),

                  // Center Trigger Scan Button
                  GestureDetector(
                    onTap: () {
                      _handleBarcodeDetected('123456789012');
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.fab,
                        boxShadow: AppShadows.fabGlow,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),

                  // Flash Control Button
                  _BottomControlButton(
                    icon: _isTorchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    label: 'Torch',
                    onTap: _toggleTorch,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarSquareButton extends StatelessWidget {
  const _AppBarSquareButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.cardBg.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _DemoBarcodeChip extends StatelessWidget {
  const _DemoBarcodeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: AppColors.cardBg.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _BottomControlButton extends StatelessWidget {
  const _BottomControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.textPrimary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
