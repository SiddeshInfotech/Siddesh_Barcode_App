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
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.cardBg;

    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettingsService().localeNotifier,
      builder: (context, _, __) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: AppShadows.nav,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home (Index 0)
              _NavItem(
                icon: Icons.home_rounded,
                label: AppTranslation.tr('home'),
                isSelected: selectedIndex == 0,
                onTap: () => onItemTapped(0),
              ),

              // Scanner (Index 1)
              _NavItem(
                icon: Icons.qr_code_scanner_rounded,
                label: AppTranslation.tr('scanner'),
                isSelected: selectedIndex == 1,
                onTap: () => onItemTapped(1),
              ),

              // History (Index 2)
              _NavItem(
                icon: Icons.history_rounded,
                label: AppTranslation.tr('history'),
                isSelected: selectedIndex == 2,
                onTap: () => onItemTapped(2),
              ),

              // Settings (Index 3)
              _NavItem(
                icon: Icons.settings_outlined,
                label: AppTranslation.tr('settings'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? AppGradients.fab : null,
                color: isSelected ? null : Colors.transparent,
                boxShadow: isSelected ? AppShadows.fabGlow : const [],
              ),
              child: Center(
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : inactiveColor,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.navLabel.copyWith(
                color: isSelected ? AppColors.primary : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
