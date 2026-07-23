import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds & Surfaces
  static const Color bgGradientTop = Color(0xFFEAF5FF);
  static const Color bgGradientBottom = Color(0xFFF7FBFF);
  static const Color background = Color(0xFFF7FBFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Primary & Accent Colors
  static const Color primary = Color(0xFF2D9CFF);
  static const Color secondary = Color(0xFF55C2FF);

  // Status & Action Colors
  static const Color green = Color(0xFF22C55E);
  static const Color orange = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color purple = Color(0xFF8B5CF6);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // Pastel Container Backgrounds
  static const Color mintPastel = Color(0xFFE6F8F6);
  static const Color mintIconBg = Color(0xFFD1F5F0);
  
  static const Color orangePastel = Color(0xFFFFF7ED);
  static const Color orangeIconBg = Color(0xFFFFEDD5);

  static const Color bluePastel = Color(0xFFEFF6FF);
  static const Color blueIconBg = Color(0xFFDBEAFE);

  static const Color purplePastel = Color(0xFFF5F3FF);
  static const Color purpleIconBg = Color(0xFFEDE9FE);

  static const Color redPastel = Color(0xFFFEE2E2);
  static const Color greenPastel = Color(0xFFDCFCE7);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 20;
}

abstract final class AppRadii {
  static const double small = 12;
  static const double medium = 20;
  static const double card = 28;
  static const double pill = 30;
  static const double hero = 28;
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
      color: const Color(0xFF1E293B).withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF2D9CFF).withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static final List<BoxShadow> hero = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.25),
      blurRadius: 30,
      offset: const Offset(0, 14),
    ),
  ];

  static final List<BoxShadow> nav = [
    BoxShadow(
      color: const Color(0xFF1E293B).withOpacity(0.12),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> fabGlow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.4),
      blurRadius: 18,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ];
}

abstract final class AppGradients {
  static const Gradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary],
  );

  static const Gradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgGradientTop, AppColors.bgGradientBottom],
  );

  static const Gradient fab = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary],
  );

  static const Gradient mintCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8FAF7), Color(0xFFF4FCFB)],
  );

  static const Gradient orangeCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF6ED), Color(0xFFFFFBF7)],
  );

  static const Gradient blueCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0F7FF), Color(0xFFF8FAFC)],
  );

  static const Gradient purpleCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6F4FF), Color(0xFFFAF9FF)],
  );
}

abstract final class AppTextStyles {
  static const TextStyle appBarPill = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heroLabel = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  static const TextStyle heroValue = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.1,
  );

  static const TextStyle heroUnit = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle badgeText = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.green,
  );

  static const TextStyle statTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const TextStyle statUnit = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle badgeBlueText = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}
