import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/floating_bottom_navigation.dart';
import '../widgets/hero_stock_card.dart';
import '../widgets/quick_access_card.dart';
import '../widgets/statistic_card.dart';
import 'barcode_scanner_screen.dart';
import 'products_hub_screen.dart' hide AppColors, AppGradients, AppSpacing, AppRadii, AppDurations, AppShadows, AppTextStyles;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  DashboardStats _stats = const DashboardStats();
  bool _isLoadingStats = true;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

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
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _apiService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) async {
    await Navigator.of(context).push(
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
    _loadDashboardStats();
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

                // Scrollable Content
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.page,
                    AppSpacing.page,
                    100, // Extra bottom padding for floating nav bar
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar
                      DashboardAppBar(
                        onMenuPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Menu tapped'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        onNotificationPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications tapped'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Hero Stock Card with Slide Down animation
                      SlideTransition(
                        position: _heroSlideDown,
                        child: HeroStockCard(
                          stockCount: _isLoadingStats ? '0' : '${_stats.currentStock}',
                          percentage: '+ 0.0%',
                          onTap: () => _navigateTo(const ProductsHubScreen()),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Statistics Section (3 Cards Row) with Slide Up animation
                      SlideTransition(
                        position: _statsSlideUp,
                        child: Row(
                          children: [
                            // Card 1: Today's Inward
                            Expanded(
                              child: StatisticCard(
                                title: "Today's\nInward",
                                value: _isLoadingStats ? '0' : '${_stats.todayInward}',
                                subtitle: 'Items',
                                valueColor: AppColors.green,
                                iconBgColor: AppColors.greenPastel,
                                iconColor: AppColors.green,
                                icon: Icons.south_west_rounded,
                                onTap: _openInwardScanner,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Card 2: Today's Outward
                            Expanded(
                              child: StatisticCard(
                                title: "Today's\nOutward",
                                value: _isLoadingStats ? '0' : '${_stats.todayOutward}',
                                subtitle: 'Items',
                                valueColor: AppColors.orange,
                                iconBgColor: AppColors.orangeIconBg,
                                iconColor: AppColors.orange,
                                icon: Icons.north_east_rounded,
                                onTap: _openOutwardScanner,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Card 3: Low Stock Items
                            Expanded(
                              child: StatisticCard(
                                title: "Low Stock\nItems",
                                value: _isLoadingStats ? '0' : '${_stats.lowStockItems}',
                                subtitle: 'Items',
                                valueColor: AppColors.red,
                                iconBgColor: AppColors.redPastel,
                                iconColor: AppColors.red,
                                icon: Icons.warning_amber_rounded,
                                onTap: () => _navigateTo(const ProductsHubScreen()),
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
                          const Text(
                            'Quick Access',
                            style: AppTextStyles.sectionTitle,
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
                            child: const Text(
                              '3 actions',
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
                                    title: 'Inward\nEntry',
                                    subtitle: 'Scan product...',
                                    icon: Icons.south_west_rounded,
                                    iconColor: AppColors.green,
                                    iconBgColor: AppColors.mintIconBg,
                                    gradient: AppGradients.mintCard,
                                    onTap: _openInwardScanner,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: QuickAccessCard(
                                    title: 'Outward\nEntry',
                                    subtitle: 'Scan product...',
                                    icon: Icons.north_east_rounded,
                                    iconColor: AppColors.orange,
                                    iconBgColor: AppColors.orangeIconBg,
                                    gradient: AppGradients.orangeCard,
                                    onTap: _openOutwardScanner,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Row 2: Products
                            QuickAccessCard(
                              title: 'Products',
                              subtitle: 'View inventory & management',
                              icon: Icons.all_inbox_rounded,
                              iconColor: AppColors.primary,
                              iconBgColor: AppColors.blueIconBg,
                              gradient: AppGradients.blueCard,
                              onTap: () => _navigateTo(const ProductsHubScreen()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Bottom Navigation Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: FloatingBottomNavigation(
                    selectedIndex: _selectedNavIndex,
                    onItemTapped: (index) {
                      setState(() {
                        _selectedNavIndex = index;
                      });
                    },
                    onFabPressed: _openInwardScanner,
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
