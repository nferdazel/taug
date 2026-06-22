import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taug/shared/widgets/research_empty_state.dart';

/// Helper: wraps widget under test in a MaterialApp so text rendering,
/// theming, and gesture handling work correctly in tests.
Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  // ──────────────────────────────────────────────
  // ThesisEmptyState
  // ──────────────────────────────────────────────
  group('ThesisEmptyState', () {
    testWidgets('renders "No Thesis Yet" state text', (tester) async {
      await tester.pumpWidget(_wrapInApp(const ThesisEmptyState()));

      expect(find.text('No Thesis Yet'), findsOneWidget);
    });

    testWidgets('renders "why it matters" explanation', (tester) async {
      await tester.pumpWidget(_wrapInApp(const ThesisEmptyState()));

      expect(
        find.textContaining('A thesis converts research into decisions'),
        findsOneWidget,
      );
    });

    testWidgets('renders "what to do" guidance', (tester) async {
      await tester.pumpWidget(_wrapInApp(const ThesisEmptyState()));

      expect(
        find.textContaining('What do you believe about this company'),
        findsOneWidget,
      );
    });

    testWidgets('renders "Create Thesis" action button', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(ThesisEmptyState(onCreateThesis: () {})),
      );

      expect(find.text('Create Thesis'), findsOneWidget);
    });

    testWidgets('button triggers onCreateThesis callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _wrapInApp(ThesisEmptyState(onCreateThesis: () => called = true)),
      );

      await tester.tap(find.text('Create Thesis'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });

  // ──────────────────────────────────────────────
  // QuestionsEmptyState
  // ──────────────────────────────────────────────
  group('QuestionsEmptyState', () {
    testWidgets('renders "No Research Questions" state text', (tester) async {
      await tester.pumpWidget(_wrapInApp(const QuestionsEmptyState()));

      expect(find.text('No Research Questions'), findsOneWidget);
    });

    testWidgets('renders "why it matters" explanation', (tester) async {
      await tester.pumpWidget(_wrapInApp(const QuestionsEmptyState()));

      expect(
        find.textContaining('Questions drive focused research'),
        findsOneWidget,
      );
    });

    testWidgets('renders "what to do" guidance', (tester) async {
      await tester.pumpWidget(_wrapInApp(const QuestionsEmptyState()));

      expect(
        find.textContaining('What do I need to know about this company'),
        findsOneWidget,
      );
    });

    testWidgets('renders "Add Question" action button', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(QuestionsEmptyState(onCreateQuestion: () {})),
      );

      expect(find.text('Add Question'), findsOneWidget);
    });

    testWidgets('button triggers onCreateQuestion callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _wrapInApp(
          QuestionsEmptyState(onCreateQuestion: () => called = true),
        ),
      );

      await tester.tap(find.text('Add Question'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });

  // ──────────────────────────────────────────────
  // NotesEmptyState
  // ──────────────────────────────────────────────
  group('NotesEmptyState', () {
    testWidgets('renders "No Research Notes" state text', (tester) async {
      await tester.pumpWidget(_wrapInApp(const NotesEmptyState()));

      expect(find.text('No Research Notes'), findsOneWidget);
    });

    testWidgets('renders "why it matters" explanation', (tester) async {
      await tester.pumpWidget(_wrapInApp(const NotesEmptyState()));

      expect(
        find.textContaining('Notes capture your research findings'),
        findsOneWidget,
      );
    });

    testWidgets('renders "what to do" guidance', (tester) async {
      await tester.pumpWidget(_wrapInApp(const NotesEmptyState()));

      expect(
        find.textContaining('Key financial metrics'),
        findsOneWidget,
      );
    });

    testWidgets('renders "Create Note" action button', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(NotesEmptyState(onCreateNote: () {})),
      );

      expect(find.text('Create Note'), findsOneWidget);
    });

    testWidgets('button triggers onCreateNote callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _wrapInApp(NotesEmptyState(onCreateNote: () => called = true)),
      );

      await tester.tap(find.text('Create Note'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });

  // ──────────────────────────────────────────────
  // PositionEmptyState
  // ──────────────────────────────────────────────
  group('PositionEmptyState', () {
    testWidgets('renders "No Position" state text', (tester) async {
      await tester.pumpWidget(_wrapInApp(const PositionEmptyState()));

      expect(find.text('No Position'), findsOneWidget);
    });

    testWidgets('renders "why it matters" explanation', (tester) async {
      await tester.pumpWidget(_wrapInApp(const PositionEmptyState()));

      expect(
        find.textContaining(
          'A position tracks your investment decision',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders "what to do" guidance', (tester) async {
      await tester.pumpWidget(_wrapInApp(const PositionEmptyState()));

      expect(
        find.textContaining('Review your thesis and conviction'),
        findsOneWidget,
      );
    });

    testWidgets('renders "Create Position" action button', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(PositionEmptyState(onCreatePosition: () {})),
      );

      expect(find.text('Create Position'), findsOneWidget);
    });

    testWidgets('button triggers onCreatePosition callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _wrapInApp(
          PositionEmptyState(onCreatePosition: () => called = true),
        ),
      );

      await tester.tap(find.text('Create Position'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });

  // ──────────────────────────────────────────────
  // LessonsEmptyState
  // ──────────────────────────────────────────────
  group('LessonsEmptyState', () {
    testWidgets('renders "No Lessons Yet" state text', (tester) async {
      await tester.pumpWidget(_wrapInApp(const LessonsEmptyState()));

      expect(find.text('No Lessons Yet'), findsOneWidget);
    });

    testWidgets('renders "why it matters" explanation', (tester) async {
      await tester.pumpWidget(_wrapInApp(const LessonsEmptyState()));

      expect(
        find.textContaining(
          'Lessons capture what you learned from each decision',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders "what to do" guidance', (tester) async {
      await tester.pumpWidget(_wrapInApp(const LessonsEmptyState()));

      expect(
        find.textContaining('Close a position with lessons'),
        findsOneWidget,
      );
    });

    testWidgets('does not render an action button', (tester) async {
      await tester.pumpWidget(_wrapInApp(const LessonsEmptyState()));

      // LessonsEmptyState passes no onAction — the button must be absent.
      // Verify "View Portfolio" label does not appear as a tappable button.
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
