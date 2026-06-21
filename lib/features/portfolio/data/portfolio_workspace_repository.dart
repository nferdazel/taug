import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/result.dart';
import 'portfolio_models.dart';

class PortfolioRepository {
  final SupabaseClient _client;

  PortfolioRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<List<PortfolioPosition>>> getPositions({String? status}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[PortfolioRepo] getPositions: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      var query = _client
          .from('portfolio_positions')
          .select('*, companies!inner(display_name)')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('updated_at', ascending: false);
      final positions = (response as List).map((p) => _mapPosition(p)).toList();
      return Result.success(positions);
    } catch (e) {
      debugPrint('[PortfolioRepo] getPositions: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<PortfolioPosition>> createPosition({
    required String companyId,
    String? thesisId,
    required String conviction,
    required DateTime entryDate,
    double? entryPrice,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from('portfolio_positions')
          .insert({
            'user_id': userId,
            'company_id': companyId,
            'thesis_id': thesisId,
            'conviction': conviction,
            'entry_date': entryDate.toIso8601String().substring(0, 10),
            'entry_price': entryPrice,
            'notes': notes,
            'status': 'active',
          })
          .select('*, companies!inner(display_name)')
          .single();

      return Result.success(_mapPosition(response));
    } catch (e) {
      debugPrint('[PortfolioRepo] createPosition: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> updatePosition({
    required String positionId,
    String? conviction,
    double? entryPrice,
    String? notes,
    String? thesisId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[PortfolioRepo] updatePosition: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final update = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (conviction != null) update['conviction'] = conviction;
      if (entryPrice != null) update['entry_price'] = entryPrice;
      if (notes != null) update['notes'] = notes;
      if (thesisId != null) update['thesis_id'] = thesisId;

      await _client
          .from('portfolio_positions')
          .update(update)
          .eq('id', positionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[PortfolioRepo] updatePosition: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> closePosition({
    required String positionId,
    required String outcome,
    String? lessonsLearned,
    DateTime? exitDate,
    double? exitPrice,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[PortfolioRepo] closePosition: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from('portfolio_positions')
          .update({
            'status': 'closed',
            'outcome': outcome,
            'lessons_learned': lessonsLearned,
            'exit_date': (exitDate ?? DateTime.now()).toIso8601String().substring(0, 10),
            'exit_price': exitPrice,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', positionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[PortfolioRepo] closePosition: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> markReviewNeeded(String positionId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[PortfolioRepo] markReviewNeeded: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from('portfolio_positions')
          .update({
            'status': 'review_needed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', positionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[PortfolioRepo] markReviewNeeded: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  PortfolioPosition _mapPosition(Map<String, dynamic> p) {
    final company = p['companies'] as Map<String, dynamic>?;
    return PortfolioPosition(
      id: p['id'] as String,
      companyId: p['company_id'] as String,
      companyName: company?['display_name'] as String?,
      thesisId: p['thesis_id'] as String?,
      conviction: p['conviction'] as String? ?? 'low',
      entryDate: DateTime.parse(p['entry_date'] as String),
      entryPrice: (p['entry_price'] as num?)?.toDouble(),
      notes: p['notes'] as String?,
      status: _parseStatus(p['status'] as String? ?? 'active'),
      exitDate: p['exit_date'] != null ? DateTime.parse(p['exit_date'] as String) : null,
      exitPrice: (p['exit_price'] as num?)?.toDouble(),
      outcome: _parseOutcome(p['outcome'] as String?),
      lessonsLearned: p['lessons_learned'] as String?,
      createdAt: DateTime.parse(p['created_at'] as String),
      updatedAt: DateTime.parse(p['updated_at'] as String),
    );
  }

  PositionStatus _parseStatus(String s) {
    switch (s) {
      case 'active': return PositionStatus.active;
      case 'review_needed': return PositionStatus.reviewNeeded;
      case 'closed': return PositionStatus.closed;
      default: return PositionStatus.active;
    }
  }

  PositionOutcome? _parseOutcome(String? s) {
    switch (s) {
      case 'correct': return PositionOutcome.correct;
      case 'incorrect': return PositionOutcome.incorrect;
      case 'partial': return PositionOutcome.partial;
      default: return null;
    }
  }
}
