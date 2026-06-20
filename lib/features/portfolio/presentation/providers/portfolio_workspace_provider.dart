import 'package:signals/signals.dart';

import '../../data/portfolio_models.dart';
import '../../data/portfolio_workspace_repository.dart';

class PortfolioProvider {
  final PortfolioRepository _repository;

  final positions = ListSignal<PortfolioPosition>([]);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final activeTab = Signal<int>(0);

  PortfolioProvider({PortfolioRepository? repository})
      : _repository = repository ?? PortfolioRepository();

  List<PortfolioPosition> get activePositions =>
      positions.where((p) => p.isActive || p.isReviewNeeded).toList();

  List<PortfolioPosition> get closedPositions =>
      positions.where((p) => p.isClosed).toList();

  int get activeCount => activePositions.length;
  int get reviewCount => activePositions.where((p) => p.isReviewNeeded).length;
  int get closedCount => closedPositions.length;

  Future<void> loadPositions() async {
    isLoading.value = true;
    error.value = null;

    final result = await _repository.getPositions();
    if (result.isSuccess) {
      positions.value = result.data!;
    } else {
      error.value = result.error.toString();
    }

    isLoading.value = false;
  }

  Future<void> addPosition({
    required String companyId,
    String? thesisId,
    required String conviction,
    required DateTime entryDate,
    double? entryPrice,
    String? notes,
  }) async {
    final result = await _repository.createPosition(
      companyId: companyId,
      thesisId: thesisId,
      conviction: conviction,
      entryDate: entryDate,
      entryPrice: entryPrice,
      notes: notes,
    );
    if (result.isSuccess) {
      positions.value = [result.data!, ...positions];
    }
  }

  Future<void> updatePosition({
    required String positionId,
    String? conviction,
    double? entryPrice,
    String? notes,
    String? thesisId,
  }) async {
    final result = await _repository.updatePosition(
      positionId: positionId,
      conviction: conviction,
      entryPrice: entryPrice,
      notes: notes,
      thesisId: thesisId,
    );
    if (result.isSuccess) {
      await loadPositions();
    }
  }

  Future<void> closePosition({
    required String positionId,
    required String outcome,
    String? lessonsLearned,
    DateTime? exitDate,
    double? exitPrice,
  }) async {
    final result = await _repository.closePosition(
      positionId: positionId,
      outcome: outcome,
      lessonsLearned: lessonsLearned,
      exitDate: exitDate,
      exitPrice: exitPrice,
    );
    if (result.isSuccess) {
      await loadPositions();
    }
  }
}
