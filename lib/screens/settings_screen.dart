import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../services/app_settings_service.dart';
import '../services/user_service.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AppSettingsService _settingsService = AppSettingsService();

  void _showLanguageBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => LanguageBottomSheet(
        currentLocale: _settingsService.localeNotifier.value,
        onLocaleSelected: (locale) {
          _settingsService.setLocale(locale);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locale.languageCode == 'mr'
                    ? 'भाषा मराठी मध्ये बदलली आहे'
                    : 'Language changed to English',
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.92);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return ValueListenableBuilder<Locale>(
      valueListenable: _settingsService.localeNotifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                14,
                AppSpacing.page,
                110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header / App Bar Section
                  Row(
                    children: [
                      Material(
                        color: cardBg,
                        shape: const CircleBorder(),
                        elevation: 0,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: isDark ? const [] : AppShadows.soft,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslation.tr('settings'),
                            style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppTranslation.tr('customizeApp'),
                            style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13, color: textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 20),

                  // Profile Card Section (Dynamic User Profile)
                  ValueListenableBuilder<UserProfile>(
                    valueListenable: UserService().userNotifier,
                    builder: (context, profile, _) {
                      return ProfileCard(
                        adminName: profile.fullName,
                        adminEmail: profile.email,
                        onEditTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Setting Options Header: Preferences & Security
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      AppTranslation.tr('preferencesSecurity'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),

                  // 1. Language Tile (Screen 4: English > pill badge)
                  SettingsTile(
                    icon: Icons.language_rounded,
                    iconBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                    iconColor: textPrimary,
                    title: AppTranslation.tr('language'),
                    subtitle: AppTranslation.tr('chooseLanguage'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            locale.languageCode == 'mr'
                                ? AppTranslation.tr('marathiName')
                                : AppTranslation.tr('englishName'),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
                        ],
                      ),
                    ),
                    onTap: _showLanguageBottomSheet,
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // 2. Theme Tile (Screen 4: Sun icon, Light Mode Enabled, Switch)
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: _settingsService.themeModeNotifier,
                    builder: (context, themeMode, _) {
                      final activeDark = themeMode == ThemeMode.dark;
                      return SettingsTile(
                        icon: activeDark ? Icons.dark_mode_outlined : Icons.wb_sunny_outlined,
                        iconBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                        iconColor: textPrimary,
                        title: AppTranslation.tr('theme'),
                        subtitle: activeDark
                            ? AppTranslation.tr('darkMode')
                            : AppTranslation.tr('lightMode'),
                        trailing: CustomSwitch(
                          value: activeDark,
                          onChanged: (val) {
                            _settingsService.toggleTheme(val);
                          },
                        ),
                        onTap: () {
                          _settingsService.toggleTheme(!activeDark);
                        },
                      );
                    },
                  ).animate().fadeIn(duration: 550.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // 3. Notifications Tile (Screen 4: Bell icon, Receive inventory alerts, Switch)
                  ValueListenableBuilder<bool>(
                    valueListenable: _settingsService.notificationsNotifier,
                    builder: (context, enabled, _) {
                      return SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        iconBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                        iconColor: textPrimary,
                        title: AppTranslation.tr('notifications'),
                        subtitle: enabled
                            ? AppTranslation.tr('receiveAlerts')
                            : AppTranslation.tr('alertsDisabled'),
                        trailing: CustomSwitch(
                          value: enabled,
                          onChanged: (val) {
                            _settingsService.toggleNotifications(val);
                          },
                        ),
                        onTap: () {
                          _settingsService.toggleNotifications(!enabled);
                        },
                      );
                    },
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),


                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Profile Card Component (Black Glassy Theme)
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.adminName,
    required this.adminEmail,
    required this.onEditTap,
  });

  final String adminName;
  final String adminEmail;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F2937),
            Color(0xFF111827),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // User Silhouette Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // User Name & Email Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  adminEmail,
                  style: AppTextStyles.cardSubtitle.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Right Circle Chevron Button
          Material(
            color: Colors.white.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEditTap,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Tile Component
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.titleColor,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.92);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: isDark ? const [] : AppShadows.soft,
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: titleColor ?? textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardSubtitle.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Switch Component matching Screen 4 active dark pill switch
class CustomSwitch extends StatelessWidget {
  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? AppColors.darkPill : const Color(0xFFE2E8F0),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Notification Switch Component
class NotificationSwitch extends StatelessWidget {
  const NotificationSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.green,
    );
  }
}

// Language Bottom Sheet Component
class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({
    super.key,
    required this.currentLocale,
    required this.onLocaleSelected,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : AppColors.cardBg;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppTranslation.tr('selectLanguage'),
            style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslation.tr('chooseLanguage'),
            style: AppTextStyles.cardSubtitle.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 20),

          // English Option
          _LanguageTile(
            flag: '🇬🇧',
            name: AppTranslation.tr('englishName'),
            subtitle: 'Standard English Interface',
            isSelected: currentLocale.languageCode == 'en',
            onTap: () => onLocaleSelected(const Locale('en')),
          ),

          const SizedBox(height: 12),

          // Marathi Option
          _LanguageTile(
            flag: '🇮🇳',
            name: AppTranslation.tr('marathiName'),
            subtitle: 'प्रादेशिक मराठी भाषा इंटरफेस',
            isSelected: currentLocale.languageCode == 'mr',
            onTap: () => onLocaleSelected(const Locale('mr')),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Text(flag, style: const TextStyle(fontSize: 28)),
        title: Text(
          name,
          style: AppTextStyles.cardTitle.copyWith(fontSize: 15, color: textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12, color: textSecondary),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            : null,
      ),
    );
  }
}


