import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../services/app_settings_service.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/floating_bottom_navigation.dart';
import '../widgets/hero_stock_card.dart';
import '../widgets/quick_access_card.dart';
import '../widgets/statistic_card.dart';
import 'barcode_scanner_screen.dart';
import 'products_hub_screen.dart';
import 'scan_history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  late final PageController _pageController = PageController();

  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _heroSlideDown = Tween<Offset>(
    begin: const Offset(0, -0.15),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    ),
  );

  late final Animation<Offset> _statsSlideUp = Tween<Offset>(
    begin: const Offset(0, 0.2),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
    ),
  );

  late final Animation<Offset> _quickAccessSlideUp = Tween<Offset>(
    begin: const Offset(0, 0.25),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
    ),
  );

  int _selectedNavIndex = 0;

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: AppDurations.route,
        reverseTransitionDuration: AppDurations.route,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
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
      ),
    );
  }

  void _openInwardScanner() {
    _navigateTo(const BarcodeScannerScreen(mode: ScannerMode.inward));
  }

  void _openOutwardScanner() {
    _navigateTo(const BarcodeScannerScreen(mode: ScannerMode.outward));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFEFF4FA),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF090D16) : const Color(0xFFEFF4FA),
          gradient: isDark ? null : AppGradients.background,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Stack(
              children: [
                // Subtle Background Blobs
                const _BackgroundBlobs(),

                // Horizontal Smooth Sliding PageView
                PageView(
                  controller: _pageController,
                  physics: const PageScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  onPageChanged: (index) {
                    if (_selectedNavIndex != index) {
                      setState(() {
                        _selectedNavIndex = index;
                      });
                    }
                  },
                  children: [
                    // Page 0: Home Dashboard
                    _HomeDashboardView(
                      heroSlideDown: _heroSlideDown,
                      statsSlideUp: _statsSlideUp,
                      quickAccessSlideUp: _quickAccessSlideUp,
                      onNavigateToProducts: () =>
                          _navigateTo(const ProductsHubScreen()),
                      onOpenInwardScanner: _openInwardScanner,
                      onOpenOutwardScanner: _openOutwardScanner,
                    ),

                    // Page 1: Scanner View
                    const BarcodeScannerScreen(mode: ScannerMode.inward),

                    // Page 2: Device Scan History
                    const ScanHistoryScreen(),

                    // Page 3: Settings
                    const SettingsScreen(),
                  ],
                ),

                // Floating Bottom Navigation Bar (Hidden when on Scanner page)
                if (_selectedNavIndex != 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: FloatingBottomNavigation(
                      selectedIndex: _selectedNavIndex,
                      onItemTapped: _onTabTapped,
                      onFabPressed: () => _onTabTapped(1),
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

class _HomeDashboardView extends StatefulWidget {
  const _HomeDashboardView({
    required this.heroSlideDown,
    required this.statsSlideUp,
    required this.quickAccessSlideUp,
    required this.onNavigateToProducts,
    required this.onOpenInwardScanner,
    required this.onOpenOutwardScanner,
  });

  final Animation<Offset> heroSlideDown;
  final Animation<Offset> statsSlideUp;
  final Animation<Offset> quickAccessSlideUp;
  final VoidCallback onNavigateToProducts;
  final VoidCallback onOpenInwardScanner;
  final VoidCallback onOpenOutwardScanner;

  @override
  State<_HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<_HomeDashboardView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettingsService().localeNotifier,
      builder: (context, _, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary =
            isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            12,
            AppSpacing.page,
            110, // Extra bottom padding for floating nav bar
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar Header
              DashboardAppBar(
                userName: 'Admin',
                notificationCount: 0,
                onNotificationPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications tapped'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Hero Stock Card with Slide Down animation
              SlideTransition(
                position: widget.heroSlideDown,
                child: HeroStockCard(
                  stockCount: '1246',
                  percentage: '12.5%',
                  onTap: widget.onNavigateToProducts,
                ),
              ),
              const SizedBox(height: 18),

              // Statistics Section (2 Cards Row: Inward & Outward)
              SlideTransition(
                position: widget.statsSlideUp,
                child: Row(
                  children: [
                    // Card 1: Today's Inward
                    Expanded(
                      child: StatisticCard(
                        title: AppTranslation.tr('todaysInward'),
                        value: '28',
                        subtitle: AppTranslation.tr('items'),
                        valueColor: textPrimary,
                        iconBgColor: isDark
                            ? const Color(0xFF1E3A5F)
                            : AppColors.blueTileBg,
                        iconColor: AppColors.primary,
                        icon: Icons.south_west_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Card 2: Today's Outward
                    Expanded(
                      child: StatisticCard(
                        title: AppTranslation.tr('todaysOutward'),
                        value: '17',
                        subtitle: AppTranslation.tr('items'),
                        valueColor: textPrimary,
                        iconBgColor: isDark
                            ? const Color(0xFF14532D)
                            : AppColors.greenTileBg,
                        iconColor: AppColors.green,
                        icon: Icons.north_east_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Access Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppTranslation.tr('quickAccess'),
                    style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
                  ),

                  // 3 actions Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark ? const Color(0xFF1E293B) : AppColors.greyPill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '3 actions',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Access Stacked Cards List
              SlideTransition(
                position: widget.quickAccessSlideUp,
                child: Column(
                  children: [
                    // 1: Inward Entry Card
                    QuickAccessCard(
                      title: AppTranslation.tr('inwardEntry'),
                      subtitle: AppTranslation.tr('scanProduct'),
                      icon: Icons.south_west_rounded,
                      iconColor: AppColors.primary,
                      iconBgColor: isDark
                          ? const Color(0xFF1E3A5F)
                          : AppColors.blueTileBg,
                      onTap: widget.onOpenInwardScanner,
                    ),
                    const SizedBox(height: 12),

                    // 2: Outward Entry Card
                    QuickAccessCard(
                      title: AppTranslation.tr('outwardEntry'),
                      subtitle: AppTranslation.tr('scanProduct'),
                      icon: Icons.north_east_rounded,
                      iconColor: AppColors.green,
                      iconBgColor: isDark
                          ? const Color(0xFF14532D)
                          : AppColors.greenTileBg,
                      onTap: widget.onOpenOutwardScanner,
                    ),
                    const SizedBox(height: 12),

                    // 3: Products Hub Card
                    QuickAccessCard(
                      title: AppTranslation.tr('products'),
                      subtitle: AppTranslation.tr('manageInventory'),
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.purple,
                      iconBgColor: isDark
                          ? const Color(0xFF312E81)
                          : AppColors.purpleTileBg,
                      onTap: widget.onNavigateToProducts,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Stack(
        children: [
          // Top Right Subtle Soft Blue Blob
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.06)
                    : AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Middle Left Subtle Soft Blue Blob
          Positioned(
            top: 280,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF60A5FA).withValues(alpha: 0.05)
                    : AppColors.secondary.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Bottom Right Subtle Purple/Blue Blob
          Positioned(
            bottom: 40,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.04)
                    : AppColors.purple.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
