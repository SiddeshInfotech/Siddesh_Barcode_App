import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;
  final Color iconBgColor;
  final Color iconColor;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Icon Pill Container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),

              // Title Label
              Text(
                title,
                style: AppTextStyles.statTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Value & Unit
              Text(
                value,
                style: AppTextStyles.statValue.copyWith(color: valueColor),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.statUnit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
