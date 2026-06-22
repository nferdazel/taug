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

class ResearchWorkspacePage extends StatefulWidget {
  const ResearchWorkspacePage({super.key});

  @override
  State<ResearchWorkspacePage> createState() => _ResearchWorkspacePageState();
}

class _ResearchWorkspacePageState extends State<ResearchWorkspacePage> {
  late final ResearchProvider _provider;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = ResearchProvider();
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

  Widget _buildContent() {
    return SignalBuilder(builder: (_) {
      if (_provider.isLoading.value) {
        return const AppLoadingState(message: 'Loading research...');
      }

      final companies = _provider.filteredCompanies;
      final theses = _provider.filteredTheses;
      final notes = _provider.filteredNotes;
      final openQuestions = _provider.filteredQuestions.where((q) => q.isOpen).toList();

      // Prioritize: companies with notes but no thesis need attention
      final needsThesis = companies.where((c) => c.notesCount > 0 && c.thesesCount == 0).toList();
      final activeResearch = companies.where((c) => c.thesesCount > 0).toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Open Questions — highest priority
            if (openQuestions.isNotEmpty) ...[
              _buildSection(
                title: 'OPEN QUESTIONS',
                icon: Icons.help_outline,
                count: openQuestions.length,
                color: AppThemeColors.warning,
                child: Column(
                  children: openQuestions.take(10).map((q) => _QuestionCard(
                    question: q,
                    onTap: () {
                      if (q.companyId != null) {
                        context.go('/companies/${q.companyId}');
                      }
                    },
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Needs Thesis — highest priority
            if (needsThesis.isNotEmpty) ...[
              _buildSection(
                title: 'NEEDS THESIS',
                icon: Icons.warning_amber,
                count: needsThesis.length,
                color: AppThemeColors.warning,
                child: Column(
                  children: needsThesis.map((c) => _ResearchCompanyCard(
                    company: c,
                    onTap: () => context.go('/companies/${c.companyId}'),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Active Research — has thesis
            _buildSection(
              title: 'ACTIVE RESEARCH',
              icon: Icons.science_outlined,
              count: activeResearch.length,
              child: activeResearch.isEmpty
                  ? _buildEmptyResearch()
                  : Column(
                      children: activeResearch.map((c) => _ResearchCompanyCard(
                        company: c,
                        onTap: () => context.go('/companies/${c.companyId}'),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // Recent Theses
            _buildSection(
              title: 'RECENT THESES',
              icon: Icons.lightbulb_outline,
              count: theses.length,
              child: theses.isEmpty
                  ? _buildEmptyTheses()
                  : Column(
                      children: theses.take(5).map((t) => _ThesisCard(
                        thesis: t,
                        onTap: () => context.go('/companies/${t.companyId}'),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // Recent Notes
            _buildSection(
              title: 'RECENT NOTES',
              icon: Icons.note_outlined,
              count: notes.length,
              child: notes.isEmpty
                  ? _buildEmptyNotes()
                  : Column(
                      children: notes.take(5).map((n) => _NoteCard(
                        note: n,
                        onTap: () => context.go('/companies/${n.companyId}'),
                      )).toList(),
                    ),
            ),
          ],
        ),
      );
    });
  }

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

  Widget _buildEmptyResearch() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.science_outlined, size: 32, color: AppThemeColors.textTertiary),
            SizedBox(height: 8),
            Text('No active research', style: AppTypography.subheading),
            SizedBox(height: 4),
            Text(
              'Start by researching companies from the Companies page.\nNotes and theses will appear here.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTheses() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline, size: 32, color: AppThemeColors.textTertiary),
            SizedBox(height: 8),
            Text('No theses yet', style: AppTypography.subheading),
            SizedBox(height: 4),
            Text(
              'Create investment theses from company research pages.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotes() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.note_outlined, size: 32, color: AppThemeColors.textTertiary),
            SizedBox(height: 8),
            Text('No notes yet', style: AppTypography.subheading),
            SizedBox(height: 4),
            Text(
              'Create research notes from company research pages.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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

class _ThesisCard extends StatelessWidget {
  final ResearchThesisIndex thesis;
  final VoidCallback onTap;

  const _ThesisCard({required this.thesis, required this.onTap});

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
            StanceBadge(stance: thesis.stance),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thesis.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${thesis.companyName}${thesis.ticker != null ? " (${thesis.ticker})" : ""}', style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppThemeColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ResearchNoteIndex note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

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
                  Text(note.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${note.companyName}${note.ticker != null ? " (${note.ticker})" : ""}', style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary)),
                  if (note.body.isNotEmpty)
                    Text(note.body, style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppThemeColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

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


