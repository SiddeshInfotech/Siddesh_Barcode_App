import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/barcode_scanner_service.dart';
import '../widgets/bottom_controls.dart';
import '../widgets/camera_view.dart';
import '../widgets/laser_animation.dart';
import '../widgets/scanner_overlay.dart';

class EntryScannerScreen extends StatefulWidget {
  const EntryScannerScreen({super.key, required this.entryType});

  final String entryType;

  @override
  State<EntryScannerScreen> createState() => _EntryScannerScreenState();
}

class _EntryScannerScreenState extends State<EntryScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final BarcodeScannerService _scannerService = BarcodeScannerService();

  bool _isProcessing = false;

  String get _title => '${widget.entryType} Entry Scanner';

  String get _helpText => widget.entryType.toLowerCase() == 'inward'
      ? 'Scan item to add stock into inventory'
      : 'Scan item to move stock out of inventory';

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _isProcessing = true;
      _controller.stop();
      _scannerService.processBarcode(context, barcodes.first.rawValue!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        centerTitle: true,
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off_outlined,
                  color: const Color(0xFF3BA8FF),
                ),
                onPressed: () => _controller.toggleTorch(),
              ).animate().scale(duration: 200.ms);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                _helpText,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraView(
                        controller: _controller,
                        onDetect: _onDetect,
                      ),
                      const Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ScannerOverlay(),
                            LaserAnimation(size: 260),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: const Text(
                            'Align barcode within the frame',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            BottomControls(
              controller: _controller,
              onGalleryTap: () =>
                  _scannerService.pickImageFromGallery(context, _controller),
            ).animate().slideY(begin: 1, duration: 300.ms, curve: Curves.easeOut),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
