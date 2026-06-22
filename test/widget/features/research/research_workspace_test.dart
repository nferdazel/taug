import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taug/core/errors/result.dart';
import 'package:taug/features/research/data/research_models.dart';
import 'package:taug/features/research/data/research_repository.dart';
import 'package:taug/features/research/presentation/pages/research_workspace_page.dart';
import 'package:taug/features/research/presentation/providers/research_provider.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockResearchRepository extends Mock implements ResearchRepository {}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Sets a wide surface size so the header Row doesn't overflow.
void _setWideSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(2800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

ResearchProvider _createProvider(MockResearchRepository mockRepo) {
  return ResearchProvider(repository: mockRepo);
}

/// Stubs all repository calls for loadAll to return empty lists.
void _stubLoadAllEmpty(MockResearchRepository mockRepo) {
  when(() => mockRepo.getResearchCompanies()).thenAnswer(
    (_) async => const Result.success(<ResearchCompany>[]),
  );
  when(() => mockRepo.getAllTheses()).thenAnswer(
    (_) async => const Result.success(<ResearchThesisIndex>[]),
  );
  when(() => mockRepo.getAllNotes()).thenAnswer(
    (_) async => const Result.success(<ResearchNoteIndex>[]),
  );
  when(() => mockRepo.getOpenQuestions()).thenAnswer(
    (_) async => const Result.success(<ResearchQuestionIndex>[]),
  );
}

/// Creates a researching company with the given counts.
ResearchCompany _researchingCompany({
  String id = 'comp-1',
  String name = 'Apple Inc.',
  String? ticker = 'AAPL',
  int notesCount = 3,
  int thesesCount = 1,
}) {
  return ResearchCompany(
    companyId: id,
    displayName: name,
    ticker: ticker,
    notesCount: notesCount,
    thesesCount: thesesCount,
    researchStatus: 'researching',
  );
}

/// Creates a thesis index entry.
ResearchThesisIndex _thesis({
  String id = 'thesis-1',
  String companyId = 'comp-1',
  String companyName = 'Apple Inc.',
  String? ticker = 'AAPL',
  String title = 'Bull case',
  String stance = 'bullish',
  String conviction = 'high',
  DateTime? updatedAt,
}) {
  return ResearchThesisIndex(
    thesisId: id,
    companyId: companyId,
    companyName: companyName,
    ticker: ticker,
    title: title,
    stance: stance,
    conviction: conviction,
    updatedAt: updatedAt ?? DateTime(2026, 6, 20),
  );
}

/// Creates a note index entry.
ResearchNoteIndex _note({
  String id = 'note-1',
  String companyId = 'comp-1',
  String companyName = 'Apple Inc.',
  String? ticker = 'AAPL',
  String title = 'Q1 Analysis',
  String body = 'Strong quarter',
  DateTime? updatedAt,
}) {
  return ResearchNoteIndex(
    noteId: id,
    companyId: companyId,
    companyName: companyName,
    ticker: ticker,
    title: title,
    body: body,
    updatedAt: updatedAt ?? DateTime(2026, 6, 21),
  );
}

/// Creates a question index entry.
ResearchQuestionIndex _question({
  String id = 'q-1',
  String? companyId = 'comp-1',
  String? companyName = 'Apple Inc.',
  String question = 'What about margins?',
  String priority = 'high',
  String status = 'open',
  int notesCount = 2,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 6, 22);
  return ResearchQuestionIndex(
    questionId: id,
    companyId: companyId,
    companyName: companyName,
    question: question,
    priority: priority,
    status: status,
    notesCount: notesCount,
    createdAt: createdAt ?? now.subtract(const Duration(days: 10)),
    updatedAt: updatedAt ?? now,
  );
}

/// Stubs loadAll with custom data.
void _stubLoadAll({
  required MockResearchRepository mockRepo,
  List<ResearchCompany>? companies,
  List<ResearchThesisIndex>? theses,
  List<ResearchNoteIndex>? notes,
  List<ResearchQuestionIndex>? questions,
}) {
  when(() => mockRepo.getResearchCompanies()).thenAnswer(
    (_) async => Result.success(companies ?? []),
  );
  when(() => mockRepo.getAllTheses()).thenAnswer(
    (_) async => Result.success(theses ?? []),
  );
  when(() => mockRepo.getAllNotes()).thenAnswer(
    (_) async => Result.success(notes ?? []),
  );
  when(() => mockRepo.getOpenQuestions()).thenAnswer(
    (_) async => Result.success(questions ?? []),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockResearchRepository mockRepo;

  setUp(() {
    mockRepo = MockResearchRepository();
  });

  // =========================================================================
  // 1. Needs Attention hero renders when items exist
  // =========================================================================

  group('Needs Attention hero', () {
    testWidgets('renders attention items when companies need thesis',
        (tester) async {
      _setWideSurface(tester);
      final now = DateTime(2026, 6, 22);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [
          _researchingCompany(notesCount: 5, thesesCount: 0),
        ],
        notes: [_note()],
        questions: [],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      // Section header
      expect(find.text('NEEDS ATTENTION'), findsOneWidget);

      // Company needs thesis attention item
      expect(find.textContaining('has no thesis'), findsOneWidget);
      expect(find.text('Write Thesis'), findsOneWidget);
    });

    testWidgets('renders stale thesis attention item', (tester) async {
      _setWideSurface(tester);
      final now = DateTime(2026, 6, 22);
      // Thesis updated 120 days ago → stale
      final staleDate = now.subtract(const Duration(days: 120));
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [_researchingCompany()],
        theses: [_thesis(updatedAt: staleDate)],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEEDS ATTENTION'), findsOneWidget);
      expect(find.textContaining('days old'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('renders critical question attention item', (tester) async {
      _setWideSurface(tester);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [_researchingCompany()],
        theses: [_thesis()],
        questions: [
          _question(priority: 'critical', question: 'Is revenue declining?'),
        ],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEEDS ATTENTION'), findsOneWidget);
      expect(find.textContaining('[CRITICAL]'), findsOneWidget);
      expect(find.text('Investigate'), findsOneWidget);
    });

    // =======================================================================
    // 2. Needs Attention shows "All research is up to date" when empty
    // =======================================================================

    testWidgets('shows "All research is up to date" when no attention items',
        (tester) async {
      _setWideSurface(tester);
      _stubLoadAllEmpty(mockRepo);

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('All research is up to date'), findsOneWidget);
      // Section header should NOT appear
      expect(find.text('NEEDS ATTENTION'), findsNothing);
    });
  });

  // =========================================================================
  // 3. Active Research section renders company rows
  // =========================================================================

  group('Active Research section', () {
    testWidgets('renders ACTIVE RESEARCH header and company names',
        (tester) async {
      _setWideSurface(tester);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [
          _researchingCompany(
            id: 'comp-1',
            name: 'Apple Inc.',
            ticker: 'AAPL',
            thesesCount: 1,
          ),
          _researchingCompany(
            id: 'comp-2',
            name: 'Microsoft Corp.',
            ticker: 'MSFT',
            thesesCount: 2,
          ),
        ],
        theses: [_thesis()],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE RESEARCH'), findsOneWidget);
      // Company names appear in both Active Research cards and Recent Activity rows
      expect(find.text('Apple Inc.'), findsAtLeastNWidgets(1));
      expect(find.text('Microsoft Corp.'), findsAtLeastNWidgets(1));
    });

    testWidgets('hides Active Research when no companies have theses',
        (tester) async {
      _setWideSurface(tester);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [
          _researchingCompany(thesesCount: 0, notesCount: 3),
        ],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE RESEARCH'), findsNothing);
    });
  });

  // =========================================================================
  // 4. Recent Activity section renders merged timeline
  // =========================================================================

  group('Recent Activity section', () {
    testWidgets('renders RECENT ACTIVITY header with theses and notes',
        (tester) async {
      _setWideSurface(tester);
      final now = DateTime(2026, 6, 22);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [_researchingCompany()],
        theses: [
          _thesis(
            id: 'thesis-1',
            title: 'Bull case for Apple',
            updatedAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        notes: [
          _note(
            id: 'note-1',
            title: 'Q1 earnings analysis',
            updatedAt: now.subtract(const Duration(hours: 5)),
          ),
        ],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECENT ACTIVITY'), findsOneWidget);

      // Both items should be visible
      expect(find.text('Bull case for Apple'), findsOneWidget);
      expect(find.text('Q1 earnings analysis'), findsOneWidget);

      // Type badges
      expect(find.text('THESIS'), findsWidgets);
      expect(find.text('NOTE'), findsOneWidget);
    });

    testWidgets('hides Recent Activity when no theses or notes', (tester) async {
      _setWideSurface(tester);
      _stubLoadAllEmpty(mockRepo);

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECENT ACTIVITY'), findsNothing);
    });
  });

  // =========================================================================
  // 5. Open Questions section renders critical/high only
  // =========================================================================

  group('Open Questions section', () {
    testWidgets('renders OPEN QUESTIONS header with questions', (tester) async {
      _setWideSurface(tester);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [_researchingCompany()],
        theses: [_thesis()],
        questions: [
          _question(
            id: 'q-1',
            question: 'Is revenue growth sustainable?',
            priority: 'critical',
          ),
          _question(
            id: 'q-2',
            question: 'What is the margin trajectory?',
            priority: 'high',
          ),
        ],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPEN QUESTIONS'), findsOneWidget);
      expect(find.text('Is revenue growth sustainable?'), findsOneWidget);
      expect(find.text('What is the margin trajectory?'), findsOneWidget);
    });

    testWidgets('renders priority badges for questions', (tester) async {
      _setWideSurface(tester);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [_researchingCompany()],
        theses: [_thesis()],
        questions: [
          _question(id: 'q-1', question: 'Q1', priority: 'critical'),
          _question(id: 'q-2', question: 'Q2', priority: 'high'),
        ],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      // PriorityBadge renders priority text in uppercase
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('hides Open Questions when no open questions exist',
        (tester) async {
      _setWideSurface(tester);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [_researchingCompany()],
        theses: [_thesis()],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPEN QUESTIONS'), findsNothing);
    });
  });

  // =========================================================================
  // 6. Empty sections are hidden (no dead space)
  // =========================================================================

  group('Empty section hiding', () {
    testWidgets('hides all sections when no data exists', (tester) async {
      _setWideSurface(tester);
      _stubLoadAllEmpty(mockRepo);

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      // Only the "All research is up to date" message should be visible
      expect(find.text('All research is up to date'), findsOneWidget);

      // All optional sections hidden
      expect(find.text('ACTIVE RESEARCH'), findsNothing);
      expect(find.text('OPEN QUESTIONS'), findsNothing);
      expect(find.text('RECENT ACTIVITY'), findsNothing);
    });

    testWidgets('hides Active Research and Open Questions when only notes exist',
        (tester) async {
      _setWideSurface(tester);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [
          _researchingCompany(notesCount: 3, thesesCount: 0),
        ],
        notes: [_note()],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      // Notes exist but no theses → Active Research hidden
      expect(find.text('ACTIVE RESEARCH'), findsNothing);
      // No questions → Open Questions hidden
      expect(find.text('OPEN QUESTIONS'), findsNothing);

      // But Recent Activity should show the note
      expect(find.text('RECENT ACTIVITY'), findsOneWidget);
    });

    testWidgets('hides Recent Activity when only questions exist (no theses/notes)',
        (tester) async {
      _setWideSurface(tester);
      _stubLoadAll(
        mockRepo: mockRepo,
        companies: [_researchingCompany(thesesCount: 0, notesCount: 0)],
        questions: [
          _question(question: 'Is this sustainable?', priority: 'high'),
        ],
      );

      final provider = _createProvider(mockRepo);
      await tester.pumpWidget(
        _wrapInApp(ResearchWorkspacePage(provider: provider)),
      );
      await tester.pumpAndSettle();

      // No theses or notes → Active Research hidden, Recent Activity hidden
      expect(find.text('ACTIVE RESEARCH'), findsNothing);
      expect(find.text('RECENT ACTIVITY'), findsNothing);
      // But Open Questions should be visible (theses empty → questions rendered anyway)
      expect(find.text('OPEN QUESTIONS'), findsOneWidget);
    });
  });
}
