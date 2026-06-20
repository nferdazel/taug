import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const _tabs = [
    '/companies',
    '/research',
    '/portfolio-workspace',
    '/data',
    '/settings',
  ];

  static const _tabLabels = [
    'Companies',
    'Research',
    'Portfolio',
    'Data',
    'Settings',
  ];

  static const _tabIcons = [
    Icons.business_outlined,
    Icons.edit_note_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.storage_outlined,
    Icons.settings_outlined,
  ];

  void _onTabTapped(int index) {
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
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = -1;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) {
        currentIndex = i;
        break;
      }
    }

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppThemeColors.surface,
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
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
                final bool isSelected = index == currentIndex;
                return InkWell(
                  onTap: () => _onTabTapped(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          size: AppSpacing.iconSize + 1,
                          color: isSelected
                              ? AppThemeColors.textPrimary
                              : AppThemeColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          _tabLabels[index],
                          style: AppTypography.labelSmall.copyWith(
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
  }
}
