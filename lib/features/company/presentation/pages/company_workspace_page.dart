import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../../../shared/widgets/status_badges.dart';
import '../../data/workspace_models.dart';
import '../providers/workspace_provider.dart';
import '../widgets/financials_tab.dart';
import '../widgets/overview_tab.dart';
import '../widgets/research_tab.dart';
import '../../../companies/presentation/widgets/research_status_badge.dart';

class CompanyWorkspacePage extends StatefulWidget {
  final String companyId;

  const CompanyWorkspacePage({super.key, required this.companyId});

  @override
  State<CompanyWorkspacePage> createState() => _CompanyWorkspacePageState();
}

class _CompanyWorkspacePageState extends State<CompanyWorkspacePage> {
  late final WorkspaceProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = WorkspaceProvider(companyId: widget.companyId);
    _provider.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      if (_provider.isLoading.value) {
        return const AppLoadingState(message: 'Loading company...');
      }

      if (_provider.error.value != null) {
        return AppErrorState(
          message: _provider.error.value!,
          onRetry: () => _provider.loadAll(),
        );
      }

      final profile = _provider.profile.value;
      if (profile == null) {
        return const AppEmptyState(
          icon: Icons.business_outlined,
          title: 'Company not found',
        );
      }

      return Column(
        children: [
          _buildHeader(profile),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      );
    });
  }

  Widget _buildHeader(CompanyProfile profile) {
    final quality = _provider.qualityScore.value;
    final freshness = _provider.freshnessStatus.value;
    final researchStatus = _provider.researchStatus;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(profile.displayName, style: AppTypography.heading),
                        if (profile.ticker != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppThemeColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(profile.ticker!, style: AppTypography.monoLabel),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (profile.sector != null) profile.sector,
                        if (profile.domicileCountryCode != null) profile.domicileCountryCode,
                      ].join(' · '),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      if (quality != null) QualityBadge(score: quality),
                      if (freshness != null) FreshnessBadge(status: _mapFreshness(freshness)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ResearchStatusBadge(status: ResearchStatus.fromString(researchStatus)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Overview',
            selected: _provider.activeTab.value == 0,
            onTap: () => _provider.activeTab.value = 0,
          ),
          _TabButton(
            label: 'Financials',
            selected: _provider.activeTab.value == 1,
            onTap: () => _provider.activeTab.value = 1,
          ),
          _TabButton(
            label: 'Research',
            selected: _provider.activeTab.value == 2,
            onTap: () => _provider.activeTab.value = 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_provider.activeTab.value) {
      case 0:
        return OverviewTab(provider: _provider);
      case 1:
        return FinancialsTab(provider: _provider);
      case 2:
        return ResearchTab(provider: _provider);
      default:
        return const SizedBox.shrink();
    }
  }

  FreshnessStatus _mapFreshness(String? status) {
    switch (status) {
      case 'fresh':
        return FreshnessStatus.fresh;
      case 'aging':
        return FreshnessStatus.aging;
      case 'stale':
        return FreshnessStatus.stale;
      case 'expired':
        return FreshnessStatus.expired;
      default:
        return FreshnessStatus.unknown;
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppThemeColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppThemeColors.textPrimary : AppThemeColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
