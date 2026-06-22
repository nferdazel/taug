import 'package:flutter_test/flutter_test.dart';
import 'package:taug/shared/models/research_progression_state.dart';

void main() {
  group('NextAction enum', () {
    test('has exactly 7 values', () {
      expect(NextAction.values.length, 7);
    });

    test('values are in expected order', () {
      expect(NextAction.values, [
        NextAction.none,
        NextAction.createNote,
        NextAction.createThesis,
        NextAction.answerQuestions,
        NextAction.createPosition,
        NextAction.reviewThesis,
        NextAction.reviewFiling,
      ]);
    });
  });

  group('NextAction.label', () {
    test('none returns "Research Complete"', () {
      expect(NextAction.none.label, 'Research Complete');
    });

    test('createNote returns "Create Note"', () {
      expect(NextAction.createNote.label, 'Create Note');
    });

    test('createThesis returns "Create Thesis"', () {
      expect(NextAction.createThesis.label, 'Create Thesis');
    });

    test('answerQuestions returns "Answer Questions"', () {
      expect(NextAction.answerQuestions.label, 'Answer Questions');
    });

    test('createPosition returns "Create Position"', () {
      expect(NextAction.createPosition.label, 'Create Position');
    });

    test('reviewThesis returns "Review Thesis"', () {
      expect(NextAction.reviewThesis.label, 'Review Thesis');
    });

    test('reviewFiling returns "Review Filing"', () {
      expect(NextAction.reviewFiling.label, 'Review Filing');
    });

    test('all labels are non-empty', () {
      for (final action in NextAction.values) {
        expect(action.label, isNotEmpty);
      }
    });

    test('all labels are distinct', () {
      final labels = NextAction.values.map((a) => a.label).toList();
      expect(labels.toSet().length, labels.length);
    });
  });

  group('NextAction.description', () {
    test('none describes research is complete', () {
      expect(
        NextAction.none.description,
        'Your research is complete. Review periodically to stay current.',
      );
    });

    test('createNote describes documenting research', () {
      expect(
        NextAction.createNote.description,
        'Start documenting your research on this company.',
      );
    });

    test('createThesis describes formalizing stance', () {
      expect(
        NextAction.createThesis.description,
        'You have notes. Formalize your research into a stance.',
      );
    });

    test('answerQuestions describes answering open questions', () {
      expect(
        NextAction.answerQuestions.description,
        'Open questions may affect your thesis. Answer them first.',
      );
    });

    test('createPosition describes tracking decision', () {
      expect(
        NextAction.createPosition.description,
        'Your research is ready. Start tracking your decision.',
      );
    });

    test('reviewThesis describes outdated research', () {
      expect(
        NextAction.reviewThesis.description,
        'Your research may be outdated. Review and update.',
      );
    });

    test('reviewFiling describes new filings', () {
      expect(
        NextAction.reviewFiling.description,
        'New filings available. Review for thesis impact.',
      );
    });

    test('all descriptions are non-empty', () {
      for (final action in NextAction.values) {
        expect(action.description, isNotEmpty);
      }
    });

    test('all descriptions are distinct', () {
      final descriptions =
          NextAction.values.map((a) => a.description).toList();
      expect(descriptions.toSet().length, descriptions.length);
    });

    test('all descriptions end with a period', () {
      for (final action in NextAction.values) {
        expect(action.description.endsWith('.'), isTrue);
      }
    });
  });

  group('NextAction.icon', () {
    test('none returns checkmark', () {
      expect(NextAction.none.icon, '\u2713');
    });

    test('createNote returns bullet', () {
      expect(NextAction.createNote.icon, '\u25AA');
    });

    test('createThesis returns diamond', () {
      expect(NextAction.createThesis.icon, '\u25C6');
    });

    test('answerQuestions returns question mark', () {
      expect(NextAction.answerQuestions.icon, '?');
    });

    test('createPosition returns filled circle', () {
      expect(NextAction.createPosition.icon, '\u25CF');
    });

    test('reviewThesis returns refresh arrow', () {
      expect(NextAction.reviewThesis.icon, '\u21BB');
    });

    test('reviewFiling returns up arrow', () {
      expect(NextAction.reviewFiling.icon, '\u2191');
    });

    test('all icons are non-empty', () {
      for (final action in NextAction.values) {
        expect(action.icon, isNotEmpty);
      }
    });

    test('all icons are single characters', () {
      for (final action in NextAction.values) {
        expect(action.icon.length, 1);
      }
    });
  });

  group('NextAction exhaustive switch coverage', () {
    test('label covers all enum values without default', () {
      // If a new enum value is added without a corresponding label case,
      // this test ensures the switch is exhaustive by iterating all values.
      for (final action in NextAction.values) {
        expect(action.label, isA<String>());
      }
    });

    test('description covers all enum values without default', () {
      for (final action in NextAction.values) {
        expect(action.description, isA<String>());
      }
    });

    test('icon covers all enum values without default', () {
      for (final action in NextAction.values) {
        expect(action.icon, isA<String>());
      }
    });
  });
}
