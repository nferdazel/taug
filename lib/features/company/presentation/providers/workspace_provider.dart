import 'package:signals/signals.dart';

import '../../../../core/errors/result.dart';
import '../../data/workspace_models.dart';
import '../../data/workspace_repository.dart';

class WorkspaceProvider {
  final WorkspaceRepository _repository;
  final String companyId;

  final profile = Signal<CompanyProfile?>(null);
  final metrics = ListSignal<MetricSnapshot>([]);
  final statements = ListSignal<StatementRow>([]);
  final notes = ListSignal<CompanyNote>([]);
  final theses = ListSignal<CompanyThesis>([]);
  final qualityScore = Signal<double?>(null);
  final freshnessStatus = Signal<String?>(null);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final activeTab = Signal<int>(0);

  WorkspaceProvider({required this.companyId, WorkspaceRepository? repository})
      : _repository = repository ?? WorkspaceRepository();

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
    ]);

    final profileResult = results[0] as Result<CompanyProfile>;
    final metricsResult = results[1] as Result<List<MetricSnapshot>>;
    final statementsResult = results[2] as Result<List<StatementRow>>;
    final notesResult = results[3] as Result<List<CompanyNote>>;
    final thesesResult = results[4] as Result<List<CompanyThesis>>;
    final qualityResult = results[5] as Result<double?>;
    final freshnessResult = results[6] as Result<String?>;

    if (profileResult.isSuccess) profile.value = profileResult.data;
    if (metricsResult.isSuccess) metrics.value = metricsResult.data!;
    if (statementsResult.isSuccess) statements.value = statementsResult.data!;
    if (notesResult.isSuccess) notes.value = notesResult.data!;
    if (thesesResult.isSuccess) theses.value = thesesResult.data!;
    if (qualityResult.isSuccess) qualityScore.value = qualityResult.data;
    if (freshnessResult.isSuccess) freshnessStatus.value = freshnessResult.data;

    if (profileResult.isFailure) {
      error.value = profileResult.error.toString();
    }

    isLoading.value = false;
  }

  Future<void> createNote(String title, String body) async {
    final result = await _repository.createNote(
      companyId: companyId, title: title, body: body,
    );
    if (result.isSuccess) notes.value = [result.data!, ...notes];
  }

  Future<void> updateNote(String noteId, String title, String body) async {
    final result = await _repository.updateNote(noteId: noteId, title: title, body: body);
    if (result.isSuccess) {
      notes.value = notes.map((n) => n.id == noteId
          ? CompanyNote(id: n.id, companyId: n.companyId, title: title, body: body, createdAt: n.createdAt, updatedAt: DateTime.now())
          : n).toList();
    }
  }

  Future<void> deleteNote(String noteId) async {
    final result = await _repository.deleteNote(noteId);
    if (result.isSuccess) notes.value = notes.where((n) => n.id != noteId).toList();
  }

  Future<void> createThesis(String title, String stance, {String? summary, String? bullCase, String? bearCase, String conviction = 'low'}) async {
    final result = await _repository.createThesis(
      companyId: companyId, title: title, stance: stance, summary: summary, bullCase: bullCase, bearCase: bearCase, conviction: conviction,
    );
    if (result.isSuccess) theses.value = [result.data!, ...theses];
  }

  Future<void> updateThesis(String thesisId, String title, String stance, {String? summary, String? bullCase, String? bearCase, String? conviction}) async {
    final result = await _repository.updateThesis(
      thesisId: thesisId, title: title, stance: stance, summary: summary, bullCase: bullCase, bearCase: bearCase, conviction: conviction,
    );
    if (result.isSuccess) {
      theses.value = theses.map((t) => t.id == thesisId
          ? CompanyThesis(id: t.id, companyId: t.companyId, title: title, stance: stance, summary: summary ?? t.summary, bullCase: bullCase ?? t.bullCase, bearCase: bearCase ?? t.bearCase, assumptions: t.assumptions, catalysts: t.catalysts, risks: t.risks, exitConditions: t.exitConditions, conviction: conviction ?? t.conviction, createdAt: t.createdAt, updatedAt: DateTime.now())
          : t).toList();
    }
  }

  Future<void> deleteThesis(String thesisId) async {
    final result = await _repository.deleteThesis(thesisId);
    if (result.isSuccess) theses.value = theses.where((t) => t.id != thesisId).toList();
  }

  String get researchStatus {
    if (theses.isNotEmpty) return 'researching';
    if (notes.isNotEmpty) return 'researching';
    return 'not_researched';
  }
}
