import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/status_badges.dart';
import '../../../portfolio/data/portfolio_models.dart';
import '../../data/workspace_models.dart';
import '../providers/workspace_provider.dart';

class ResearchTab extends StatelessWidget {
  final WorkspaceProvider provider;

  const ResearchTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (_) {
      final theses = provider.theses;
      final notes = provider.notes;
      final openQuestions = provider.questions.where((q) => q.isOpen).toList();
      final answeredQuestions = provider.questions.where((q) => !q.isOpen).toList();

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thesis Section
          Row(
            children: [
              const Expanded(
                child: Text('MY THESIS', style: AppTypography.monoSection),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _showThesisDialog(context),
                tooltip: 'Create Thesis',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (theses.isEmpty)
            const _EmptyCard(
              message:
                  'No thesis yet. Create one to track your investment thesis.',
            )
          else
            _ThesisCard(
              thesis: theses.first,
              onEdit: () => _showThesisDialog(context, thesis: theses.first),
              onDelete: () => _confirmDelete(context, 'thesis', () => provider.deleteThesis(theses.first.id)),
              onCreatePosition: () {
                final thesis = theses.first;
                final companyName = provider.profile.value?.displayName ?? '';
                final uri = Uri(
                  path: '/portfolio-workspace',
                  queryParameters: {
                    'companyId': thesis.companyId,
                    'companyName': companyName,
                    'thesisId': thesis.id,
                    'thesisTitle': thesis.title,
                    'conviction': thesis.conviction,
                  },
                );
                context.go(uri.toString());
              },
            ),
          const SizedBox(height: 24),

          // Questions Section
          Row(
            children: [
              Expanded(
                child: Text(
                  'QUESTIONS (${openQuestions.length})',
                  style: AppTypography.monoSection,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _showQuestionDialog(context),
                tooltip: 'Create Question',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (openQuestions.isEmpty && answeredQuestions.isEmpty)
            const _EmptyCard(
              message: 'No questions yet. Create one to track research questions.',
            )
          else ...[
            ...openQuestions.map(
              (q) => _QuestionCard(
                question: q,
                onAnswer: () => _showAnswerDialog(context, q),
                onDelete: () => _confirmDelete(context, 'question', () => provider.deleteQuestion(q.id)),
              ),
            ),
            if (answeredQuestions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'ANSWERED (${answeredQuestions.length})',
                  style: AppTypography.monoSection.copyWith(
                    color: AppThemeColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ...answeredQuestions.take(3).map(
                (q) => _AnsweredQuestionCard(question: q),
              ),
            ],
          ],
          const SizedBox(height: 24),

          // Notes Section
          Row(
            children: [
              Expanded(
                child: Text(
                  'NOTES (${notes.length})',
                  style: AppTypography.monoSection,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _showNoteDialog(context),
                tooltip: 'Create Note',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (notes.isEmpty)
            const _EmptyCard(
              message: 'No notes yet. Create one to record your research.',
            )
          else
            ...notes.map(
              (note) => _NoteCard(
                note: note,
                onEdit: () => _showNoteDialog(context, note: note),
                onDelete: () => _confirmDelete(context, 'note', () => provider.deleteNote(note.id)),
              ),
            ),
        ],
      );
    });
  }

  void _confirmDelete(BuildContext context, String type, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemeColors.surface,
        title: Text('Delete $type', style: AppTypography.heading),
        content: Text('Are you sure you want to delete this $type? This cannot be undone.', style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppThemeColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppThemeColors.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, {CompanyNote? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final bodyController = TextEditingController(text: note?.body ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemeColors.surface,
        title: Text(
          note == null ? 'New Note' : 'Edit Note',
          style: AppTypography.heading,
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: AppTypography.body,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: AppTypography.caption,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.accent),
                  ),
                  filled: true,
                  fillColor: AppThemeColors.surfaceMuted,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                style: AppTypography.body,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Write your research note...',
                  hintStyle: AppTypography.caption,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.accent),
                  ),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppThemeColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isEmpty) return;

              if (note == null) {
                provider.createNote(title, body);
              } else {
                provider.updateNote(note.id, title, body);
              }
              Navigator.pop(context);
            },
            child: Text(note == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showThesisDialog(BuildContext context, {CompanyThesis? thesis}) {
    final titleController = TextEditingController(text: thesis?.title ?? '');
    final summaryController = TextEditingController(
      text: thesis?.summary ?? '',
    );
    final bullCaseController = TextEditingController(
      text: thesis?.bullCase ?? '',
    );
    final bearCaseController = TextEditingController(
      text: thesis?.bearCase ?? '',
    );
    final assumptionsController = TextEditingController(
      text: thesis?.assumptions ?? '',
    );
    final catalystsController = TextEditingController(
      text: thesis?.catalysts ?? '',
    );
    final risksController = TextEditingController(
      text: thesis?.risks ?? '',
    );
    final exitConditionsController = TextEditingController(
      text: thesis?.exitConditions ?? '',
    );
    String stance = thesis?.stance ?? 'neutral';
    String conviction = thesis?.conviction ?? 'low';

    // Load prior lessons for this company when dialog opens
    provider.loadCompanyLessons(provider.companyId);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppThemeColors.surface,
          title: Text(
            thesis == null ? 'New Thesis' : 'Edit Thesis',
            style: AppTypography.heading,
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prior Lessons Section
                  SignalBuilder(builder: (_) {
                    final lessons = provider.companyLessons;
                    final loading = provider.isLoadingLessons.value;
                    if (loading) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (lessons.isEmpty) return const SizedBox.shrink();
                    return _LessonsSection(
                      lessons: lessons,
                      onNavigateToPortfolio: () {
                        Navigator.pop(context);
                        context.go('/portfolio-workspace');
                      },
                    );
                  }),
                  TextField(
                    controller: titleController,
                    style: AppTypography.body,
                    decoration: const InputDecoration(
                      hintText: 'Thesis title (e.g., "NVIDIA — Bullish")',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.accent),
                      ),
                      filled: true,
                      fillColor: AppThemeColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Stance: ', style: AppTypography.body),
                      ...['bullish', 'neutral', 'bearish'].map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: ChoiceChip(
                            label: Text(s[0].toUpperCase() + s.substring(1)),
                            selected: stance == s,
                            onSelected: (selected) {
                              if (selected) setDialogState(() => stance = s);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Conviction: ', style: AppTypography.body),
                      ...['low', 'medium', 'high'].map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: ChoiceChip(
                            label: Text(c[0].toUpperCase() + c.substring(1)),
                            selected: conviction == c,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => conviction = c);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: summaryController,
                    style: AppTypography.body,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Summary...',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.accent),
                      ),
                      filled: true,
                      fillColor: AppThemeColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bullCaseController,
                    style: AppTypography.body,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Bull case...',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.accent),
                      ),
                      filled: true,
                      fillColor: AppThemeColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bearCaseController,
                    style: AppTypography.body,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Bear case...',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.accent),
                      ),
                      filled: true,
                      fillColor: AppThemeColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: assumptionsController,
                    style: AppTypography.body,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Key assumptions...',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.accent),
                      ),
                      filled: true,
                      fillColor: AppThemeColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: catalystsController,
                    style: AppTypography.body,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Catalysts...',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.accent),
                      ),
                      filled: true,
                      fillColor: AppThemeColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: risksController,
                    style: AppTypography.body,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Key risks...',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.accent),
                      ),
                      filled: true,
                      fillColor: AppThemeColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: exitConditionsController,
                    style: AppTypography.body,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Exit conditions...',
                      hintStyle: AppTypography.caption,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppThemeColors.accent),
                      ),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppThemeColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                if (thesis == null) {
                  provider.createThesis(
                    title,
                    stance,
                    summary: summaryController.text.trim(),
                    bullCase: bullCaseController.text.trim(),
                    bearCase: bearCaseController.text.trim(),
                    assumptions: assumptionsController.text.trim(),
                    catalysts: catalystsController.text.trim(),
                    risks: risksController.text.trim(),
                    exitConditions: exitConditionsController.text.trim(),
                    conviction: conviction,
                  );
                } else {
                  provider.updateThesis(
                    thesis.id,
                    title,
                    stance,
                    summary: summaryController.text.trim(),
                    bullCase: bullCaseController.text.trim(),
                    bearCase: bearCaseController.text.trim(),
                    assumptions: assumptionsController.text.trim(),
                    catalysts: catalystsController.text.trim(),
                    risks: risksController.text.trim(),
                    exitConditions: exitConditionsController.text.trim(),
                    conviction: conviction,
                  );
                }
                Navigator.pop(context);
              },
              child: Text(thesis == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionDialog(BuildContext context) {
    final questionController = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppThemeColors.surface,
          title: const Text('New Question', style: AppTypography.heading),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  style: AppTypography.body,
                  maxLines: 3,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'What do you need to find out?',
                    hintStyle: AppTypography.caption,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppThemeColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppThemeColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppThemeColors.accent),
                    ),
                    filled: true,
                    fillColor: AppThemeColors.surfaceMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Priority: ', style: AppTypography.body),
                    ...['low', 'medium', 'high', 'critical'].map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ChoiceChip(
                          label: Text(p[0].toUpperCase() + p.substring(1)),
                          selected: priority == p,
                          onSelected: (selected) {
                            if (selected) setDialogState(() => priority = p);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppThemeColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final question = questionController.text.trim();
                if (question.isEmpty) return;
                provider.createQuestion(question, priority: priority);
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, CompanyQuestion question) {
    final answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemeColors.surface,
        title: const Text('Answer Question', style: AppTypography.heading),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppThemeColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppThemeColors.border),
                ),
                child: Text(question.question, style: AppTypography.body),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: answerController,
                style: AppTypography.body,
                maxLines: 5,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Your answer or findings...',
                  hintStyle: AppTypography.caption,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppThemeColors.accent),
                  ),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppThemeColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final answer = answerController.text.trim();
              if (answer.isEmpty) return;
              provider.answerQuestion(question.id, answer);
              Navigator.pop(context);
            },
            child: const Text('Mark Answered'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Center(child: Text(message, style: AppTypography.caption)),
    );
  }
}

class _ThesisCard extends StatelessWidget {
  final CompanyThesis thesis;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCreatePosition;

  const _ThesisCard({
    required this.thesis,
    required this.onEdit,
    required this.onDelete,
    required this.onCreatePosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                child: Text(thesis.title, style: AppTypography.subheading),
              ),
              StanceBadge(stance: thesis.stance),
              const SizedBox(width: 8),
              _ConvictionBadge(conviction: thesis.conviction),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 16,
                  color: AppThemeColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          if (thesis.summary != null && thesis.summary!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(thesis.summary!, style: AppTypography.body),
          ],
          if (thesis.bullCase != null && thesis.bullCase!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Bull Case',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(thesis.bullCase!, style: AppTypography.body),
          ],
          if (thesis.bearCase != null && thesis.bearCase!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Bear Case',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(thesis.bearCase!, style: AppTypography.body),
          ],
          if (thesis.assumptions != null && thesis.assumptions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Assumptions',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(thesis.assumptions!, style: AppTypography.body),
          ],
          if (thesis.catalysts != null && thesis.catalysts!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catalysts',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(thesis.catalysts!, style: AppTypography.body),
          ],
          if (thesis.risks != null && thesis.risks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Risks',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(thesis.risks!, style: AppTypography.body),
          ],
          if (thesis.exitConditions != null && thesis.exitConditions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Exit Conditions',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(thesis.exitConditions!, style: AppTypography.body),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 28,
            child: ElevatedButton.icon(
              onPressed: onCreatePosition,
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 14),
              label: const Text('Create Position'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeColors.accent,
                foregroundColor: AppThemeColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Updated: ${_formatDate(thesis.updatedAt)}',
            style: AppTypography.caption.copyWith(
              color: AppThemeColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _NoteCard extends StatelessWidget {
  final CompanyNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
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
                child: Text(note.title, style: AppTypography.subheading, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 16,
                  color: AppThemeColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          if (note.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.body,
              style: AppTypography.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDate(note.updatedAt),
            style: AppTypography.caption.copyWith(
              color: AppThemeColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _LessonsSection extends StatefulWidget {
  final List<PortfolioPosition> lessons;
  final VoidCallback onNavigateToPortfolio;

  const _LessonsSection({
    required this.lessons,
    required this.onNavigateToPortfolio,
  });

  @override
  State<_LessonsSection> createState() => _LessonsSectionState();
}

class _LessonsSectionState extends State<_LessonsSection> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.lessons.length > 2;
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.lessons;
    final visibleLessons = _collapsed ? lessons.take(2).toList() : lessons;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppThemeColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Row(
              children: [
                Icon(
                  _collapsed ? Icons.expand_more : Icons.expand_less,
                  size: 16,
                  color: AppThemeColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'PRIOR LESSONS (${lessons.length})',
                  style: AppTypography.monoSection,
                ),
              ],
            ),
          ),
          // Lesson items
          const SizedBox(height: 8),
          ...visibleLessons.map((pos) => _LessonItem(position: pos)),
          // Expand hint if collapsed and more than 2
          if (_collapsed && lessons.length > 2) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _collapsed = false),
              child: Text(
                'Show ${lessons.length - 2} more...',
                style: AppTypography.caption.copyWith(
                  color: AppThemeColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          // Link to portfolio if more than 3
          if (lessons.length > 3) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onNavigateToPortfolio,
              child: Text(
                'View all in Portfolio →',
                style: AppTypography.caption.copyWith(
                  color: AppThemeColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonItem extends StatelessWidget {
  final PortfolioPosition position;

  const _LessonItem({required this.position});

  @override
  Widget build(BuildContext context) {
    final Color outcomeColor;
    final String outcomeLabel;
    switch (position.outcome) {
      case PositionOutcome.correct:
        outcomeColor = AppThemeColors.success;
        outcomeLabel = 'Win';
      case PositionOutcome.incorrect:
        outcomeColor = AppThemeColors.critical;
        outcomeLabel = 'Loss';
      case PositionOutcome.partial:
        outcomeColor = AppThemeColors.warning;
        outcomeLabel = 'Partial';
      default:
        outcomeColor = AppThemeColors.textTertiary;
        outcomeLabel = '—';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: outcomeColor.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  outcomeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: outcomeColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (position.thesisStance != null) ...[
                StanceBadge(stance: position.thesisStance!, size: StanceBadgeSize.small),
                const SizedBox(width: 6),
              ],
              _ConvictionBadgeSmall(conviction: position.conviction),
            ],
          ),
          if (position.lessonsLearned != null && position.lessonsLearned!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              position.lessonsLearned!,
              style: AppTypography.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConvictionBadgeSmall extends StatelessWidget {
  final String conviction;

  const _ConvictionBadgeSmall({required this.conviction});

  @override
  Widget build(BuildContext context) {
    final level = ConvictionLevel.values.firstWhere(
      (l) => l.name == conviction,
      orElse: () => ConvictionLevel.low,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: level.color,
        ),
      ),
    );
  }
}

class _ConvictionBadge extends StatelessWidget {
  final String conviction;

  const _ConvictionBadge({required this.conviction});

  @override
  Widget build(BuildContext context) {
    final level = ConvictionLevel.values.firstWhere(
      (l) => l.name == conviction,
      orElse: () => ConvictionLevel.low,
    );
    return ConvictionBadge(level: level);
  }
}

class _QuestionCard extends StatelessWidget {
  final CompanyQuestion question;
  final VoidCallback onAnswer;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.onAnswer,
    required this.onDelete,
  });

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
              if (question.isCritical)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.warning_amber, size: 14, color: priorityColor),
                ),
              Expanded(
                child: Text(
                  question.question,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              _PriorityBadge(priority: question.priority, color: priorityColor),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 16,
                  color: AppThemeColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'answer') onAnswer();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'answer', child: Text('Answer')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${question.daysOpen} days open',
            style: AppTypography.caption.copyWith(color: AppThemeColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _AnsweredQuestionCard extends StatelessWidget {
  final CompanyQuestion question;

  const _AnsweredQuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemeColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppThemeColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: AppThemeColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  question.question,
                  style: AppTypography.body.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppThemeColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (question.answer != null && question.answer!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              question.answer!,
              style: AppTypography.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  final Color color;

  const _PriorityBadge({required this.priority, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
