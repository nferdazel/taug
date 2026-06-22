import 'package:signals/signals.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../../shared/models/research_progression_state.dart';
import '../../../portfolio/data/portfolio_models.dart';
import '../../../portfolio/data/portfolio_workspace_repository.dart';
import '../../data/workspace_models.dart';
import '../../data/workspace_repository.dart';

class WorkspaceProvider {
  final WorkspaceRepository _repository;
  final PortfolioPositionRepository _portfolioRepository;
  final String companyId;

  final profile = Signal<CompanyProfile?>(null);
  final metrics = ListSignal<MetricSnapshot>([]);
  final statements = ListSignal<StatementRow>([]);
  final notes = ListSignal<CompanyNote>([]);
  final theses = ListSignal<CompanyThesis>([]);
  final questions = ListSignal<CompanyQuestion>([]);
  final qualityDetail = Signal<QualityScoreDetail?>(null);
  final freshnessStatus = Signal<String?>(null);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final mutationError = Signal<String?>(null);
  final activeTab = Signal<int>(0);
  final companyLessons = ListSignal<PortfolioPosition>([]);
  final isLoadingLessons = Signal<bool>(false);
  final activePosition = Signal<PortfolioPosition?>(null);
  bool _isMutating = false;

  WorkspaceProvider({required this.companyId, WorkspaceRepository? repository, PortfolioPositionRepository? portfolioRepository})
      : _repository = repository ?? WorkspaceRepository(),
        _portfolioRepository = portfolioRepository ?? PortfolioPositionRepository();

  void dispose() {
    profile.dispose();
    metrics.dispose();
    statements.dispose();
    notes.dispose();
    theses.dispose();
    questions.dispose();
    qualityDetail.dispose();
    freshnessStatus.dispose();
    isLoading.dispose();
    error.dispose();
    mutationError.dispose();
    activeTab.dispose();
    companyLessons.dispose();
    isLoadingLessons.dispose();
    activePosition.dispose();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    error.value = null;

    final results = await Future.wait([
      _repository.getCompanyProfile(companyId),
      _repository.getMetrics(companyId),
      _repository.getFinancialStatements(companyId),
      _repository.getNotes(companyId),
      _repository.getTheses(companyId),
      _repository.getQualityScore(companyId),
      _repository.getFreshnessStatus(companyId),
      _repository.getQuestions(companyId),
    ]);

    final profileResult = results[0] as Result<CompanyProfile>;
    final metricsResult = results[1] as Result<List<MetricSnapshot>>;
    final statementsResult = results[2] as Result<List<StatementRow>>;
    final notesResult = results[3] as Result<List<CompanyNote>>;
    final thesesResult = results[4] as Result<List<CompanyThesis>>;
    final qualityResult = results[5] as Result<QualityScoreDetail?>;
    final freshnessResult = results[6] as Result<String?>;
    final questionsResult = results[7] as Result<List<CompanyQuestion>>;

    if (profileResult.isSuccess) profile.value = profileResult.data;
    if (metricsResult.isSuccess) metrics.value = metricsResult.data!;
    if (statementsResult.isSuccess) statements.value = statementsResult.data!;
    if (notesResult.isSuccess) notes.value = notesResult.data!;
    if (thesesResult.isSuccess) theses.value = thesesResult.data!;
    if (qualityResult.isSuccess) qualityDetail.value = qualityResult.data;
    if (freshnessResult.isSuccess) freshnessStatus.value = freshnessResult.data;
    if (questionsResult.isSuccess) questions.value = questionsResult.data!;

    if (profileResult.isFailure) {
      error.value = ErrorSanitizer.message(profileResult.error);
    }

    // Load active position in parallel (non-blocking)
    _loadActivePosition();

    isLoading.value = false;
  }

  Future<void> loadCompanyLessons(String companyId) async {
    isLoadingLessons.value = true;
    final result = await _portfolioRepository.getLessonsForCompany(companyId);
    if (result.isSuccess) {
      companyLessons.value = result.data!;
    } else {
      ErrorSanitizer.debugLog('WorkspaceProvider', 'loadCompanyLessons failed: ${result.error}');
    }
    isLoadingLessons.value = false;
  }

  Future<void> _loadActivePosition() async {
    final result = await _portfolioRepository.getPositions(status: 'active');
    if (result.isSuccess) {
      final positions = result.data!;
      activePosition.value = positions.where((p) => p.companyId == companyId).firstOrNull;
    } else {
      ErrorSanitizer.debugLog('WorkspaceProvider', 'loadActivePosition failed: ${result.error}');
    }
  }

  Future<void> createNote(String title, String body) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.createNote(
        companyId: companyId, title: title, body: body,
      );
      if (result.isSuccess) {
        notes.value = [result.data!, ...notes];
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'createNote failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> updateNote(String noteId, String title, String body) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.updateNote(noteId: noteId, title: title, body: body);
      if (result.isSuccess) {
        notes.value = notes.map((n) => n.id == noteId
            ? CompanyNote(id: n.id, companyId: n.companyId, title: title, body: body, createdAt: n.createdAt, updatedAt: DateTime.now())
            : n).toList();
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'updateNote failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> deleteNote(String noteId) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.deleteNote(noteId);
      if (result.isSuccess) {
        notes.value = notes.where((n) => n.id != noteId).toList();
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'deleteNote failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> createThesis(String title, String stance, {String? summary, String? bullCase, String? bearCase, String? assumptions, String? catalysts, String? risks, String? exitConditions, String conviction = 'low'}) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.createThesis(
        companyId: companyId, title: title, stance: stance, summary: summary, bullCase: bullCase, bearCase: bearCase, assumptions: assumptions, catalysts: catalysts, risks: risks, exitConditions: exitConditions, conviction: conviction,
      );
      if (result.isSuccess) {
        theses.value = [result.data!, ...theses];
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'createThesis failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> updateThesis(String thesisId, String title, String stance, {String? summary, String? bullCase, String? bearCase, String? assumptions, String? catalysts, String? risks, String? exitConditions, String? conviction}) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.updateThesis(
        thesisId: thesisId, title: title, stance: stance, summary: summary, bullCase: bullCase, bearCase: bearCase, assumptions: assumptions, catalysts: catalysts, risks: risks, exitConditions: exitConditions, conviction: conviction,
      );
      if (result.isSuccess) {
        theses.value = theses.map((t) => t.id == thesisId
            ? CompanyThesis(id: t.id, companyId: t.companyId, title: title, stance: stance, summary: summary ?? t.summary, bullCase: bullCase ?? t.bullCase, bearCase: bearCase ?? t.bearCase, assumptions: assumptions ?? t.assumptions, catalysts: catalysts ?? t.catalysts, risks: risks ?? t.risks, exitConditions: exitConditions ?? t.exitConditions, conviction: conviction ?? t.conviction, createdAt: t.createdAt, updatedAt: DateTime.now())
            : t).toList();
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'updateThesis failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> deleteThesis(String thesisId) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.deleteThesis(thesisId);
      if (result.isSuccess) {
        theses.value = theses.where((t) => t.id != thesisId).toList();
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'deleteThesis failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> markThesisReviewed(String thesisId) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.markThesisReviewed(thesisId);
      if (result.isSuccess) {
        final now = DateTime.now();
        theses.value = theses.map((t) => t.id == thesisId
            ? CompanyThesis(
                id: t.id,
                companyId: t.companyId,
                title: t.title,
                stance: t.stance,
                summary: t.summary,
                bullCase: t.bullCase,
                bearCase: t.bearCase,
                assumptions: t.assumptions,
                catalysts: t.catalysts,
                risks: t.risks,
                exitConditions: t.exitConditions,
                conviction: t.conviction,
                createdAt: t.createdAt,
                updatedAt: now,
                lastReviewedAt: now,
                researchFreshness: t.researchFreshness,
              )
            : t).toList();
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'markThesisReviewed failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> createReview({
    required String thesisId,
    String? reviewNotes,
    String? convictionBefore,
    String? convictionAfter,
    String? stanceBefore,
    String? stanceAfter,
  }) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.createReview(
        thesisId: thesisId,
        reviewNotes: reviewNotes,
        convictionBefore: convictionBefore,
        convictionAfter: convictionAfter,
        stanceBefore: stanceBefore,
        stanceAfter: stanceAfter,
      );
      if (result.isSuccess) {
        final now = DateTime.now();
        theses.value = theses.map((t) => t.id == thesisId
            ? CompanyThesis(
                id: t.id,
                companyId: t.companyId,
                title: t.title,
                stance: t.stance,
                summary: t.summary,
                bullCase: t.bullCase,
                bearCase: t.bearCase,
                assumptions: t.assumptions,
                catalysts: t.catalysts,
                risks: t.risks,
                exitConditions: t.exitConditions,
                conviction: t.conviction,
                createdAt: t.createdAt,
                updatedAt: now,
                lastReviewedAt: now,
                researchFreshness: t.researchFreshness,
              )
            : t).toList();
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'createReview failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> createQuestion(String question, {String priority = 'medium'}) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.createQuestion(
        companyId: companyId,
        question: question,
        priority: priority,
      );
      if (result.isSuccess) {
        questions.value = [result.data!, ...questions];
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'createQuestion failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> answerQuestion(String questionId, String answer) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.answerQuestion(
        questionId: questionId,
        answer: answer,
      );
      if (result.isSuccess) {
        final now = DateTime.now();
        questions.value = questions.map((q) => q.id == questionId
            ? CompanyQuestion(
                id: q.id,
                companyId: q.companyId,
                thesisId: q.thesisId,
                question: q.question,
                priority: q.priority,
                status: 'answered',
                answer: answer,
                answeredAt: now,
                createdAt: q.createdAt,
                updatedAt: now,
              )
            : q).toList();
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'answerQuestion failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    if (_isMutating) return;
    _isMutating = true;
    mutationError.value = null;
    try {
      final result = await _repository.deleteQuestion(questionId);
      if (result.isSuccess) {
        questions.value = questions.where((q) => q.id != questionId).toList();
      } else {
        ErrorSanitizer.debugLog('WorkspaceProvider', 'deleteQuestion failed: ${result.error}');
        mutationError.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  String get researchStatus {
    if (theses.isNotEmpty) return 'researching';
    if (notes.isNotEmpty) return 'researching';
    return 'not_researched';
  }

  /// Canonical research progression state.
  /// Single source of truth for all workflow guidance.
  ResearchProgressionState get progressionState => ResearchProgressionState(
        companyId: companyId,
        companyName: profile.value?.displayName ?? '',
        notesCount: notes.length,
        openQuestionsCount: questions.where((q) => q.isOpen).length,
        criticalQuestionsCount: questions.where((q) => q.isCritical).length,
        thesesCount: theses.length,
        positionsCount: companyLessons.where((l) => l.isActive).length,
        lessonsCount: companyLessons.where((l) => l.isClosed).length,
        thesisStance: theses.isNotEmpty ? theses.first.stance : null,
        thesisConviction: theses.isNotEmpty ? theses.first.conviction : null,
        thesisLastUpdated: theses.isNotEmpty ? theses.first.updatedAt : null,
        researchFreshness: freshnessStatus.value,
      );
}
