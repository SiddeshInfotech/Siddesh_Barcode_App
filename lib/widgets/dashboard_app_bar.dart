import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class DashboardAppBar extends StatefulWidget {
  const DashboardAppBar({
    super.key,
    this.onNotificationPressed,
  });

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
    // Periodically trigger a subtle swing animation for the bell icon
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Right Notification Bell Button with Red Badge & Swing Animation
        AnimatedBuilder(
          animation: _bellController,
          builder: (context, child) {
            // Swing calculation
            final double sineValue = math.sin(_bellController.value * math.pi * 4);
            final double angle = sineValue * 0.15;
            return Transform.rotate(
              angle: angle,
              child: child,
            );
          },
          child: _SquareIconButton(
            icon: Icons.notifications_none_rounded,
            hasBadge: true,
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
    this.hasBadge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.textPrimary,
                size: 24,
              ),
              if (hasBadge)
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
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
