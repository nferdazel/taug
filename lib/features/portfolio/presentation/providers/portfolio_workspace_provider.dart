import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../../../shared/models/price_data.dart';
import '../../data/portfolio_models.dart';
import '../../data/portfolio_repository.dart' as legacy;
import '../../data/portfolio_workspace_repository.dart';

class PortfolioWorkspaceProvider {
  final PortfolioRepository _repository;
  final legacy.PortfolioRepository _priceRepository;

  final positions = ListSignal<PortfolioPosition>([]);
  final isLoading = Signal<bool>(false);
  final error = Signal<String?>(null);
  final activeTab = Signal<int>(0);
  final prices = MapSignal<String, PriceData>({});
  bool _isMutating = false;

  // ── Pattern Intelligence Signals ──
  final stanceAccuracy = Signal<Map<String, int>>({});
  final convictionAccuracy = Signal<Map<String, int>>({});
  final commonThemes = Signal<List<String>>([]);
  final holdingPeriodStats = Signal<Map<String, double>>({});
  final overallStats = Signal<Map<String, int>>({});

  PortfolioWorkspaceProvider({
    PortfolioRepository? repository,
    legacy.PortfolioRepository? priceRepository,
  })  : _repository = repository ?? PortfolioRepository(),
        _priceRepository = priceRepository ?? legacy.PortfolioRepository();

  void dispose() {
    positions.dispose();
    isLoading.dispose();
    error.dispose();
    activeTab.dispose();
    prices.dispose();
    stanceAccuracy.dispose();
    convictionAccuracy.dispose();
    commonThemes.dispose();
    holdingPeriodStats.dispose();
    overallStats.dispose();
  }

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
      await _loadPricesForActivePositions();
    } else {
      error.value = ErrorSanitizer.message(result.error);
    }

    isLoading.value = false;
  }

  Future<void> _loadPricesForActivePositions() async {
    final tickers = activePositions
        .where((p) => p.ticker != null && p.ticker!.isNotEmpty)
        .map((p) => p.ticker!)
        .toSet()
        .toList();
    if (tickers.isEmpty) return;

    final result = await _priceRepository.getPrices(tickers);
    if (result.isSuccess) {
      prices.value = result.data!;
    } else {
      debugPrint('[PortfolioWorkspace] loadPrices error: ${result.error}');
    }
  }

  /// Get current price for a position's ticker
  PriceData? getPriceForTicker(String? ticker) {
    if (ticker == null || ticker.isEmpty) return null;
    return prices[ticker];
  }

  Future<void> loadPatterns() async {
    final userId = _repository.clientId;
    if (userId == null) return;

    final result = await _repository.getAllPatternData(userId);
    if (result.isSuccess) {
      final data = result.data!;
      stanceAccuracy.value = data['stanceAccuracy'] as Map<String, int>;
      convictionAccuracy.value = data['convictionAccuracy'] as Map<String, int>;
      commonThemes.value = data['commonThemes'] as List<String>;
      holdingPeriodStats.value = data['holdingPeriodStats'] as Map<String, double>;
      overallStats.value = data['overallStats'] as Map<String, int>;
    } else {
      debugPrint('[PortfolioWorkspace] loadPatterns error: ${result.error}');
    }
  }

  Future<void> addPosition({
    required String companyId,
    String? thesisId,
    required String conviction,
    required DateTime entryDate,
    double? entryPrice,
    String? notes,
  }) async {
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
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
      } else {
        ErrorSanitizer.debugLog('PortfolioWorkspaceProvider', 'addPosition failed: ${result.error}');
        error.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> updatePosition({
    required String positionId,
    String? conviction,
    double? entryPrice,
    String? notes,
    String? thesisId,
  }) async {
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
      final result = await _repository.updatePosition(
        positionId: positionId,
        conviction: conviction,
        entryPrice: entryPrice,
        notes: notes,
        thesisId: thesisId,
      );
      if (result.isSuccess) {
        await loadPositions();
      } else {
        ErrorSanitizer.debugLog('PortfolioWorkspaceProvider', 'updatePosition failed: ${result.error}');
        error.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> closePosition({
    required String positionId,
    required String outcome,
    String? lessonsLearned,
    DateTime? exitDate,
    double? exitPrice,
  }) async {
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
      final result = await _repository.closePosition(
        positionId: positionId,
        outcome: outcome,
        lessonsLearned: lessonsLearned,
        exitDate: exitDate,
        exitPrice: exitPrice,
      );
      if (result.isSuccess) {
        await loadPositions();
      } else {
        ErrorSanitizer.debugLog('PortfolioWorkspaceProvider', 'closePosition failed: ${result.error}');
        error.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }

  Future<void> markReviewNeeded(String positionId) async {
    if (_isMutating) return;
    _isMutating = true;
    error.value = null;
    try {
      final result = await _repository.markReviewNeeded(positionId);
      if (result.isSuccess) {
        final index = positions.indexWhere((p) => p.id == positionId);
        if (index != -1) {
          final updated = PortfolioPosition(
            id: positions[index].id,
            companyId: positions[index].companyId,
            companyName: positions[index].companyName,
            ticker: positions[index].ticker,
            thesisId: positions[index].thesisId,
            thesisTitle: positions[index].thesisTitle,
            thesisStance: positions[index].thesisStance,
            conviction: positions[index].conviction,
            entryDate: positions[index].entryDate,
            entryPrice: positions[index].entryPrice,
            notes: positions[index].notes,
            status: PositionStatus.reviewNeeded,
            exitDate: positions[index].exitDate,
            exitPrice: positions[index].exitPrice,
            outcome: positions[index].outcome,
            lessonsLearned: positions[index].lessonsLearned,
            createdAt: positions[index].createdAt,
            updatedAt: DateTime.now(),
          );
          positions.value = [
            for (int i = 0; i < positions.length; i++)
              if (i == index) updated else positions[i],
          ];
        }
      } else {
        ErrorSanitizer.debugLog('PortfolioWorkspaceProvider', 'markReviewNeeded failed: ${result.error}');
        error.value = ErrorSanitizer.message(result.error);
      }
    } finally {
      _isMutating = false;
    }
  }
}
