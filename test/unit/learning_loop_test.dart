import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taug/features/portfolio/data/portfolio_models.dart';
import 'package:taug/features/portfolio/data/portfolio_workspace_repository.dart';

import '../helpers/test_helpers.dart';

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockSelectFilter;
  late MockPostgrestTransformBuilder<List<Map<String, dynamic>>> mockSelectTransform;
  late PortfolioRepository repository;

  const testUserId = 'user-learn-001';

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

  Map<String, dynamic> buildClosedPosition({
    String id = 'pos-1',
    String companyId = 'comp-1',
    String exitDate = '2026-06-15',
    String? lessonsLearned = 'Lesson text',
  }) {
    return {
      'id': id,
      'company_id': companyId,
      'companies': {'display_name': 'Test Corp'},
      'thesis_id': null,
      'conviction': 'medium',
      'entry_date': '2026-01-01',
      'entry_price': 100.0,
      'notes': null,
      'status': 'closed',
      'exit_date': exitDate,
      'exit_price': 120.0,
      'outcome': 'correct',
      'lessons_learned': lessonsLearned,
      'created_at': '2026-01-01T00:00:00',
      'updated_at': '2026-06-15T00:00:00',
    };
  }

  group('Learning Loop', () {
    test('fetches lessons for the correct company', () async {
      wireLessonsQuery([buildClosedPosition(id: 'pos-1', companyId: 'comp-42')]);
      final result = await repository.getLessonsForCompany('comp-42');
      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      verify(() => mockSelectFilter.eq('company_id', 'comp-42')).called(1);
    });

    test('filters lessons to closed positions only', () async {
      wireLessonsQuery([]);
      await repository.getLessonsForCompany('comp-1');
      verify(() => mockSelectFilter.eq('status', 'closed')).called(1);
    });

    test('filters lessons to those with non-null lessons_learned', () async {
      wireLessonsQuery([]);
      await repository.getLessonsForCompany('comp-1');
      verify(() => mockSelectFilter.not('lessons_learned', 'is', null)).called(1);
    });

    test('limits results to 10', () async {
      wireLessonsQuery([]);
      await repository.getLessonsForCompany('comp-1');
      verify(() => mockSelectTransform.limit(10)).called(1);
    });

    test('orders by exit_date descending', () async {
      wireLessonsQuery([]);
      await repository.getLessonsForCompany('comp-1');
      verify(() => mockSelectFilter.order('exit_date', ascending: false)).called(1);
    });

    test('returns lessons ordered by most recent exit first', () async {
      wireLessonsQuery([
        buildClosedPosition(id: 'pos-newest', exitDate: '2026-06-15', lessonsLearned: 'Most recent lesson'),
        buildClosedPosition(id: 'pos-middle', exitDate: '2026-03-15', lessonsLearned: 'Middle lesson'),
        buildClosedPosition(id: 'pos-oldest', exitDate: '2026-01-15', lessonsLearned: 'Oldest lesson'),
      ]);
      final result = await repository.getLessonsForCompany('comp-1');
      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(3));
      expect(result.data![0].id, 'pos-newest');
      expect(result.data![0].exitDate, DateTime(2026, 6, 15));
      expect(result.data![1].id, 'pos-middle');
      expect(result.data![2].id, 'pos-oldest');
    });

    test('returns empty list when no closed positions with lessons', () async {
      wireLessonsQuery([]);
      final result = await repository.getLessonsForCompany('comp-empty');
      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test('returns failure when not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final result = await repository.getLessonsForCompany('comp-1');
      expect(result.isFailure, isTrue);
    });

    test('includes user_id filter to scope lessons to current user', () async {
      wireLessonsQuery([]);
      await repository.getLessonsForCompany('comp-1');
      verify(() => mockSelectFilter.eq('user_id', testUserId)).called(1);
    });

    test('maps lesson fields correctly from response', () async {
      wireLessonsQuery([
        buildClosedPosition(id: 'pos-detail', companyId: 'comp-detail', exitDate: '2026-05-20', lessonsLearned: 'Never average down without catalyst'),
      ]);
      final result = await repository.getLessonsForCompany('comp-detail');
      expect(result.isSuccess, isTrue);
      final lesson = result.data!.first;
      expect(lesson.id, 'pos-detail');
      expect(lesson.companyId, 'comp-detail');
      expect(lesson.status, PositionStatus.closed);
      expect(lesson.exitDate, DateTime(2026, 5, 20));
      expect(lesson.lessonsLearned, 'Never average down without catalyst');
      expect(lesson.outcome, PositionOutcome.correct);
      expect(lesson.entryPrice, 100.0);
      expect(lesson.exitPrice, 120.0);
    });
  });
}
