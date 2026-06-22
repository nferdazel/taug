import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_state_widgets.dart';
import '../../../../shared/widgets/status_badges.dart';
import '../../../companies/presentation/widgets/research_status_badge.dart';
import '../../data/research_models.dart';
import '../providers/research_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Attention Item Model
// ─────────────────────────────────────────────────────────────────────────────

class _AttentionItem {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final String? companyId;

  const _AttentionItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    this.companyId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Item Model (merged timeline)
// ─────────────────────────────────────────────────────────────────────────────

enum _ActivityType { thesis, note }

class _ActivityItem {
  final _ActivityType type;
  final String id;
  final String title;
  final String companyName;
  final String? ticker;
  final String? subtitle;
  final DateTime updatedAt;
  final String companyId;

  const _ActivityItem({
    required this.type,
    required this.id,
    required this.title,
    required this.companyName,
    this.ticker,
    this.subtitle,
    required this.updatedAt,
    required this.companyId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────────────────────

class ResearchWorkspacePage extends StatefulWidget {
  final ResearchProvider? provider;

  const ResearchWorkspacePage({super.key, this.provider});

  @override
  State<ResearchWorkspacePage> createState() => _ResearchWorkspacePageState();
}

class _ResearchWorkspacePageState extends State<ResearchWorkspacePage> {
  late final ResearchProvider _provider;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? ResearchProvider();
    _provider.loadAll();
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
        Expanded(child: _buildContent()),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return SignalBuilder(builder: (_) {
      final totalResearch = _provider.researchCompanies.length;
      final totalTheses = _provider.theses.length;
      final totalNotes = _provider.notes.length;
      final totalQuestions = _provider.questions.length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
        ),
        child: Row(
          children: [
            const Text('Research', style: AppTypography.heading),
            const SizedBox(width: 12),
            _CounterBadge(label: '$totalResearch companies', color: AppThemeColors.accent),
            const SizedBox(width: 6),
            _CounterBadge(label: '$totalTheses theses', color: AppThemeColors.warning),
            const SizedBox(width: 6),
            _CounterBadge(label: '$totalNotes notes', color: AppThemeColors.textSecondary),
            if (totalQuestions > 0) ...[
              const SizedBox(width: 6),
              _CounterBadge(label: '$totalQuestions questions', color: AppThemeColors.bearish),
            ],
            const Spacer(),
            SizedBox(
              width: 240,
              height: 32,
              child: TextField(
                controller: _searchController,
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: 'Search research...',
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
                onChanged: (v) => _provider.setSearchQuery(v),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Content ─────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return SignalBuilder(builder: (_) {
      if (_provider.isLoading.value) {
        return const AppLoadingState(message: 'Loading research...');
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNeedsAttention(),
            const SizedBox(height: 24),
            _buildActiveResearch(),
            const SizedBox(height: 24),
            _buildOpenQuestions(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      );
    });
  }

  // ── Needs Attention Hero ────────────────────────────────────────────────

  List<_AttentionItem> _computeAttentionItems() {
    final items = <_AttentionItem>[];
    final companies = _provider.filteredCompanies;
    final theses = _provider.filteredTheses;
    final questions = _provider.filteredQuestions;

    // Companies with notes but no thesis — need a thesis
    final needsThesis = companies.where((c) => c.notesCount > 0 && c.thesesCount == 0).toList();
    for (final c in needsThesis) {
      final tickerSuffix = c.ticker != null ? ' (${c.ticker})' : '';
      items.add(_AttentionItem(
        icon: Icons.warning_amber,
        color: AppThemeColors.warning,
        title: '${c.displayName}$tickerSuffix has no thesis',
        subtitle: '${c.notesCount} notes ready to synthesize',
        actionLabel: 'Write Thesis',
        companyId: c.companyId,
      ));
    }

    // Stale theses (>90 days since update)
    final now = DateTime.now();
    final staleThreshold = now.subtract(const Duration(days: 90));
    final staleTheses = theses.where((t) => t.updatedAt.isBefore(staleThreshold)).toList();
    for (final t in staleTheses) {
      final daysOld = now.difference(t.updatedAt).inDays;
      items.add(_AttentionItem(
        icon: Icons.schedule,
        color: AppThemeColors.bearish,
        title: 'Thesis is $daysOld days old',
        subtitle: '${t.title} · ${t.companyName}',
        actionLabel: 'Review',
        companyId: t.companyId,
      ));
    }

    // Critical / High priority open questions
    final criticalQuestions = questions
        .where((q) => q.isOpen && q.isHigh)
        .toList();
    for (final q in criticalQuestions) {
      final color = q.isCritical ? AppThemeColors.critical : AppThemeColors.warning;
      final label = q.isCritical ? 'CRITICAL' : 'HIGH';
      final companyLabel = q.companyName ?? 'Global';
      items.add(_AttentionItem(
        icon: Icons.help_outline,
        color: color,
        title: '[$label] ${q.question}',
        subtitle: '$companyLabel · ${q.daysOpen}d open · ${q.notesCount} notes',
        actionLabel: 'Investigate',
        companyId: q.companyId,
      ));
    }

    return items;
  }

  Widget _buildNeedsAttention() {
    final items = _computeAttentionItems();

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppThemeColors.success.withValues(alpha: 0.1),
          border: const Border(left: BorderSide(color: AppThemeColors.success, width: 3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: AppThemeColors.success),
            SizedBox(width: 8),
            Text('All research is up to date', style: AppTypography.body),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NEEDS ATTENTION', style: AppTypography.monoSection),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppThemeColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++)
                _AttentionRow(
                  item: items[i],
                  isFirst: i == 0,
                  isLast: i == items.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Active Research ─────────────────────────────────────────────────────

  Widget _buildActiveResearch() {
    final companies = _provider.filteredCompanies;
    final activeResearch = companies.where((c) => c.thesesCount > 0).toList();

    if (activeResearch.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'ACTIVE RESEARCH',
      icon: Icons.science_outlined,
      count: activeResearch.length,
      child: Column(
        children: activeResearch.map((c) => _ResearchCompanyCard(
          company: c,
          onTap: () => context.go('/companies/${c.companyId}'),
        )).toList(),
      ),
    );
  }

  // ── Open Questions ──────────────────────────────────────────────────────

  Widget _buildOpenQuestions() {
    final questions = _provider.filteredQuestions.where((q) => q.isOpen).toList();

    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'OPEN QUESTIONS',
      icon: Icons.help_outline,
      count: questions.length,
      color: AppThemeColors.warning,
      child: Column(
        children: questions.take(10).map((q) => _QuestionCard(
          question: q,
          onTap: () {
            if (q.companyId != null) {
              context.go('/companies/${q.companyId}');
            }
          },
        )).toList(),
      ),
    );
  }

  // ── Recent Activity (merged timeline) ───────────────────────────────────

  Widget _buildRecentActivity() {
    final theses = _provider.filteredTheses;
    final notes = _provider.filteredNotes;

    final items = <_ActivityItem>[
      for (final t in theses)
        _ActivityItem(
          type: _ActivityType.thesis,
          id: t.thesisId,
          title: t.title,
          companyName: t.companyName,
          ticker: t.ticker,
          subtitle: t.stance,
          updatedAt: t.updatedAt,
          companyId: t.companyId,
        ),
      for (final n in notes)
        _ActivityItem(
          type: _ActivityType.note,
          id: n.noteId,
          title: n.title,
          companyName: n.companyName,
          ticker: n.ticker,
          subtitle: n.body.isNotEmpty ? n.body : null,
          updatedAt: n.updatedAt,
          companyId: n.companyId,
        ),
    ];

    // Sort by updatedAt descending
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayItems = items.take(10).toList();

    return _buildSection(
      title: 'RECENT ACTIVITY',
      icon: Icons.update,
      count: items.length,
      child: Column(
        children: displayItems.map((item) => _ActivityRow(
          item: item,
          onTap: () => context.go('/companies/${item.companyId}'),
        )).toList(),
      ),
    );
  }

  // ── Shared Section Builder ──────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required int count,
    required Widget child,
    Color? color,
  }) {
    final headerColor = color ?? AppThemeColors.textSecondary;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color != null ? color.withValues(alpha: 0.3) : AppThemeColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color != null ? color.withValues(alpha: 0.08) : AppThemeColors.surfaceMuted,
              border: Border(bottom: BorderSide(color: color != null ? color.withValues(alpha: 0.3) : AppThemeColors.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: headerColor),
                const SizedBox(width: 8),
                Text(title, style: AppTypography.monoSection.copyWith(color: headerColor)),
                const Spacer(),
                Text('$count', style: AppTypography.monoLabel.copyWith(color: AppThemeColors.textTertiary)),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attention Row Widget
// ─────────────────────────────────────────────────────────────────────────────

class _AttentionRow extends StatelessWidget {
  final _AttentionItem item;
  final bool isFirst;
  final bool isLast;

  const _AttentionRow({
    required this.item,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.companyId != null ? () => context.go('/companies/${item.companyId}') : null,
      hoverColor: AppThemeColors.surfaceLight.withValues(alpha: 0.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: AppThemeColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 16, color: item.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.actionLabel,
                style: AppTypography.microBadge.copyWith(color: item.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Row Widget (merged timeline entry)
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  final VoidCallback onTap;

  const _ActivityRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isThesis = item.type == _ActivityType.thesis;
    final typeColor = isThesis ? AppThemeColors.warning : AppThemeColors.textSecondary;
    final typeLabel = isThesis ? 'THESIS' : 'NOTE';

    return InkWell(
      onTap: onTap,
      hoverColor: AppThemeColors.surfaceLight.withValues(alpha: 0.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  typeLabel,
                  style: AppTypography.microBadge.copyWith(color: typeColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.companyName,
                        style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                      ),
                      if (item.ticker != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          item.ticker!,
                          style: AppTypography.monoLabel.copyWith(color: AppThemeColors.textTertiary, fontSize: 10),
                        ),
                      ],
                      if (item.subtitle != null && !isThesis) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.subtitle!,
                            style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else if (isThesis && item.subtitle != null) ...[
                        const SizedBox(width: 8),
                        StanceBadge(stance: item.subtitle!, size: StanceBadgeSize.small),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatTimeAgo(item.updatedAt),
              style: AppTypography.monoMeta.copyWith(color: AppThemeColors.textTertiary),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AppThemeColors.textTertiary),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Counter Badge
// ─────────────────────────────────────────────────────────────────────────────

class _CounterBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CounterBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTypography.monoLabel.copyWith(color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Research Company Card
// ─────────────────────────────────────────────────────────────────────────────

class _ResearchCompanyCard extends StatelessWidget {
  final ResearchCompany company;
  final VoidCallback onTap;

  const _ResearchCompanyCard({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: AppThemeColors.surfaceLight.withValues(alpha: 0.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(company.displayName, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
                      if (company.ticker != null) ...[
                        const SizedBox(width: 6),
                        Text(company.ticker!, style: AppTypography.monoLabel.copyWith(color: AppThemeColors.textTertiary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${company.notesCount} notes · ${company.thesesCount} theses',
                    style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                  ),
                ],
              ),
            ),
            ResearchStatusBadge(status: ResearchStatus.fromString(company.researchStatus)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AppThemeColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Question Card
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final ResearchQuestionIndex question;
  final VoidCallback onTap;

  const _QuestionCard({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color priorityColor;
    switch (question.priority) {
      case 'critical':
        priorityColor = AppThemeColors.critical;
      case 'high':
        priorityColor = AppThemeColors.warning;
      case 'medium':
        priorityColor = AppThemeColors.accent;
      default:
        priorityColor = AppThemeColors.textTertiary;
    }

    return InkWell(
      onTap: onTap,
      hoverColor: AppThemeColors.surfaceLight.withValues(alpha: 0.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppThemeColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            if (question.isCritical)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.warning_amber, size: 14, color: priorityColor),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.question,
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (question.companyName != null) ...[
                        Text(
                          question.companyName!,
                          style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                        ),
                        Text(
                          ' · ${question.notesCount} notes · ${question.daysOpen}d open',
                          style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                        ),
                      ] else
                        Text(
                          '${question.notesCount} notes · ${question.daysOpen} days open',
                          style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PriorityBadge(priority: question.priority, color: priorityColor),
          ],
        ),
      ),
    );
  }
}
