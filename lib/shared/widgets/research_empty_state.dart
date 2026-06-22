import 'package:flutter/material.dart';

import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Context-aware empty state framework:
/// State → Why It Matters → What To Do → Action
class ResearchEmptyState extends StatelessWidget {
  final String state;
  final String whyItMatters;
  final String whatToDo;
  final String actionLabel;
  final VoidCallback? onAction;

  const ResearchEmptyState({
    super.key,
    required this.state,
    required this.whyItMatters,
    required this.whatToDo,
    required this.actionLabel,
    this.onAction,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(state, style: AppTypography.subheading),
          const SizedBox(height: 8),
          Text(
            whyItMatters,
            style: AppTypography.caption,
          ),
          const SizedBox(height: 8),
          Text(whatToDo, style: AppTypography.body),
          if (onAction != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: actionLabel,
              icon: Icons.arrow_forward,
              onPressed: onAction,
              variant: AppButtonVariant.primary,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pre-built empty state: No thesis created yet.
class ThesisEmptyState extends StatelessWidget {
  final VoidCallback? onCreateThesis;

  const ThesisEmptyState({super.key, this.onCreateThesis});

  @override
  Widget build(BuildContext context) {
    return ResearchEmptyState(
      state: 'No Thesis Yet',
      whyItMatters:
          'A thesis converts research into decisions. It defines what you believe, why, and what could invalidate it.',
      whatToDo:
          'Start by defining:\n• What do you believe about this company?\n• Why do you believe it?\n• What could invalidate your thesis?',
      actionLabel: 'Create Thesis',
      onAction: onCreateThesis,
    );
  }
}

/// Pre-built empty state: No research questions.
class QuestionsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateQuestion;

  const QuestionsEmptyState({super.key, this.onCreateQuestion});

  @override
  Widget build(BuildContext context) {
    return ResearchEmptyState(
      state: 'No Research Questions',
      whyItMatters:
          'Questions drive focused research. They help you identify what you need to know before making a decision.',
      whatToDo:
          'Start by asking:\n• What do I need to know about this company?\n• What assumptions am I making?\n• What could change my mind?',
      actionLabel: 'Add Question',
      onAction: onCreateQuestion,
    );
  }
}

/// Pre-built empty state: No research notes.
class NotesEmptyState extends StatelessWidget {
  final VoidCallback? onCreateNote;

  const NotesEmptyState({super.key, this.onCreateNote});

  @override
  Widget build(BuildContext context) {
    return ResearchEmptyState(
      state: 'No Research Notes',
      whyItMatters:
          'Notes capture your research findings. They provide evidence for your thesis and help you remember your reasoning.',
      whatToDo:
          'Start by documenting:\n• Key financial metrics\n• Competitive advantages\n• Industry trends\n• Management quality',
      actionLabel: 'Create Note',
      onAction: onCreateNote,
    );
  }
}

/// Pre-built empty state: No position created.
class PositionEmptyState extends StatelessWidget {
  final VoidCallback? onCreatePosition;

  const PositionEmptyState({super.key, this.onCreatePosition});

  @override
  Widget build(BuildContext context) {
    return ResearchEmptyState(
      state: 'No Position',
      whyItMatters:
          'A position tracks your investment decision. It connects your thesis to real-world outcomes.',
      whatToDo:
          'When your research is complete:\n• Review your thesis and conviction\n• Consider position sizing\n• Create a position to track your decision',
      actionLabel: 'Create Position',
      onAction: onCreatePosition,
    );
  }
}

/// Pre-built empty state: No lessons yet.
class LessonsEmptyState extends StatelessWidget {
  const LessonsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResearchEmptyState(
      state: 'No Lessons Yet',
      whyItMatters:
          'Lessons capture what you learned from each decision. They help you improve over time.',
      whatToDo:
          'Close a position with lessons to start building your knowledge base. Lessons from correct and incorrect decisions are equally valuable.',
      actionLabel: 'View Portfolio',
    );
  }
}
