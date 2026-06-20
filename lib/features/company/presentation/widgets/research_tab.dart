import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/status_badges.dart';
import '../../data/workspace_models.dart';
import '../providers/workspace_provider.dart';

class ResearchTab extends StatelessWidget {
  final WorkspaceProvider provider;

  const ResearchTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final theses = provider.theses;
      final notes = provider.notes;

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
            ),
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
    String stance = thesis?.stance ?? 'neutral';
    String conviction = thesis?.conviction ?? 'low';

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

  const _ThesisCard({
    required this.thesis,
    required this.onEdit,
    required this.onDelete,
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
              _StanceBadge(stance: thesis.stance),
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

class _StanceBadge extends StatelessWidget {
  final String stance;

  const _StanceBadge({required this.stance});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (stance) {
      case 'bullish':
        color = AppThemeColors.success;
        label = 'Bullish';
        break;
      case 'bearish':
        color = AppThemeColors.critical;
        label = 'Bearish';
        break;
      default:
        color = AppThemeColors.neutral;
        label = 'Neutral';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
