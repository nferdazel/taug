import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';

import '../../../../core/errors/result.dart';
import '../../data/research_models.dart';
import '../../data/research_repository.dart';

class ResearchProvider {
  final ResearchRepository _repository;

  final companies = ListSignal<ResearchCompany>([]);
  final theses = ListSignal<ResearchThesisIndex>([]);
  final notes = ListSignal<ResearchNoteIndex>([]);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final searchQuery = Signal<String>('');
  final activeTab = Signal<int>(0);

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
      ]);

      final companiesResult = results[0] as Result<List<ResearchCompany>>;
      final thesesResult = results[1] as Result<List<ResearchThesisIndex>>;
      final notesResult = results[2] as Result<List<ResearchNoteIndex>>;

      if (companiesResult.isSuccess) companies.value = companiesResult.data!;
      if (thesesResult.isSuccess) theses.value = thesesResult.data!;
      if (notesResult.isSuccess) notes.value = notesResult.data!;
    } catch (e) {
      debugPrint('[ResearchProvider] loadAll error: $e');
      error.value = e.toString();
    }

    isLoading.value = false;
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

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }
}
