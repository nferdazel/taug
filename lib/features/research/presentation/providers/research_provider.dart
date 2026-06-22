import 'package:signals/signals.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../data/research_models.dart';
import '../../data/research_repository.dart';

class ResearchProvider {
  final ResearchRepository _repository;

  final companies = ListSignal<ResearchCompany>([]);
  final theses = ListSignal<ResearchThesisIndex>([]);
  final notes = ListSignal<ResearchNoteIndex>([]);
  final questions = ListSignal<ResearchQuestionIndex>([]);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final searchQuery = Signal<String>('');
  final activeTab = Signal<int>(0);
  bool _isMutating = false;

  ResearchProvider({ResearchRepository? repository})
      : _repository = repository ?? ResearchRepository();

  Future<void> loadAll() async {
    isLoading.value = true;
    error.value = null;

    try {
      final results = await Future.wait([
        _repository.getResearchCompanies(),
        _repository.getAllTheses(),
        _repository.getAllNotes(),
        _repository.getOpenQuestions(),
      ]);

      final companiesResult = results[0] as Result<List<ResearchCompany>>;
      final thesesResult = results[1] as Result<List<ResearchThesisIndex>>;
      final notesResult = results[2] as Result<List<ResearchNoteIndex>>;
      final questionsResult = results[3] as Result<List<ResearchQuestionIndex>>;

      if (companiesResult.isSuccess) companies.value = companiesResult.data!;
      if (thesesResult.isSuccess) theses.value = thesesResult.data!;
      if (notesResult.isSuccess) notes.value = notesResult.data!;
      if (questionsResult.isSuccess) questions.value = questionsResult.data!;
    } catch (e) {
      ErrorSanitizer.debugLog('ResearchProvider', 'loadAll error: $e');
      error.value = ErrorSanitizer.message(e);
    }

    isLoading.value = false;
  }

  Future<void> createQuestion({
    String? companyId,
    String? thesisId,
    required String question,
    String priority = 'medium',
  }) async {
    if (_isMutating) return;
    _isMutating = true;
    try {
      final result = await _repository.createQuestion(
        companyId: companyId,
        thesisId: thesisId,
        question: question,
        priority: priority,
      );
      if (result.isSuccess) {
        final q = result.data!;
        questions.value = [
          ResearchQuestionIndex(
            questionId: q.id,
            companyId: q.companyId,
            thesisId: q.thesisId,
            question: q.question,
            priority: q.priority,
            status: q.status,
            createdAt: q.createdAt,
            updatedAt: q.updatedAt,
          ),
          ...questions,
        ];
      } else {
        ErrorSanitizer.debugLog('ResearchProvider', 'createQuestion failed: ${result.error}');
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> answerQuestion(String questionId, String answer) async {
    if (_isMutating) return;
    _isMutating = true;
    try {
      final result = await _repository.answerQuestion(
        questionId: questionId,
        answer: answer,
      );
      if (result.isSuccess) {
        questions.value = questions.where((q) => q.questionId != questionId).toList();
      } else {
        ErrorSanitizer.debugLog('ResearchProvider', 'answerQuestion failed: ${result.error}');
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    if (_isMutating) return;
    _isMutating = true;
    try {
      final result = await _repository.deleteQuestion(questionId);
      if (result.isSuccess) {
        questions.value = questions.where((q) => q.questionId != questionId).toList();
      } else {
        ErrorSanitizer.debugLog('ResearchProvider', 'deleteQuestion failed: ${result.error}');
      }
    } finally {
      _isMutating = false;
    }
  }

  List<ResearchCompany> get researchCompanies =>
      companies.where((c) => c.researchStatus == 'researching').toList();

  List<ResearchCompany> get filteredCompanies {
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) return researchCompanies;
    return researchCompanies.where((c) {
      return c.displayName.toLowerCase().contains(query) ||
          (c.ticker ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<ResearchThesisIndex> get filteredTheses {
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) return theses;
    return theses.where((t) {
      return t.title.toLowerCase().contains(query) ||
          t.companyName.toLowerCase().contains(query) ||
          (t.ticker ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<ResearchNoteIndex> get filteredNotes {
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) return notes;
    return notes.where((n) {
      return n.title.toLowerCase().contains(query) ||
          n.companyName.toLowerCase().contains(query) ||
          n.body.toLowerCase().contains(query) ||
          (n.ticker ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<ResearchQuestionIndex> get filteredQuestions {
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) return questions;
    return questions.where((q) {
      return q.question.toLowerCase().contains(query) ||
          (q.companyName ?? '').toLowerCase().contains(query) ||
          (q.ticker ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }
}
