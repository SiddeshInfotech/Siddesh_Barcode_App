import 'package:flutter/material.dart';

class AppSettingsService {
  static final AppSettingsService _instance = AppSettingsService._internal();
  factory AppSettingsService() => _instance;
  AppSettingsService._internal();

  final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);
  final ValueNotifier<bool> notificationsNotifier = ValueNotifier(true);

  bool lowStockAlerts = true;
  bool productAddedAlerts = true;
  bool productRemovedAlerts = true;
  bool dailySummaryAlerts = false;

  void setLocale(Locale locale) {
    localeNotifier.value = locale;
  }

  void toggleTheme(bool isDark) {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleNotifications(bool enabled) {
    notificationsNotifier.value = enabled;
  }
}

class AppTranslation {
  static String tr(String key) {
    final currentLocale = AppSettingsService().localeNotifier.value.languageCode;
    final dict = _localizedStrings[currentLocale] ?? _localizedStrings['en']!;
    return dict[key] ?? key;
  }

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'currentStock': 'Current Stock',
      'items': 'Items',
      'todaysInward': 'Today\'s\nInward',
      'todaysOutward': 'Today\'s\nOutward',
      'quickAccess': 'Quick Access',
      'actions': '3 actions',
      'inwardEntry': 'Inward\nEntry',
      'outwardEntry': 'Outward\nEntry',
      'scanProduct': 'Scan product...',
      'products': 'Products',
      'viewInventory': 'View inventory & management',
      'home': 'Home',
      'scanner': 'Scanner',
      'history': 'History',
      'settings': 'Settings',
      'customizeApp': 'Customize your application',
      'adminUser': 'Admin User',
      'preferencesSecurity': 'Preferences & Security',
      'language': 'Language',
      'chooseLanguage': 'Choose your preferred language',
      'theme': 'Theme',
      'lightMode': 'Light Mode Enabled',
      'darkMode': 'Dark Mode Enabled',
      'notifications': 'Notifications',
      'receiveAlerts': 'Receive inventory alerts',
      'alertsDisabled': 'Alerts disabled',
      'backupData': 'Backup Data',
      'backupInfo': 'Backup inventory information',
      'logout': 'Logout',
      'signOutSecurely': 'Sign out securely',
      'scanHistory': 'Device Scan History',
      'scanHistorySub': 'Real-time record of all scanned items',
      'all': 'All',
      'inward': 'Inward',
      'outward': 'Outward',
      'clearHistory': 'Clear History',
      'noScans': 'No scan history recorded yet',
      'searchProducts': 'Search products by name or barcode...',
      'allCategories': 'All Categories',
      'stock': 'Stock',
      'minStock': 'Min Stock',
      'selectLanguage': 'Select Application Language',
      'languageChanged': 'Language changed to English',
      'marathiName': '🇮🇳 Marathi',
      'englishName': '🇬🇧 English',
      'accessGalleryTitle': 'Access Gallery?',
      'accessGalleryDesc': 'Allow this app to access your photo gallery to select a barcode image?',
      'cancel': 'Cancel',
      'yesAllow': 'Yes, Allow',
    },
    'mr': {
      'currentStock': 'सध्याचा साठा',
      'items': 'वस्तू',
      'todaysInward': 'आजची\nआवक',
      'todaysOutward': 'आजची\nजावक',
      'quickAccess': 'जलद प्रवेश',
      'actions': '३ कृती',
      'inwardEntry': 'आवक\nनोंद',
      'outwardEntry': 'जावक\nनोंद',
      'scanProduct': 'उत्पादन स्कॅन करा...',
      'products': 'उत्पादने',
      'viewInventory': 'साठा आणि व्यवस्थापन पहा',
      'home': 'मुख्यपृष्ठ',
      'scanner': 'स्कॅनर',
      'history': 'इतिहास',
      'settings': 'सेटिंग्ज',
      'customizeApp': 'आपले ॲप्लिकेशन सानुकूलित करा',
      'adminUser': 'ॲडमिन वापरकर्ता',
      'preferencesSecurity': 'प्राधान्ये आणि सुरक्षा',
      'language': 'भाषा',
      'chooseLanguage': 'तुमची पसंतीची भाषा निवडा',
      'theme': 'थीम',
      'lightMode': 'लाइट मोड चालू आहे',
      'darkMode': 'डार्क मोड चालू आहे',
      'notifications': 'सूचना',
      'receiveAlerts': 'साठा सूचना मिळवा',
      'alertsDisabled': 'सूचना बंद आहेत',
      'backupData': 'डेटा बॅकअप',
      'backupInfo': 'साठा माहितीचा बॅकअप घ्या',
      'logout': 'लॉगआउट',
      'signOutSecurely': 'सुरक्षितपणे बाहेर पडा',
      'scanHistory': 'स्कॅन इतिहास',
      'scanHistorySub': 'स्कॅन केलेल्या वस्तूंची रिअल-टाइम नोंद',
      'all': 'सर्व',
      'inward': 'आवक',
      'outward': 'जावक',
      'clearHistory': 'इतिहास हटवा',
      'noScans': 'कोणताही इतिहास उपलब्ध नाही',
      'searchProducts': 'नाव किंवा बारकोडने शोधा...',
      'allCategories': 'सर्व श्रेणी',
      'stock': 'साठा',
      'minStock': 'कमीत कमी साठा',
      'selectLanguage': 'ॲप्लिकेशन भाषा निवडा',
      'languageChanged': 'भाषा मराठी मध्ये बदलली आहे',
      'marathiName': '🇮🇳 मराठी',
      'englishName': '🇬🇧 इंग्रजी',
      'accessGalleryTitle': 'गॅलरी वापरा?',
      'accessGalleryDesc': 'बारकोड इमेज निवडण्यासाठी तुमच्या फोटो गॅलरीचा वापर करू द्यायचा का?',
      'cancel': 'रद्द करा',
      'yesAllow': 'होय, परवानगी द्या',
    },
  };
}
