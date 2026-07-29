import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/floating_bottom_navigation.dart';
import '../widgets/hero_stock_card.dart';
import '../widgets/quick_access_card.dart';
import '../widgets/statistic_card.dart';
import 'barcode_scanner_screen.dart';
import 'products_hub_screen.dart' hide AppColors, AppGradients, AppShadows;
import 'scan_history_screen.dart';
import 'settings_screen.dart';
import '../services/app_settings_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
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
    setState(() {
      _selectedNavIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.background,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Stack(
              children: [
                // Subtle Background Blobs
                const _BackgroundBlobs(),

                // Horizontal Sliding PageView
                PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _selectedNavIndex = index;
                    });
                  },
                  children: [
                    // Page 0: Home Dashboard
                    _buildHomeDashboardView(),

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

  Widget _buildHomeDashboardView() {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettingsService().localeNotifier,
      builder: (context, _, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            8,
            AppSpacing.page,
            100, // Extra bottom padding for floating nav bar
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              DashboardAppBar(
                onNotificationPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications tapped'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Hero Stock Card with Slide Down animation
              SlideTransition(
                position: _heroSlideDown,
                child: HeroStockCard(
                  stockCount: '1246',
                  percentage: '+ 12.5%',
                  onTap: () => _navigateTo(const ProductsHubScreen()),
                ),
              ),
              const SizedBox(height: 20),

              // Statistics Section (2 Cards Row) with Slide Up animation
              SlideTransition(
                position: _statsSlideUp,
                child: Row(
                  children: [
                    // Card 1: Today's Inward
                    Expanded(
                      child: StatisticCard(
                        title: AppTranslation.tr('todaysInward'),
                        value: '28',
                        subtitle: AppTranslation.tr('items'),
                        valueColor: AppColors.green,
                        iconBgColor: isDark ? const Color(0xFF14532D) : AppColors.greenPastel,
                        iconColor: AppColors.green,
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
                        valueColor: AppColors.orange,
                        iconBgColor: isDark ? const Color(0xFF7C2D12) : AppColors.orangeIconBg,
                        iconColor: AppColors.orange,
                        icon: Icons.north_east_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

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
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppTranslation.tr('actions'),
                      style: AppTextStyles.badgeBlueText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Access Grid (2 Columns, 2 Rows)
              SlideTransition(
                position: _quickAccessSlideUp,
                child: Column(
                  children: [
                    // Row 1: Inward Entry & Outward Entry (Both open BarcodeScannerScreen)
                    Row(
                      children: [
                        Expanded(
                          child: QuickAccessCard(
                            title: AppTranslation.tr('inwardEntry'),
                            subtitle: AppTranslation.tr('scanProduct'),
                            icon: Icons.south_west_rounded,
                            iconColor: AppColors.green,
                            iconBgColor: isDark ? const Color(0xFF14532D) : AppColors.mintIconBg,
                            gradient: isDark
                                ? const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF022C22)])
                                : AppGradients.mintCard,
                            onTap: _openInwardScanner,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: QuickAccessCard(
                            title: AppTranslation.tr('outwardEntry'),
                            subtitle: AppTranslation.tr('scanProduct'),
                            icon: Icons.north_east_rounded,
                            iconColor: AppColors.orange,
                            iconBgColor: isDark ? const Color(0xFF7C2D12) : AppColors.orangeIconBg,
                            gradient: isDark
                                ? const LinearGradient(colors: [Color(0xFF78350F), Color(0xFF451A03)])
                                : AppGradients.orangeCard,
                            onTap: _openOutwardScanner,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 2: Products
                    QuickAccessCard(
                      title: AppTranslation.tr('products'),
                      subtitle: AppTranslation.tr('viewInventory'),
                      icon: Icons.all_inbox_rounded,
                      iconColor: AppColors.primary,
                      iconBgColor: isDark ? const Color(0xFF1E3A5F) : AppColors.blueIconBg,
                      gradient: isDark
                          ? const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)])
                          : AppGradients.blueCard,
                      onTap: () => _navigateTo(const ProductsHubScreen()),
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

  Widget _buildSettingsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.bluePastel,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Settings', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          const Text('Manage device & app configuration', style: AppTextStyles.cardSubtitle),
        ],
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
          // Top Right Subtle Soft Blue Blob
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
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
                color: AppColors.secondary.withValues(alpha: 0.07),
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
                color: AppColors.purple.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
