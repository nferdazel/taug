import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../../../shared/widgets/status_badges.dart';
import '../../data/company_list_models.dart';
import '../providers/companies_provider.dart';
import '../widgets/research_status_badge.dart';

class CompaniesWorkspacePage extends StatefulWidget {
  const CompaniesWorkspacePage({super.key});

  @override
  State<CompaniesWorkspacePage> createState() => _CompaniesWorkspacePageState();
}

class _CompaniesWorkspacePageState extends State<CompaniesWorkspacePage> {
  late final CompaniesProvider _provider;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = CompaniesProvider();
    _provider.loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildToolbar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return SignalBuilder(builder: (_) {
      final total = _provider.companies.length;
      final researching = _provider.companies.where((c) => c.researchStatus != 'not_researched').length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
        ),
        child: Row(
          children: [
            const Text('Companies', style: AppTypography.heading),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppThemeColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('$total', style: AppTypography.monoLabel),
            ),
            if (researching > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppThemeColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('$researching researching', style: AppTypography.monoLabel.copyWith(color: AppThemeColors.accent)),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _searchController,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: 'Search by name or ticker...',
                  hintStyle: AppTypography.caption,
                  prefixIcon: const Icon(Icons.search, size: 16),
                  prefixIconColor: AppThemeColors.textTertiary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppThemeColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppThemeColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppThemeColors.accent),
                  ),
                  filled: true,
                  fillColor: AppThemeColors.surfaceMuted,
                ),
                onChanged: (value) => _provider.setSearchQuery(value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SignalBuilder(builder: (_) {
      if (_provider.isLoading.value) {
        return const AppLoadingState(message: 'Loading companies...');
      }

      if (_provider.error.value != null) {
        return AppErrorState(
          message: _provider.error.value!,
          onRetry: () => _provider.loadCompanies(),
        );
      }

      final companies = _provider.filteredCompanies;

      if (companies.isEmpty) {
        if (_provider.searchQuery.value.isNotEmpty) {
          return AppEmptyState(
            icon: Icons.search_off,
            title: 'No results',
            description: 'No companies match "${_provider.searchQuery.value}".',
            actionLabel: 'Clear',
            onAction: () {
              _searchController.clear();
              _provider.setSearchQuery('');
            },
          );
        }
        return const AppEmptyState(
          icon: Icons.business_outlined,
          title: 'No companies',
          description: 'Companies will appear after SEC ingestion.',
        );
      }

      return _buildTable(companies);
    });
  }

  Widget _buildTable(List<CompanyListItem> companies) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: companies.length,
                itemExtent: 44,
                itemBuilder: (context, index) => _buildRow(companies[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppThemeColors.surfaceMuted,
        border: Border(bottom: BorderSide(color: AppThemeColors.border)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Company', style: AppTypography.monoLabel)),
          Expanded(flex: 2, child: Text('Status', style: AppTypography.monoLabel)),
          Expanded(flex: 1, child: Text('Quality', style: AppTypography.monoLabel, textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('Fresh', style: AppTypography.monoLabel, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildRow(CompanyListItem company) {
    final quality = _provider.getQualityScore(company.id);
    final freshness = _provider.getFreshnessStatus(company.id);
    final researchStatus = ResearchStatus.fromString(_provider.getResearchStatus(company));

    return InkWell(
      onTap: () => context.go('/companies/${company.id}'),
      hoverColor: AppThemeColors.surfaceLight.withValues(alpha: 0.5),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.displayName,
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (company.ticker != null)
                    Text(
                      company.ticker!,
                      style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ResearchStatusBadge(status: researchStatus),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: quality != null
                    ? QualityBadge(score: quality)
                    : Text('—', style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary)),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: freshness != null
                    ? FreshnessBadge(status: _mapFreshness(freshness))
                    : Text('—', style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  FreshnessStatus _mapFreshness(String status) {
    switch (status) {
      case 'fresh': return FreshnessStatus.fresh;
      case 'aging': return FreshnessStatus.aging;
      case 'stale': return FreshnessStatus.stale;
      case 'expired': return FreshnessStatus.expired;
      default: return FreshnessStatus.unknown;
    }
  }
}
