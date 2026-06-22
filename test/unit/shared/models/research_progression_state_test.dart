import 'package:flutter_test/flutter_test.dart';
import 'package:taug/shared/models/research_progression_state.dart';

void main() {
  group('ResearchProgressionState', () {
    // -----------------------------------------------------------------------
    // Stage computation
    // -----------------------------------------------------------------------
    group('stage', () {
      test('returns noResearch when all counts are zero', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
        );
        expect(state.stage, ResearchStage.noResearch);
      });

      test('returns noResearch when only positions exist (no notes/theses)',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          positionsCount: 1,
        );
        // notesCount==0 && thesesCount==0 triggers noResearch first
        expect(state.stage, ResearchStage.noResearch);
      });

      test('returns notesOnly when notes exist but no theses', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 3,
        );
        expect(state.stage, ResearchStage.notesOnly);
      });

      test('returns questionsOutstanding when theses exist with open and critical questions',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 2,
          thesesCount: 1,
          openQuestionsCount: 3,
          criticalQuestionsCount: 1,
        );
        expect(state.stage, ResearchStage.questionsOutstanding);
      });

      test('returns positionReady when theses exist, no positions, questions resolved',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 5,
          thesesCount: 1,
          openQuestionsCount: 0,
        );
        expect(state.stage, ResearchStage.positionReady);
      });

      test('returns questionsOutstanding when theses exist with open questions',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          openQuestionsCount: 2,
          criticalQuestionsCount: 0,
        );
        // questionsOutstanding requires openQuestionsCount > 0
        expect(state.stage, ResearchStage.questionsOutstanding);
      });

      test('returns activePosition when positions exist but no lessons', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 5,
          thesesCount: 1,
          positionsCount: 1,
        );
        expect(state.stage, ResearchStage.activePosition);
      });

      test('returns researchComplete when lessons exist', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 5,
          thesesCount: 2,
          positionsCount: 3,
          lessonsCount: 2,
        );
        expect(state.stage, ResearchStage.researchComplete);
      });

      test('returns questionsOutstanding over researchComplete when critical questions remain',
          () {
        // The stage getter checks questionsOutstanding BEFORE positions/lessons
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          openQuestionsCount: 5,
          criticalQuestionsCount: 2,
          positionsCount: 1,
          lessonsCount: 1,
        );
        expect(state.stage, ResearchStage.questionsOutstanding);
      });

      test('returns notesOnly with minimal notes (notesCount=1)', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 1,
        );
        expect(state.stage, ResearchStage.notesOnly);
      });

      test('returns questionsOutstanding with theses and non-critical open questions only',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          openQuestionsCount: 4,
          criticalQuestionsCount: 0,
        );
        expect(state.stage, ResearchStage.questionsOutstanding);
      });

      test('returns positionReady without notes (notesCount=0)', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          openQuestionsCount: 0,
        );
        expect(state.stage, ResearchStage.positionReady);
      });

      test('returns activePosition with minimal positions (positionsCount=1)',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
        );
        expect(state.stage, ResearchStage.activePosition);
      });

      test('returns researchComplete without notes (notesCount=0)', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          lessonsCount: 1,
        );
        expect(state.stage, ResearchStage.researchComplete);
      });

      test('returns researchComplete with minimal lessons (lessonsCount=1)', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 2,
          positionsCount: 1,
          lessonsCount: 1,
        );
        expect(state.stage, ResearchStage.researchComplete);
      });

      test('stage precedence: questionsOutstanding wins over activePosition', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          openQuestionsCount: 3,
          positionsCount: 2,
        );
        expect(state.stage, ResearchStage.questionsOutstanding);
      });

      test('stage precedence: questionsOutstanding wins over researchComplete',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          openQuestionsCount: 1,
          positionsCount: 1,
          lessonsCount: 1,
        );
        expect(state.stage, ResearchStage.questionsOutstanding);
      });
    });

    // -----------------------------------------------------------------------
    // Next action computation
    // -----------------------------------------------------------------------
    group('nextAction', () {
      test('returns createNote when noResearch', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
        );
        expect(state.nextAction, NextAction.createNote);
      });

      test('returns createThesis when notesOnly', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 3,
        );
        expect(state.nextAction, NextAction.createThesis);
      });

      test('returns answerQuestions when questionsOutstanding', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          openQuestionsCount: 2,
          criticalQuestionsCount: 1,
        );
        expect(state.nextAction, NextAction.answerQuestions);
      });

      test('returns createPosition when positionReady', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
        );
        expect(state.nextAction, NextAction.createPosition);
      });

      test('returns reviewThesis when stale and activePosition', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          researchFreshness: 'stale',
        );
        expect(state.nextAction, NextAction.reviewThesis);
      });

      test('returns reviewThesis when expired and activePosition', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          researchFreshness: 'expired',
        );
        expect(state.nextAction, NextAction.reviewThesis);
      });

      test('returns none when researchComplete and not stale', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          lessonsCount: 1,
          researchFreshness: 'fresh',
        );
        expect(state.nextAction, NextAction.none);
      });

      test('returns none when activePosition and freshness is fresh', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          researchFreshness: 'fresh',
        );
        // stage is activePosition, isStale is false -> falls through to none
        expect(state.nextAction, NextAction.none);
      });

      test('returns reviewThesis when stale at researchComplete', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          lessonsCount: 1,
          researchFreshness: 'stale',
        );
        // isStale check before returning none
        expect(state.nextAction, NextAction.reviewThesis);
      });

      test('returns reviewThesis when expired at researchComplete', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          lessonsCount: 1,
          researchFreshness: 'expired',
        );
        expect(state.nextAction, NextAction.reviewThesis);
      });

      test('stage takes precedence: createNote even when noResearch is stale',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'stale',
        );
        expect(state.nextAction, NextAction.createNote);
      });

      test('stage takes precedence: createThesis even when notesOnly is stale',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 2,
          researchFreshness: 'stale',
        );
        expect(state.nextAction, NextAction.createThesis);
      });

      test(
          'stage takes precedence: answerQuestions even when questionsOutstanding is stale',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          openQuestionsCount: 3,
          researchFreshness: 'expired',
        );
        expect(state.nextAction, NextAction.answerQuestions);
      });

      test(
          'stage takes precedence: createPosition even when positionReady is stale',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          researchFreshness: 'stale',
        );
        expect(state.nextAction, NextAction.createPosition);
      });

      test('returns reviewThesis when activePosition and freshness is expired',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          researchFreshness: 'expired',
        );
        expect(state.nextAction, NextAction.reviewThesis);
      });

      test('returns none when activePosition and freshness is aging', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          researchFreshness: 'aging',
        );
        expect(state.nextAction, NextAction.none);
      });

      test('returns none when researchComplete and freshness is aging', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 1,
          positionsCount: 1,
          lessonsCount: 1,
          researchFreshness: 'aging',
        );
        expect(state.nextAction, NextAction.none);
      });
    });

    // -----------------------------------------------------------------------
    // isStale
    // -----------------------------------------------------------------------
    group('isStale', () {
      test('returns false when freshness is null', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
        );
        expect(state.isStale, isFalse);
      });

      test('returns false when freshness is fresh', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'fresh',
        );
        expect(state.isStale, isFalse);
      });

      test('returns false when freshness is aging', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'aging',
        );
        expect(state.isStale, isFalse);
      });

      test('returns true when freshness is stale', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'stale',
        );
        expect(state.isStale, isTrue);
      });

      test('returns true when freshness is expired', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'expired',
        );
        expect(state.isStale, isTrue);
      });

      test('returns false when freshness is unknown string', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'unknown',
        );
        expect(state.isStale, isFalse);
      });

      test('returns false when freshness is empty string', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: '',
        );
        expect(state.isStale, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // needsReview
    // -----------------------------------------------------------------------
    group('needsReview', () {
      test('returns false when not stale and no critical questions', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'fresh',
          criticalQuestionsCount: 0,
        );
        expect(state.needsReview, isFalse);
      });

      test('returns true when stale', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'stale',
          criticalQuestionsCount: 0,
        );
        expect(state.needsReview, isTrue);
      });

      test('returns true when critical questions exist', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'fresh',
          criticalQuestionsCount: 2,
        );
        expect(state.needsReview, isTrue);
      });

      test('returns true when both stale and critical questions exist', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          researchFreshness: 'expired',
          criticalQuestionsCount: 5,
        );
        expect(state.needsReview, isTrue);
      });

      test('returns false when freshness is null and no critical questions',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          criticalQuestionsCount: 0,
        );
        expect(state.needsReview, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // completedCount
    // -----------------------------------------------------------------------
    group('completedCount', () {
      test('returns 0 when all counts are zero', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
        );
        expect(state.completedCount, 0);
      });

      test('counts notes + resolved questions as 2 checklist items', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 3,
        );
        // notes>0 -> +1, openQuestions==0 && notes>0 -> +1
        expect(state.completedCount, 2);
      });

      test('counts notes + thesis as 2 items', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 3,
          thesesCount: 1,
        );
        // notes>0 -> +1, theses>0 -> +1, openQuestions==0 && (notes>0) -> +1
        expect(state.completedCount, 3);
      });

      test('counts notes + thesis + resolved questions + position as 4', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 5,
          thesesCount: 1,
          openQuestionsCount: 0,
          positionsCount: 1,
        );
        expect(state.completedCount, 4);
      });

      test('does not count questions resolved when no notes or theses', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          openQuestionsCount: 0,
        );
        // openQuestions==0 but notesCount==0 && thesesCount==0 -> no credit
        expect(state.completedCount, 0);
      });

      test('does not count questions resolved when open questions remain', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 3,
          thesesCount: 1,
          openQuestionsCount: 2,
        );
        // openQuestions>0 -> no question credit
        expect(state.completedCount, 2);
      });

      test('counts theses + resolved questions when no notes (2 items)', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          thesesCount: 2,
          openQuestionsCount: 0,
        );
        // notes=0 → skip, theses>0 → +1, openQ==0 && theses>0 → +1
        expect(state.completedCount, 2);
      });

      test('counts only position when only positionsCount > 0 (1 item)', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          positionsCount: 1,
        );
        // notes=0 → skip, theses=0 → skip, openQ==0 but no notes/theses → skip
        // positions>0 → +1
        expect(state.completedCount, 1);
      });

      test('returns 3 when all populated but open questions remain', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 5,
          thesesCount: 2,
          openQuestionsCount: 3,
          positionsCount: 1,
        );
        // notes>0 → +1, theses>0 → +1, openQ>0 → skip, positions>0 → +1
        expect(state.completedCount, 3);
      });

      test('returns 4 when all checklist items are complete', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 5,
          thesesCount: 2,
          openQuestionsCount: 0,
          positionsCount: 1,
        );
        expect(state.completedCount, 4);
      });

      test('returns max 4 even with all fields including lessons', () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          notesCount: 5,
          thesesCount: 2,
          openQuestionsCount: 0,
          positionsCount: 1,
          lessonsCount: 3,
        );
        // lessons not counted in completedCount
        expect(state.completedCount, 4);
      });

      test('returns 0 when only openQuestionsCount and criticalQuestionsCount populated',
          () {
        const state = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Test Corp',
          openQuestionsCount: 3,
          criticalQuestionsCount: 2,
        );
        expect(state.completedCount, 0);
      });
    });

    // -----------------------------------------------------------------------
    // Equatable
    // -----------------------------------------------------------------------
    group('equality', () {
      test('two instances with same values are equal', () {
        const a = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Corp',
          notesCount: 3,
          thesesCount: 1,
        );
        const b = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Corp',
          notesCount: 3,
          thesesCount: 1,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different companyId produces inequality', () {
        const a = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Corp',
        );
        const b = ResearchProgressionState(
          companyId: 'c2',
          companyName: 'Corp',
        );
        expect(a, isNot(equals(b)));
      });

      test('different notesCount produces inequality', () {
        const a = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Corp',
          notesCount: 1,
        );
        const b = ResearchProgressionState(
          companyId: 'c1',
          companyName: 'Corp',
          notesCount: 5,
        );
        expect(a, isNot(equals(b)));
      });
    });

    // -----------------------------------------------------------------------
    // NextActionExtension
    // -----------------------------------------------------------------------
    group('NextActionExtension', () {
      test('label returns human-readable string for each action', () {
        expect(NextAction.none.label, 'Research Complete');
        expect(NextAction.createNote.label, 'Create Note');
        expect(NextAction.createThesis.label, 'Create Thesis');
        expect(NextAction.answerQuestions.label, 'Answer Questions');
        expect(NextAction.createPosition.label, 'Create Position');
        expect(NextAction.reviewThesis.label, 'Review Thesis');
        expect(NextAction.reviewFiling.label, 'Review Filing');
      });

      test('description returns non-empty string for each action', () {
        for (final action in NextAction.values) {
          expect(action.description, isNotEmpty);
        }
      });

      test('icon returns non-empty string for each action', () {
        for (final action in NextAction.values) {
          expect(action.icon, isNotEmpty);
        }
      });

      test('all 7 enum values are present', () {
        expect(NextAction.values.length, 7);
      });

      test('description for each action is distinct', () {
        final descriptions =
            NextAction.values.map((a) => a.description).toSet();
        expect(descriptions.length, NextAction.values.length);
      });

      test('label for each action is distinct', () {
        final labels = NextAction.values.map((a) => a.label).toSet();
        expect(labels.length, NextAction.values.length);
      });

      test('icon for none is checkmark', () {
        expect(NextAction.none.icon, '\u2713');
      });

      test('icon for createNote is bullet', () {
        expect(NextAction.createNote.icon, '\u25AA');
      });

      test('icon for createThesis is diamond', () {
        expect(NextAction.createThesis.icon, '\u25C6');
      });

      test('icon for answerQuestions is question mark', () {
        expect(NextAction.answerQuestions.icon, '?');
      });

      test('icon for createPosition is filled circle', () {
        expect(NextAction.createPosition.icon, '\u25CF');
      });

      test('icon for reviewThesis is refresh arrow', () {
        expect(NextAction.reviewThesis.icon, '\u21BB');
      });

      test('icon for reviewFiling is up arrow', () {
        expect(NextAction.reviewFiling.icon, '\u2191');
      });
    });
  });
}
