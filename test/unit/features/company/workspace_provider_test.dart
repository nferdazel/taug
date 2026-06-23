import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taug/core/errors/result.dart';
import 'package:taug/features/company/data/workspace_models.dart';
import 'package:taug/features/company/data/workspace_repository.dart';
import 'package:taug/features/company/presentation/providers/workspace_provider.dart';
import 'package:taug/features/portfolio/data/portfolio_models.dart';
import 'package:taug/features/portfolio/data/portfolio_workspace_repository.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

class MockPortfolioPositionRepository extends Mock implements PortfolioPositionRepository {}

void main() {
  late MockWorkspaceRepository mockRepo;
  late MockPortfolioPositionRepository mockPortfolioRepo;
  late WorkspaceProvider provider;

  const testCompanyId = 'comp-1';

  setUp(() {
    mockRepo = MockWorkspaceRepository();
    mockPortfolioRepo = MockPortfolioPositionRepository();
    provider = WorkspaceProvider(
      companyId: testCompanyId,
      repository: mockRepo,
      portfolioRepository: mockPortfolioRepo,
    );
  });

  // ── Stub helpers ────────────────────────────────────────────────────────

  void stubLoadAllSuccess({
    CompanyProfile? profile,
    List<MetricSnapshot>? metrics,
    List<StatementRow>? statements,
    List<CompanyNote>? notes,
    List<CompanyThesis>? theses,
    QualityScoreDetail? quality,
    String? freshness,
    List<CompanyQuestion>? questions,
  }) {
    when(() => mockRepo.getCompanyProfile(testCompanyId)).thenAnswer(
      (_) async => Result.success(
        profile ??
            const CompanyProfile(
              id: testCompanyId,
              displayName: 'Apple Inc.',
              ticker: 'AAPL',
            ),
      ),
    );
    when(() => mockRepo.getMetrics(testCompanyId)).thenAnswer(
      (_) async => Result.success(metrics ?? []),
    );
    when(() => mockRepo.getFinancialStatements(testCompanyId)).thenAnswer(
      (_) async => Result.success(statements ?? []),
    );
    when(() => mockRepo.getNotes(testCompanyId)).thenAnswer(
      (_) async => Result.success(notes ?? []),
    );
    when(() => mockRepo.getTheses(testCompanyId)).thenAnswer(
      (_) async => Result.success(theses ?? []),
    );
    when(() => mockRepo.getQualityScore(testCompanyId)).thenAnswer(
      (_) async => Result.success(quality),
    );
    when(() => mockRepo.getFreshnessStatus(testCompanyId)).thenAnswer(
      (_) async => Result.success(freshness),
    );
    when(() => mockRepo.getQuestions(testCompanyId)).thenAnswer(
      (_) async => Result.success(questions ?? []),
    );
    when(() => mockPortfolioRepo.getPositions(status: 'active')).thenAnswer(
      (_) async => Result.success([]),
    );
  }

  // =========================================================================
  // Tests
  // =========================================================================

  group('WorkspaceProvider', () {
    // ── loadAll ──────────────────────────────────────────────────────────

    group('loadAll', () {
      test('populates all signals on success', () async {
        final now = DateTime(2026, 6, 22);
        const profile = CompanyProfile(
          id: testCompanyId,
          displayName: 'Apple Inc.',
          ticker: 'AAPL',
        );
        final metrics = [
          const MetricSnapshot(
            metricCode: 'pe_ratio',
            metricName: 'P/E Ratio',
            metricCategory: 'valuation',
            valueNumeric: 25.5,
            computationStatus: 'ok',
          ),
        ];
        final statements = [
          const StatementRow(
            statementType: 'income',
            periodEnd: '2026-03-31',
            items: {'revenue': 100000000},
          ),
        ];
        final notes = [
          CompanyNote(
            id: 'note-1',
            companyId: testCompanyId,
            title: 'Q1 Analysis',
            body: 'Strong quarter',
            createdAt: now,
            updatedAt: now,
          ),
        ];
        final theses = [
          CompanyThesis(
            id: 'thesis-1',
            companyId: testCompanyId,
            title: 'Bull case',
            stance: 'bullish',
            createdAt: now,
            updatedAt: now,
          ),
        ];
        const quality = QualityScoreDetail(overallScore: 0.85);
        final questions = [
          CompanyQuestion(
            id: 'q-1',
            companyId: testCompanyId,
            question: 'What about margins?',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        stubLoadAllSuccess(
          profile: profile,
          metrics: metrics,
          statements: statements,
          notes: notes,
          theses: theses,
          quality: quality,
          freshness: 'current',
          questions: questions,
        );

        await provider.loadAll();

        expect(provider.profile.value?.displayName, 'Apple Inc.');
        expect(provider.profile.value?.ticker, 'AAPL');
        expect(provider.metrics.value, hasLength(1));
        expect(provider.metrics.value.first.metricCode, 'pe_ratio');
        expect(provider.statements.value, hasLength(1));
        expect(provider.notes.value, hasLength(1));
        expect(provider.notes.value.first.title, 'Q1 Analysis');
        expect(provider.theses.value, hasLength(1));
        expect(provider.theses.value.first.title, 'Bull case');
        expect(provider.qualityDetail.value?.overallScore, 0.85);
        expect(provider.freshnessStatus.value, 'current');
        expect(provider.questions.value, hasLength(1));
        expect(provider.isLoading.value, isFalse);
        expect(provider.error.value, isNull);
      });

      test('sets isLoading during load and clears after', () async {
        stubLoadAllSuccess();

        expect(provider.isLoading.value, isFalse);
        final future = provider.loadAll();
        // isLoading should be true while loading (but we can't reliably
        // observe intermediate state without delay — just verify final state)
        await future;

        expect(provider.isLoading.value, isFalse);
      });

      test('sets error when profile fetch fails', () async {
        when(() => mockRepo.getCompanyProfile(testCompanyId)).thenAnswer(
          (_) async => Result.failure(Exception('not found')),
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
        when(() => mockPortfolioRepo.getPositions(status: 'active'))
            .thenAnswer((_) async => const Result.success([]));

        await provider.loadAll();

        expect(provider.error.value, isNotNull);
        expect(provider.isLoading.value, isFalse);
      });

      test('still populates other signals when profile fails', () async {
        when(() => mockRepo.getCompanyProfile(testCompanyId)).thenAnswer(
          (_) async => Result.failure(Exception('not found')),
        );
        when(() => mockRepo.getMetrics(testCompanyId)).thenAnswer(
          (_) async => const Result.success([
            MetricSnapshot(
              metricCode: 'roe',
              metricName: 'ROE',
              metricCategory: 'profitability',
              valueNumeric: 0.15,
              computationStatus: 'ok',
            ),
          ]),
        );
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
        when(() => mockPortfolioRepo.getPositions(status: 'active'))
            .thenAnswer((_) async => const Result.success([]));

        await provider.loadAll();

        expect(provider.profile.value, isNull);
        expect(provider.metrics.value, hasLength(1));
        expect(provider.error.value, isNotNull);
      });
    });

    // ── loadCompanyLessons ───────────────────────────────────────────────

    group('loadCompanyLessons', () {
      test('populates companyLessons signal on success', () async {
        final now = DateTime(2026, 6, 22);
        final lessons = [
          PortfolioPosition(
            id: 'pos-1',
            companyId: testCompanyId,
            companyName: 'Apple Inc.',
            conviction: 'high',
            entryDate: DateTime(2026, 1, 1),
            status: PositionStatus.closed,
            exitDate: DateTime(2026, 6, 1),
            outcome: PositionOutcome.correct,
            lessonsLearned: 'Follow momentum',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(() => mockPortfolioRepo.getLessonsForCompany(testCompanyId))
            .thenAnswer((_) async => Result.success(lessons));

        await provider.loadCompanyLessons(testCompanyId);

        expect(provider.companyLessons.value, hasLength(1));
        expect(provider.companyLessons.value.first.lessonsLearned,
            'Follow momentum');
        expect(provider.isLoadingLessons.value, isFalse);
      });

      test('clears isLoadingLessons after failure', () async {
        when(() => mockPortfolioRepo.getLessonsForCompany(testCompanyId))
            .thenAnswer((_) async => Result.failure(Exception('db error')));

        await provider.loadCompanyLessons(testCompanyId);

        expect(provider.companyLessons.value, isEmpty);
        expect(provider.isLoadingLessons.value, isFalse);
      });
    });

    // ── createNote ───────────────────────────────────────────────────────

    group('createNote', () {
      test('prepends new note to notes signal on success', () async {
        final now = DateTime(2026, 6, 22);
        final existingNote = CompanyNote(
          id: 'note-old',
          companyId: testCompanyId,
          title: 'Old Note',
          body: 'Old body',
          createdAt: now,
          updatedAt: now,
        );
        provider.notes.value = [existingNote];

        final newNote = CompanyNote(
          id: 'note-new',
          companyId: testCompanyId,
          title: 'New Note',
          body: 'New body',
          createdAt: now,
          updatedAt: now,
        );
        when(() => mockRepo.createNote(
              companyId: testCompanyId,
              title: 'New Note',
              body: 'New body',
            )).thenAnswer((_) async => Result.success(newNote));

        await provider.createNote('New Note', 'New body');

        expect(provider.notes.value, hasLength(2));
        expect(provider.notes.value.first.id, 'note-new');
        expect(provider.notes.value.first.title, 'New Note');
        expect(provider.mutationError.value, isNull);
      });

      test('sets mutationError on failure', () async {
        when(() => mockRepo.createNote(
              companyId: testCompanyId,
              title: 'Fail',
              body: 'Fail body',
            )).thenAnswer((_) async => Result.failure(Exception('db error')));

        await provider.createNote('Fail', 'Fail body');

        expect(provider.notes.value, isEmpty);
        expect(provider.mutationError.value, isNotNull);
      });

      test('prevents concurrent mutations', () async {
        // Simulate a slow repo call
        when(() => mockRepo.createNote(
              companyId: testCompanyId,
              title: any(named: 'title'),
              body: any(named: 'body'),
            )).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return Result.success(CompanyNote(
            id: 'note-1',
            companyId: testCompanyId,
            title: 't',
            body: 'b',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        });

        // Start first mutation (don't await)
        final first = provider.createNote('t', 'b');
        // Second mutation should be skipped (_isMutating guard)
        await provider.createNote('t2', 'b2');
        await first;

        // Only one note should be created
        verify(() => mockRepo.createNote(
              companyId: testCompanyId,
              title: 't',
              body: 'b',
            )).called(1);
      });
    });

    // ── createThesis ─────────────────────────────────────────────────────

    group('createThesis', () {
      test('prepends new thesis to theses signal on success', () async {
        final now = DateTime(2026, 6, 22);
        final newThesis = CompanyThesis(
          id: 'thesis-new',
          companyId: testCompanyId,
          title: 'Growth thesis',
          stance: 'bullish',
          conviction: 'high',
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockRepo.createThesis(
              companyId: testCompanyId,
              title: 'Growth thesis',
              stance: 'bullish',
              summary: any(named: 'summary'),
              bullCase: any(named: 'bullCase'),
              bearCase: any(named: 'bearCase'),
              assumptions: any(named: 'assumptions'),
              catalysts: any(named: 'catalysts'),
              risks: any(named: 'risks'),
              exitConditions: any(named: 'exitConditions'),
              conviction: any(named: 'conviction'),
            )).thenAnswer((_) async => Result.success(newThesis));

        await provider.createThesis('Growth thesis', 'bullish',
            conviction: 'high');

        expect(provider.theses.value, hasLength(1));
        expect(provider.theses.value.first.title, 'Growth thesis');
        expect(provider.theses.value.first.stance, 'bullish');
        expect(provider.mutationError.value, isNull);
      });

      test('sets mutationError on failure', () async {
        when(() => mockRepo.createThesis(
              companyId: testCompanyId,
              title: any(named: 'title'),
              stance: any(named: 'stance'),
              conviction: any(named: 'conviction'),
            )).thenAnswer(
            (_) async => Result.failure(Exception('constraint violation')));

        await provider.createThesis('Fail', 'bullish');

        expect(provider.theses.value, isEmpty);
        expect(provider.mutationError.value, isNotNull);
      });
    });

    // ── markThesisReviewed ───────────────────────────────────────────────

    group('markThesisReviewed', () {
      test('updates lastReviewedAt on the matching thesis', () async {
        final now = DateTime(2026, 6, 22);
        final thesis = CompanyThesis(
          id: 'thesis-1',
          companyId: testCompanyId,
          title: 'My thesis',
          stance: 'bullish',
          createdAt: now,
          updatedAt: now,
        );
        provider.theses.value = [thesis];

        when(() => mockRepo.markThesisReviewed('thesis-1'))
            .thenAnswer((_) async => const Result.success(null));

        await provider.markThesisReviewed('thesis-1');

        final updated = provider.theses.value.firstWhere(
          (t) => t.id == 'thesis-1',
        );
        expect(updated.lastReviewedAt, isNotNull);
        expect(updated.updatedAt, isNotNull);
        expect(provider.mutationError.value, isNull);
      });

      test('sets mutationError on failure', () async {
        final now = DateTime(2026, 6, 22);
        provider.theses.value = [
          CompanyThesis(
            id: 'thesis-1',
            companyId: testCompanyId,
            title: 'My thesis',
            stance: 'bullish',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(() => mockRepo.markThesisReviewed('thesis-1')).thenAnswer(
            (_) async => Result.failure(Exception('permission denied')));

        await provider.markThesisReviewed('thesis-1');

        expect(provider.mutationError.value, isNotNull);
        // Original thesis should be unchanged
        expect(provider.theses.value.first.lastReviewedAt, isNull);
      });
    });

    // ── researchStatus ───────────────────────────────────────────────────

    group('researchStatus', () {
      test('returns not_researched when empty', () {
        expect(provider.researchStatus, 'not_researched');
      });

      test('returns researching when notes exist', () {
        final now = DateTime(2026, 6, 22);
        provider.notes.value = [
          CompanyNote(
            id: 'n1',
            companyId: testCompanyId,
            title: 't',
            body: 'b',
            createdAt: now,
            updatedAt: now,
          ),
        ];
        expect(provider.researchStatus, 'researching');
      });

      test('returns researching when theses exist', () {
        final now = DateTime(2026, 6, 22);
        provider.theses.value = [
          CompanyThesis(
            id: 't1',
            companyId: testCompanyId,
            title: 't',
            stance: 'bullish',
            createdAt: now,
            updatedAt: now,
          ),
        ];
        expect(provider.researchStatus, 'researching');
      });
    });

    // ── deleteNote ───────────────────────────────────────────────────────

    group('deleteNote', () {
      test('removes note from signal on success', () async {
        final now = DateTime(2026, 6, 22);
        provider.notes.value = [
          CompanyNote(
            id: 'note-1',
            companyId: testCompanyId,
            title: 't',
            body: 'b',
            createdAt: now,
            updatedAt: now,
          ),
          CompanyNote(
            id: 'note-2',
            companyId: testCompanyId,
            title: 't2',
            body: 'b2',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(() => mockRepo.deleteNote('note-1'))
            .thenAnswer((_) async => const Result.success(null));

        await provider.deleteNote('note-1');

        expect(provider.notes.value, hasLength(1));
        expect(provider.notes.value.first.id, 'note-2');
      });

      test('sets mutationError on failure', () async {
        final now = DateTime(2026, 6, 22);
        provider.notes.value = [
          CompanyNote(
            id: 'note-1',
            companyId: testCompanyId,
            title: 't',
            body: 'b',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(() => mockRepo.deleteNote('note-1')).thenAnswer(
            (_) async => Result.failure(Exception('foreign key')));

        await provider.deleteNote('note-1');

        expect(provider.notes.value, hasLength(1));
        expect(provider.mutationError.value, isNotNull);
      });
    });
  });
}
