import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../data/portfolio_models.dart';
import '../providers/portfolio_workspace_provider.dart';

class PortfolioWorkspacePage extends StatefulWidget {
  const PortfolioWorkspacePage({super.key});

  @override
  State<PortfolioWorkspacePage> createState() => _PortfolioWorkspacePageState();
}

class _PortfolioWorkspacePageState extends State<PortfolioWorkspacePage> {
  late final PortfolioProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = PortfolioProvider();
    _provider.loadPositions();
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
    return Watch((_) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
        ),
        child: Row(
          children: [
            const Text('Portfolio', style: AppTypography.heading),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppThemeColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${_provider.activeCount} active', style: AppTypography.monoLabel.copyWith(color: AppThemeColors.accent)),
            ),
            if (_provider.reviewCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppThemeColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${_provider.reviewCount} review', style: AppTypography.monoLabel.copyWith(color: AppThemeColors.warning)),
              ),
            ],
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppThemeColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${_provider.closedCount} closed', style: AppTypography.monoLabel),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showAddPositionDialog(context),
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
    return Watch((_) {
      return Container(
        height: 36,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
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
          ],
        ),
      );
    });
  }

  Widget _buildContent() {
    return Watch((_) {
      if (_provider.isLoading.value) {
        return const AppLoadingState(message: 'Loading portfolio...');
      }

      return _provider.activeTab.value == 0
          ? _buildActiveView()
          : _buildClosedView();
    });
  }

  Widget _buildActiveView() {
    return Watch((_) {
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
        padding: const EdgeInsets.all(16),
        itemCount: positions.length,
        itemBuilder: (context, index) {
          return _ActivePositionCard(
            position: positions[index],
            onClose: () => _showClosePositionDialog(context, positions[index]),
            onViewCompany: () => context.go('/companies/${positions[index].companyId}'),
          );
        },
      );
    });
  }

  Widget _buildClosedView() {
    return Watch((_) {
      final positions = _provider.closedPositions;

      if (positions.isEmpty) {
        return const AppEmptyState(
          icon: Icons.history,
          title: 'No closed positions',
          description: 'Closed positions and their outcomes will appear here.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: positions.length,
        itemBuilder: (context, index) {
          return _ClosedPositionCard(
            position: positions[index],
            onViewCompany: () => context.go('/companies/${positions[index].companyId}'),
          );
        },
      );
    });
  }

  void _showAddPositionDialog(BuildContext context) {
    final entryPriceController = TextEditingController();
    final notesController = TextEditingController();
    String conviction = 'low';
    DateTime entryDate = DateTime.now();
    String? selectedCompanyId;
    String? selectedCompanyName;
    String? selectedThesisId;
    String? selectedThesisTitle;
    List<Map<String, dynamic>> availableTheses = [];
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];

    // Fetch theses for selected company
    Future<void> fetchTheses(String companyId) async {
      try {
        final client = Supabase.instance.client;
        final response = await client
            .from('theses')
            .select('id, title, stance, conviction')
            .eq('company_id', companyId)
            .eq('status', 'active')
            .order('created_at', ascending: false);
        availableTheses = List<Map<String, dynamic>>.from(response as List);
      } catch (e) {
        debugPrint('[Portfolio] Fetch theses error: $e');
        availableTheses = [];
      }
    }

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
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedCompanyId = null;
                                selectedCompanyName = null;
                                selectedThesisId = null;
                                selectedThesisTitle = null;
                                availableTheses = [];
                              });
                            },
                            child: const Icon(Icons.close, size: 16, color: AppThemeColors.textTertiary),
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
                            try {
                              final client = Supabase.instance.client;
                              final response = await client
                                  .from('companies')
                                  .select('id, display_name')
                                  .ilike('display_name', '%$query%')
                                  .limit(5);
                              setDialogState(() {
                                searchResults = List<Map<String, dynamic>>.from(response as List);
                              });
                            } catch (e) {
                              debugPrint('[Portfolio] Company search error: $e');
                              setDialogState(() => searchResults = []);
                            }
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
                                    selectedThesisTitle = null;
                                  });
                                  await fetchTheses(companyId);
                                  setDialogState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        hint: Text('Link to a thesis...', style: AppTypography.caption),
                        items: availableTheses.map((t) {
                          final stance = t['stance'] as String? ?? 'neutral';
                          final title = t['title'] as String;
                          return DropdownMenuItem<String>(
                            value: t['id'] as String,
                            child: Row(
                              children: [
                                Expanded(child: Text(title, style: AppTypography.body, overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                _StanceChipSmall(stance: stance),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          final thesis = availableTheses.firstWhere((t) => t['id'] == id);
                          setDialogState(() {
                            selectedThesisId = id;
                            selectedThesisTitle = thesis['title'] as String;
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

class _ActivePositionCard extends StatelessWidget {
  final PortfolioPosition position;
  final VoidCallback onClose;
  final VoidCallback onViewCompany;

  const _ActivePositionCard({
    required this.position,
    required this.onClose,
    required this.onViewCompany,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
              if (position.isReviewNeeded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppThemeColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Review Needed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppThemeColors.warning)),
                ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: AppThemeColors.textSecondary),
                onSelected: (value) {
                  if (value == 'view') onViewCompany();
                  if (value == 'close') onClose();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Company')),
                  const PopupMenuItem(value: 'close', child: Text('Close Position')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ConvictionChip(conviction: position.conviction),
              const SizedBox(width: 8),
              if (position.thesisTitle != null) ...[
                const Icon(Icons.lightbulb_outline, size: 12, color: AppThemeColors.textTertiary),
                const SizedBox(width: 4),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Entry: ${_formatDate(position.entryDate)}',
                style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
              ),
              if (position.entryPrice != null) ...[
                const SizedBox(width: 12),
                Text(
                  'Price: \$${position.entryPrice!.toStringAsFixed(2)}',
                  style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                ),
              ],
            ],
          ),
          if (position.notes != null && position.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(position.notes!, style: AppTypography.caption),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
          Row(
            children: [
              Text(
                'Entry: ${_formatDate(position.entryDate)}',
                style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
              ),
              if (position.exitDate != null) ...[
                const SizedBox(width: 12),
                Text(
                  'Exit: ${_formatDate(position.exitDate!)}',
                  style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                ),
              ],
            ],
          ),
          if (position.lessonsLearned != null && position.lessonsLearned!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Lessons:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
            Text(position.lessonsLearned!, style: AppTypography.caption),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        conviction[0].toUpperCase() + conviction.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _StanceChipSmall extends StatelessWidget {
  final String stance;

  const _StanceChipSmall({required this.stance});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (stance) {
      case 'bullish':
        color = AppThemeColors.success;
        break;
      case 'bearish':
        color = AppThemeColors.critical;
        break;
      default:
        color = AppThemeColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        stance[0].toUpperCase() + stance.substring(1),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
