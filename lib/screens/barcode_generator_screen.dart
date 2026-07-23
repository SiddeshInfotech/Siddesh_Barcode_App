<<<<<<< HEAD:lib/screens/barcode_generator_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class BarcodeGeneratorScreen extends StatelessWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Barcode Generator', style: AppTextStyles.sectionTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.purpleIconBg,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.purple,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Barcode Generator',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate and print custom product barcodes.',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardSubtitle,
              ),
            ],
          ),
        ),
=======
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class BarcodeGeneratorScreen extends StatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  State<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  static const String _barcodeValue = 'ST00012345';

  final GlobalKey _previewKey = GlobalKey();
  final List<Color> _palette = const [
    Color(0xFF2563EB),
    Color(0xFF38BDF8),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFFF43F5E),
    Color(0xFFA855F7),
    Color(0xFF111827),
  ];

  int _selectedColorIndex = 0;
  bool _isSaving = false;

  Color get _selectedColor => _palette[_selectedColorIndex];

  Future<void> _saveBarcodeImage({required String actionLabel}) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Barcode preview is not ready');
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to render barcode image');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = Directory.systemTemp;
      final file = File('${directory.path}/barcode_${_barcodeValue}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$actionLabel saved to ${file.path}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save barcode: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showPrintPreview() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Print Preview',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                AspectRatio(
                  aspectRatio: 1.35,
                  child: _BarcodeCard(
                    barcodeValue: _barcodeValue,
                    accentColor: _selectedColor,
                    showLargePrinter: false,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _saveBarcodeImage(actionLabel: 'Print label');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Print'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().scale(duration: 220.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          'Generate Barcode',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF7FBFF), Color(0xFFEAF4FF)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            top: 80,
            child: _backgroundBlob(const Color(0xFFDBEAFE)),
          ),
          Positioned(
            right: -20,
            bottom: 90,
            child: _backgroundBlob(const Color(0xFFC7F9E8)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Barcode',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    key: _previewKey,
                    child: _BarcodeCard(
                      barcodeValue: _barcodeValue,
                      accentColor: _selectedColor,
                      showLargePrinter: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Choose Color',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_palette.length, (index) {
                      final color = _palette[index];
                      final selected = index == _selectedColorIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorIndex = index),
                        child: AnimatedScale(
                          scale: selected ? 1.08 : 1,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.65),
                                width: selected ? 3 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: selected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  _ActionButton(
                    icon: Icons.download_rounded,
                    label: 'Download',
                    gradient: LinearGradient(
                      colors: [_selectedColor, _selectedColor.withValues(alpha: 0.78)],
                    ),
                    onPressed: () => _saveBarcodeImage(actionLabel: 'Barcode'),
                  ),
                  const SizedBox(height: 14),
                  _ActionButton(
                    icon: Icons.print_rounded,
                    label: 'Print Label',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    onPressed: _showPrintPreview,
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.96, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEEF7FF), Color(0xFFDCEEFF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        border: Border.all(color: const Color(0xFFE0ECFA)),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            bottom: 18,
                            child: Container(
                              width: 180,
                              height: 76,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 38,
                            child: Container(
                              width: 130,
                              height: 66,
                              decoration: BoxDecoration(
                                color: const Color(0xFF334155),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.print_rounded, color: Colors.white, size: 42),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: 110,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 32,
                            bottom: 24,
                            child: Container(
                              width: 48,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF93C5FD),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.15, end: 0, duration: 450.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundBlob(Color color) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        shape: BoxShape.circle,
>>>>>>> origin/backend-mahim:Frontend/lib/screens/barcode_generator_screen.dart
      ),
    );
  }
}
<<<<<<< HEAD:lib/screens/barcode_generator_screen.dart
=======

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0, duration: 350.ms);
  }
}

class _BarcodeCard extends StatelessWidget {
  const _BarcodeCard({
    required this.barcodeValue,
    required this.accentColor,
    required this.showLargePrinter,
  });

  final String barcodeValue;
  final Color accentColor;
  final bool showLargePrinter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your Barcode',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7C8AA5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            barcodeValue,
            style: GoogleFonts.poppins(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 118,
            child: CustomPaint(
              painter: _Code128Painter(barcodeValue: barcodeValue),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'CODE128',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: 1.0,
            ),
          ),
          if (showLargePrinter) ...[
            const SizedBox(height: 10),
            Text(
              'Generate, download, and preview printable labels.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0, duration: 450.ms);
  }
}

class _Code128Painter extends CustomPainter {
  _Code128Painter({required this.barcodeValue});

  final String barcodeValue;

  static const List<String> _patterns = [
    '212222', '222122', '222221', '121223', '121322', '131222', '122213',
    '122312', '132212', '221213', '221312', '231212', '112232', '122132',
    '122231', '113222', '123122', '123221', '223211', '221132', '221231',
    '213212', '223112', '312131', '311222', '321122', '321221', '312212',
    '322112', '322211', '212123', '212321', '232121', '111323', '131123',
    '131321', '112313', '132113', '132311', '211313', '231113', '231311',
    '112133', '112331', '132131', '113123', '113321', '133121', '313121',
    '211331', '231131', '213113', '213311', '213131', '311123', '311321',
    '331121', '312113', '312311', '332111', '314111', '221411', '431111',
    '111224', '111422', '121124', '121421', '141122', '141221', '112214',
    '112412', '122114', '122411', '142112', '142211', '241211', '221114',
    '413111', '241112', '134111', '111242', '121142', '121241', '114212',
    '124112', '124211', '411212', '421112', '421211', '212141', '214121',
    '412121', '111143', '111341', '131141', '114113', '114311', '411113',
    '411311', '113141', '114131', '311141', '411131', '211412', '211214',
    '211232', '2331112',
  ];

  List<int> _encodeToValues(String value) {
    final values = <int>[104];
    for (final unit in value.codeUnits) {
      if (unit < 32 || unit > 126) {
        throw ArgumentError('Code 128 B supports ASCII 32-126 only');
      }
      values.add(unit - 32);
    }

    var checksum = values.first;
    for (var index = 1; index < values.length; index++) {
      checksum += values[index] * index;
    }
    values.add(checksum % 103);
    values.add(106);
    return values;
  }

  List<int> _toModules(List<int> codeValues) {
    final modules = <int>[];
    for (final codeValue in codeValues) {
      final pattern = _patterns[codeValue];
      for (final digit in pattern.codeUnits) {
        modules.add(digit - 48);
      }
    }
    return modules;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0F172A);
    final modules = _toModules(_encodeToValues(barcodeValue));
    const quietZoneModules = 10;
    final totalModules = quietZoneModules * 2 + modules.fold<int>(0, (sum, module) => sum + module);
    final moduleWidth = size.width / totalModules;
    final barHeight = size.height * 0.9;
    final topOffset = (size.height - barHeight) / 2;

    var cursor = quietZoneModules * moduleWidth;
    var isBar = true;
    for (final module in modules) {
      final width = module * moduleWidth;
      if (isBar) {
        canvas.drawRect(
          Rect.fromLTWH(cursor, topOffset, width, barHeight),
          paint,
        );
      }
      cursor += width;
      isBar = !isBar;
    }
  }

  @override
  bool shouldRepaint(covariant _Code128Painter oldDelegate) {
    return oldDelegate.barcodeValue != barcodeValue;
  }
}
>>>>>>> origin/backend-mahim:Frontend/lib/screens/barcode_generator_screen.dart
