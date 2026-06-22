import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taug/core/errors/result.dart';
import 'package:taug/features/company/data/workspace_models.dart';
import 'package:taug/features/company/data/workspace_repository.dart';
import 'package:taug/features/company/presentation/providers/workspace_provider.dart';
import 'package:taug/features/portfolio/data/portfolio_models.dart';
import 'package:taug/features/portfolio/data/portfolio_workspace_repository.dart';

import '../../helpers/test_helpers.dart';

class MockUser extends Mock implements User {}

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

class MockPortfolioRepository extends Mock implements PortfolioRepository {}

/// Regression suite exercising end-to-end workflows across features.
/// Each test group validates a critical user workflow to prevent future breakage.
void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;

  const testUserId = 'user-regression-001';

  setUp(() {
    mockClient = createMockSupabaseClient();
    mockAuth = mockClient.auth as MockGoTrueClient;
    mockUser = MockUser();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(testUserId);
  });

  // ==========================================================================
  // 1. Research Questions CRUD (create, answer, delete)
  // ==========================================================================
  group('Regression: Research Questions CRUD', () {
    late MockWorkspaceRepository mockRepo;
    late MockPortfolioRepository mockPortfolioRepo;
    late WorkspaceProvider provider;

    const testCompanyId = 'comp-reg-001';

    setUp(() {
      mockRepo = MockWorkspaceRepository();
      mockPortfolioRepo = MockPortfolioRepository();

      // Stub loadAll dependencies.
      when(() => mockRepo.getCompanyProfile(testCompanyId)).thenAnswer(
        (_) async => const Result.success(
          CompanyProfile(id: testCompanyId, displayName: 'Test Corp'),
        ),
      );
      when(() => mockRepo.getMetrics(testCompanyId))
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockRepo.getFinancialStatements(testCompanyId))
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockRepo.getNotes(testCompanyId))
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockRepo.getTheses(testCompanyId))
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockRepo.getQualityScore(testCompanyId))
          .thenAnswer((_) async => const Result.success(null));
      when(() => mockRepo.getFreshnessStatus(testCompanyId))
          .thenAnswer((_) async => const Result.success(null));
      when(() => mockRepo.getQuestions(testCompanyId))
          .thenAnswer((_) async => const Result.success([]));

      provider = WorkspaceProvider(
        companyId: testCompanyId,
        repository: mockRepo,
        portfolioRepository: mockPortfolioRepo,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('create → answer → delete full lifecycle', () async {
      final now = DateTime(2026, 6, 22);

      // Step 1: Create question.
      when(() => mockRepo.createQuestion(
            companyId: testCompanyId,
            question: 'What is the debt maturity schedule?',
            priority: 'high',
          )).thenAnswer((_) async => Result.success(CompanyQuestion(
            id: 'q-created',
            companyId: testCompanyId,
            question: 'What is the debt maturity schedule?',
            priority: 'high',
            status: 'open',
            createdAt: now,
            updatedAt: now,
          )));

      await provider.createQuestion(
        'What is the debt maturity schedule?',
        priority: 'high',
      );

      expect(provider.questions.value, hasLength(1));
      expect(provider.questions.value.first.id, 'q-created');
      expect(provider.questions.value.first.priority, 'high');
      expect(provider.questions.value.first.isOpen, isTrue);
      expect(provider.mutationError.value, isNull);

      // Step 2: Answer question — pre-populate to avoid _isMutating race.
      when(() => mockRepo.answerQuestion(
            questionId: 'q-created',
            answer: 'Debt matures in 2028',
          )).thenAnswer((_) async => const Result.success(null));

      await provider.answerQuestion('q-created', 'Debt matures in 2028');

      expect(provider.mutationError.value, isNull);

      // Step 3: Delete question.
      when(() => mockRepo.deleteQuestion('q-created'))
          .thenAnswer((_) async => const Result.success(null));

      await provider.deleteQuestion('q-created');

      expect(provider.questions.value, isEmpty);
      expect(provider.mutationError.value, isNull);
    });

    test('create question prepends to list (newest first)', () async {
      final now = DateTime(2026, 6, 22);
      provider.questions.value = [
        CompanyQuestion(
          id: 'q-old',
          companyId: testCompanyId,
          question: 'Old question',
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
      ];

      when(() => mockRepo.createQuestion(
            companyId: testCompanyId,
            question: 'New question',
            priority: 'medium',
          )).thenAnswer((_) async => Result.success(CompanyQuestion(
            id: 'q-new',
            companyId: testCompanyId,
            question: 'New question',
            status: 'open',
            createdAt: now,
            updatedAt: now,
          )));

      await provider.createQuestion('New question');

      expect(provider.questions.value, hasLength(2));
      expect(provider.questions.value.first.id, 'q-new');
      expect(provider.questions.value.last.id, 'q-old');
    });

    test('answer failure sets mutationError without modifying question',
        () async {
      final now = DateTime(2026, 6, 22);
      provider.questions.value = [
        CompanyQuestion(
          id: 'q-fail',
          companyId: testCompanyId,
          question: 'Test?',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(() => mockRepo.answerQuestion(
            questionId: 'q-fail',
            answer: 'any',
          )).thenAnswer((_) async => Result.failure(Exception('timeout')));

      await provider.answerQuestion('q-fail', 'any');

      expect(provider.questions.value.first.status, 'open');
      expect(provider.questions.value.first.answer, isNull);
      expect(provider.mutationError.value, isNotNull);
    });

    test('delete failure preserves question in list', () async {
      final now = DateTime(2026, 6, 22);
      provider.questions.value = [
        CompanyQuestion(
          id: 'q-keep',
          companyId: testCompanyId,
          question: 'Keep me',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      when(() => mockRepo.deleteQuestion('q-keep'))
          .thenAnswer((_) async => Result.failure(Exception('fk violation')));

      await provider.deleteQuestion('q-keep');

      expect(provider.questions.value, hasLength(1));
      expect(provider.mutationError.value, isNotNull);
    });

    test('concurrent question mutations are guarded', () async {
      final now = DateTime(2026, 6, 22);

      when(() => mockRepo.createQuestion(
            companyId: testCompanyId,
            question: any(named: 'question'),
            priority: any(named: 'priority'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return Result.success(CompanyQuestion(
          id: 'q-1',
          companyId: testCompanyId,
          question: 't',
          createdAt: now,
          updatedAt: now,
        ));
      });

      final first = provider.createQuestion('first');
      await provider.createQuestion('second');
      await first;

      verify(() => mockRepo.createQuestion(
            companyId: testCompanyId,
            question: 'first',
            priority: 'medium',
          )).called(1);
    });

    test('progressionState reflects open questions count', () async {
      final now = DateTime(2026, 6, 22);
      provider.questions.value = [
        CompanyQuestion(
          id: 'q-1',
          companyId: testCompanyId,
          question: 'Open 1',
          createdAt: now,
          updatedAt: now,
        ),
        CompanyQuestion(
          id: 'q-2',
          companyId: testCompanyId,
          question: 'Open 2',
          priority: 'critical',
          createdAt: now,
          updatedAt: now,
        ),
        CompanyQuestion(
          id: 'q-3',
          companyId: testCompanyId,
          question: 'Answered',
          status: 'answered',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final state = provider.progressionState;
      expect(state.openQuestionsCount, 2);
      expect(state.criticalQuestionsCount, 1);
    });
  });

  // ==========================================================================
  // 2. Learning Loop (lessons fetched for company, filtered by status)
  // ==========================================================================
  group('Regression: Learning Loop', () {
    late PortfolioRepository repository;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockFilter;
    late MockPostgrestTransformBuilder<List<Map<String, dynamic>>>
        mockTransform;

    setUp(() {
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilter = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockTransform =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      repository = PortfolioRepository(client: mockClient);
    });

    void wireLessonsQuery(dynamic data) {
      when(() => mockClient.from(any()))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select(any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.eq(any(), any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.not(any(), any(), any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.order(any(), ascending: any(named: 'ascending')))
          .thenAnswer((_) => mockTransform);
      when(() => mockTransform.limit(any()))
          .thenAnswer((_) => mockTransform);
      mockTransform.stubFuture(data);
    }

    Map<String, dynamic> buildLesson({
      String id = 'pos-1',
      String companyId = 'comp-1',
      String exitDate = '2026-06-15',
      String? lessonsLearned = 'Follow momentum',
      String outcome = 'correct',
    }) {
      return {
        'id': id,
        'company_id': companyId,
        'companies': {'display_name': 'Test Corp'},
        'thesis_id': null,
        'conviction': 'high',
        'entry_date': '2026-01-01',
        'entry_price': 100.0,
        'notes': null,
        'status': 'closed',
        'exit_date': exitDate,
        'exit_price': 120.0,
        'outcome': outcome,
        'lessons_learned': lessonsLearned,
        'created_at': '2026-01-01T00:00:00',
        'updated_at': '2026-06-15T00:00:00',
      };
    }

    test('fetches lessons scoped to company and user', () async {
      wireLessonsQuery([
        buildLesson(id: 'l-1', companyId: 'comp-42'),
      ]);

      final result = await repository.getLessonsForCompany('comp-42');

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      verify(() => mockFilter.eq('company_id', 'comp-42')).called(1);
      verify(() => mockFilter.eq('user_id', testUserId)).called(1);
    });

    test('filters to closed positions with lessons only', () async {
      wireLessonsQuery([]);

      await repository.getLessonsForCompany('comp-1');

      verify(() => mockFilter.eq('status', 'closed')).called(1);
      verify(() => mockFilter.not('lessons_learned', 'is', null)).called(1);
    });

    test('returns lessons ordered by most recent exit first', () async {
      wireLessonsQuery([
        buildLesson(id: 'newest', exitDate: '2026-06-15'),
        buildLesson(id: 'middle', exitDate: '2026-03-15'),
        buildLesson(id: 'oldest', exitDate: '2026-01-15'),
      ]);

      final result = await repository.getLessonsForCompany('comp-1');

      expect(result.data![0].id, 'newest');
      expect(result.data![1].id, 'middle');
      expect(result.data![2].id, 'oldest');
      verify(() => mockFilter.order('exit_date', ascending: false)).called(1);
    });

    test('limits results to 10', () async {
      wireLessonsQuery([]);

      await repository.getLessonsForCompany('comp-1');

      verify(() => mockTransform.limit(10)).called(1);
    });

    test('maps lesson fields correctly', () async {
      wireLessonsQuery([
        buildLesson(
          id: 'l-detail',
          companyId: 'comp-detail',
          exitDate: '2026-05-20',
          lessonsLearned: 'Never average down without catalyst',
        ),
      ]);

      final result = await repository.getLessonsForCompany('comp-detail');
      final lesson = result.data!.first;

      expect(lesson.id, 'l-detail');
      expect(lesson.companyId, 'comp-detail');
      expect(lesson.status, PositionStatus.closed);
      expect(lesson.exitDate, DateTime(2026, 5, 20));
      expect(lesson.lessonsLearned, 'Never average down without catalyst');
      expect(lesson.outcome, PositionOutcome.correct);
    });

    test('returns empty when no closed positions with lessons exist',
        () async {
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

    test('provider loads lessons into companyLessons signal', () async {
      final mockRepo = MockWorkspaceRepository();
      final mockPortfolioRepo = MockPortfolioRepository();

      when(() => mockRepo.getCompanyProfile(any()))
          .thenAnswer((_) async => const Result.success(
                CompanyProfile(id: 'c1', displayName: 'T'),
              ));
      when(() => mockRepo.getMetrics(any()))
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockRepo.getFinancialStatements(any()))
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockRepo.getNotes(any()))
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockRepo.getTheses(any()))
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockRepo.getQualityScore(any()))
          .thenAnswer((_) async => const Result.success(null));
      when(() => mockRepo.getFreshnessStatus(any()))
          .thenAnswer((_) async => const Result.success(null));
      when(() => mockRepo.getQuestions(any()))
          .thenAnswer((_) async => const Result.success([]));

      final provider = WorkspaceProvider(
        companyId: 'c1',
        repository: mockRepo,
        portfolioRepository: mockPortfolioRepo,
      );

      when(() => mockPortfolioRepo.getLessonsForCompany('c1')).thenAnswer(
        (_) async => Result.success([
          PortfolioPosition(
            id: 'lesson-1',
            companyId: 'c1',
            companyName: 'T',
            conviction: 'high',
            entryDate: DateTime(2026, 1, 1),
            status: PositionStatus.closed,
            exitDate: DateTime(2026, 6, 1),
            outcome: PositionOutcome.correct,
            lessonsLearned: 'Lesson learned',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 6, 1),
          ),
        ]),
      );

      await provider.loadCompanyLessons('c1');

      expect(provider.companyLessons.value, hasLength(1));
      expect(provider.companyLessons.value.first.lessonsLearned,
          'Lesson learned');
      expect(provider.isLoadingLessons.value, isFalse);

      provider.dispose();
    });
  });

  // ==========================================================================
  // 3. Evidence Tracking (link note to thesis, unlink)
  // ==========================================================================
  group('Regression: Evidence Tracking', () {
    late WorkspaceRepository repository;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockFilter;
    late MockPostgrestTransformBuilder<List<Map<String, dynamic>>>
        mockListTransform;
    late MockPostgrestTransformBuilder<Map<String, dynamic>>
        mockSingleTransform;

    setUp(() {
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilter = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockListTransform =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      mockSingleTransform =
          MockPostgrestTransformBuilder<Map<String, dynamic>>();
      repository = WorkspaceRepository(client: mockClient);
    });

    Map<String, dynamic> buildLinkJson({
      String id = 'link-1',
      String noteId = 'note-1',
      String thesisId = 'thesis-1',
      String relationship = 'supports',
      String? thesisField,
    }) {
      return {
        'id': id,
        'note_id': noteId,
        'thesis_id': thesisId,
        'relationship': relationship,
        'thesis_field': thesisField,
        'created_at': '2026-06-22T10:00:00',
      };
    }

    test('link → getLinkedNotes → unlink full lifecycle', () async {
      // Step 1: Link note to thesis.
      when(() => mockClient.from('note_thesis_links'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.select(any()))
          .thenAnswer((_) => mockListTransform);
      when(() => mockListTransform.single())
          .thenAnswer((_) => mockSingleTransform);
      mockSingleTransform.stubFuture(
          buildLinkJson(id: 'link-new', relationship: 'supports'));

      final linkResult = await repository.linkNoteToThesis(
        noteId: 'note-1',
        thesisId: 'thesis-1',
      );

      expect(linkResult.isSuccess, isTrue);
      expect(linkResult.data!.id, 'link-new');
      expect(linkResult.data!.relationship, 'supports');

      // Step 2: Get linked notes.
      final listFilter =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final listTransform =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      when(() => mockClient.from('note_thesis_links'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select(any()))
          .thenAnswer((_) => listFilter);
      when(() => listFilter.eq(any(), any()))
          .thenAnswer((_) => listFilter);
      when(() => listFilter.order(any(), ascending: any(named: 'ascending')))
          .thenAnswer((_) => listTransform);
      listTransform.stubFuture([
        buildLinkJson(id: 'link-new', relationship: 'supports'),
      ]);

      final listResult = await repository.getLinkedNotes('thesis-1');

      expect(listResult.isSuccess, isTrue);
      expect(listResult.data, hasLength(1));
      expect(listResult.data!.first.relationship, 'supports');

      // Step 3: Unlink.
      final unlinkFilter =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      when(() => mockClient.from('note_thesis_links'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.delete())
          .thenAnswer((_) => unlinkFilter);
      when(() => unlinkFilter.eq(any(), any()))
          .thenAnswer((_) => unlinkFilter);
      unlinkFilter.stubFuture(null);

      final unlinkResult = await repository.unlinkNoteFromThesis(
        noteId: 'note-1',
        thesisId: 'thesis-1',
      );

      expect(unlinkResult.isSuccess, isTrue);
      verify(() => unlinkFilter.eq('note_id', 'note-1')).called(1);
      verify(() => unlinkFilter.eq('thesis_id', 'thesis-1')).called(1);
    });

    test('supports all relationship types', () async {
      for (final rel in ['supports', 'contradicts', 'updates', 'context']) {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockFilter);
        when(() => mockFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(buildLinkJson(relationship: rel));

        final result = await repository.linkNoteToThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
          relationship: rel,
        );

        expect(result.isSuccess, isTrue,
            reason: 'Failed for relationship: $rel');
        expect(result.data!.relationship, rel);
      }
    });

    test('thesisField filter applied on unlink when provided', () async {
      when(() => mockClient.from('note_thesis_links'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.delete())
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.eq(any(), any()))
          .thenAnswer((_) => mockFilter);
      mockFilter.stubFuture(null);

      await repository.unlinkNoteFromThesis(
        noteId: 'note-1',
        thesisId: 'thesis-1',
        thesisField: 'bull_case',
      );

      verify(() => mockFilter.eq('thesis_field', 'bull_case')).called(1);
    });

    test('link returns failure when not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.linkNoteToThesis(
        noteId: 'n1',
        thesisId: 't1',
      );

      expect(result.isFailure, isTrue);
    });

    test('unlink returns failure when not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.unlinkNoteFromThesis(
        noteId: 'n1',
        thesisId: 't1',
      );

      expect(result.isFailure, isTrue);
    });

    test('getLinkedNotes returns empty when no links exist', () async {
      when(() => mockClient.from('note_thesis_links'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select(any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.eq(any(), any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.order(any(), ascending: any(named: 'ascending')))
          .thenAnswer((_) => mockListTransform);
      mockListTransform.stubFuture([]);

      final result = await repository.getLinkedNotes('thesis-empty');

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });
  });

  // ==========================================================================
  // 4. Pattern Intelligence (stance accuracy, conviction accuracy)
  // ==========================================================================
  group('Regression: Pattern Intelligence', () {
    late PortfolioRepository repository;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockFilter;

    setUp(() {
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilter = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      repository = PortfolioRepository(client: mockClient);
    });

    void wireClosedPositionsQuery(dynamic data) {
      when(() => mockClient.from(any()))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select(any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.eq(any(), any()))
          .thenAnswer((_) => mockFilter);
      mockFilter.stubFuture(data);
    }

    Map<String, dynamic> buildClosedPosition({
      String id = 'pos-1',
      String companyId = 'comp-1',
      String conviction = 'high',
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
        'status': 'closed',
        'exit_date': exitDate,
        'exit_price': exitPrice,
        'outcome': outcome,
        'lessons_learned': lessonsLearned,
        'created_at': '2026-01-15T00:00:00',
        'updated_at': '2026-06-15T00:00:00',
        if (stance != null) 'investment_theses': {'stance': stance},
      };
    }

    test('computes stance accuracy correctly', () async {
      wireClosedPositionsQuery([
        buildClosedPosition(
            id: 'p1', outcome: 'correct', stance: 'bullish'),
        buildClosedPosition(
            id: 'p2', outcome: 'incorrect', stance: 'bullish'),
        buildClosedPosition(
            id: 'p3', outcome: 'correct', stance: 'bearish'),
        buildClosedPosition(
            id: 'p4', outcome: 'correct', stance: 'bullish'),
      ]);

      final result = await repository.getAllPatternData(testUserId);

      expect(result.isSuccess, isTrue);
      final stance =
          result.data!['stanceAccuracy'] as Map<String, int>;
      expect(stance['bullish_correct'], 2);
      expect(stance['bullish_incorrect'], 1);
      expect(stance['bearish_correct'], 1);
    });

    test('computes conviction accuracy correctly', () async {
      wireClosedPositionsQuery([
        buildClosedPosition(
            id: 'p1', outcome: 'correct', conviction: 'high'),
        buildClosedPosition(
            id: 'p2', outcome: 'correct', conviction: 'high'),
        buildClosedPosition(
            id: 'p3', outcome: 'incorrect', conviction: 'low'),
        buildClosedPosition(
            id: 'p4', outcome: 'partial', conviction: 'medium'),
      ]);

      final result = await repository.getAllPatternData(testUserId);

      expect(result.isSuccess, isTrue);
      final conviction =
          result.data!['convictionAccuracy'] as Map<String, int>;
      expect(conviction['high_correct'], 2);
      expect(conviction['low_incorrect'], 1);
      expect(conviction['medium_partial'], 1);
    });

    test('computes overall stats correctly', () async {
      wireClosedPositionsQuery([
        buildClosedPosition(id: 'p1', outcome: 'correct'),
        buildClosedPosition(id: 'p2', outcome: 'incorrect'),
        buildClosedPosition(id: 'p3', outcome: 'correct'),
        buildClosedPosition(id: 'p4', outcome: 'partial'),
        buildClosedPosition(id: 'p5', outcome: 'correct'),
      ]);

      final result = await repository.getAllPatternData(testUserId);

      final overall =
          result.data!['overallStats'] as Map<String, int>;
      expect(overall['total'], 5);
      expect(overall['correct'], 3);
      expect(overall['incorrect'], 1);
      expect(overall['partial'], 1);
    });

    test('extracts common themes from lessons', () async {
      wireClosedPositionsQuery([
        buildClosedPosition(
            id: 'p1',
            outcome: 'correct',
            lessonsLearned: 'momentum trading works well'),
        buildClosedPosition(
            id: 'p2',
            outcome: 'incorrect',
            lessonsLearned: 'momentum reversals happen fast'),
      ]);

      final result = await repository.getAllPatternData(testUserId);

      final themes = result.data!['commonThemes'] as List<String>;
      expect(themes, contains('momentum'));
    });

    test('defaults null stance to neutral', () async {
      wireClosedPositionsQuery([
        buildClosedPosition(id: 'p1', outcome: 'correct', stance: null),
      ]);

      final result = await repository.getAllPatternData(testUserId);

      final stance =
          result.data!['stanceAccuracy'] as Map<String, int>;
      expect(stance['neutral_correct'], 1);
    });

    test('skips positions with null outcome', () async {
      wireClosedPositionsQuery([
        buildClosedPosition(id: 'p1', outcome: null, stance: 'bullish'),
      ]);

      final result = await repository.getAllPatternData(testUserId);

      expect(result.data!['stanceAccuracy'], isEmpty);
      final overall =
          result.data!['overallStats'] as Map<String, int>;
      expect(overall['total'], 1);
      expect(overall['correct'], 0);
      expect(overall['incorrect'], 0);
      expect(overall['partial'], 0);
    });

    test('computes holding period stats', () async {
      wireClosedPositionsQuery([
        buildClosedPosition(
            id: 'p1',
            outcome: 'correct',
            entryDate: '2026-01-01',
            exitDate: '2026-03-01'),
        buildClosedPosition(
            id: 'p2',
            outcome: 'incorrect',
            entryDate: '2026-01-01',
            exitDate: '2026-06-01'),
      ]);

      final result = await repository.getAllPatternData(testUserId);

      final holding =
          result.data!['holdingPeriodStats'] as Map<String, dynamic>;
      expect(holding['correct_avg'], isA<double>());
      expect(holding['incorrect_avg'], isA<double>());
      expect(holding['correct_avg'], lessThan(holding['incorrect_avg'] as double));
    });

    test('returns failure on exception', () async {
      when(() => mockClient.from(any())).thenThrow(Exception('db down'));

      final result = await repository.getAllPatternData(testUserId);

      expect(result.isFailure, isTrue);
    });
  });

  // ==========================================================================
  // 5. Portfolio Workflow (add position, close position, mark review)
  // ==========================================================================
  group('Regression: Portfolio Workflow', () {
    late PortfolioRepository repository;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockFilter;
    late MockPostgrestTransformBuilder<List<Map<String, dynamic>>>
        mockTransform;

    setUp(() {
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilter = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockTransform =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      repository = PortfolioRepository(client: mockClient);
    });

    Map<String, dynamic> buildPositionJson({
      String id = 'pos-1',
      String companyId = 'comp-1',
      String conviction = 'high',
      String status = 'active',
      String entryDate = '2026-01-15',
      double? entryPrice = 150.0,
      String? exitDate,
      double? exitPrice,
      String? outcome,
      String? lessonsLearned,
    }) {
      return {
        'id': id,
        'company_id': companyId,
        'companies': {'display_name': 'Apple Inc.'},
        'thesis_id': null,
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
      };
    }

    void setupInsertQuery() {
      when(() => mockClient.from(any()))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.select(any()))
          .thenAnswer((_) => mockTransform);
    }

    void setupUpdateQuery() {
      when(() => mockClient.from(any()))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.update(any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.eq(any(), any()))
          .thenAnswer((_) => mockFilter);
      mockFilter.stubFuture(null);
    }

    void setupSelectQuery(dynamic data) {
      when(() => mockClient.from(any()))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select(any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.eq(any(), any()))
          .thenAnswer((_) => mockFilter);
      when(() => mockFilter.order(any(),
              ascending: any(named: 'ascending')))
          .thenAnswer((_) => mockTransform);
      mockTransform.stubFuture(data);
    }

    test('add position full lifecycle', () async {
      // Step 1: Create position.
      final singleTransform =
          MockPostgrestTransformBuilder<Map<String, dynamic>>();
      setupInsertQuery();
      when(() => mockTransform.single())
          .thenAnswer((_) => singleTransform);
      singleTransform.stubFuture(buildPositionJson(
        id: 'pos-new',
        companyId: 'comp-new',
        conviction: 'high',
        status: 'active',
      ));

      final createResult = await repository.createPosition(
        companyId: 'comp-new',
        conviction: 'high',
        entryDate: DateTime(2026, 6, 1),
        entryPrice: 150.0,
      );

      expect(createResult.isSuccess, isTrue);
      expect(createResult.data!.id, 'pos-new');
      expect(createResult.data!.status, PositionStatus.active);
      expect(createResult.data!.companyId, 'comp-new');

      // Step 2: Verify it appears in getPositions.
      setupSelectQuery([
        buildPositionJson(id: 'pos-new', companyId: 'comp-new'),
      ]);

      final listResult = await repository.getPositions();

      expect(listResult.isSuccess, isTrue);
      expect(listResult.data, hasLength(1));
      expect(listResult.data!.first.id, 'pos-new');
    });

    test('close position sets status, outcome, and lessons', () async {
      setupUpdateQuery();

      final result = await repository.closePosition(
        positionId: 'pos-1',
        outcome: 'correct',
        lessonsLearned: 'Follow momentum',
        exitDate: DateTime(2026, 6, 15),
        exitPrice: 180.0,
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockQueryBuilder.update(any())).called(1);
      verify(() => mockFilter.eq('id', 'pos-1')).called(1);
      verify(() => mockFilter.eq('user_id', testUserId)).called(1);
    });

    test('mark review needed updates status to review_needed', () async {
      setupUpdateQuery();

      final result = await repository.markReviewNeeded('pos-1');

      expect(result.isSuccess, isTrue);
      verify(() => mockQueryBuilder.update(any())).called(1);
      verify(() => mockFilter.eq('id', 'pos-1')).called(1);
      verify(() => mockFilter.eq('user_id', testUserId)).called(1);
    });

    test('add → close → verify closed status', () async {
      // Create.
      final singleTransform =
          MockPostgrestTransformBuilder<Map<String, dynamic>>();
      setupInsertQuery();
      when(() => mockTransform.single())
          .thenAnswer((_) => singleTransform);
      singleTransform.stubFuture(buildPositionJson(
        id: 'pos-lifecycle',
        status: 'active',
      ));

      final createResult = await repository.createPosition(
        companyId: 'comp-1',
        conviction: 'high',
        entryDate: DateTime(2026, 1, 1),
        entryPrice: 100.0,
      );

      expect(createResult.data!.status, PositionStatus.active);

      // Close.
      setupUpdateQuery();

      final closeResult = await repository.closePosition(
        positionId: 'pos-lifecycle',
        outcome: 'correct',
        lessonsLearned: 'Great trade',
        exitDate: DateTime(2026, 6, 1),
        exitPrice: 150.0,
      );

      expect(closeResult.isSuccess, isTrue);

      // Verify it shows up as closed in getPositions.
      setupSelectQuery([
        buildPositionJson(
          id: 'pos-lifecycle',
          status: 'closed',
          outcome: 'correct',
          exitDate: '2026-06-01',
          exitPrice: 150.0,
          lessonsLearned: 'Great trade',
        ),
      ]);

      final listResult = await repository.getPositions(status: 'closed');

      expect(listResult.isSuccess, isTrue);
      expect(listResult.data, hasLength(1));
      expect(listResult.data!.first.status, PositionStatus.closed);
      expect(listResult.data!.first.outcome, PositionOutcome.correct);
    });

    test('add → mark review needed → verify review status', () async {
      // Create.
      final singleTransform =
          MockPostgrestTransformBuilder<Map<String, dynamic>>();
      setupInsertQuery();
      when(() => mockTransform.single())
          .thenAnswer((_) => singleTransform);
      singleTransform.stubFuture(buildPositionJson(
        id: 'pos-review',
        status: 'active',
      ));

      final createResult = await repository.createPosition(
        companyId: 'comp-1',
        conviction: 'medium',
        entryDate: DateTime(2026, 3, 1),
        entryPrice: 200.0,
      );

      expect(createResult.data!.status, PositionStatus.active);

      // Mark review needed.
      setupUpdateQuery();

      final reviewResult =
          await repository.markReviewNeeded('pos-review');

      expect(reviewResult.isSuccess, isTrue);

      // Verify status in getPositions.
      setupSelectQuery([
        buildPositionJson(id: 'pos-review', status: 'review_needed'),
      ]);

      final listResult =
          await repository.getPositions(status: 'review_needed');

      expect(listResult.isSuccess, isTrue);
      expect(listResult.data, hasLength(1));
      expect(listResult.data!.first.status, PositionStatus.reviewNeeded);
    });

    test('getPositions filters by status', () async {
      setupSelectQuery([
        buildPositionJson(id: 'pos-1', status: 'active'),
        buildPositionJson(id: 'pos-2', status: 'active'),
      ]);

      final result = await repository.getPositions(status: 'active');

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(2));
      verify(() => mockFilter.eq('status', 'active')).called(1);
    });

    test('createPosition returns failure when not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.createPosition(
        companyId: 'comp-1',
        conviction: 'high',
        entryDate: DateTime(2026, 1, 1),
      );

      expect(result.isFailure, isTrue);
    });

    test('closePosition returns failure when not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.closePosition(
        positionId: 'pos-1',
        outcome: 'correct',
      );

      expect(result.isFailure, isTrue);
    });

    test('markReviewNeeded returns failure when not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.markReviewNeeded('pos-1');

      expect(result.isFailure, isTrue);
    });

    test('returnPercent calculates correctly from entry/exit prices', () {
      final position = PortfolioPosition(
        id: 'pos-1',
        companyId: 'comp-1',
        conviction: 'high',
        entryDate: DateTime(2026, 1, 1),
        entryPrice: 100.0,
        status: PositionStatus.closed,
        exitDate: DateTime(2026, 6, 1),
        exitPrice: 150.0,
        outcome: PositionOutcome.correct,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

      expect(position.returnPercent, 50.0);
    });

    test('returnPercent is null when entry or exit price is missing', () {
      final noEntry = PortfolioPosition(
        id: 'pos-1',
        companyId: 'comp-1',
        conviction: 'high',
        entryDate: DateTime(2026, 1, 1),
        status: PositionStatus.closed,
        exitDate: DateTime(2026, 6, 1),
        exitPrice: 150.0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

      final noExit = PortfolioPosition(
        id: 'pos-2',
        companyId: 'comp-1',
        conviction: 'high',
        entryDate: DateTime(2026, 1, 1),
        entryPrice: 100.0,
        status: PositionStatus.closed,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

      expect(noEntry.returnPercent, isNull);
      expect(noExit.returnPercent, isNull);
    });

    test('position status helpers work correctly', () {
      final active = PortfolioPosition(
        id: 'a',
        companyId: 'c',
        conviction: 'high',
        entryDate: DateTime(2026, 1, 1),
        status: PositionStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final review = PortfolioPosition(
        id: 'r',
        companyId: 'c',
        conviction: 'medium',
        entryDate: DateTime(2026, 1, 1),
        status: PositionStatus.reviewNeeded,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final closed = PortfolioPosition(
        id: 'cl',
        companyId: 'c',
        conviction: 'low',
        entryDate: DateTime(2026, 1, 1),
        status: PositionStatus.closed,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(active.isActive, isTrue);
      expect(active.isReviewNeeded, isFalse);
      expect(active.isClosed, isFalse);

      expect(review.isActive, isFalse);
      expect(review.isReviewNeeded, isTrue);
      expect(review.isClosed, isFalse);

      expect(closed.isActive, isFalse);
      expect(closed.isReviewNeeded, isFalse);
      expect(closed.isClosed, isTrue);
    });
  });
}
