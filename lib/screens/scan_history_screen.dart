import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/app_settings_service.dart';
import '../services/scan_history_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final ScanHistoryService _historyService = ScanHistoryService();
  String _selectedFilter = 'All';

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.cardBg;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettingsService().localeNotifier,
      builder: (context, _, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslation.tr('scanHistory'),
                        style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppTranslation.tr('scanHistorySub'),
                        style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),

                  // Clear Button
                  ValueListenableBuilder<List<ScanHistoryItem>>(
                    valueListenable: _historyService.historyNotifier,
                    builder: (context, history, _) {
                      if (history.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: textSecondary),
                        tooltip: AppTranslation.tr('clearHistory'),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: cardBg,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text(AppTranslation.tr('clearHistory'), style: TextStyle(color: textPrimary)),
                              content: Text('Remove all device scan logs?', style: TextStyle(color: textSecondary)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(AppTranslation.tr('cancel'), style: TextStyle(color: textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _historyService.clearHistory();
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Clear', style: TextStyle(color: AppColors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['All', 'Inward', 'Outward'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final filterLabel = filter == 'All'
                      ? AppTranslation.tr('all')
                      : (filter == 'Inward' ? AppTranslation.tr('inward') : AppTranslation.tr('outward'));

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filterLabel),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: cardBg,
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Scan History List
            Expanded(
              child: ValueListenableBuilder<List<ScanHistoryItem>>(
                valueListenable: _historyService.historyNotifier,
                builder: (context, rawHistory, _) {
                  final history = rawHistory.where((item) {
                    if (_selectedFilter == 'All') return true;
                    return item.entryType.toLowerCase() == _selectedFilter.toLowerCase();
                  }).toList();

                  if (history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 64,
                            color: textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppTranslation.tr('noScans'),
                            style: AppTextStyles.cardTitle.copyWith(color: textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: history.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final isInward = item.entryType.toLowerCase() == 'inward';
                      final badgeColor = isInward ? AppColors.green : AppColors.orange;
                      final badgeBg = isInward
                          ? (isDark ? const Color(0xFF14532D) : AppColors.greenPastel)
                          : (isDark ? const Color(0xFF7C2D12) : AppColors.orangeIconBg);
                      final icon = isInward ? Icons.south_west_rounded : Icons.north_east_rounded;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(AppRadii.medium),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                icon,
                                color: badgeColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.productName,
                                          style: AppTextStyles.cardTitle.copyWith(fontSize: 14, color: textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        _formatTimestamp(item.timestamp),
                                        style: AppTextStyles.cardSubtitle.copyWith(fontSize: 11, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.qr_code_2_rounded,
                                              size: 13,
                                              color: textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.barcode,
                                              style: TextStyle(
                                                fontFamily: 'Monospace',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '•  ${item.category}',
                                        style: AppTextStyles.cardSubtitle.copyWith(fontSize: 11, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${isInward ? "+" : "-"}${item.quantity}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
