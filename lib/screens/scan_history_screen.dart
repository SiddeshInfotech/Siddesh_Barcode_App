import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/app_settings_service.dart';
import '../services/scan_history_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.92);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettingsService().localeNotifier,
      builder: (context, _, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title Bar with Filter Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslation.tr('history'),
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppTranslation.tr('scanHistorySub'),
                        style: AppTextStyles.cardSubtitle.copyWith(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Filter Icon Glass Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          boxShadow: isDark ? const [] : AppShadows.soft,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Tabs (All, Inward, Outward)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['All', 'Inward', 'Outward'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final filterLabel = filter == 'All'
                      ? AppTranslation.tr('all')
                      : (filter == 'Inward' ? AppTranslation.tr('inward') : AppTranslation.tr('outward'));

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : AppColors.darkPill)
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: (isSelected && !isDark) ? AppShadows.soft : const [],
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          filterLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? AppColors.darkPill : Colors.white)
                                : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Scan History Content / Empty State Card
            Expanded(
              child: ValueListenableBuilder<List<ScanHistoryItem>>(
                valueListenable: _historyService.historyNotifier,
                builder: (context, rawHistory, _) {
                  final history = rawHistory.where((item) {
                    if (_selectedFilter == 'All') return true;
                    return item.entryType.toLowerCase() == _selectedFilter.toLowerCase();
                  }).toList();

                  if (history.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: isDark ? const [] : AppShadows.soft,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _3DClipboardIllustrationWidget(),
                            const SizedBox(height: 24),
                            Text(
                              AppTranslation.tr('noScans'),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Start scanning to see your history here.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.cardSubtitle.copyWith(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                    itemCount: history.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final isInward = item.entryType.toLowerCase() == 'inward';
                      final badgeColor = isInward ? AppColors.primary : AppColors.green;
                      final badgeBg = isInward
                          ? (isDark ? const Color(0xFF1E3A5F) : AppColors.blueTileBg)
                          : (isDark ? const Color(0xFF14532D) : AppColors.greenTileBg);
                      final icon = isInward ? Icons.south_west_rounded : Icons.north_east_rounded;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          boxShadow: isDark ? const [] : AppShadows.soft,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 1.5,
                          ),
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
                                          style: AppTextStyles.cardTitle.copyWith(fontSize: 15, color: textPrimary),
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
                                  Text(
                                    '${item.barcode}  •  ${item.category}',
                                    style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12, color: textSecondary),
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
                                  fontFamily: 'Inter',
                                  fontSize: 13,
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

class _3DClipboardIllustrationWidget extends StatelessWidget {
  const _3DClipboardIllustrationWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Glow Behind Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.18),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // 3D Clipboard Container
          Container(
            width: 100,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Top Metallic Clip
                Container(
                  width: 44,
                  height: 14,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 14),

                // Content Lines
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF93C5FD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 6,
                        margin: const EdgeInsets.only(right: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Clock Badge
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 2.5,
                ),
              ),
              child: const Icon(
                Icons.access_time_filled_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          // Floating Spheres Accent
          Positioned(
            left: 20,
            top: 26,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 14,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
