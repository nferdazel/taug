import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taug/features/portfolio/data/portfolio_workspace_repository.dart';

import '../../../helpers/test_helpers.dart';

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockSelectFilter;
  late PortfolioPositionRepository repository;

  const testUserId = 'user-pattern-001';

  setUp(() {
    mockClient = createMockSupabaseClient();
    mockAuth = mockClient.auth as MockGoTrueClient;
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockSelectFilter =
        MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(testUserId);

    repository = PortfolioPositionRepository(client: mockClient);
  });

  /// Wire the closed positions query used by all pattern intelligence methods.
  void wireClosedPositionsQuery(dynamic data) {
    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.select(any()))
        .thenAnswer((_) => mockSelectFilter);
    when(() => mockSelectFilter.eq(any(), any()))
        .thenAnswer((_) => mockSelectFilter);
    mockSelectFilter.stubFuture(data);
  }

  Map<String, dynamic> buildClosedPosition({
    String id = 'pos-1',
    String companyId = 'comp-1',
    String conviction = 'high',
    String status = 'closed',
    String entryDate = '2026-01-15',
    String exitDate = '2026-06-15',
    double entryPrice = 100.0,
    double exitPrice = 120.0,
    String? outcome,
    String? lessonsLearned,
    String? stance,
  }) {
    return {
      'id': id,
      'company_id': companyId,
      'companies': {'display_name': 'Test Corp'},
      'thesis_id': 'th-1',
      'conviction': conviction,
      'entry_date': entryDate,
      'entry_price': entryPrice,
      'notes': null,
      'status': status,
      'exit_date': exitDate,
      'exit_price': exitPrice,
      'outcome': outcome,
      'lessons_learned': lessonsLearned,
      'created_at': '2026-01-15T00:00:00',
      'updated_at': '2026-06-15T00:00:00',
      if (stance != null) 'investment_theses': {'stance': stance},
    };
  }

  group('Pattern Intelligence', () {
    group('getAllPatternData', () {
      test('returns all pattern data in single query', () async {
        wireClosedPositionsQuery([
          buildClosedPosition(
              id: 'p1',
              outcome: 'correct',
              stance: 'bullish',
              conviction: 'high',
              lessonsLearned: 'Follow momentum'),
          buildClosedPosition(
              id: 'p2',
              outcome: 'incorrect',
              stance: 'bullish',
              conviction: 'low',
              lessonsLearned: 'Avoid FOMO'),
          buildClosedPosition(
              id: 'p3',
              outcome: 'correct',
              stance: 'bearish',
              conviction: 'high'),
          buildClosedPosition(
              id: 'p4',
              outcome: 'partial',
              stance: 'bullish',
              conviction: 'medium'),
        ]);

        final result = await repository.getAllPatternData(testUserId);

        expect(result.isSuccess, isTrue);
        final data = result.data!;

        // Stance accuracy
        final stance = data['stanceAccuracy'] as Map<String, int>;
        expect(stance['bullish_correct'], 1);
        expect(stance['bullish_incorrect'], 1);
        expect(stance['bullish_partial'], 1);
        expect(stance['bearish_correct'], 1);

        // Conviction accuracy
        final conviction = data['convictionAccuracy'] as Map<String, int>;
        expect(conviction['high_correct'], 2);
        expect(conviction['low_incorrect'], 1);
        expect(conviction['medium_partial'], 1);

        // Common themes
        final themes = data['commonThemes'] as List<String>;
        expect(themes, isNotEmpty);

        // Holding period stats
        final holding = data['holdingPeriodStats'] as Map<String, dynamic>;
        expect(holding['correct_avg'], isNotNull);
        expect(holding['incorrect_avg'], isNotNull);

        // Overall stats
        final overall = data['overallStats'] as Map<String, int>;
        expect(overall['total'], 4);
        expect(overall['correct'], 2);
        expect(overall['incorrect'], 1);
        expect(overall['partial'], 1);
      });

      test('handles empty closed positions', () async {
        wireClosedPositionsQuery([]);

        final result = await repository.getAllPatternData(testUserId);

        expect(result.isSuccess, isTrue);
        final data = result.data!;
        expect(data['stanceAccuracy'], isEmpty);
        expect(data['convictionAccuracy'], isEmpty);
        expect(data['commonThemes'], isEmpty);
        expect((data['overallStats'] as Map<String, int>)['total'], 0);
      });

      test('defaults null stance to neutral', () async {
        wireClosedPositionsQuery([
          buildClosedPosition(id: 'p1', outcome: 'correct', stance: null),
        ]);

        final result = await repository.getAllPatternData(testUserId);

        expect(result.isSuccess, isTrue);
        final stance = result.data!['stanceAccuracy'] as Map<String, int>;
        expect(stance['neutral_correct'], 1);
      });

      test('skips positions with null outcome', () async {
        wireClosedPositionsQuery([
          buildClosedPosition(id: 'p1', outcome: null, stance: 'bullish'),
        ]);

        final result = await repository.getAllPatternData(testUserId);

        expect(result.isSuccess, isTrue);
        expect(result.data!['stanceAccuracy'], isEmpty);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any())).thenThrow(Exception('db down'));

        final result = await repository.getAllPatternData(testUserId);

        expect(result.isFailure, isTrue);
      });
    });
  });
}
