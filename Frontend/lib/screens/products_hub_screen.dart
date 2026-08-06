import 'dart:ui';

import 'package:flutter/material.dart';

class ProductsHubScreen extends StatefulWidget {
  const ProductsHubScreen({super.key});

  @override
  State<ProductsHubScreen> createState() => _ProductsHubScreenState();
}

class _ProductsHubScreenState extends State<ProductsHubScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _baseDuration = Duration(milliseconds: 1100);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _baseDuration,
  )..forward();

  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _heroSlide = Tween<Offset>(
    begin: const Offset(0, -0.14),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    ),
  );

  late final List<Animation<double>> _cardAnimations = List.generate(3, (index) {
    final start = 0.28 + (index * 0.12);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, (start + 0.34).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Stack(
            children: [
              const _BackgroundBlobs(),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.page,
                  AppSpacing.page,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductsAppBar(onBackPressed: () => Navigator.pop(context)),
                    const SizedBox(height: AppSpacing.lg),
                    SlideTransition(
                      position: _heroSlide,
                      child: HeroHeader(
                        animation: _controller,
                        productsCount: 256,
                        onAnimationRequested: _controller,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const _SectionHeader(
                      title: 'Choose an Action',
                      subtitle: 'Select what you want to do',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ProductActionCard(
                      animation: _cardAnimations[0],
                      accent: AppColors.primary,
                      gradient: AppGradients.productList,
                      icon: Icons.inventory_2_outlined,
                      title: 'Product List',
                      subtitle: 'View all products available in inventory',
                      onTap: () {
                        Navigator.push(
                          context,
                          _buildRoute(const ProductListScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ProductActionCard(
                      animation: _cardAnimations[1],
                      accent: AppColors.success,
                      gradient: AppGradients.addProduct,
                      icon: Icons.add_box_outlined,
                      title: 'Add Product',
                      subtitle: 'Create a new inventory product',
                      onTap: () {
                        Navigator.push(
                          context,
                          _buildRoute(const AddProductScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ProductActionCard(
                      animation: _cardAnimations[2],
                      accent: AppColors.purple,
                      gradient: AppGradients.productDetails,
                      icon: Icons.qr_code_scanner_outlined,
                      title: 'Product Details',
                      subtitle:
                          'Search or scan a product to view complete information',
                      onTap: () {
                        Navigator.push(
                          context,
                          _buildRoute(const ProductSearchScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const TipCard(
                      title: 'Quick Tip',
                      text:
                          'Use the search icon or Product Details option to open a product instantly.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductActionCard extends StatefulWidget {
  const ProductActionCard({
    super.key,
    required this.animation,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accent,
  });

  final Animation<double> animation;
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  @override
  State<ProductActionCard> createState() => _ProductActionCardState();
}

class _ProductActionCardState extends State<ProductActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final animationValue = widget.animation.value;
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - animationValue)),
            child: Transform.scale(
              scale: 0.98 + (0.02 * animationValue) * (_pressed ? 0.985 : 1),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          child: Container(
            height: 124,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: AppShadows.soft,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    border: Border.all(color: Colors.white.withOpacity(0.28)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -18,
                        top: -18,
                        child: _FloatingOrb(color: Colors.white.withOpacity(0.14), size: 84),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        bottom: 16,
                        right: 16,
                        child: Row(
                          children: [
                            _ActionIcon(icon: widget.icon, accent: widget.accent),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: AppTextStyles.actionTitle,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.actionSubtitle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.animation,
    required this.productsCount,
    required this.onAnimationRequested,
  });

  final Animation<double> animation;
  final int productsCount;
  final AnimationController onAnimationRequested;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'products-hub-hero',
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.hero),
          boxShadow: AppShadows.hero,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.hero),
          child: Stack(
            children: [
              const _HeroShimmerLayer(),
              DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.hero),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      const _PackageIllustration(),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Product Management',
                              style: AppTextStyles.heroTitle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage all inventory products',
                              style: AppTextStyles.heroSubtitle,
                            ),
                            const SizedBox(height: 12),
                            _ProductPill(count: productsCount),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: onAnimationRequested,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.16,
                        child: Transform.translate(
                          offset: Offset(
                            28 * (animation.value - 0.5),
                            8 * (1 - animation.value),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: const _FloatingParticles(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.tipBackground,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tipAccent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.tipAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.tipTitle),
                const SizedBox(height: 6),
                Text(text, style: AppTextStyles.tipText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsAppBar extends StatelessWidget {
  const _ProductsAppBar({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AppBarButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBackPressed,
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Products',
              style: AppTextStyles.appBarTitle,
            ),
          ),
        ),
        _AppBarButton(
          icon: Icons.search_rounded,
          onTap: () {
            Navigator.of(context).push(_buildRoute(const ProductSearchScreen()));
          },
        ),
      ],
    );
  }
}

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.72),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTextStyles.sectionSubtitle),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: accent, size: 30),
    );
  }
}

class _ProductPill extends StatelessWidget {
  const _ProductPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        '$count Products',
        style: AppTextStyles.productCount,
      ),
    );
  }
}

class _PackageIllustration extends StatelessWidget {
  const _PackageIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
          ),
          const Icon(Icons.inventory_2_rounded, size: 46, color: Colors.white),
          Positioned(
            top: 2,
            right: 0,
            child: _FloatingOrb(color: Colors.white.withOpacity(0.35), size: 14),
          ),
          Positioned(
            bottom: 0,
            left: 2,
            child: _FloatingOrb(color: Colors.white.withOpacity(0.18), size: 10),
          ),
        ],
      ),
    );
  }
}

class _FloatingParticles extends StatelessWidget {
  const _FloatingParticles();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(left: 36, top: 24, child: _Particle(size: 8)),
        Positioned(left: 92, top: 16, child: _Particle(size: 6)),
        Positioned(right: 108, top: 20, child: _Particle(size: 10)),
        Positioned(right: 42, bottom: 24, child: _Particle(size: 8)),
        Positioned(right: 82, bottom: 44, child: _Particle(size: 5)),
      ],
    );
  }
}

class _Particle extends StatelessWidget {
  const _Particle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: _Blob(
              size: 220,
              color: AppColors.primary.withOpacity(0.16),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -100,
            child: _Blob(
              size: 260,
              color: AppColors.secondary.withOpacity(0.14),
            ),
          ),
          Positioned(
            bottom: -120,
            right: 18,
            child: _Blob(
              size: 180,
              color: AppColors.purple.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  const _FloatingOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HeroShimmerLayer extends StatefulWidget {
  const _HeroShimmerLayer();

  @override
  State<_HeroShimmerLayer> createState() => _HeroShimmerLayerState();
}

class _HeroShimmerLayerState extends State<_HeroShimmerLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(120 * (_controller.value - 0.5), 0),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -0.6),
                end: Alignment(1, 0.6),
                colors: [
                  Color.fromRGBO(255, 255, 255, 0.02),
                  Color.fromRGBO(255, 255, 255, 0.24),
                  Color.fromRGBO(255, 255, 255, 0.02),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),
        );
      },
    );
  }
}

Route<void> _buildRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: AppDurations.route,
    reverseTransitionDuration: AppDurations.route,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0.05),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Product List',
      subtitle: 'Product list screen placeholder',
      icon: Icons.inventory_2_outlined,
      heroTag: 'products-hub-hero',
    );
  }
}

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Add Product',
      subtitle: 'Add product screen placeholder',
      icon: Icons.add_box_outlined,
      heroTag: 'products-hub-hero',
    );
  }
}

class ProductSearchScreen extends StatelessWidget {
  const ProductSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      title: 'Product Details',
      subtitle: 'Search or scan screen placeholder',
      icon: Icons.qr_code_scanner_outlined,
      heroTag: 'products-hub-hero',
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.heroTag,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Hero(
              tag: heroTag,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppGradients.hero,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(icon, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(title, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sectionSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class AppColors {
  static const Color background = Color(0xFFF7FBFF);
  static const Color primary = Color(0xFF3BA8FF);
  static const Color secondary = Color(0xFF6CCBFF);
  static const Color success = Color(0xFF22C55E);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color tipBackground = Color(0xFFFFF8D8);
  static const Color tipAccent = Color(0xFFF4B400);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 20;
}

abstract final class AppRadii {
  static const double card = 24;
  static const double hero = 28;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration route = Duration(milliseconds: 320);
}

abstract final class AppShadows {
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF1E293B).withOpacity(0.08),
      blurRadius: 26,
      offset: const Offset(0, 14),
    ),
  ];

  static final List<BoxShadow> hero = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.18),
      blurRadius: 32,
      offset: const Offset(0, 18),
    ),
  ];
}

abstract final class AppGradients {
  static const Gradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3BA8FF), Color(0xFF6CCBFF)],
  );

  static const Gradient productList = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4AA9FF), Color(0xFF2F8DFF)],
  );

  static const Gradient addProduct = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF22C55E), Color(0xFF55D983)],
  );

  static const Gradient productDetails = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFB58CFF)],
  );
}

abstract final class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle heroTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.05,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle productCount = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle actionTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle actionSubtitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.35,
  );

  static const TextStyle tipTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle tipText = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.45,
  );
}