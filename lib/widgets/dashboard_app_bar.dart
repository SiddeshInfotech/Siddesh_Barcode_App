import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class DashboardAppBar extends StatefulWidget {
  const DashboardAppBar({
    super.key,
    this.userName = 'Admin',
    this.notificationCount = 0,
    this.onNotificationPressed,
  });

  final String userName;
  final int notificationCount;
  final VoidCallback? onNotificationPressed;

  @override
  State<DashboardAppBar> createState() => _DashboardAppBarState();
}

class _DashboardAppBarState extends State<DashboardAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bellController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _bellController.forward().then((_) {
          if (mounted) _bellController.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  void _triggerBellSwing() {
    if (!_bellController.isAnimating) {
      _bellController.forward(from: 0).then((_) {
        if (mounted) _bellController.reset();
      });
    }
    widget.onNotificationPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Hello Admin & Dashboard
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Hello, ${widget.userName}',
                  style: AppTextStyles.cardSubtitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('👋', style: TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Dashboard',
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ],
        ),

        // Right: Notification Bell Button with Red Badge '0'
        AnimatedBuilder(
          animation: _bellController,
          builder: (context, child) {
            final double sineValue = math.sin(_bellController.value * math.pi * 4);
            final double angle = sineValue * 0.15;
            return Transform.rotate(
              angle: angle,
              child: child,
            );
          },
          child: _SquareIconButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: widget.notificationCount,
            onTap: _triggerBellSwing,
          ),
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.9);
    final iconColor = isDark ? Colors.white : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: isDark ? const [] : AppShadows.soft,
            border: Border.all(
              color: border,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
              // Red Badge Circle with count '0'
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
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
