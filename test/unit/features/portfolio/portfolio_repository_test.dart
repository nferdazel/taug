import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taug/features/portfolio/data/portfolio_models.dart';
import 'package:taug/features/portfolio/data/portfolio_workspace_repository.dart';

import '../../../helpers/test_helpers.dart';

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockSelectFilter;
  late MockPostgrestTransformBuilder<List<Map<String, dynamic>>> mockSelectTransform;
  late PortfolioRepository repository;

  const testUserId = 'user-abc-123';

  setUp(() {
    mockClient = createMockSupabaseClient();
    mockAuth = mockClient.auth as MockGoTrueClient;
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockSelectFilter = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    mockSelectTransform = MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(testUserId);

    repository = PortfolioRepository(client: mockClient);
  });

  Map<String, dynamic> buildPositionJson({
    String id = 'pos-1',
    String companyId = 'comp-1',
    String companyName = 'Apple Inc.',
    String conviction = 'high',
    String status = 'active',
    String entryDate = '2026-01-15',
    double? entryPrice = 150.0,
    String? exitDate,
    double? exitPrice,
    String? outcome,
    String? lessonsLearned,
    String? thesisId,
    String? stance,
  }) {
    return {
      'id': id,
      'company_id': companyId,
      'companies': {'display_name': companyName},
      'thesis_id': thesisId,
      'conviction': conviction,
      'entry_date': entryDate,
      'entry_price': entryPrice,
      'notes': 'test note',
      'status': status,
      'exit_date': exitDate,
      'exit_price': exitPrice,
      'outcome': outcome,
      'lessons_learned': lessonsLearned,
      'created_at': '2026-01-15T00:00:00',
      'updated_at': '2026-06-01T00:00:00',
      if (stance != null)
        'investment_theses': {'stance': stance},
    };
  }

  /// Wire a select -> eq -> order -> await chain.
  void setupSelectQuery(dynamic data) {
    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockSelectFilter);
    when(() => mockSelectFilter.eq(any(), any())).thenAnswer((_) => mockSelectFilter);
    when(() => mockSelectFilter.order(any(), ascending: any(named: 'ascending')))
        .thenAnswer((_) => mockSelectTransform);
    mockSelectTransform.stubFuture(data);
  }

  /// Wire a select -> eq -> await chain (no order).
  void setupSelectFilterQuery(dynamic data) {
    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockSelectFilter);
    when(() => mockSelectFilter.eq(any(), any())).thenAnswer((_) => mockSelectFilter);
    mockSelectFilter.stubFuture(data);
  }

  /// Wire an update -> eq -> await chain.
  void setupUpdateQuery() {
    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.update(any())).thenAnswer((_) => mockSelectFilter);
    when(() => mockSelectFilter.eq(any(), any())).thenAnswer((_) => mockSelectFilter);
    mockSelectFilter.stubFuture(null);
  }

  group('PortfolioRepository', () {
    group('getPositions', () {
      test('returns positions filtered by user_id on success', () async {
        setupSelectQuery([
          buildPositionJson(id: 'pos-1', companyName: 'Apple Inc.'),
          buildPositionJson(id: 'pos-2', companyId: 'comp-2', companyName: 'Tesla Inc.', conviction: 'medium'),
        ]);

        final result = await repository.getPositions();

        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(2));
        expect(result.data![0].id, 'pos-1');
        expect(result.data![0].companyName, 'Apple Inc.');
        expect(result.data![1].id, 'pos-2');
        verify(() => mockSelectFilter.eq('user_id', testUserId)).called(1);
      });

      test('applies status filter when provided', () async {
        setupSelectQuery([]);
        await repository.getPositions(status: 'active');
        verify(() => mockSelectFilter.eq('status', 'active')).called(1);
      });

      test('returns empty list when no positions exist', () async {
        setupSelectQuery([]);
        final result = await repository.getPositions();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        final result = await repository.getPositions();
        expect(result.isFailure, isTrue);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any())).thenThrow(Exception('connection refused'));
        final result = await repository.getPositions();
        expect(result.isFailure, isTrue);
      });

      test('maps status string to PositionStatus enum', () async {
        setupSelectQuery([
          buildPositionJson(status: 'active'),
          buildPositionJson(id: 'pos-2', status: 'review_needed'),
          buildPositionJson(id: 'pos-3', status: 'closed'),
        ]);
        final result = await repository.getPositions();
        expect(result.data![0].status, PositionStatus.active);
        expect(result.data![1].status, PositionStatus.reviewNeeded);
        expect(result.data![2].status, PositionStatus.closed);
      });

      test('maps outcome string to PositionOutcome enum', () async {
        setupSelectQuery([
          buildPositionJson(id: 'pos-1', status: 'closed', outcome: 'correct', exitDate: '2026-06-01'),
          buildPositionJson(id: 'pos-2', status: 'closed', outcome: 'incorrect', exitDate: '2026-06-01'),
          buildPositionJson(id: 'pos-3', status: 'closed', outcome: 'partial', exitDate: '2026-06-01'),
          buildPositionJson(id: 'pos-4', status: 'active', outcome: null),
        ]);
        final result = await repository.getPositions();
        expect(result.data![0].outcome, PositionOutcome.correct);
        expect(result.data![1].outcome, PositionOutcome.incorrect);
        expect(result.data![2].outcome, PositionOutcome.partial);
        expect(result.data![3].outcome, isNull);
      });
    });

    group('getLessonsForCompany', () {
      void wireLessonsQuery(dynamic data) {
        when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.not(any(), any(), any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.order(any(), ascending: any(named: 'ascending')))
            .thenAnswer((_) => mockSelectTransform);
        when(() => mockSelectTransform.limit(any())).thenAnswer((_) => mockSelectTransform);
        mockSelectTransform.stubFuture(data);
      }

      test('returns lessons for closed positions only', () async {
        wireLessonsQuery([
          buildPositionJson(id: 'pos-1', status: 'closed', lessonsLearned: 'Follow the trend', exitDate: '2026-06-01', outcome: 'correct'),
        ]);
        final result = await repository.getLessonsForCompany('comp-1');
        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(1));
        expect(result.data![0].lessonsLearned, 'Follow the trend');
        verify(() => mockSelectFilter.eq('company_id', 'comp-1')).called(1);
        verify(() => mockSelectFilter.eq('status', 'closed')).called(1);
      });

      test('filters by not null lessons_learned', () async {
        wireLessonsQuery([]);
        await repository.getLessonsForCompany('comp-1');
        verify(() => mockSelectFilter.not('lessons_learned', 'is', null)).called(1);
      });

      test('orders by exit_date descending', () async {
        wireLessonsQuery([]);
        await repository.getLessonsForCompany('comp-1');
        verify(() => mockSelectFilter.order('exit_date', ascending: false)).called(1);
      });

      test('limits to 10 results', () async {
        wireLessonsQuery([]);
        await repository.getLessonsForCompany('comp-1');
        verify(() => mockSelectTransform.limit(10)).called(1);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        final result = await repository.getLessonsForCompany('comp-1');
        expect(result.isFailure, isTrue);
      });
    });

    group('markReviewNeeded', () {
      test('updates position status to review_needed', () async {
        setupUpdateQuery();
        final result = await repository.markReviewNeeded('pos-1');
        expect(result.isSuccess, isTrue);
        verify(() => mockQueryBuilder.update(any())).called(1);
        verify(() => mockSelectFilter.eq('id', 'pos-1')).called(1);
        verify(() => mockSelectFilter.eq('user_id', testUserId)).called(1);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        final result = await repository.markReviewNeeded('pos-1');
        expect(result.isFailure, isTrue);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any())).thenThrow(Exception('network error'));
        final result = await repository.markReviewNeeded('pos-1');
        expect(result.isFailure, isTrue);
      });
    });

    group('getAllPatternData', () {
      test('returns all pattern data in single query', () async {
        setupSelectFilterQuery([
          buildPositionJson(id: 'pos-1', status: 'closed', outcome: 'correct', stance: 'bullish', conviction: 'high'),
          buildPositionJson(id: 'pos-2', status: 'closed', outcome: 'incorrect', stance: 'bullish', conviction: 'low'),
          buildPositionJson(id: 'pos-3', status: 'closed', outcome: 'correct', stance: 'bearish', conviction: 'high'),
        ]);
        final result = await repository.getAllPatternData(testUserId);
        expect(result.isSuccess, isTrue);
        final data = result.data!;
        expect(data['stanceAccuracy'], isA<Map<String, int>>());
        expect(data['convictionAccuracy'], isA<Map<String, int>>());
        expect(data['commonThemes'], isA<List<String>>());
        expect(data['holdingPeriodStats'], isA<Map<String, dynamic>>());
        expect(data['overallStats'], isA<Map<String, int>>());
      });

      test('returns failure when upstream query fails', () async {
        when(() => mockClient.from(any())).thenThrow(Exception('db down'));
        final result = await repository.getAllPatternData(testUserId);
        expect(result.isFailure, isTrue);
      });
    });

    group('closePosition', () {
      test('updates position to closed with outcome and lessons', () async {
        setupUpdateQuery();
        final result = await repository.closePosition(
          positionId: 'pos-1', outcome: 'correct', lessonsLearned: 'Follow momentum',
        );
        expect(result.isSuccess, isTrue);
        verify(() => mockQueryBuilder.update(any())).called(1);
        verify(() => mockSelectFilter.eq('id', 'pos-1')).called(1);
        verify(() => mockSelectFilter.eq('user_id', testUserId)).called(1);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        final result = await repository.closePosition(positionId: 'pos-1', outcome: 'correct');
        expect(result.isFailure, isTrue);
      });
    });
  });
}
