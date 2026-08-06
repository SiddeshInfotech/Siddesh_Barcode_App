import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
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

  void _showBackupBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackupBottomSheet(
        onOptionSelected: (title) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text('$title Completed Successfully!')),
                ],
              ),
              backgroundColor: AppColors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBackendConfigSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BackendConfigBottomSheet(),
    );
    // Refresh the tile subtitle to reflect any new manual/auto selection.
    if (mounted) setState(() {});
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => LogoutDialog(
        onLogout: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTranslation.tr('signOutSecurely')),
              backgroundColor: AppColors.red,
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

                  const SizedBox(height: 12),

                  // 4. Backend Server Tile — configure / test the desktop backend connection
                  SettingsTile(
                    icon: Icons.dns_rounded,
                    iconBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                    iconColor: textPrimary,
                    title: 'Backend Server',
                    subtitle: ApiService.manualBaseUrl == null
                        ? 'Auto-detect on this network'
                        : 'Manual: ${ApiService.manualBaseUrl}',
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                    onTap: _showBackendConfigSheet,
                  ).animate().fadeIn(duration: 630.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // 5. Backup Data Tile (Screen 4: Cloud icon, Backup inventory information, Chevron)
                  SettingsTile(
                    icon: Icons.cloud_queue_rounded,
                    iconBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                    iconColor: textPrimary,
                    title: AppTranslation.tr('backupData'),
                    subtitle: AppTranslation.tr('backupInfo'),
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                    onTap: _showBackupBottomSheet,
                  ).animate().fadeIn(duration: 650.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // 5. Logout Tile (Screen 4: Red exit icon, Red Logout text & subtitle)
                  SettingsTile(
                    icon: Icons.logout_rounded,
                    iconBgColor: const Color(0xFFFFECE5),
                    iconColor: AppColors.red,
                    title: AppTranslation.tr('logout'),
                    subtitle: AppTranslation.tr('signOutSecurely'),
                    titleColor: AppColors.red,
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                    onTap: _showLogoutDialog,
                  ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.1, end: 0),
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

// Backup Bottom Sheet Component
class BackupBottomSheet extends StatelessWidget {
  const BackupBottomSheet({
    super.key,
    required this.onOptionSelected,
  });

  final ValueChanged<String> onOptionSelected;

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
            AppTranslation.tr('backupData'),
            style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslation.tr('backupInfo'),
            style: AppTextStyles.cardSubtitle.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 20),

          ListTile(
            onTap: () => onOptionSelected('Create Backup'),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A5F) : AppColors.bluePastel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
            ),
            title: Text('Create Backup', style: AppTextStyles.cardTitle.copyWith(color: textPrimary)),
            subtitle: Text('Generate full database backup file', style: AppTextStyles.cardSubtitle.copyWith(color: textSecondary)),
            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
          ),
          const Divider(),

          ListTile(
            onTap: () => onOptionSelected('Restore Backup'),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14532D) : AppColors.greenPastel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cloud_download_rounded, color: AppColors.green),
            ),
            title: Text('Restore Backup', style: AppTextStyles.cardTitle.copyWith(color: textPrimary)),
            subtitle: Text('Restore from previous backup file', style: AppTextStyles.cardSubtitle.copyWith(color: textSecondary)),
            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
          ),
          const Divider(),

          ListTile(
            onTap: () => onOptionSelected('Export Backup'),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF312E81) : AppColors.purplePastel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.ios_share_rounded, color: AppColors.purple),
            ),
            title: Text('Export Backup', style: AppTextStyles.cardTitle.copyWith(color: textPrimary)),
            subtitle: Text('Export inventory CSV or JSON data', style: AppTextStyles.cardSubtitle.copyWith(color: textSecondary)),
            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// Logout Confirmation Dialog Component
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : AppColors.cardBg;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF7F1D1D) : AppColors.redPastel,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded, color: AppColors.red, size: 24),
          ),
          const SizedBox(width: 12),
          Text(AppTranslation.tr('logout'), style: AppTextStyles.sectionTitle.copyWith(color: textPrimary)),
        ],
      ),
      content: Text(
        'Are you sure you want to logout from your inventory management session?',
        style: AppTextStyles.cardSubtitle.copyWith(color: textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppTranslation.tr('cancel'), style: TextStyle(color: textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onLogout,
          child: Text(AppTranslation.tr('logout'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// Backend Server Configuration Bottom Sheet — lets the user override or test the
// desktop backend address when auto-discovery cannot find it on the current network.
class BackendConfigBottomSheet extends StatefulWidget {
  const BackendConfigBottomSheet({super.key});

  @override
  State<BackendConfigBottomSheet> createState() => _BackendConfigBottomSheetState();
}

class _BackendConfigBottomSheetState extends State<BackendConfigBottomSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: ApiService.manualBaseUrl ?? '');

  bool _isTesting = false;
  bool? _testPassed; // null = not tested yet
  String? _resultMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _testPassed = false;
        _resultMessage = 'Enter the laptop IP address first (e.g. 192.168.43.5).';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testPassed = null;
      _resultMessage = null;
    });

    final reachable = await ApiService().testConnection(input);

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testPassed = reachable != null;
      _resultMessage = reachable != null
          ? 'Connected — backend reachable at $reachable'
          : 'No response. Check the IP, that the backend is running, and that both devices are on the same network.';
    });
  }

  void _save() {
    final input = _controller.text.trim();
    ApiService.setManualBaseUrl(input.isEmpty ? null : input);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(input.isEmpty
            ? 'Cleared — using automatic detection'
            : 'Saved backend server: $input'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _useAutoDetect() {
    ApiService.setManualBaseUrl(null);
    _controller.clear();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Using automatic detection on this network'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : AppColors.cardBg;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    final Color? statusColor = _testPassed == null
        ? null
        : (_testPassed! ? AppColors.green : AppColors.red);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
              'Backend Server',
              style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'The app finds the laptop automatically. Set the IP manually only if it cannot.',
              style: AppTextStyles.cardSubtitle.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 20),

            // IP / URL input — a real label, not just a placeholder.
            Text(
              'Laptop IP or address',
              style: AppTextStyles.statTitle.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '192.168.43.5  (port 8080 assumed)',
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
                prefixIcon: Icon(Icons.dns_rounded, color: AppColors.primary, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            if (_resultMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _testPassed! ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _resultMessage!,
                      style: AppTextStyles.cardSubtitle.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Test Connection
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isTesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(Icons.wifi_tethering_rounded, color: AppColors.primary),
                label: Text(
                  _isTesting ? 'Testing…' : 'Test Connection',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Auto-detect (clear override)
            Center(
              child: TextButton.icon(
                onPressed: _isTesting ? null : _useAutoDetect,
                icon: Icon(Icons.autorenew_rounded, size: 18, color: textSecondary),
                label: Text(
                  'Use automatic detection',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
