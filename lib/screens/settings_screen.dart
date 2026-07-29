import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../services/app_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.cardBg;
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
                12,
                AppSpacing.page,
                100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header / App Bar Section
                  Row(
                    children: [
                      Material(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
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
                            style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
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

                  // Profile Card Section
                  ProfileCard(
                    adminName: AppTranslation.tr('adminUser'),
                    adminEmail: 'admin@inventory.com',
                    onEditTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Editing Profile for ${AppTranslation.tr("adminUser")}...'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Setting Options Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      AppTranslation.tr('preferencesSecurity'),
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 15,
                        color: textSecondary,
                      ),
                    ),
                  ),

                  // 1. Language Tile
                  SettingsTile(
                    icon: Icons.language_rounded,
                    iconBgColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                    iconColor: AppColors.primary,
                    title: AppTranslation.tr('language'),
                    subtitle: AppTranslation.tr('chooseLanguage'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            locale.languageCode == 'mr'
                                ? AppTranslation.tr('marathiName')
                                : AppTranslation.tr('englishName'),
                            style: TextStyle(
                              fontFamily: 'Poppins',
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

                  // 2. Theme Tile
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: _settingsService.themeModeNotifier,
                    builder: (context, themeMode, _) {
                      final activeDark = themeMode == ThemeMode.dark;
                      return SettingsTile(
                        icon: activeDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        iconBgColor: activeDark ? const Color(0xFF312E81) : const Color(0xFFF5F3FF),
                        iconColor: AppColors.purple,
                        title: AppTranslation.tr('theme'),
                        subtitle: activeDark
                            ? AppTranslation.tr('darkMode')
                            : AppTranslation.tr('lightMode'),
                        trailing: ThemeSwitch(
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

                  // 3. Notifications Tile
                  ValueListenableBuilder<bool>(
                    valueListenable: _settingsService.notificationsNotifier,
                    builder: (context, enabled, _) {
                      return SettingsTile(
                        icon: Icons.notifications_active_rounded,
                        iconBgColor: isDark ? const Color(0xFF14532D) : AppColors.greenPastel,
                        iconColor: AppColors.green,
                        title: AppTranslation.tr('notifications'),
                        subtitle: enabled
                            ? AppTranslation.tr('receiveAlerts')
                            : AppTranslation.tr('alertsDisabled'),
                        trailing: NotificationSwitch(
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

                  // 4. Backup Data Tile
                  SettingsTile(
                    icon: Icons.backup_rounded,
                    iconBgColor: isDark ? const Color(0xFF7C2D12) : AppColors.orangeIconBg,
                    iconColor: AppColors.orange,
                    title: AppTranslation.tr('backupData'),
                    subtitle: AppTranslation.tr('backupInfo'),
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                    onTap: _showBackupBottomSheet,
                  ).animate().fadeIn(duration: 650.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // 5. Logout Tile
                  SettingsTile(
                    icon: Icons.logout_rounded,
                    iconBgColor: isDark ? const Color(0xFF7F1D1D) : AppColors.redPastel,
                    iconColor: AppColors.red,
                    title: AppTranslation.tr('logout'),
                    subtitle: AppTranslation.tr('signOutSecurely'),
                    titleColor: AppColors.red,
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.red),
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

// Profile Card Component
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.cardBg;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.hero,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminName,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  adminEmail,
                  style: AppTextStyles.cardSubtitle.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
          Material(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onEditTap,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.primary,
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
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.cardBg;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
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

// Theme Switch Component
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({
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
      activeColor: AppColors.purple,
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
      activeColor: AppColors.green,
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
