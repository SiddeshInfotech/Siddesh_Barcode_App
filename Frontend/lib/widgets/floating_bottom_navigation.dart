import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class FloatingBottomNavigation extends StatelessWidget {
  const FloatingBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.onFabPressed,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback? onFabPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: AppShadows.nav,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
          ),

          // Categories
          _NavItem(
            icon: Icons.category_outlined,
            label: 'Categori...',
            isSelected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
          ),

          // Optional Center FAB / Plus action
          if (onFabPressed != null) ...[
            _CenterFabButton(onPressed: onFabPressed!),
          ],

          // Stats
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            isSelected: selectedIndex == 2,
            onTap: () => onItemTapped(2),
          ),

          // Settings
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isSelected: selectedIndex == 3,
            onTap: () => onItemTapped(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textSecondary.withOpacity(0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.navLabel.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterFabButton extends StatefulWidget {
  const _CenterFabButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_CenterFabButton> createState() => _CenterFabButtonState();
}

class _CenterFabButtonState extends State<_CenterFabButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.fab,
            boxShadow: AppShadows.fabGlow,
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
