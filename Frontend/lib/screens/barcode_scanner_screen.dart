import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
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

  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isScanning = true;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  bool _showSuccessCheck = false;

  @override
  void initState() {
    super.initState();
    _preAuthenticateBackend();
  }

  Future<void> _preAuthenticateBackend() async {
    try {
      final baseUrl = await _apiService.getBaseUrl();
      debugPrint('================ SCANNER INIT ================');
      debugPrint('PRE-AUTH BACKEND BASE URL: $baseUrl');
      debugPrint('==============================================');
      final success = await _apiService.ensureAuthenticated();
      if (mounted) {
        if (!success) {
          debugPrint('[BarcodeScannerScreen] Pre-auth warning: backend at $baseUrl unreachable or credentials invalid.');
        } else {
          debugPrint('[BarcodeScannerScreen] Pre-auth complete! Auth token acquired prior to scanner detection.');
        }
      }
    } catch (e) {
      debugPrint('[BarcodeScannerScreen] Pre-auth check skipped: $e');
    }
  }

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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final capture = await _scannerController.analyzeImage(image.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final rawValue = capture.barcodes.first.rawValue;
          if (rawValue != null && rawValue.isNotEmpty) {
            _handleBarcodeDetected(rawValue);
            return;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No barcode found in image')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
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

    Product? product;

    // 1. Try querying Spring Boot backend first
    try {
      product = await _apiService.getProductByBarcode(barcode);
    } catch (e) {
      debugPrint('[BarcodeScannerScreen] Backend lookup failed or timed out ($e). Falling back to local ProductLookupService...');
    }

    // 2. Fallback to mock product database if backend query fails or product missing
    if (product == null) {
      product = await ProductLookupService.getProductByBarcode(barcode);
    }

    // 3. Fallback to auto-generated product model so inward entry form opens seamlessly
    if (product == null) {
      final shortId = barcode.length > 6 ? barcode.substring(barcode.length - 6) : barcode;
      product = Product(
        id: 'PRD-$shortId',
        barcode: barcode,
        name: 'Scanned Item ($barcode)',
        category: 'General Inventory',
        brand: 'Siddesh Tech',
        model: 'STD-2026',
        currentStock: 50,
        minimumStock: 10,
        availableStock: 45,
        imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500',
        supplier: 'Siddesh Infotech Supplier',
      );
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _showSuccessCheck = false;
    });

    _navigateToEntryScreen(product, barcode);
  }


  void _navigateToEntryScreen(Product product, String scannedBarcode) {
    if (widget.mode == ScannerMode.inward) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => InwardEntryScreen(product: product, scannedBarcode: scannedBarcode),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OutwardEntryScreen(product: product, scannedBarcode: scannedBarcode),
        ),
      );
    }
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
                    onTap: _pickImageFromGallery,
                  ),

                  // Center Trigger Scan Button
                  GestureDetector(
                    onTap: _resetScanner,
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
