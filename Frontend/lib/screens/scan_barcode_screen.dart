import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/barcode_scanner_service.dart';
import '../widgets/camera_view.dart';
import '../widgets/scanner_overlay.dart';
import '../widgets/laser_animation.dart';
import '../widgets/bottom_controls.dart';

class ScanBarcodeScreen extends StatefulWidget {
  const ScanBarcodeScreen({Key? key}) : super(key: key);

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [
      BarcodeFormat.code128,
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  bool _isProcessing = false;

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Barcode',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off_outlined,
                  color: const Color(0xFF3BA8FF),
                ),
                onPressed: () => _controller.toggleTorch(),
              ).animate().scale(duration: 200.ms);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF6FF), Color(0xFFCFE8FF)],
              ),
            ),
          ),
          
          // Floating Particles
          ...List.generate(15, (index) {
            final random = Random();
            return Positioned(
              left: random.nextDouble() * MediaQuery.of(context).size.width,
              top: random.nextDouble() * MediaQuery.of(context).size.height,
              child: Container(
                width: random.nextDouble() * 4 + 2,
                height: random.nextDouble() * 4 + 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF3BA8FF).withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .moveY(begin: -10, end: 10, duration: (random.nextInt(2000) + 2000).ms)
               .fade(begin: 0.2, end: 1.0, duration: (random.nextInt(1000) + 1000).ms),
            );
          }),

          // Camera View
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraView(
                            controller: _controller,
                            onDetect: _onDetect,
                          ),
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: const [
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
                              ).animate().fade(delay: 500.ms),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom Controls
                BottomControls(
                  controller: _controller,
                  onGalleryTap: () => _scannerService.pickImageFromGallery(context, _controller),
                ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}
