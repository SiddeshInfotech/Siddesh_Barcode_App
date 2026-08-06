import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../services/user_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  late final AnimationController _floatingController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  late final Animation<double> _fadeAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    ),
  );

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 0.88,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    ),
  );

  late final Animation<double> _progressAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.95, curve: Curves.easeInOut),
    ),
  );

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _mainController.forward();

    // Always navigate to LoginScreen after splash animation
    _navigationTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _mainController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: Stack(
        children: [
          // Ambient Dark Space Background with Glowing Arcs & Stars
          const Positioned.fill(
            child: _DarkSplashBackground(),
          ),

          // Main Center Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 4),

                            // Floating 3D Glowing Glass Cube Box (Exact Image Match)
                            AnimatedBuilder(
                              animation: _floatingController,
                              builder: (context, child) {
                                final dy = math.sin(
                                        _floatingController.value * math.pi) *
                                    6;
                                return Transform.translate(
                                  offset: Offset(0, -dy),
                                  child: child,
                                );
                              },
                              child: const _FuturisticGlassCubeWidget(),
                            ),

                            const SizedBox(height: 48),

                            // Title: Inventory
                            const Text(
                              'Inventory',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Subtitle: Management System
                            const Text(
                              'Management System',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                                letterSpacing: -0.2,
                              ),
                            ),

                            const Spacer(flex: 4),

                            // Subtitle: Smart Inventory, Smarter Business
                            const Text(
                              'Smart Inventory, Smarter Business',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.1,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Sleek Capsule Loading Indicator (Exact Image Match)
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 140,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Stack(
                                    children: [
                                      FractionallySizedBox(
                                        widthFactor: _progressAnimation.value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white
                                                    .withValues(alpha: 0.8),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Futuristic 3D Glass Cube Box Widget (Matches User Image)
class _FuturisticGlassCubeWidget extends StatelessWidget {
  const _FuturisticGlassCubeWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Soft Ambient Blue Light Core Behind Cube
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
                  blurRadius: 50,
                  spreadRadius: 12,
                ),
                BoxShadow(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // 2. Main 3D Glass Box Body
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top Metallic Reflection Beam
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                    ),
                  ),
                ),

                // Center Box Content Layout (Top Lid Square + Front Slot)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top Lid Glowing Square Ring
                      Container(
                        width: 44,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF60A5FA),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Front Face USB/Handle Recess Slot
                      Container(
                        width: 40,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF070A12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Specular Light Border Highlights on Corners
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.6),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark Space Background Painter with Light Arcs & Star Particles
class _DarkSplashBackground extends StatelessWidget {
  const _DarkSplashBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DarkSpacePainter(),
      child: Stack(
        children: const [
          // Top Right Star Sparkle
          Positioned(
            top: 220,
            right: 80,
            child: Icon(
              CupertinoIcons.sparkles,
              size: 14,
              color: Color(0x9993C5FD),
            ),
          ),
          // Center Left Star Particle
          Positioned(
            top: 420,
            left: 50,
            child: Icon(
              CupertinoIcons.sparkles,
              size: 10,
              color: Color(0x6660A5FA),
            ),
          ),
          // Bottom Light Flare Particle
          Positioned(
            bottom: 240,
            left: 120,
            child: Icon(
              CupertinoIcons.sparkles,
              size: 16,
              color: Color(0xAA93C5FD),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter drawing the sweeping glowing light arcs (Matching Image)
class _DarkSpacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep Dark Background Gradient
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF04060B),
          Color(0xFF080D18),
          Color(0xFF04060A),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Top Right Sweeping Glowing Light Arc
    final topArcPath = Path();
    topArcPath.moveTo(size.width * 0.3, 0);
    topArcPath.cubicTo(
      size.width * 0.8,
      size.height * 0.15,
      size.width * 0.95,
      size.height * 0.35,
      size.width * 0.1,
      size.height * 0.55,
    );

    final topArcGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(topArcPath, topArcGlowPaint);

    final topArcCorePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawPath(topArcPath, topArcCorePaint);

    // 3. Bottom Sweeping Arc Curve
    final bottomArcPath = Path();
    bottomArcPath.moveTo(0, size.height * 0.92);
    bottomArcPath.cubicTo(
      size.width * 0.3,
      size.height * 0.82,
      size.width * 0.7,
      size.height * 0.72,
      size.width,
      size.height * 0.88,
    );

    final bottomArcGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(bottomArcPath, bottomArcGlowPaint);

    final bottomArcCorePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawPath(bottomArcPath, bottomArcCorePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
