import 'package:signals/signals.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../data/company_repository.dart';

class CompanyProvider {
  final CompanyRepository _repository;

  final Signal<CompanyFullProfile?> profile = Signal<CompanyFullProfile?>(null);
  final Signal<bool> isLoading = Signal<bool>(false);
  final Signal<String?> error = Signal<String?>(null);
  final Signal<String?> selectedCompanyId = Signal<String?>(null);

  CompanyProvider({CompanyRepository? repository})
      : _repository = repository ?? CompanyRepository();

  Future<void> loadCompany(String companyId) async {
    selectedCompanyId.value = companyId;
    isLoading.value = true;
    error.value = null;

    final result = await _repository.getFullProfile(companyId: companyId);

    if (result.isSuccess) {
      profile.value = result.data!;
    } else {
      error.value = ErrorSanitizer.message(result.error);
    }

    isLoading.value = false;
  }

  void dispose() {
    profile.dispose();
    isLoading.dispose();
    error.dispose();
    selectedCompanyId.dispose();
  }
}
