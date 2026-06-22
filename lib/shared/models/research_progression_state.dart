import 'package:equatable/equatable.dart';

/// Canonical research progression state for a company.
/// Single source of truth for all workflow guidance across
/// Company Overview, Company Research, Research Workspace, and Empty States.
class ResearchProgressionState extends Equatable {
  final String companyId;
  final String companyName;

  // Research artifacts
  final int notesCount;
  final int openQuestionsCount;
  final int criticalQuestionsCount;
  final int thesesCount;
  final int positionsCount;
  final int lessonsCount;

  // Thesis state
  final String? thesisStance; // 'bullish', 'bearish', 'neutral'
  final String? thesisConviction; // 'low', 'medium', 'high'
  final DateTime? thesisLastUpdated;

  // Freshness
  final String? researchFreshness; // 'fresh', 'aging', 'stale', 'expired'

  const ResearchProgressionState({
    required this.companyId,
    required this.companyName,
    this.notesCount = 0,
    this.openQuestionsCount = 0,
    this.criticalQuestionsCount = 0,
    this.thesesCount = 0,
    this.positionsCount = 0,
    this.lessonsCount = 0,
    this.thesisStance,
    this.thesisConviction,
    this.thesisLastUpdated,
    this.researchFreshness,
  });

  /// Current progression stage derived from artifact counts.
  ResearchStage get stage {
    if (notesCount == 0 && thesesCount == 0) return ResearchStage.noResearch;
    if (notesCount > 0 && thesesCount == 0) return ResearchStage.notesOnly;
    if (thesesCount > 0 && openQuestionsCount > 0) {
      return ResearchStage.questionsOutstanding;
    }
    if (thesesCount > 0 && positionsCount == 0) {
      return ResearchStage.positionReady;
    }
    if (positionsCount > 0 && lessonsCount == 0) {
      return ResearchStage.activePosition;
    }
    if (lessonsCount > 0) return ResearchStage.researchComplete;
    return ResearchStage.noResearch;
  }

  /// Whether research is stale or expired.
  bool get isStale =>
      researchFreshness == 'stale' || researchFreshness == 'expired';

  /// Whether research needs review (stale or has critical open questions).
  bool get needsReview => isStale || criticalQuestionsCount > 0;

  /// Count of completed research checklist items (notes, thesis, questions resolved, position).
  int get completedCount {
    int count = 0;
    if (notesCount > 0) count++;
    if (thesesCount > 0) count++;
    if (openQuestionsCount == 0 && (notesCount > 0 || thesesCount > 0)) count++;
    if (positionsCount > 0) count++;
    return count;
  }

  /// Next recommended action based on current stage and freshness.
  NextAction get nextAction {
    if (stage == ResearchStage.noResearch) return NextAction.createNote;
    if (stage == ResearchStage.notesOnly) return NextAction.createThesis;
    if (stage == ResearchStage.questionsOutstanding) {
      return NextAction.answerQuestions;
    }
    if (stage == ResearchStage.positionReady) return NextAction.createPosition;
    if (isStale) return NextAction.reviewThesis;
    return NextAction.none;
  }

  @override
  List<Object?> get props => [
        companyId,
        companyName,
        notesCount,
        openQuestionsCount,
        criticalQuestionsCount,
        thesesCount,
        positionsCount,
        lessonsCount,
        thesisStance,
        thesisConviction,
        thesisLastUpdated,
        researchFreshness,
      ];
}

/// Research progression stages representing the workflow funnel.
enum ResearchStage {
  noResearch,
  notesOnly,
  questionsOutstanding,
  positionReady,
  activePosition,
  researchComplete,
}

/// Next action recommendations derived from progression state.
enum NextAction {
  none,
  createNote,
  createThesis,
  answerQuestions,
  createPosition,
  reviewThesis,
  reviewFiling,
}

/// Display helpers for [NextAction].
extension NextActionExtension on NextAction {
  String get label {
    switch (this) {
      case NextAction.none:
        return 'Research Complete';
      case NextAction.createNote:
        return 'Create Note';
      case NextAction.createThesis:
        return 'Create Thesis';
      case NextAction.answerQuestions:
        return 'Answer Questions';
      case NextAction.createPosition:
        return 'Create Position';
      case NextAction.reviewThesis:
        return 'Review Thesis';
      case NextAction.reviewFiling:
        return 'Review Filing';
    }
  }

  String get description {
    switch (this) {
      case NextAction.none:
        return 'Your research is complete. Review periodically to stay current.';
      case NextAction.createNote:
        return 'Start documenting your research on this company.';
      case NextAction.createThesis:
        return 'You have notes. Formalize your research into a stance.';
      case NextAction.answerQuestions:
        return 'Open questions may affect your thesis. Answer them first.';
      case NextAction.createPosition:
        return 'Your research is ready. Start tracking your decision.';
      case NextAction.reviewThesis:
        return 'Your research may be outdated. Review and update.';
      case NextAction.reviewFiling:
        return 'New filings available. Review for thesis impact.';
    }
  }

  String get icon {
    switch (this) {
      case NextAction.none:
        return '\u2713'; // checkmark
      case NextAction.createNote:
        return '\u25AA'; // bullet
      case NextAction.createThesis:
        return '\u25C6'; // diamond
      case NextAction.answerQuestions:
        return '?';
      case NextAction.createPosition:
        return '\u25CF'; // circle
      case NextAction.reviewThesis:
        return '\u21BB'; // refresh
      case NextAction.reviewFiling:
        return '\u2191'; // up arrow
    }
  }
}
