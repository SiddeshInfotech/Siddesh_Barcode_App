import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class HeroStockCard extends StatefulWidget {
  const HeroStockCard({
    super.key,
    this.stockCount = '1246',
    this.percentage = '12.5%',
    this.onTap,
  });

  final String stockCount;
  final String percentage;
  final VoidCallback? onTap;

  @override
  State<HeroStockCard> createState() => _HeroStockCardState();
}

class _HeroStockCardState extends State<HeroStockCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatingController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadii.hero),
        child: Container(
          width: double.infinity,
          height: 168,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.hero),
            gradient: AppGradients.hero,
            boxShadow: isDark ? const [] : AppShadows.hero,
            border: Border.all(
              color: isDark ? Colors.transparent : Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.hero),
            child: Stack(
              children: [
                // Soft background light reflections
                Positioned(
                  left: -20,
                  top: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    ),
                  ),
                ),

                // Card Content Padding
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      // Left Column Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Current Stock',
                              style: AppTextStyles.heroLabel,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  widget.stockCount,
                                  style: AppTextStyles.heroValue,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Items',
                                  style: AppTextStyles.heroUnit,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Peach/Orange Trend Badge (^ 12.5%) vs last month
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.orangeBadgeBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.keyboard_arrow_up_rounded,
                                        color: AppColors.orangeBadgeText,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        widget.percentage,
                                        style: AppTextStyles.badgeText,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'vs last month',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right Column: Floating 3D Glossy Box Container & Sparkles
                      AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          final offset = math.sin(_floatingController.value * math.pi) * 6;
                          return Transform.translate(
                            offset: Offset(0, -offset),
                            child: child,
                          );
                        },
                        child: const _3DBoxIllustrationWidget(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _3DBoxIllustrationWidget extends StatelessWidget {
  const _3DBoxIllustrationWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // Glossy Translucent Glass Cube Container
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top Gloss Highlight
                Positioned(
                  top: 0,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Package Box Vector Icon
                const Icon(
                  Icons.inventory_2_rounded,
                  size: 46,
                  color: Colors.white,
                ),

                // Center Blue Light Beam line
                Positioned(
                  bottom: 18,
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF3B82F6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sparkle star at top right
          const Positioned(
            top: 2,
            right: 2,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),

          // Sparkle dot at bottom left
          Positioned(
            bottom: 4,
            left: 6,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
