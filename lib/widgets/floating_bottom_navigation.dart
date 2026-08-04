import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/app_settings_service.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xEE111827)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor = isDark
        ? const Color(0xFF1F2937)
        : Colors.white.withValues(alpha: 0.95);

    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettingsService().localeNotifier,
      builder: (context, _, __) {
        return Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: isDark ? const [] : AppShadows.nav,
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home (Index 0)
              _NavItem(
                icon: Icons.home_rounded,
                activeIcon: Icons.home_rounded,
                isSelected: selectedIndex == 0,
                onTap: () => onItemTapped(0),
              ),

              // Scanner (Index 1)
              _NavItem(
                icon: Icons.qr_code_scanner_rounded,
                activeIcon: Icons.qr_code_scanner_rounded,
                isSelected: selectedIndex == 1,
                onTap: () => onItemTapped(1),
              ),

              // History (Index 2)
              _NavItem(
                icon: Icons.history_rounded,
                activeIcon: Icons.history_rounded,
                isSelected: selectedIndex == 2,
                onTap: () => onItemTapped(2),
              ),

              // Settings (Index 3)
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                isSelected: selectedIndex == 3,
                onTap: () => onItemTapped(3),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? Colors.white : AppColors.darkPill;
    final activeFg = isDark ? AppColors.darkPill : Colors.white;
    final inactiveFg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? activeFg : inactiveFg,
          size: 24,
        ),
      ),
    );
  }
}
