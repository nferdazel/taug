import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/models/price_data.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../../../shared/widgets/status_badges.dart';
import '../../data/portfolio_models.dart';
import '../providers/portfolio_workspace_provider.dart';

class PortfolioWorkspacePage extends StatefulWidget {
  const PortfolioWorkspacePage({super.key});

  @override
  State<PortfolioWorkspacePage> createState() => _PortfolioWorkspacePageState();
}

class _PortfolioWorkspacePageState extends State<PortfolioWorkspacePage> {
  late final PortfolioWorkspaceProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = PortfolioWorkspaceProvider();
    _provider.loadPositions();
    _provider.loadPatterns();

    // Auto-open Add Position dialog if pre-population params are present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final params = GoRouterState.of(context).uri.queryParameters;
      if (params.containsKey('companyId') && params['companyId']!.isNotEmpty) {
        _showAddPositionDialog(
          preCompanyId: params['companyId'],
          preCompanyName: params['companyName'],
          preThesisId: params['thesisId'],
          preThesisTitle: params['thesisTitle'],
          preConviction: params['conviction'],
        );
      }
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return SignalBuilder(builder: (_) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.xl),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border)),
        ),
        child: Row(
          children: [
            const Text('Portfolio', style: AppTypography.heading),
            const SizedBox(width: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppThemeColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${_provider.activeCount} active', style: AppTypography.monoLabel.copyWith(color: AppThemeColors.accent)),
            ),
            if (_provider.reviewCount > 0) ...[
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppThemeColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${_provider.reviewCount} review', style: AppTypography.monoLabel.copyWith(color: AppThemeColors.warning)),
              ),
            ],
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppThemeColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${_provider.closedCount} closed', style: AppTypography.monoLabel),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showAddPositionDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Position'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeColors.accent,
                foregroundColor: AppThemeColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabBar() {
    return SignalBuilder(builder: (_) {
      return Container(
        height: 36,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border)),
        ),
        child: Row(
          children: [
            _TabButton(
              label: 'Active (${_provider.activeCount})',
              selected: _provider.activeTab.value == 0,
              onTap: () => _provider.activeTab.value = 0,
            ),
            _TabButton(
              label: 'Closed (${_provider.closedCount})',
              selected: _provider.activeTab.value == 1,
              onTap: () => _provider.activeTab.value = 1,
            ),
            _TabButton(
              label: 'Lessons',
              selected: _provider.activeTab.value == 2,
              onTap: () => _provider.activeTab.value = 2,
            ),
            _TabButton(
              label: 'Patterns',
              selected: _provider.activeTab.value == 3,
              onTap: () => _provider.activeTab.value = 3,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildContent() {
    return SignalBuilder(builder: (_) {
      if (_provider.isLoading.value) {
        return const AppLoadingState(message: 'Loading portfolio...');
      }

      switch (_provider.activeTab.value) {
        case 0:
          return _buildActiveView();
        case 1:
          return _buildClosedView();
        case 2:
          return _buildLessonsView();
        case 3:
          return _buildPatternsView();
        default:
          return _buildActiveView();
      }
    });
  }

  Widget _buildActiveView() {
    return SignalBuilder(builder: (_) {
      final positions = _provider.activePositions;

      if (positions.isEmpty) {
        return const AppEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'No active positions',
          description: 'Start by researching companies and creating theses. Then add positions to track your investment decisions.',
          actionLabel: 'Browse Companies',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        itemCount: positions.length,
        itemExtent: 120,
        itemBuilder: (context, index) {
          final pos = positions[index];
          return _ActivePositionCard(
            position: pos,
            currentPrice: _provider.getPriceForTicker(pos.ticker),
            onClose: () => _showClosePositionDialog(context, pos),
            onViewCompany: () => context.go('/companies/${pos.companyId}'),
            onMarkReview: () => _provider.markReviewNeeded(pos.id),
          );
        },
      );
    });
  }

  Widget _buildClosedView() {
    return SignalBuilder(builder: (_) {
      final positions = _provider.closedPositions;

      if (positions.isEmpty) {
        return const AppEmptyState(
          icon: Icons.history,
          title: 'No closed positions',
          description: 'Closed positions and their outcomes will appear here.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        itemCount: positions.length,
        itemExtent: 120,
        itemBuilder: (context, index) {
          return _ClosedPositionCard(
            position: positions[index],
            onViewCompany: () => context.go('/companies/${positions[index].companyId}'),
          );
        },
      );
    });
  }

  Widget _buildLessonsView() {
    return SignalBuilder(builder: (_) {
      final closedPositions = _provider.closedPositions;
      final positionsWithLessons = closedPositions
          .where((p) => p.lessonsLearned != null && p.lessonsLearned!.isNotEmpty)
          .toList();

      if (positionsWithLessons.isEmpty) {
        return const AppEmptyState(
          icon: Icons.school_outlined,
          title: 'No lessons yet',
          description: 'Close positions with lessons learned to build your investment knowledge base.',
        );
      }

      // Group by outcome
      final correctLessons = positionsWithLessons.where((p) => p.outcome == PositionOutcome.correct).toList();
      final incorrectLessons = positionsWithLessons.where((p) => p.outcome == PositionOutcome.incorrect).toList();
      final partialLessons = positionsWithLessons.where((p) => p.outcome == PositionOutcome.partial).toList();

      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppThemeColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppThemeColors.border),
            ),
            child: Row(
              children: [
                _LessonSummaryChip(
                  label: 'Correct',
                  count: correctLessons.length,
                  color: AppThemeColors.success,
                ),
                const SizedBox(width: AppSpacing.lg),
                _LessonSummaryChip(
                  label: 'Incorrect',
                  count: incorrectLessons.length,
                  color: AppThemeColors.critical,
                ),
                const SizedBox(width: AppSpacing.lg),
                _LessonSummaryChip(
                  label: 'Partial',
                  count: partialLessons.length,
                  color: AppThemeColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Correct lessons
          if (correctLessons.isNotEmpty) ...[
            const Text('FROM CORRECT DECISIONS', style: AppTypography.monoSection),
            const SizedBox(height: AppSpacing.lg),
            ...correctLessons.map((p) => _LessonCard(
              position: p,
              onViewCompany: () => context.go('/companies/${p.companyId}'),
              onNewResearch: () => context.go('/companies/${p.companyId}/research'),
            )),
            const SizedBox(height: AppSpacing.xxl),
          ],

          // Incorrect lessons
          if (incorrectLessons.isNotEmpty) ...[
            const Text('FROM INCORRECT DECISIONS', style: AppTypography.monoSection),
            const SizedBox(height: AppSpacing.lg),
            ...incorrectLessons.map((p) => _LessonCard(
              position: p,
              onViewCompany: () => context.go('/companies/${p.companyId}'),
              onNewResearch: () => context.go('/companies/${p.companyId}/research'),
            )),
            const SizedBox(height: AppSpacing.xxl),
          ],

          // Partial lessons
          if (partialLessons.isNotEmpty) ...[
            const Text('FROM PARTIAL DECISIONS', style: AppTypography.monoSection),
            const SizedBox(height: AppSpacing.lg),
            ...partialLessons.map((p) => _LessonCard(
              position: p,
              onViewCompany: () => context.go('/companies/${p.companyId}'),
              onNewResearch: () => context.go('/companies/${p.companyId}/research'),
            )),
          ],
        ],
      );
    });
  }

  // ── PATTERNS TAB ──

  Widget _buildPatternsView() {
    return SignalBuilder(builder: (_) {
      final stats = _provider.overallStats.value;

      if (stats.isEmpty || stats['total'] == 0) {
        return const AppEmptyState(
          icon: Icons.insights_outlined,
          title: 'No patterns yet',
          description: 'Close positions with outcomes to build your pattern intelligence.',
        );
      }

      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          _buildPatternsPanel(),
        ],
      );
    });
  }

  Widget _buildPatternsPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('YOUR PATTERNS', style: AppTypography.monoSection),
          const SizedBox(height: AppSpacing.xl),
          _buildStanceAccuracy(),
          const SizedBox(height: AppSpacing.xl),
          _buildConvictionAccuracy(),
          const SizedBox(height: AppSpacing.xl),
          _buildCommonThemes(),
          const SizedBox(height: AppSpacing.xl),
          _buildHoldingPeriods(),
          const SizedBox(height: AppSpacing.xl),
          _buildOverallStats(),
        ],
      ),
    );
  }

  Widget _buildStanceAccuracy() {
    final stance = _provider.stanceAccuracy.value;
    if (stance.isEmpty) return const SizedBox.shrink();

    final stances = ['bullish', 'bearish', 'neutral'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in stances) ...[
          if (stance.containsKey('${s}_correct') ||
              stance.containsKey('${s}_incorrect') ||
              stance.containsKey('${s}_partial'))
            _buildAccuracyRow(
              label: '${s[0].toUpperCase()}${s.substring(1)} Theses',
              correct: stance['${s}_correct'] ?? 0,
              incorrect: stance['${s}_incorrect'] ?? 0,
              partial: stance['${s}_partial'] ?? 0,
            ),
        ],
      ],
    );
  }

  Widget _buildConvictionAccuracy() {
    final conviction = _provider.convictionAccuracy.value;
    if (conviction.isEmpty) return const SizedBox.shrink();

    final levels = ['high', 'medium', 'low'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in levels) ...[
          if (conviction.containsKey('${c}_correct') ||
              conviction.containsKey('${c}_incorrect') ||
              conviction.containsKey('${c}_partial'))
            _buildAccuracyRow(
              label: '${c[0].toUpperCase()}${c.substring(1)} Conviction',
              correct: conviction['${c}_correct'] ?? 0,
              incorrect: conviction['${c}_incorrect'] ?? 0,
              partial: conviction['${c}_partial'] ?? 0,
            ),
        ],
      ],
    );
  }

  Widget _buildAccuracyRow({
    required String label,
    required int correct,
    required int incorrect,
    required int partial,
  }) {
    final total = correct + incorrect + partial;
    if (total == 0) return const SizedBox.shrink();
    final pct = ((correct / total) * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.body),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: _accuracyColor(pct).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$pct% correct ($correct/$total)',
              style: AppTypography.monoData.copyWith(color: _accuracyColor(pct)),
            ),
          ),
        ],
      ),
    );
  }

  Color _accuracyColor(int pct) {
    if (pct >= 70) return AppThemeColors.success;
    if (pct >= 50) return AppThemeColors.warning;
    return AppThemeColors.critical;
  }

  Widget _buildCommonThemes() {
    final themes = _provider.commonThemes.value;
    if (themes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COMMON LESSONS', style: AppTypography.monoSection),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: themes.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppThemeColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppThemeColors.accent.withValues(alpha: 0.3)),
            ),
            child: Text(t, style: AppTypography.monoLabel.copyWith(color: AppThemeColors.accent)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildHoldingPeriods() {
    final holding = _provider.holdingPeriodStats.value;
    if (holding.isEmpty) return const SizedBox.shrink();

    final correctDays = holding['correct_avg'] ?? 0;
    final incorrectDays = holding['incorrect_avg'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HOLDING PERIODS', style: AppTypography.monoSection),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Text('Avg Holding (Correct): ', style: AppTypography.caption),
            Text(
              '${correctDays.round()} days',
              style: AppTypography.monoData.copyWith(color: AppThemeColors.success),
            ),
            const SizedBox(width: AppSpacing.xxl),
            const Text('Avg Holding (Incorrect): ', style: AppTypography.caption),
            Text(
              '${incorrectDays.round()} days',
              style: AppTypography.monoData.copyWith(color: AppThemeColors.critical),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverallStats() {
    final stats = _provider.overallStats.value;
    if (stats.isEmpty) return const SizedBox.shrink();

    final total = stats['total'] ?? 0;
    final correct = stats['correct'] ?? 0;
    final partial = stats['partial'] ?? 0;
    final pct = total > 0 ? ((correct / total) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OVERALL', style: AppTypography.monoSection),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Text('Win Rate: ', style: AppTypography.caption),
            Text(
              '$pct% ($correct/$total)',
              style: AppTypography.monoData.copyWith(color: _accuracyColor(pct)),
            ),
            const SizedBox(width: AppSpacing.xxl),
            const Text('Partial: ', style: AppTypography.caption),
            Text(
              '$partial',
              style: AppTypography.monoData.copyWith(color: AppThemeColors.warning),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddPositionDialog({
    String? preCompanyId,
    String? preCompanyName,
    String? preThesisId,
    String? preThesisTitle,
    String? preConviction,
  }) async {
    final entryPriceController = TextEditingController();
    final notesController = TextEditingController();
    String conviction = preConviction ?? 'low';
    DateTime entryDate = DateTime.now();
    String? selectedCompanyId = preCompanyId;
    String? selectedCompanyName = preCompanyName;
    String? selectedThesisId = preThesisId;
    List<Map<String, dynamic>> availableTheses = [];
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];

    // Pre-fetch theses if company is pre-selected so dialog opens with data
    if (preCompanyId != null && preCompanyId.isNotEmpty) {
      availableTheses = await _provider.getActiveThesesForCompany(preCompanyId);
    }

    // Fetch theses for selected company
    Future<void> fetchTheses(String companyId) async {
      availableTheses = await _provider.getActiveThesesForCompany(companyId);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppThemeColors.surface,
          title: const Text('Add Position', style: AppTypography.heading),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  if (selectedCompanyId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppThemeColors.accent),
                        borderRadius: BorderRadius.circular(4),
                        color: AppThemeColors.surfaceMuted,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(selectedCompanyName ?? selectedCompanyId!, style: AppTypography.body)),
                          Semantics(
                            button: true,
                            label: 'Clear selected company',
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedCompanyId = null;
                                  selectedCompanyName = null;
                                  selectedThesisId = null;
                                  availableTheses = [];
                                });
                              },
                              focusColor: AppThemeColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.close, size: 16, color: AppThemeColors.textTertiary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        TextField(
                          controller: searchController,
                          style: AppTypography.body,
                          decoration: const InputDecoration(
                            hintText: 'Search by company name or ticker...',
                            hintStyle: AppTypography.caption,
                            border: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.accent)),
                            filled: true,
                            fillColor: AppThemeColors.surfaceMuted,
                          ),
                          onChanged: (query) async {
                            if (query.length < 2) {
                              setDialogState(() => searchResults = []);
                              return;
                            }
                            final results = await _provider.searchCompanies(query);
                            setDialogState(() {
                              searchResults = results;
                            });
                          },
                        ),
                        if (searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppThemeColors.border),
                              borderRadius: BorderRadius.circular(4),
                              color: AppThemeColors.surface,
                            ),
                            child: Column(
                              children: searchResults.map((r) => InkWell(
                                onTap: () async {
                                  final companyId = r['id'] as String;
                                  final companyName = r['display_name'] as String;
                                  setDialogState(() {
                                    selectedCompanyId = companyId;
                                    selectedCompanyName = companyName;
                                    searchResults = [];
                                    searchController.clear();
                                     selectedThesisId = null;
                                   });
                                  await fetchTheses(companyId);
                                  setDialogState(() {});
                                },
                                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppThemeColors.border.withValues(alpha: 0.5))),
                                  ),
                                  child: Text(r['display_name'] as String, style: AppTypography.body),
                                ),
                              )).toList(),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  // Thesis selector (if company selected and has theses)
                  if (selectedCompanyId != null && availableTheses.isNotEmpty) ...[
                    const Text('Thesis (optional)', style: AppTypography.caption),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppThemeColors.border),
                        borderRadius: BorderRadius.circular(4),
                        color: AppThemeColors.surfaceMuted,
                      ),
                      child: DropdownButton<String>(
                        value: selectedThesisId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppThemeColors.surface,
                        hint: const Text('Link to a thesis...', style: AppTypography.caption),
                        items: availableTheses.map((t) {
                          final stance = t['stance'] as String? ?? 'neutral';
                          final title = t['title'] as String;
                          return DropdownMenuItem<String>(
                            value: t['id'] as String,
                            child: Row(
                              children: [
                                Expanded(child: Text(title, style: AppTypography.body, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                StanceBadge(stance: stance, size: StanceBadgeSize.small),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          final thesis = availableTheses.firstWhere((t) => t['id'] == id);
                          setDialogState(() {
                            selectedThesisId = id;
                            // Auto-populate conviction from thesis
                            final thesisConviction = thesis['conviction'] as String?;
                            if (thesisConviction != null && ['low', 'medium', 'high'].contains(thesisConviction)) {
                              conviction = thesisConviction;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text('Conviction', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  Row(
                    children: ['low', 'medium', 'high'].map((c) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ChoiceChip(
                        label: Text(c[0].toUpperCase() + c.substring(1)),
                        selected: conviction == c,
                        onSelected: (selected) {
                          if (selected) setDialogState(() => conviction = c);
                        },
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Entry Date', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: entryDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setDialogState(() => entryDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppThemeColors.border),
                        borderRadius: BorderRadius.circular(4),
                        color: AppThemeColors.surfaceMuted,
                      ),
                      child: Text(
                        '${entryDate.year}-${entryDate.month.toString().padLeft(2, '0')}-${entryDate.day.toString().padLeft(2, '0')}',
                        style: AppTypography.body,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Entry Price (optional)', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  TextField(
                    controller: entryPriceController,
                    style: AppTypography.body,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 150.00',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.accent)),
                      filled: true,
                      fillColor: AppThemeColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Notes (optional)', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  TextField(
                    controller: notesController,
                    style: AppTypography.body,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Why are you making this decision?',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.accent)),
                      filled: true,
                      fillColor: AppThemeColors.surfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppThemeColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCompanyId == null || selectedCompanyId!.isEmpty) return;
                _provider.addPosition(
                  companyId: selectedCompanyId!,
                  thesisId: selectedThesisId,
                  conviction: conviction,
                  entryDate: entryDate,
                  entryPrice: double.tryParse(entryPriceController.text),
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                Navigator.pop(context);
                if (context.mounted) showSuccessSnackBar(context, 'Position added');
              },
              child: const Text('Add Position'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClosePositionDialog(BuildContext context, PortfolioPosition position) {
    String outcome = 'correct';
    final lessonsController = TextEditingController();
    final exitPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppThemeColors.surface,
          title: const Text('Close Position', style: AppTypography.heading),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Outcome', style: AppTypography.caption),
                const SizedBox(height: 4),
                Row(
                  children: ['correct', 'incorrect', 'partial'].map((o) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(o[0].toUpperCase() + o.substring(1)),
                      selected: outcome == o,
                      onSelected: (selected) {
                        if (selected) setDialogState(() => outcome = o);
                      },
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Exit Price (optional)', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextField(
                  controller: exitPriceController,
                  style: AppTypography.body,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 175.00',
                    hintStyle: AppTypography.caption,
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.accent)),
                    filled: true,
                    fillColor: AppThemeColors.surfaceMuted,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Lessons Learned (optional)', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextField(
                  controller: lessonsController,
                  style: AppTypography.body,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'What did you learn from this decision?',
                    hintStyle: AppTypography.caption,
                    border: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.border)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppThemeColors.accent)),
                    filled: true,
                    fillColor: AppThemeColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppThemeColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                _provider.closePosition(
                  positionId: position.id,
                  outcome: outcome,
                  lessonsLearned: lessonsController.text.isNotEmpty ? lessonsController.text : null,
                  exitPrice: double.tryParse(exitPriceController.text),
                );
                Navigator.pop(context);
                if (context.mounted) showSuccessSnackBar(context, 'Position closed');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppThemeColors.critical),
              child: const Text('Close Position'),
            ),
          ],
        ),
      ),
    );
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
    return Semantics(
      button: true,
      selected: selected,
      label: '$label tab',
      child: InkWell(
        onTap: onTap,
        focusColor: AppThemeColors.accent.withValues(alpha: 0.2),
        highlightColor: AppThemeColors.accent.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
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
      ),
    );
  }
}

class _ActivePositionCard extends StatelessWidget {
  final PortfolioPosition position;
  final VoidCallback onClose;
  final VoidCallback onViewCompany;
  final VoidCallback onMarkReview;
  final PriceData? currentPrice;

  const _ActivePositionCard({
    required this.position,
    required this.onClose,
    required this.onViewCompany,
    required this.onMarkReview,
    this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    final daysHeld = DateTime.now().difference(position.entryDate).inDays;
    final double? unrealizedPnl;
    if (position.entryPrice != null &&
        position.entryPrice! > 0 &&
        currentPrice != null) {
      unrealizedPnl =
          ((currentPrice!.price - position.entryPrice!) / position.entryPrice!) *
              100;
    } else {
      unrealizedPnl = null;
    }

    final pnlText = unrealizedPnl != null
        ? ', P&L ${unrealizedPnl >= 0 ? '+' : ''}${unrealizedPnl.toStringAsFixed(2)} percent'
        : '';
    final statusText = position.isReviewNeeded ? ', review needed' : '';
    final semanticsLabel = '${position.companyName ?? 'Unknown Company'}'
        '${position.ticker != null ? ' ${position.ticker}' : ''}'
        '$pnlText'
        '$statusText';

    return Semantics(
      label: semanticsLabel,
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: position.isReviewNeeded ? AppThemeColors.warning : AppThemeColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.companyName ?? 'Unknown Company',
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (position.ticker != null)
                      Text(position.ticker!, style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary)),
                  ],
                ),
              ),
              if (unrealizedPnl != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
                  decoration: BoxDecoration(
                    color: (unrealizedPnl >= 0
                            ? AppThemeColors.success
                            : AppThemeColors.critical)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${unrealizedPnl >= 0 ? '+' : ''}${unrealizedPnl.toStringAsFixed(2)}%',
                    style: AppTypography.monoLabel.copyWith(
                      color: unrealizedPnl >= 0
                          ? AppThemeColors.success
                          : AppThemeColors.critical,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (position.isReviewNeeded) ...[
                const SizedBox(width: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppThemeColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Review Needed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppThemeColors.warning)),
                ),
              ],
              const SizedBox(width: AppSpacing.lg),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: AppThemeColors.textSecondary),
                tooltip: 'Position actions',
                onSelected: (value) {
                  if (value == 'view') onViewCompany();
                  if (value == 'close') onClose();
                  if (value == 'review') onMarkReview();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Company')),
                  if (!position.isReviewNeeded)
                    const PopupMenuItem(value: 'review', child: Text('Mark for Review')),
                  const PopupMenuItem(value: 'close', child: Text('Close Position')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _ConvictionChip(conviction: position.conviction),
              const SizedBox(width: AppSpacing.lg),
              if (position.thesisTitle != null) ...[
                const Icon(Icons.lightbulb_outline, size: 12, color: AppThemeColors.textTertiary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    position.thesisTitle!,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                'Entry: ${position.entryDate.toYyyyMmDd()}',
                style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
              ),
              const SizedBox(width: AppSpacing.xl),
              Text(
                '${daysHeld}d held',
                style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
              ),
              if (position.entryPrice != null) ...[
                const SizedBox(width: AppSpacing.xl),
                Text(
                  '@ \$${position.entryPrice!.toStringAsFixed(2)}',
                  style: AppTypography.monoLabel.copyWith(color: AppThemeColors.textTertiary),
                ),
              ],
              if (currentPrice != null) ...[
                const SizedBox(width: AppSpacing.xl),
                Text(
                  'Now: \$${currentPrice!.price.toStringAsFixed(2)}',
                  style: AppTypography.monoLabel.copyWith(color: AppThemeColors.textPrimary),
                ),
              ],
            ],
          ),
          if (position.isReviewNeeded) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Review needed — position flagged for attention',
              style: AppTypography.caption.copyWith(color: AppThemeColors.warning),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _ClosedPositionCard extends StatelessWidget {
  final PortfolioPosition position;
  final VoidCallback onViewCompany;

  const _ClosedPositionCard({
    required this.position,
    required this.onViewCompany,
  });

  @override
  Widget build(BuildContext context) {
    final outcomeText = position.outcome != null
        ? ', outcome: ${position.outcome!.name}'
        : '';
    final returnText = position.returnPercent != null
        ? ', return: ${position.returnPercent! >= 0 ? '+' : ''}${position.returnPercent!.toStringAsFixed(1)} percent'
        : '';
    final semanticsLabel = '${position.companyName ?? 'Unknown Company'}'
        '$outcomeText'
        '$returnText';

    return Semantics(
      label: semanticsLabel,
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  position.companyName ?? 'Unknown Company',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              if (position.returnPercent != null) ...[
                _ReturnBadge(returnPercent: position.returnPercent!),
                const SizedBox(width: AppSpacing.lg),
              ],
              if (position.outcome != null) _OutcomeBadge(outcome: position.outcome!),
              const SizedBox(width: AppSpacing.lg),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 16, color: AppThemeColors.textSecondary),
                onPressed: onViewCompany,
                tooltip: 'View Company',
              ),
            ],
          ),
          if (position.thesisTitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(position.thesisTitle!, style: AppTypography.caption),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                'Entry: ${position.entryDate.toYyyyMmDd()}',
                style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
              ),
              if (position.exitDate != null) ...[
                const SizedBox(width: AppSpacing.xl),
                Text(
                  'Exit: ${position.exitDate!.toYyyyMmDd()}',
                  style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                ),
              ],
            ],
          ),
          if (position.lessonsLearned != null && position.lessonsLearned!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Lessons:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
            Text(position.lessonsLearned!, style: AppTypography.caption),
          ],
        ],
      ),
      ),
    );
  }
}

class _ConvictionChip extends StatelessWidget {
  final String conviction;

  const _ConvictionChip({required this.conviction});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (conviction) {
      case 'high':
        color = AppThemeColors.accent;
        break;
      case 'medium':
        color = AppThemeColors.warning;
        break;
      default:
        color = AppThemeColors.textTertiary;
    }

    return Semantics(
      label: 'Conviction: ${conviction[0].toUpperCase()}${conviction.substring(1)}',
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        conviction[0].toUpperCase() + conviction.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
      ),
    );
  }
}

class _OutcomeBadge extends StatelessWidget {
  final PositionOutcome outcome;

  const _OutcomeBadge({required this.outcome});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (outcome) {
      case PositionOutcome.correct:
        color = AppThemeColors.success;
        label = 'Correct';
      case PositionOutcome.incorrect:
        color = AppThemeColors.critical;
        label = 'Incorrect';
      case PositionOutcome.partial:
        color = AppThemeColors.warning;
        label = 'Partial';
    }

    return Semantics(
      label: 'Outcome: $label',
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

class _ReturnBadge extends StatelessWidget {
  final double returnPercent;

  const _ReturnBadge({required this.returnPercent});

  @override
  Widget build(BuildContext context) {
    final isPositive = returnPercent >= 0;
    final color = isPositive ? AppThemeColors.success : AppThemeColors.critical;
    final prefix = isPositive ? '+' : '';

    return Semantics(
      label: 'Return: $prefix${returnPercent.toStringAsFixed(2)} percent',
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$prefix${returnPercent.toStringAsFixed(2)}%',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
      ),
    );
  }
}

class _LessonSummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _LessonSummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final PortfolioPosition position;
  final VoidCallback onViewCompany;
  final VoidCallback onNewResearch;

  const _LessonCard({
    required this.position,
    required this.onViewCompany,
    required this.onNewResearch,
  });

  @override
  Widget build(BuildContext context) {
    final outcomeText = position.outcome != null
        ? ', ${position.outcome!.name}'
        : '';
    final returnText = position.returnPercent != null
        ? ', return: ${position.returnPercent! >= 0 ? '+' : ''}${position.returnPercent!.toStringAsFixed(1)} percent'
        : '';
    final lessonPreview = position.lessonsLearned != null && position.lessonsLearned!.isNotEmpty
        ? ', lesson: ${position.lessonsLearned!.length > 80 ? position.lessonsLearned!.substring(0, 80) : position.lessonsLearned}'
        : '';
    final semanticsLabel = '${position.companyName ?? 'Unknown Company'}'
        '$outcomeText'
        '$returnText'
        '$lessonPreview';

    return Semantics(
      label: semanticsLabel,
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  position.companyName ?? 'Unknown Company',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              if (position.returnPercent != null) ...[
                _ReturnBadge(returnPercent: position.returnPercent!),
                const SizedBox(width: 8),
              ],
              if (position.outcome != null) _OutcomeBadge(outcome: position.outcome!),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 16, color: AppThemeColors.textSecondary),
                onPressed: onViewCompany,
                tooltip: 'View Company',
              ),
            ],
          ),
          if (position.thesisTitle != null) ...[
            const SizedBox(height: 4),
            Text(position.thesisTitle!, style: AppTypography.caption),
          ],
          const SizedBox(height: 8),
          Text('Lessons:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(position.lessonsLearned!, style: AppTypography.body),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: OutlinedButton.icon(
              onPressed: onNewResearch,
              icon: const Icon(Icons.science_outlined, size: 14),
              label: const Text('Apply to New Research'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemeColors.accent,
                side: const BorderSide(color: AppThemeColors.accent),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
