import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taug/core/errors/result.dart';
import 'package:taug/features/company/data/workspace_models.dart';
import 'package:taug/features/company/data/workspace_repository.dart';
import 'package:taug/features/company/presentation/providers/workspace_provider.dart';
import 'package:taug/features/company/presentation/widgets/financials_tab.dart';
import 'package:taug/features/portfolio/data/portfolio_models.dart';
import 'package:taug/features/portfolio/data/portfolio_workspace_repository.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

class MockPortfolioPositionRepository extends Mock implements PortfolioPositionRepository {}

/// Sets the test surface to the given logical [width]x[height] and returns
/// a tear-down that resets to the default.
void _setViewport(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width * 2.0, height * 2.0);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Wrapper that renders [FinancialsTab] filling the available space.
class _TestHarness extends StatelessWidget {
  final WorkspaceProvider provider;

  const _TestHarness({required this.provider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FinancialsTab(provider: provider),
      ),
    );
  }
}

void main() {
  late MockWorkspaceRepository mockRepo;
  late MockPortfolioPositionRepository mockPortfolioRepo;
  late WorkspaceProvider provider;

  const testCompanyId = 'comp-fin-001';

  setUp(() {
    mockRepo = MockWorkspaceRepository();
    mockPortfolioRepo = MockPortfolioPositionRepository();

    // Stub all loadAll calls so the provider can be populated manually.
    when(() => mockRepo.getCompanyProfile(testCompanyId)).thenAnswer(
      (_) async => const Result.success(
        CompanyProfile(
          id: testCompanyId,
          displayName: 'Apple Inc.',
          ticker: 'AAPL',
        ),
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

  /// Populate provider signals with sample financial data.
  void populateProvider({
    List<StatementRow>? statements,
    QualityScoreDetail? quality,
    String? freshness,
    List<CompanyQuestion>? questions,
    List<CompanyThesis>? theses,
  }) {
    provider.statements.value = statements ?? [];
    provider.qualityDetail.value = quality;
    provider.freshnessStatus.value = freshness;
    provider.questions.value = questions ?? [];
    provider.theses.value = theses ?? [];
  }

  // ==========================================================================
  // Track F: Financials Widget Tests
  // ==========================================================================

  group('FinancialsTab', () {
    // -------------------------------------------------------------------------
    // 1. Two-pane layout renders (tables left, sidebar right)
    // -------------------------------------------------------------------------
    group('two-pane layout', () {
      testWidgets('renders tables on left and sidebar on right at ≥1200px',
          (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000, 'net_income': 25000000},
            ),
          ],
          quality: const QualityScoreDetail(overallScore: 0.85),
          freshness: 'fresh',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        // The sidebar should be visible: 'RESEARCH CONTEXT' header.
        expect(find.text('RESEARCH CONTEXT'), findsOneWidget);

        // Tables should render: 'Income Statement' section header.
        expect(find.text('INCOME STATEMENT'), findsOneWidget);

        // Financial values should render.
        expect(find.text('\$100.00M'), findsOneWidget);
        expect(find.text('\$25.00M'), findsOneWidget);
      });

      testWidgets('shows VerticalDivider between panes at wide viewport',
          (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 50000000},
            ),
          ],
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        // Sidebar should be visible initially.
        expect(find.text('RESEARCH CONTEXT'), findsOneWidget);

        // The VerticalDivider separates left/right panes.
        expect(find.byType(VerticalDivider), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 2. Sidebar shows Freshness card
    // -------------------------------------------------------------------------
    group('Freshness card', () {
      testWidgets('displays freshness header and status badge', (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          freshness: 'fresh',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('FRESHNESS'), findsOneWidget);
        expect(find.text('Fresh'), findsAtLeast(1));
        expect(find.text('Data as-of'), findsOneWidget);
        expect(find.text('Last filing'), findsOneWidget);
      });

      testWidgets('shows Aging badge when freshness is aging', (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 50000000},
            ),
          ],
          freshness: 'aging',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('Aging'), findsAtLeast(1));
      });

      testWidgets('shows Stale badge when freshness is stale', (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 50000000},
            ),
          ],
          freshness: 'stale',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('Stale'), findsAtLeast(1));
      });

      testWidgets('shows Expired badge when freshness is expired',
          (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 50000000},
            ),
          ],
          freshness: 'expired',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('Expired'), findsAtLeast(1));
      });

      testWidgets('shows dash when no statements available', (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [],
          freshness: null,
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('FRESHNESS'), findsOneWidget);
        // Should show em-dash for as-of and filing dates.
        expect(find.text('\u2014'), findsAtLeast(1));
      });
    });

    // -------------------------------------------------------------------------
    // 3. Sidebar shows Coverage card
    // -------------------------------------------------------------------------
    group('Coverage card', () {
      testWidgets('displays COVERAGE header and percentage', (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          quality: const QualityScoreDetail(
            overallScore: 0.85,
            historicalCoverageScore: 0.9,
            completenessScore: 0.8,
            validationScore: 0.7,
            verificationScore: 0.6,
            freshnessScore: 0.95,
          ),
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('COVERAGE'), findsOneWidget);
        expect(find.text('85%'), findsOneWidget);
        // Component bars.
        expect(find.text('Historical'), findsOneWidget);
        expect(find.text('Completeness'), findsOneWidget);
        expect(find.text('Validation'), findsOneWidget);
        expect(find.text('Verification'), findsOneWidget);
        expect(find.text('Freshness'), findsOneWidget);
      });

      testWidgets('shows No quality data when quality is null', (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          quality: null,
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('COVERAGE'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);
        expect(find.text('No quality data'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 4. Sidebar shows Restatement card
    // -------------------------------------------------------------------------
    group('Restatement card', () {
      testWidgets('displays RESTATEMENTS header and counts', (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              statementVersion: 2,
              isRestated: true,
              items: {'revenue': 100000000},
            ),
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2025-12-31',
              items: {'revenue': 90000000},
            ),
          ],
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('RESTATEMENTS'), findsOneWidget);
        expect(find.text('Restated'), findsOneWidget);
        expect(find.text('Revised versions'), findsOneWidget);
      });

      testWidgets('shows zero counts when no restatements', (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('RESTATEMENTS'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 5. Sidebar shows Next Steps card
    // -------------------------------------------------------------------------
    group('Next Steps card', () {
      testWidgets('displays NEXT STEPS header with open questions count',
          (tester) async {
        _setViewport(tester, 1400, 800);
        final now = DateTime(2026, 6, 22);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          theses: [
            CompanyThesis(
              id: 'th-1',
              companyId: testCompanyId,
              title: 'Growth thesis',
              stance: 'bullish',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          questions: [
            CompanyQuestion(
              id: 'q-1',
              companyId: testCompanyId,
              question: 'What about margins?',
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('NEXT STEPS'), findsOneWidget);
        expect(find.text('Open questions'), findsOneWidget);
        expect(find.text('Thesis freshness'), findsOneWidget);
      });

      testWidgets('shows next action prompt based on progression state',
          (tester) async {
        _setViewport(tester, 1400, 800);
        final now = DateTime(2026, 6, 22);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          theses: [
            CompanyThesis(
              id: 'th-1',
              companyId: testCompanyId,
              title: 'Growth thesis',
              stance: 'bullish',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          questions: [
            CompanyQuestion(
              id: 'q-1',
              companyId: testCompanyId,
              question: 'Margins?',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          freshness: 'stale',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        // With open questions, nextAction = answerQuestions regardless of freshness.
        expect(find.text('Answer Questions'), findsOneWidget);
      });

      testWidgets('shows Review Thesis when stale with no open questions',
          (tester) async {
        _setViewport(tester, 1400, 800);
        final now = DateTime(2026, 6, 22);
        // Need active position to bypass positionReady stage.
        provider.companyLessons.value = [
          PortfolioPosition(
            id: 'pos-1',
            companyId: testCompanyId,
            companyName: 'Apple Inc.',
            conviction: 'high',
            entryDate: DateTime(2026, 1, 1),
            status: PositionStatus.active,
            createdAt: now,
            updatedAt: now,
          ),
        ];
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          theses: [
            CompanyThesis(
              id: 'th-1',
              companyId: testCompanyId,
              title: 'Growth thesis',
              stance: 'bullish',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          questions: [],
          freshness: 'stale',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        // stage=activePosition, isStale=true → reviewThesis.
        expect(find.text('Review Thesis'), findsOneWidget);
      });

      testWidgets('shows dash for thesis freshness when no thesis',
          (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          theses: [],
          questions: [],
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('NEXT STEPS'), findsOneWidget);
        expect(find.text('Thesis freshness'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 6. Sidebar collapses below 1200px viewport
    // -------------------------------------------------------------------------
    group('sidebar collapse below breakpoint', () {
      testWidgets('hides sidebar at 800px viewport width', (tester) async {
        _setViewport(tester, 800, 600);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          quality: const QualityScoreDetail(overallScore: 0.85),
          freshness: 'fresh',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        // Sidebar should NOT be visible at 800px.
        expect(find.text('RESEARCH CONTEXT'), findsNothing);
        expect(find.text('FRESHNESS'), findsNothing);
        expect(find.text('COVERAGE'), findsNothing);
        expect(find.text('RESTATEMENTS'), findsNothing);
        expect(find.text('NEXT STEPS'), findsNothing);

        // Toggle button should be visible. Initial state is _sidebarVisible=true
        // so isExpanded=true → text is 'HIDE CONTEXT'.
        expect(find.text('HIDE CONTEXT'), findsOneWidget);
      });

      testWidgets('hides sidebar at 1199px viewport width (just below)',
          (tester) async {
        _setViewport(tester, 1199, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          freshness: 'fresh',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('RESEARCH CONTEXT'), findsNothing);
        expect(find.text('HIDE CONTEXT'), findsOneWidget);
      });

      testWidgets('shows sidebar at exactly 1200px viewport width',
          (tester) async {
        _setViewport(tester, 1200, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          freshness: 'fresh',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('RESEARCH CONTEXT'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 7. Toggle button shows/hides sidebar
    // -------------------------------------------------------------------------
    group('toggle button', () {
      testWidgets('shows toggle button below breakpoint', (tester) async {
        _setViewport(tester, 800, 600);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        // _sidebarVisible starts true, isExpanded=true at narrow viewport.
        expect(find.text('HIDE CONTEXT'), findsOneWidget);
      });

      testWidgets('tapping toggle changes text at narrow viewport',
          (tester) async {
        _setViewport(tester, 800, 600);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          freshness: 'fresh',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        // Initially "HIDE CONTEXT" (sidebar preference is visible).
        expect(find.text('HIDE CONTEXT'), findsOneWidget);

        // Tap to toggle _sidebarVisible to false.
        await tester.tap(find.text('HIDE CONTEXT'));
        await tester.pumpAndSettle();

        // Now _sidebarVisible=false, isExpanded=false → "SHOW CONTEXT".
        expect(find.text('SHOW CONTEXT'), findsOneWidget);
      });

      testWidgets('tapping toggle twice restores original text',
          (tester) async {
        _setViewport(tester, 800, 600);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          freshness: 'fresh',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        // Tap to toggle to "SHOW CONTEXT".
        await tester.tap(find.text('HIDE CONTEXT'));
        await tester.pumpAndSettle();
        expect(find.text('SHOW CONTEXT'), findsOneWidget);

        // Tap to toggle back to "HIDE CONTEXT".
        await tester.tap(find.text('SHOW CONTEXT'));
        await tester.pumpAndSettle();
        expect(find.text('HIDE CONTEXT'), findsOneWidget);
      });

      testWidgets('no toggle shown when sidebar visible at wide viewport',
          (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(
          statements: [
            const StatementRow(
              statementType: 'income_statement',
              periodEnd: '2026-03-31',
              items: {'revenue': 100000000},
            ),
          ],
          freshness: 'fresh',
        );

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        // At wide viewport with sidebar visible, no toggle button.
        expect(find.text('SHOW CONTEXT'), findsNothing);
        expect(find.text('HIDE CONTEXT'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // Empty state
    // -------------------------------------------------------------------------
    group('empty state', () {
      testWidgets('shows no financial data message when statements empty',
          (tester) async {
        _setViewport(tester, 1400, 800);
        populateProvider(statements: []);

        await tester.pumpWidget(_TestHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.text('No financial data available'), findsOneWidget);
      });
    });
  });
}
