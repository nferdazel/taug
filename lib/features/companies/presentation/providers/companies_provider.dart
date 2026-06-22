import 'package:signals/signals.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../data/company_list_models.dart';
import '../../data/company_list_repository.dart';

class CompaniesProvider {
  final CompanyListRepository _repository;

  final companies = ListSignal<CompanyListItem>([]);
  final qualityScores = MapSignal<String, double>({});
  final freshnessStatuses = MapSignal<String, String>({});
  final isLoading = Signal<bool>(false);
  final searchQuery = Signal<String>('');
  final error = Signal<String?>(null);

  CompaniesProvider({CompanyListRepository? repository})
      : _repository = repository ?? CompanyListRepository();

  List<CompanyListItem> get filteredCompanies {
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) return companies;
    return companies.where((c) {
      final name = c.displayName.toLowerCase();
      final ticker = (c.ticker ?? '').toLowerCase();
      return name.contains(query) || ticker.contains(query);
    }).toList();
  }

  Future<void> loadCompanies() async {
    isLoading.value = true;
    error.value = null;

    final results = await Future.wait([
      _repository.getCompanies(),
      _repository.getQualityScores(),
      _repository.getFreshnessStatuses(),
    ]);

    final companiesResult = results[0] as Result<CompanyListData>;
    final qualityResult = results[1] as Result<Map<String, double>>;
    final freshnessResult = results[2] as Result<Map<String, String>>;

    if (companiesResult.isSuccess) {
      companies.value = companiesResult.data!.companies;
    } else {
      error.value = ErrorSanitizer.message(companiesResult.error);
    }

    if (qualityResult.isSuccess) {
      qualityScores.value = qualityResult.data!;
    }

    if (freshnessResult.isSuccess) {
      freshnessStatuses.value = freshnessResult.data!;
    }

    isLoading.value = false;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  double? getQualityScore(String companyId) => qualityScores[companyId];

  String? getFreshnessStatus(String companyId) => freshnessStatuses[companyId];

  String getResearchStatus(CompanyListItem company) {
    return company.researchStatus;
  }
}
