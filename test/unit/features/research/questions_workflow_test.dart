import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taug/features/research/data/research_models.dart';
import 'package:taug/features/research/data/research_repository.dart';

import '../../../helpers/test_helpers.dart';

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockSelectFilter;
  late MockPostgrestTransformBuilder<List<Map<String, dynamic>>>
      mockListTransform;
  late MockPostgrestTransformBuilder<Map<String, dynamic>> mockSingleTransform;
  late ResearchRepository repository;

  const testUserId = 'user-qw-001';

  setUp(() {
    mockClient = createMockSupabaseClient();
    mockAuth = mockClient.auth as MockGoTrueClient;
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockSelectFilter =
        MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    mockListTransform =
        MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
    mockSingleTransform =
        MockPostgrestTransformBuilder<Map<String, dynamic>>();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(testUserId);

    repository = ResearchRepository(client: mockClient);
  });

  Map<String, dynamic> buildQuestionJson({
    String id = 'q-1',
    String? companyId = 'comp-1',
    String? thesisId,
    String question = 'What about margins?',
    String priority = 'medium',
    String status = 'open',
    String? answer,
    String? answeredAt,
  }) {
    return {
      'id': id,
      'company_id': companyId,
      'thesis_id': thesisId,
      'question': question,
      'priority': priority,
      'status': status,
      'answer': answer,
      'answered_at': answeredAt,
      'created_at': '2026-06-01T00:00:00',
      'updated_at': '2026-06-01T00:00:00',
    };
  }

  /// Wire supporting tables (companies, securities, investment_theses)
  /// needed by getOpenQuestions.
  void wireSupportingTables() {
    final companiesBuilder = MockSupabaseQueryBuilder();
    final companiesFilter =
        MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    when(() => mockClient.from('companies'))
        .thenAnswer((_) => companiesBuilder);
    when(() => companiesBuilder.select(any()))
        .thenAnswer((_) => companiesFilter);
    companiesFilter.stubFuture([
      {'id': 'comp-1', 'display_name': 'Apple Inc.'},
    ]);

    final securitiesBuilder = MockSupabaseQueryBuilder();
    final securitiesFilter =
        MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    when(() => mockClient.from('securities'))
        .thenAnswer((_) => securitiesBuilder);
    when(() => securitiesBuilder.select(any()))
        .thenAnswer((_) => securitiesFilter);
    when(() => securitiesFilter.eq(any(), any()))
        .thenAnswer((_) => securitiesFilter);
    securitiesFilter.stubFuture([
      {'company_id': 'comp-1', 'ticker': 'AAPL'},
    ]);

    final thesesBuilder = MockSupabaseQueryBuilder();
    final thesesFilter =
        MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    when(() => mockClient.from('investment_theses'))
        .thenAnswer((_) => thesesBuilder);
    when(() => thesesBuilder.select(any()))
        .thenAnswer((_) => thesesFilter);
    thesesFilter.stubFuture([
      {'id': 'th-1', 'title': 'Growth thesis'},
    ]);
  }

  group('Research Questions Workflow', () {
    // -----------------------------------------------------------------------
    // Create question with priority
    // -----------------------------------------------------------------------
    group('createQuestion', () {
      test('creates question with specified priority', () async {
        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(
            buildQuestionJson(id: 'q-new', question: 'Is revenue growing?', priority: 'high'));

        final result = await repository.createQuestion(
          companyId: 'comp-1',
          question: 'Is revenue growing?',
          priority: 'high',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.id, 'q-new');
        expect(result.data!.question, 'Is revenue growing?');
        expect(result.data!.priority, 'high');
        expect(result.data!.status, 'open');
      });

      test('creates question with critical priority', () async {
        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(
            buildQuestionJson(id: 'q-crit', priority: 'critical'));

        final result = await repository.createQuestion(
          question: 'Debt maturity risk?',
          priority: 'critical',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.priority, 'critical');
        expect(result.data!.isCritical, isTrue);
      });

      test('defaults priority to medium when not specified', () async {
        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(buildQuestionJson());

        final result = await repository.createQuestion(
          question: 'General question',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.priority, 'medium');
      });

      test('creates question with thesisId link', () async {
        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(
            buildQuestionJson(thesisId: 'th-1'));

        final result = await repository.createQuestion(
          companyId: 'comp-1',
          thesisId: 'th-1',
          question: 'Does thesis hold?',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.thesisId, 'th-1');
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await repository.createQuestion(question: 'test');

        expect(result.isFailure, isTrue);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any()))
            .thenThrow(Exception('constraint violation'));

        final result = await repository.createQuestion(question: 'test');

        expect(result.isFailure, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Answer question with text
    // -----------------------------------------------------------------------
    group('answerQuestion', () {
      test('marks question as answered with answer text', () async {
        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        final result = await repository.answerQuestion(
          questionId: 'q-1',
          answer: 'Revenue grew 15% YoY',
        );

        expect(result.isSuccess, isTrue);
        verify(() => mockQueryBuilder.update(any())).called(1);
        verify(() => mockSelectFilter.eq('id', 'q-1')).called(1);
        verify(() => mockSelectFilter.eq('user_id', testUserId)).called(1);
      });

      test('sets status to answered and answered_at timestamp', () async {
        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        await repository.answerQuestion(
          questionId: 'q-1',
          answer: 'Test answer',
        );

        final captured =
            verify(() => mockQueryBuilder.update(captureAny())).captured;
        // ignore: avoid_dynamic_calls
        final updateData = captured.first as Map;
        expect(updateData['answer'], 'Test answer');
        expect(updateData['status'], 'answered');
        expect(updateData.containsKey('answered_at'), isTrue);
        expect(updateData.containsKey('updated_at'), isTrue);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await repository.answerQuestion(
          questionId: 'q-1',
          answer: 'test',
        );

        expect(result.isFailure, isTrue);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any())).thenThrow(Exception('timeout'));

        final result = await repository.answerQuestion(
          questionId: 'q-1',
          answer: 'test',
        );

        expect(result.isFailure, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Delete question
    // -----------------------------------------------------------------------
    group('deleteQuestion', () {
      test('deletes with user_id guard', () async {
        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        final result = await repository.deleteQuestion('q-1');

        expect(result.isSuccess, isTrue);
        verify(() => mockQueryBuilder.delete()).called(1);
        verify(() => mockSelectFilter.eq('id', 'q-1')).called(1);
        verify(() => mockSelectFilter.eq('user_id', testUserId)).called(1);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await repository.deleteQuestion('q-1');

        expect(result.isFailure, isTrue);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any()))
            .thenThrow(Exception('fk violation'));

        final result = await repository.deleteQuestion('q-1');

        expect(result.isFailure, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Update question
    // -----------------------------------------------------------------------
    group('updateQuestion', () {
      test('updates question text and priority', () async {
        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        final result = await repository.updateQuestion(
          questionId: 'q-1',
          question: 'Updated question text',
          priority: 'critical',
        );

        expect(result.isSuccess, isTrue);
        verify(() => mockSelectFilter.eq('id', 'q-1')).called(1);
        verify(() => mockSelectFilter.eq('user_id', testUserId)).called(1);
      });

      test('updates only question text when priority is null', () async {
        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        final result = await repository.updateQuestion(
          questionId: 'q-1',
          question: 'New text only',
        );

        expect(result.isSuccess, isTrue);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await repository.updateQuestion(
          questionId: 'q-1',
          question: 'test',
        );

        expect(result.isFailure, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Filter by status (getOpenQuestions)
    // -----------------------------------------------------------------------
    group('getOpenQuestions (status filter)', () {
      test('returns only open questions', () async {
        wireSupportingTables();

        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.order(any(),
                ascending: any(named: 'ascending')))
            .thenAnswer((_) => mockListTransform);
        mockListTransform.stubFuture([
          buildQuestionJson(
              id: 'q-open-1',
              status: 'open',
              question: 'Open question 1'),
          buildQuestionJson(
              id: 'q-open-2',
              status: 'open',
              question: 'Open question 2'),
        ]);

        final result = await repository.getOpenQuestions();

        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(2));
        for (final q in result.data!) {
          expect(q.isOpen, isTrue);
        }
        verify(() => mockSelectFilter.eq('status', 'open')).called(1);
      });

      test('returns empty when no open questions', () async {
        wireSupportingTables();

        when(() => mockClient.from('research_questions'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.order(any(),
                ascending: any(named: 'ascending')))
            .thenAnswer((_) => mockListTransform);
        mockListTransform.stubFuture([]);

        final result = await repository.getOpenQuestions();

        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // Filter by priority
    // -----------------------------------------------------------------------
    group('priority filtering on models', () {
      test('isCritical returns true only for critical priority', () {
        final critical = ResearchQuestion(
          id: 'q1',
          question: 'test',
          priority: 'critical',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final high = ResearchQuestion(
          id: 'q2',
          question: 'test',
          priority: 'high',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final medium = ResearchQuestion(
          id: 'q3',
          question: 'test',
          priority: 'medium',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final low = ResearchQuestion(
          id: 'q4',
          question: 'test',
          priority: 'low',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );

        expect(critical.isCritical, isTrue);
        expect(high.isCritical, isFalse);
        expect(medium.isCritical, isFalse);
        expect(low.isCritical, isFalse);
      });

      test('isHigh returns true for high and critical priorities', () {
        final critical = ResearchQuestion(
          id: 'q1',
          question: 'test',
          priority: 'critical',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final high = ResearchQuestion(
          id: 'q2',
          question: 'test',
          priority: 'high',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final medium = ResearchQuestion(
          id: 'q3',
          question: 'test',
          priority: 'medium',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final low = ResearchQuestion(
          id: 'q4',
          question: 'test',
          priority: 'low',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );

        expect(critical.isHigh, isTrue);
        expect(high.isHigh, isTrue);
        expect(medium.isHigh, isFalse);
        expect(low.isHigh, isFalse);
      });

      test('isOpen returns true only for open status', () {
        final open = ResearchQuestion(
          id: 'q1',
          question: 'test',
          status: 'open',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final answered = ResearchQuestion(
          id: 'q2',
          question: 'test',
          status: 'answered',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final abandoned = ResearchQuestion(
          id: 'q3',
          question: 'test',
          status: 'abandoned',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );

        expect(open.isOpen, isTrue);
        expect(answered.isOpen, isFalse);
        expect(abandoned.isOpen, isFalse);
      });

      test('ResearchQuestionIndex has matching priority/status helpers', () {
        final open = ResearchQuestionIndex(
          questionId: 'q1',
          question: 'test',
          priority: 'high',
          status: 'open',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final answered = ResearchQuestionIndex(
          questionId: 'q2',
          question: 'test',
          priority: 'low',
          status: 'answered',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );

        expect(open.isOpen, isTrue);
        expect(open.isHigh, isTrue);
        expect(open.isCritical, isFalse);
        expect(answered.isOpen, isFalse);
        expect(answered.isHigh, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Equatable for ResearchQuestion
    // -----------------------------------------------------------------------
    group('ResearchQuestion equality', () {
      test('two instances with same id are equal', () {
        final a = ResearchQuestion(
          id: 'q-1',
          question: 'test',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final b = ResearchQuestion(
          id: 'q-1',
          question: 'different question',
          priority: 'high',
          createdAt: DateTime(2026, 7, 1),
          updatedAt: DateTime(2026, 7, 1),
        );
        expect(a, equals(b));
      });

      test('two instances with different id are not equal', () {
        final a = ResearchQuestion(
          id: 'q-1',
          question: 'test',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        final b = ResearchQuestion(
          id: 'q-2',
          question: 'test',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        );
        expect(a, isNot(equals(b)));
      });
    });
  });
}
