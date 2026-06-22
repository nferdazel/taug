import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/result.dart';
import 'portfolio_models.dart';

class PortfolioRepository {
  final SupabaseClient _client;

  PortfolioRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get clientId => _client.auth.currentUser?.id;

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

  Future<Result<List<PortfolioPosition>>> getLessonsForCompany(String companyId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[PortfolioRepo] getLessonsForCompany: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from('portfolio_positions')
          .select('*, companies!inner(display_name)')
          .eq('user_id', userId)
          .eq('company_id', companyId)
          .eq('status', 'closed')
          .not('lessons_learned', 'is', null)
          .order('exit_date', ascending: false)
          .limit(10);

      final positions = (response as List).map((p) => _mapPosition(p)).toList();
      return Result.success(positions);
    } catch (e) {
      debugPrint('[PortfolioRepo] getLessonsForCompany: $e');
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

  // ── Pattern Intelligence Methods ──

  Future<Result<List<_ClosedPositionWithStance>>> _fetchClosedWithStance(String userId) async {
    try {
      final response = await _client
          .from('portfolio_positions')
          .select('*, companies!inner(display_name), investment_theses!left(stance)')
          .eq('user_id', userId)
          .eq('status', 'closed');

      final positions = (response as List).map((p) {
        final thesis = p['investment_theses'] as Map<String, dynamic>?;
        return _ClosedPositionWithStance(
          position: _mapPosition(p),
          stance: thesis?['stance'] as String?,
        );
      }).toList();
      return Result.success(positions);
    } catch (e) {
      debugPrint('[PortfolioRepo] _fetchClosedWithStance: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<Map<String, int>>> getStanceAccuracy(String userId) async {
    try {
      final closedResult = await _fetchClosedWithStance(userId);
      if (closedResult.isFailure) return Result.failure(closedResult.error);

      final Map<String, int> counts = {};
      for (final entry in closedResult.data!) {
        final stance = entry.stance ?? 'neutral';
        final outcome = entry.position.outcome;
        if (outcome == null) continue;

        switch (outcome) {
          case PositionOutcome.correct:
            counts['${stance}_correct'] = (counts['${stance}_correct'] ?? 0) + 1;
          case PositionOutcome.incorrect:
            counts['${stance}_incorrect'] = (counts['${stance}_incorrect'] ?? 0) + 1;
          case PositionOutcome.partial:
            counts['${stance}_partial'] = (counts['${stance}_partial'] ?? 0) + 1;
        }
      }
      return Result.success(counts);
    } catch (e) {
      debugPrint('[PortfolioRepo] getStanceAccuracy: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<Map<String, int>>> getConvictionAccuracy(String userId) async {
    try {
      final closedResult = await _fetchClosedWithStance(userId);
      if (closedResult.isFailure) return Result.failure(closedResult.error);

      final Map<String, int> counts = {};
      for (final entry in closedResult.data!) {
        final conviction = entry.position.conviction;
        final outcome = entry.position.outcome;
        if (outcome == null) continue;

        switch (outcome) {
          case PositionOutcome.correct:
            counts['${conviction}_correct'] = (counts['${conviction}_correct'] ?? 0) + 1;
          case PositionOutcome.incorrect:
            counts['${conviction}_incorrect'] = (counts['${conviction}_incorrect'] ?? 0) + 1;
          case PositionOutcome.partial:
            counts['${conviction}_partial'] = (counts['${conviction}_partial'] ?? 0) + 1;
        }
      }
      return Result.success(counts);
    } catch (e) {
      debugPrint('[PortfolioRepo] getConvictionAccuracy: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<String>>> getCommonLessonThemes(String userId) async {
    try {
      final closedResult = await _fetchClosedWithStance(userId);
      if (closedResult.isFailure) return Result.failure(closedResult.error);

      final wordCounts = <String, int>{};
      for (final entry in closedResult.data!) {
        final lesson = entry.position.lessonsLearned;
        if (lesson == null || lesson.isEmpty) continue;
        final words = _extractSignificantWords(lesson);
        for (final word in words) {
          wordCounts[word] = (wordCounts[word] ?? 0) + 1;
        }
      }

      final sorted = wordCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Result.success(sorted.take(5).map((e) => e.key).toList());
    } catch (e) {
      debugPrint('[PortfolioRepo] getCommonLessonThemes: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<Map<String, double>>> getHoldingPeriodStats(String userId) async {
    try {
      final closedResult = await _fetchClosedWithStance(userId);
      if (closedResult.isFailure) return Result.failure(closedResult.error);

      double correctTotal = 0;
      int correctCount = 0;
      double incorrectTotal = 0;
      int incorrectCount = 0;

      for (final entry in closedResult.data!) {
        final pos = entry.position;
        if (pos.exitDate == null) continue;
        final days = pos.exitDate!.difference(pos.entryDate).inDays.toDouble();

        if (pos.outcome == PositionOutcome.correct) {
          correctTotal += days;
          correctCount++;
        } else if (pos.outcome == PositionOutcome.incorrect) {
          incorrectTotal += days;
          incorrectCount++;
        }
      }

      return Result.success({
        'correct_avg': correctCount > 0 ? correctTotal / correctCount : 0,
        'incorrect_avg': incorrectCount > 0 ? incorrectTotal / incorrectCount : 0,
      });
    } catch (e) {
      debugPrint('[PortfolioRepo] getHoldingPeriodStats: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<Map<String, int>>> getOverallStats(String userId) async {
    try {
      final closedResult = await _fetchClosedWithStance(userId);
      if (closedResult.isFailure) return Result.failure(closedResult.error);

      int correct = 0;
      int incorrect = 0;
      int partial = 0;
      for (final entry in closedResult.data!) {
        switch (entry.position.outcome) {
          case PositionOutcome.correct:
            correct++;
          case PositionOutcome.incorrect:
            incorrect++;
          case PositionOutcome.partial:
            partial++;
          case null:
            break;
        }
      }

      return Result.success({
        'total': closedResult.data!.length,
        'correct': correct,
        'incorrect': incorrect,
        'partial': partial,
      });
    } catch (e) {
      debugPrint('[PortfolioRepo] getOverallStats: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  static const _stopWords = {
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i',
    'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
    'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her',
    'she', 'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there',
    'their', 'what', 'so', 'up', 'out', 'if', 'about', 'who', 'get',
    'which', 'go', 'me', 'when', 'make', 'can', 'like', 'time', 'no',
    'just', 'him', 'know', 'take', 'people', 'into', 'year', 'your',
    'good', 'some', 'could', 'them', 'see', 'other', 'than', 'then',
    'now', 'look', 'only', 'come', 'its', 'over', 'think', 'also',
    'back', 'after', 'use', 'two', 'how', 'our', 'work', 'first',
    'well', 'way', 'even', 'new', 'want', 'because', 'any', 'these',
    'give', 'day', 'most', 'us', 'is', 'are', 'was', 'were', 'been',
    'has', 'had', 'did', 'does', 'should', 'very', 'much', 'too',
    'more', 'may', 'need', 'still', 'being',
    'already', 'didn', 'wasn', 'isn', 'hasn', 'doesn', 'wouldn',
    'shouldn', 'couldn', 'won', 'don', 'hadn', 'aren',
    'position', 'stock', 'bought', 'sold', 'hold', 'held',
  };

  List<String> _extractSignificantWords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s-]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4 && !_stopWords.contains(w))
        .toList();
    return words;
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

class _ClosedPositionWithStance {
  final PortfolioPosition position;
  final String? stance;

  const _ClosedPositionWithStance({required this.position, this.stance});
}
