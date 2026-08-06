import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds & Glass Surfaces
  static const Color bgGradientTop = Color(0xFFE8F0F8);
  static const Color bgGradientBottom = Color(0xFFF2F5FA);
  static const Color background = Color(0xFFEFF4FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF090D16);

  // Active Pill & Nav Bar
  static const Color darkPill = Color(0xFF111827);
  static const Color lightPill = Color(0xFFFFFFFF);
  static const Color greyPill = Color(0xFFEEF2F6);

  // Primary & Accent Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF3B82F6);

  // Status & Action Colors
  static const Color green = Color(0xFF10B981);
  static const Color orange = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color purple = Color(0xFF8B5CF6);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Soft Pastel Icon Tile Backgrounds & Legacy Aliases
  static const Color blueTileBg = Color(0xFFEBF3FE);
  static const Color greenTileBg = Color(0xFFECFDF5);
  static const Color purpleTileBg = Color(0xFFF3E8FF);
  static const Color orangeTileBg = Color(0xFFFFF7ED);
  static const Color redTileBg = Color(0xFFFEE2E2);
  static const Color greyTileBg = Color(0xFFF3F4F6);

  static const Color bluePastel = Color(0xFFEFF6FF);
  static const Color blueIconBg = Color(0xFFDBEAFE);
  static const Color greenPastel = Color(0xFFDCFCE7);
  static const Color mintPastel = Color(0xFFE6F8F6);
  static const Color mintIconBg = Color(0xFFD1F5F0);
  static const Color orangePastel = Color(0xFFFFF7ED);
  static const Color orangeIconBg = Color(0xFFFFEDD5);
  static const Color purplePastel = Color(0xFFF5F3FF);
  static const Color purpleIconBg = Color(0xFFEDE9FE);
  static const Color redPastel = Color(0xFFFEE2E2);

  // Badge & Tag Colors
  static const Color orangeBadgeBg = Color(0xFFFFECE5);
  static const Color orangeBadgeText = Color(0xFFE0562A);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 18;
}

abstract final class AppRadii {
  static const double small = 14;
  static const double medium = 20;
  static const double card = 24;
  static const double hero = 26;
  static const double pill = 32;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration route = Duration(milliseconds: 320);
}

abstract final class AppShadows {
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.8),
      blurRadius: 10,
      spreadRadius: -2,
      offset: const Offset(0, -4),
    ),
  ];

  static final List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF1E293B).withValues(alpha: 0.06),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> hero = [
    BoxShadow(
      color: const Color(0xFF1E2638).withValues(alpha: 0.35),
      blurRadius: 28,
      spreadRadius: 0,
      offset: const Offset(0, 14),
    ),
  ];

  static final List<BoxShadow> nav = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 30,
      spreadRadius: 0,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> fabGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ];
}

abstract final class AppGradients {
  static const Gradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4C5D75),
      Color(0xFF2B3648),
      Color(0xFF1E2638),
    ],
  );

  static const Gradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
  );

  static const Gradient glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );

  static const Gradient fab = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary],
  );
}

abstract final class AppTextStyles {
  static const TextStyle appBarPill = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heroLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF94A3B8),
  );

  static const TextStyle heroValue = TextStyle(
    fontFamily: 'Inter',
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.1,
  );

  static const TextStyle heroUnit = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFFCBD5E1),
  );

  static const TextStyle badgeText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.orangeBadgeText,
  );

  static const TextStyle statTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: 'Inter',
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static const TextStyle statUnit = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle badgeBlueText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}
