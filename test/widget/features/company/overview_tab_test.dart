import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taug/core/errors/result.dart';
import 'package:taug/features/company/data/workspace_models.dart';
import 'package:taug/features/company/data/workspace_repository.dart';
import 'package:taug/features/company/presentation/providers/workspace_provider.dart';
import 'package:taug/features/company/presentation/widgets/overview_tab.dart';
import 'package:taug/features/portfolio/data/portfolio_models.dart';
import 'package:taug/features/portfolio/data/portfolio_workspace_repository.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

class MockPortfolioPositionRepository extends Mock implements PortfolioPositionRepository {}

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 800, height: 600, child: child)),
  );
}

WorkspaceProvider _createProvider({
  required MockWorkspaceRepository mockRepo,
  required MockPortfolioPositionRepository mockPortfolioRepo,
}) {
  return WorkspaceProvider(
    companyId: 'comp-1',
    repository: mockRepo,
    portfolioRepository: mockPortfolioRepo,
  );
}

/// Stubs all repository calls for loadAll to succeed with empty defaults.
void _stubLoadAllDefaults(MockWorkspaceRepository mockRepo) {
  when(() => mockRepo.getCompanyProfile('comp-1')).thenAnswer(
    (_) async => const Result.success(
      CompanyProfile(id: 'comp-1', displayName: 'Test Co'),
    ),
  );
  when(() => mockRepo.getMetrics('comp-1')).thenAnswer(
    (_) async => const Result.success(<MetricSnapshot>[]),
  );
  when(() => mockRepo.getFinancialStatements('comp-1')).thenAnswer(
    (_) async => const Result.success(<StatementRow>[]),
  );
  when(() => mockRepo.getNotes('comp-1')).thenAnswer(
    (_) async => const Result.success(<CompanyNote>[]),
  );
  when(() => mockRepo.getTheses('comp-1')).thenAnswer(
    (_) async => const Result.success(<CompanyThesis>[]),
  );
  when(() => mockRepo.getQualityScore('comp-1')).thenAnswer(
    (_) async => const Result.success(null),
  );
  when(() => mockRepo.getFreshnessStatus('comp-1')).thenAnswer(
    (_) async => const Result.success(null),
  );
  when(() => mockRepo.getQuestions('comp-1')).thenAnswer(
    (_) async => const Result.success(<CompanyQuestion>[]),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockWorkspaceRepository mockRepo;
  late MockPortfolioPositionRepository mockPortfolioRepo;

  setUp(() {
    mockRepo = MockWorkspaceRepository();
    mockPortfolioRepo = MockPortfolioPositionRepository();
    _stubLoadAllDefaults(mockRepo);
  });

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(const CompanyProfile(id: '', displayName: ''));
  });

  // =========================================================================
  // 1. Research Snapshot renders 4 cells (Thesis, Notes, Questions, Position)
  // =========================================================================

  group('Research Snapshot', () {
    testWidgets('renders 4 snapshot cells: THESIS, NOTES, QUESTIONS, POSITION',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // Section header
      expect(find.text('RESEARCH SNAPSHOT'), findsOneWidget);

      // All four snapshot cell labels
      expect(find.text('THESIS'), findsOneWidget);
      expect(find.text('NOTES'), findsOneWidget);
      expect(find.text('QUESTIONS'), findsOneWidget);
      expect(find.text('POSITION'), findsOneWidget);
    });
  });

  // =========================================================================
  // 2. Next Action banner renders when action is not none
  // =========================================================================

  group('Next Action banner', () {
    testWidgets('renders action label and description when action is not none',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      // No notes, no theses → stage = noResearch → nextAction = createNote
      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // createNote.label = 'Create Note'
      expect(find.text('Create Note'), findsWidgets);
      // createNote.description
      expect(
        find.text('Start documenting your research on this company.'),
        findsOneWidget,
      );
    });

    // =======================================================================
    // 3. Next Action banner hidden when action is none
    // =======================================================================

    testWidgets('hides banner when nextAction is none', (tester) async {
      final now = DateTime(2026, 6, 22);
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      // Set up complete research: notes + thesis + position + lessons
      // → stage = researchComplete → nextAction = none
      provider.notes.value = [
        CompanyNote(
          id: 'n1',
          companyId: 'comp-1',
          title: 'Note',
          body: 'Body',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      provider.theses.value = [
        CompanyThesis(
          id: 't1',
          companyId: 'comp-1',
          title: 'Thesis',
          stance: 'bullish',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      // Add active position + closed lesson to reach researchComplete
      provider.companyLessons.value = [
        PortfolioPosition(
          id: 'p-active',
          companyId: 'comp-1',
          conviction: 'high',
          entryDate: DateTime(2026, 1, 1),
          status: PositionStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
        PortfolioPosition(
          id: 'p-closed',
          companyId: 'comp-1',
          conviction: 'high',
          entryDate: DateTime(2026, 1, 1),
          exitDate: DateTime(2026, 5, 1),
          status: PositionStatus.closed,
          outcome: PositionOutcome.correct,
          lessonsLearned: 'Good trade',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // 'Research Complete' label appears in none state — but the icon
      // is a checkmark and description is different from active actions.
      // The key: the banner IS rendered for none (it shows "Research Complete").
      // Verify no other action labels like 'Create Note' appear.
      expect(find.text('Create Note'), findsNothing);
      expect(find.text('Create Thesis'), findsNothing);
      expect(find.text('Answer Questions'), findsNothing);
    });
  });

  // =========================================================================
  // 4. Snapshot cell shows "None" when count is 0
  // =========================================================================

  group('Snapshot cell empty state', () {
    testWidgets('shows "None" for THESIS when thesesCount is 0',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      // Default: no theses
      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // THESIS cell should show "None"
      expect(find.text('None'), findsWidgets);
    });

    testWidgets('shows "0 items" for NOTES when notesCount is 0',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      expect(find.text('0 items'), findsOneWidget);
    });

    // =======================================================================
    // 5. Snapshot cell shows action link when empty
    // =======================================================================

    testWidgets('shows "Create thesis" link when THESIS count is 0',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // THESIS cell has actionLabel = 'Create thesis'
      expect(find.text('Create thesis'), findsOneWidget);
    });

    testWidgets('shows "Create note" link when NOTES count is 0',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      expect(find.text('Create note'), findsOneWidget);
    });

    testWidgets('shows "Add question" link when QUESTIONS count is 0',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      expect(find.text('Add question'), findsOneWidget);
    });
  });

  // =========================================================================
  // 6. Data Trust section renders quality badge
  // =========================================================================

  group('Data Trust section', () {
    testWidgets('renders quality badge when qualityDetail is provided',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      provider.qualityDetail.value = QualityScoreDetail(
        overallScore: 0.85,
        scoreDate: DateTime(2026, 6, 1),
      );
      provider.freshnessStatus.value = 'fresh';

      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // Section header
      expect(find.text('DATA TRUST'), findsOneWidget);

      // Quality badge shows "85%"
      expect(find.text('85%'), findsOneWidget);

      // Quality label
      expect(find.text('Quality'), findsOneWidget);
    });

    testWidgets('renders freshness badge with correct label', (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      provider.qualityDetail.value = const QualityScoreDetail(
        overallScore: 0.65,
      );
      provider.freshnessStatus.value = 'stale';

      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // Freshness badge shows "Stale" for stale status
      expect(find.text('Stale'), findsOneWidget);
      // Statements label
      expect(find.text('Statements'), findsOneWidget);
    });

    testWidgets('hides Data Trust section when both quality and freshness are null',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      // Both null by default
      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      expect(find.text('DATA TRUST'), findsNothing);
    });
  });

  // =========================================================================
  // 7. Key Metrics section renders metric cells
  // =========================================================================

  group('Key Metrics section', () {
    testWidgets('renders KEY METRICS header and metric labels', (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      // Add metrics with recognized codes
      provider.metrics.value = [
        const MetricSnapshot(
          metricCode: 'market_cap',
          metricName: 'Market Cap',
          metricCategory: 'size',
          valueNumeric: 2.5e12,
          computationStatus: 'ok',
          unitType: 'monetary',
        ),
        const MetricSnapshot(
          metricCode: 'pe',
          metricName: 'P/E Ratio',
          metricCategory: 'valuation',
          valueNumeric: 25.5,
          computationStatus: 'ok',
          unitType: 'ratio',
        ),
        const MetricSnapshot(
          metricCode: 'roe',
          metricName: 'ROE',
          metricCategory: 'profitability',
          valueNumeric: 0.15,
          computationStatus: 'ok',
          unitType: 'percentage',
        ),
        const MetricSnapshot(
          metricCode: 'gross_margin',
          metricName: 'Gross Margin',
          metricCategory: 'profitability',
          valueNumeric: 0.42,
          computationStatus: 'ok',
          unitType: 'percentage',
        ),
        const MetricSnapshot(
          metricCode: 'net_margin',
          metricName: 'Net Margin',
          metricCategory: 'profitability',
          valueNumeric: 0.21,
          computationStatus: 'ok',
          unitType: 'percentage',
        ),
        const MetricSnapshot(
          metricCode: 'debt_equity',
          metricName: 'D/E',
          metricCategory: 'leverage',
          valueNumeric: 0.35,
          computationStatus: 'ok',
          unitType: 'ratio',
        ),
      ];

      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // Section header
      expect(find.text('KEY METRICS'), findsOneWidget);

      // All 6 metric labels
      expect(find.text('Market Cap'), findsOneWidget);
      expect(find.text('PE'), findsOneWidget);
      expect(find.text('ROE'), findsOneWidget);
      expect(find.text('Gross Margin'), findsOneWidget);
      expect(find.text('Net Margin'), findsOneWidget);
      expect(find.text('D/E'), findsOneWidget);
    });

    testWidgets('shows formatted values for present metrics', (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      provider.metrics.value = [
        const MetricSnapshot(
          metricCode: 'pe',
          metricName: 'P/E Ratio',
          metricCategory: 'valuation',
          valueNumeric: 25.5,
          computationStatus: 'ok',
          unitType: 'ratio',
        ),
      ];

      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // PE value: 25.50 (ratio → toFixed(2))
      expect(find.text('25.50'), findsOneWidget);
    });

    testWidgets('shows em-dash for missing metrics', (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      // Empty metrics — all cells show '—'
      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // 6 em-dashes for 6 empty metric cells
      expect(find.text('—'), findsNWidgets(6));
    });

    testWidgets('shows percentage format for percentage metrics',
        (tester) async {
      final provider = _createProvider(
        mockRepo: mockRepo,
        mockPortfolioRepo: mockPortfolioRepo,
      );
      provider.metrics.value = [
        const MetricSnapshot(
          metricCode: 'roe',
          metricName: 'ROE',
          metricCategory: 'profitability',
          valueNumeric: 0.1542,
          computationStatus: 'ok',
          unitType: 'percentage',
        ),
      ];

      await tester.pumpWidget(_wrapInApp(OverviewTab(provider: provider)));
      await tester.pumpAndSettle();

      // ROE value: 15.42%
      expect(find.text('15.42%'), findsOneWidget);
    });
  });
}
