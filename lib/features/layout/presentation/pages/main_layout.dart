import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _currentIndex = Signal<int>(1);

  static const _tabs = [
    '/market',
    '/watchlist',
    '/portfolio',
    '/chart',
    '/news',
    '/policy',
    '/calendar',
    '/settings',
  ];

  static const _tabLabels = [
    'Market',
    'Watchlist',
    'Portfolio',
    'Chart',
    'News',
    'Policy',
    'Calendar',
    'Settings',
  ];

  static const _tabIcons = [
    Icons.show_chart,
    Icons.list_alt,
    Icons.account_balance_wallet_outlined,
    Icons.candlestick_chart_outlined,
    Icons.newspaper_outlined,
    Icons.account_balance_outlined,
    Icons.calendar_today_outlined,
    Icons.settings_outlined,
  ];

  void _onTabTapped(int index) {
    _currentIndex.value = index;
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Watch((_) {
      return Container(
        height: 32,
        decoration: const BoxDecoration(
          color: AppThemeColors.surface,
          border: Border(bottom: BorderSide(color: AppThemeColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: double.infinity,
              alignment: Alignment.center,
              child: Text(
                AppStrings.appName.toUpperCase(),
                style: AppTypography.monoData.copyWith(
                  color: AppThemeColors.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = _currentIndex.value == index;
                  return InkWell(
                    onTap: () => _onTabTapped(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? AppThemeColors.accent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tabIcons[index],
                            size: 13,
                            color: isSelected
                                ? AppThemeColors.textPrimary
                                : AppThemeColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _tabLabels[index],
                            style: AppTypography.caption.copyWith(
                              color: isSelected
                                  ? AppThemeColors.textPrimary
                                  : AppThemeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
