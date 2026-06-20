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
    return Watch((_) {
      final total = _provider.companies.length;
      final queueCount = _provider.companies
          .where((c) => c.researchStatus == 'queued')
          .length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Companies', style: AppTypography.heading),
                const SizedBox(height: 2),
                Text(
                  '$total companies available${queueCount > 0 ? ' · $queueCount in research queue' : ''}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  hintText: 'Search companies...',
                  hintStyle: AppTypography.caption,
                  prefixIcon: const Icon(Icons.search, size: 16),
                  prefixIconColor: AppThemeColors.textTertiary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
    return Watch((_) {
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
            title: 'No results found',
            description: 'No companies match "${_provider.searchQuery.value}".',
            actionLabel: 'Clear Search',
            onAction: () {
              _searchController.clear();
              _provider.setSearchQuery('');
            },
          );
        }
        return const AppEmptyState(
          icon: Icons.business_outlined,
          title: 'No companies available',
          description:
              'Companies will appear after the first SEC ingestion completes.',
        );
      }

      return _buildTable(companies);
    });
  }

  Widget _buildTable(List<CompanyListItem> companies) {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 36,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 40,
        columns: const [
          DataColumn(
            label: Text(
              'Company',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text(
              'Quality',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          DataColumn(
            label: Text('Fresh', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
        rows: companies.map((company) => _buildRow(company)).toList(),
      ),
    );
  }

  DataRow _buildRow(CompanyListItem company) {
    final quality = _provider.getQualityScore(company.id);
    final freshness = _provider.getFreshnessStatus(company.id);
    final researchStatus = ResearchStatus.fromString(
      _provider.getResearchStatus(company),
    );

    return DataRow(
      cells: [
        DataCell(
          GestureDetector(
            onTap: () => context.go('/companies/${company.id}'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.displayName,
                  style: AppTypography.body.copyWith(
                    color: AppThemeColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (company.ticker != null)
                  Text(
                    company.ticker!,
                    style: AppTypography.caption.copyWith(
                      color: AppThemeColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        DataCell(ResearchStatusBadge(status: researchStatus)),
        DataCell(
          quality != null
              ? QualityBadge(score: quality)
              : const Text('—', style: AppTypography.caption),
        ),
        DataCell(
          freshness != null
              ? FreshnessBadge(status: _mapFreshness(freshness))
              : const Text('—', style: AppTypography.caption),
        ),
      ],
    );
  }

  FreshnessStatus _mapFreshness(String status) {
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
