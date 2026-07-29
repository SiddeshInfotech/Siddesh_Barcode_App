import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class HeroStockCard extends StatefulWidget {
  const HeroStockCard({
    super.key,
    this.stockCount = '1246',
    this.percentage = '+ 12.5%',
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadii.hero),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.hero),
            gradient: AppGradients.hero,
            boxShadow: AppShadows.hero,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.hero),
            child: Stack(
              children: [
                // Soft background glowing circles
                Positioned(
                  right: -20,
                  top: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
                Positioned(
                  right: 40,
                  bottom: -40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),

                // Card Content Padding
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
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
                            const SizedBox(height: 12),

                            // Green Trend Badge (+ 12.5%)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.trending_up_rounded,
                                    color: AppColors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.percentage,
                                    style: AppTextStyles.badgeText,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Column: Floating 3D Package Illustration & Sparkles
                      AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          final offset = math.sin(_floatingController.value * math.pi) * 8;
                          return Transform.translate(
                            offset: Offset(0, -offset),
                            child: child,
                          );
                        },
                        child: const _PackageIllustrationWidget(),
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

class _PackageIllustrationWidget extends StatelessWidget {
  const _PackageIllustrationWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Semi-transparent rounded background card for package
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),

          // Top Right Sparkle Star
          Positioned(
            top: 4,
            right: 4,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          // Bottom Left Small Sparkle Dot
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
