import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taug/features/research/data/research_repository.dart';

import '../../../helpers/test_helpers.dart';

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockSelectFilter;
  late MockPostgrestTransformBuilder<List<Map<String, dynamic>>> mockListTransform;
  late MockPostgrestTransformBuilder<Map<String, dynamic>> mockSingleTransform;
  late ResearchRepository repository;

  const testUserId = 'user-xyz-789';

  setUp(() {
    mockClient = createMockSupabaseClient();
    mockAuth = mockClient.auth as MockGoTrueClient;
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockSelectFilter = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    mockListTransform = MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
    mockSingleTransform = MockPostgrestTransformBuilder<Map<String, dynamic>>();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(testUserId);

    repository = ResearchRepository(client: mockClient);
  });

  void wireSupportingTable(String tableName, {dynamic data = const [], bool withEq = false}) {
    final builder = MockSupabaseQueryBuilder();
    final filter = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    when(() => mockClient.from(tableName)).thenAnswer((_) => builder);
    when(() => builder.select(any())).thenAnswer((_) => filter);
    if (withEq) {
      when(() => filter.eq(any(), any())).thenAnswer((_) => filter);
    }
    filter.stubFuture(data);
  }

  Map<String, dynamic> buildQuestionJson({
    String id = 'q-1',
    String? companyId = 'comp-1',
    String? thesisId,
    String question = 'What about margins?',
    String priority = 'medium',
    String status = 'open',
  }) {
    return {
      'id': id,
      'company_id': companyId,
      'thesis_id': thesisId,
      'question': question,
      'priority': priority,
      'status': status,
      'answer': null,
      'answered_at': null,
      'created_at': '2026-06-01T00:00:00',
      'updated_at': '2026-06-01T00:00:00',
    };
  }

  group('ResearchRepository', () {
    group('getOpenQuestions', () {
      test('returns open questions with company and thesis context', () async {
        wireSupportingTable('companies', data: [
          {'id': 'comp-1', 'display_name': 'Apple Inc.'},
        ]);
        wireSupportingTable('securities', data: [
          {'company_id': 'comp-1', 'ticker': 'AAPL'},
        ], withEq: true);
        wireSupportingTable('investment_theses', data: [
          {'id': 'th-1', 'title': 'Bull case'},
        ]);

        when(() => mockClient.from('research_questions')).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.order(any(), ascending: any(named: 'ascending')))
            .thenAnswer((_) => mockListTransform);
        mockListTransform.stubFuture([
          buildQuestionJson(id: 'q-1', companyId: 'comp-1', thesisId: 'th-1', question: 'Is revenue accelerating?', priority: 'high'),
        ]);

        final result = await repository.getOpenQuestions();

        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(1));
        expect(result.data![0].questionId, 'q-1');
        expect(result.data![0].question, 'Is revenue accelerating?');
        expect(result.data![0].companyName, 'Apple Inc.');
        expect(result.data![0].ticker, 'AAPL');
        expect(result.data![0].thesisTitle, 'Bull case');
        expect(result.data![0].priority, 'high');
      });

      test('returns empty list when no open questions', () async {
        wireSupportingTable('companies');
        wireSupportingTable('securities', withEq: true);
        wireSupportingTable('investment_theses');

        when(() => mockClient.from('research_questions')).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.order(any(), ascending: any(named: 'ascending')))
            .thenAnswer((_) => mockListTransform);
        mockListTransform.stubFuture([]);

        final result = await repository.getOpenQuestions();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any())).thenThrow(Exception('connection refused'));
        final result = await repository.getOpenQuestions();
        expect(result.isFailure, isTrue);
      });
    });

    group('createQuestion', () {
      test('creates question with user_id from current auth', () async {
        when(() => mockClient.from('research_questions')).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any())).thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single()).thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(buildQuestionJson(id: 'q-new', question: 'What about margins?', priority: 'high'));

        final result = await repository.createQuestion(companyId: 'comp-1', question: 'What about margins?', priority: 'high');

        expect(result.isSuccess, isTrue);
        expect(result.data!.id, 'q-new');
        expect(result.data!.question, 'What about margins?');
        expect(result.data!.priority, 'high');

        final captured = verify(() => mockQueryBuilder.insert(captureAny())).captured;
        final insertData = captured.first as Map<String, dynamic>;
        expect(insertData['user_id'], testUserId);
        expect(insertData['company_id'], 'comp-1');
        expect(insertData['question'], 'What about margins?');
        expect(insertData['priority'], 'high');
      });

      test('creates question without companyId', () async {
        when(() => mockClient.from('research_questions')).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any())).thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single()).thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(buildQuestionJson(id: 'q-new', companyId: null, question: 'General question'));

        final result = await repository.createQuestion(question: 'General question');
        expect(result.isSuccess, isTrue);

        final captured = verify(() => mockQueryBuilder.insert(captureAny())).captured;
        final insertData = captured.first as Map<String, dynamic>;
        expect(insertData.containsKey('company_id'), isFalse);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        final result = await repository.createQuestion(question: 'test');
        expect(result.isFailure, isTrue);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any())).thenThrow(Exception('constraint'));
        final result = await repository.createQuestion(question: 'test');
        expect(result.isFailure, isTrue);
      });
    });

    group('answerQuestion', () {
      test('marks question as answered with answer text', () async {
        when(() => mockClient.from('research_questions')).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any())).thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        final result = await repository.answerQuestion(questionId: 'q-1', answer: 'Revenue is accelerating');
        expect(result.isSuccess, isTrue);
        verify(() => mockQueryBuilder.update(any())).called(1);
        verify(() => mockSelectFilter.eq('id', 'q-1')).called(1);
        verify(() => mockSelectFilter.eq('user_id', testUserId)).called(1);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        final result = await repository.answerQuestion(questionId: 'q-1', answer: 'test');
        expect(result.isFailure, isTrue);
      });
    });

    group('deleteQuestion', () {
      test('deletes with user_id guard', () async {
        when(() => mockClient.from('research_questions')).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any())).thenAnswer((_) => mockSelectFilter);
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
        when(() => mockClient.from(any())).thenThrow(Exception('fk violation'));
        final result = await repository.deleteQuestion('q-1');
        expect(result.isFailure, isTrue);
      });
    });

    group('updateQuestion', () {
      test('updates question text and priority', () async {
        when(() => mockClient.from('research_questions')).thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any())).thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        final result = await repository.updateQuestion(questionId: 'q-1', question: 'Updated question?', priority: 'critical');
        expect(result.isSuccess, isTrue);
        verify(() => mockSelectFilter.eq('id', 'q-1')).called(1);
        verify(() => mockSelectFilter.eq('user_id', testUserId)).called(1);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        final result = await repository.updateQuestion(questionId: 'q-1', question: 'test');
        expect(result.isFailure, isTrue);
      });
    });
  });
}
