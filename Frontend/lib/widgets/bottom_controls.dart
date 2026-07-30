import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BottomControls extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final MobileScannerController controller;

  const BottomControls({
    Key? key,
    required this.onGalleryTap,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gallery Button
          _GlassButton(
            icon: Icons.image_outlined,
            onTap: onGalleryTap,
          ),
          
          // Capture Button (decorative pulse)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFF3BA8FF), width: 6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3BA8FF).withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 4,
                )
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds, curve: Curves.easeInOut),
          
          // Flash Toggle
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              return _GlassButton(
                icon: state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off_outlined,
                onTap: () => controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(icon, color: const Color(0xFF1E293B), size: 28),
        ),
      ),
    );
  }
}
