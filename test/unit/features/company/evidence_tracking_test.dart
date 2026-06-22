import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taug/features/company/data/workspace_repository.dart';

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
  late WorkspaceRepository repository;

  const testUserId = 'user-evidence-001';

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

  group('Evidence Tracking', () {
    // -----------------------------------------------------------------------
    // linkNoteToThesis
    // -----------------------------------------------------------------------
    group('linkNoteToThesis', () {
      test('creates a link with default supports relationship', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(buildLinkJson());

        final result = await repository.linkNoteToThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.noteId, 'note-1');
        expect(result.data!.thesisId, 'thesis-1');
        expect(result.data!.relationship, 'supports');
      });

      test('creates a link with contradicts relationship', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(buildLinkJson(relationship: 'contradicts'));

        final result = await repository.linkNoteToThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
          relationship: 'contradicts',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.relationship, 'contradicts');
      });

      test('creates a link with updates relationship', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(buildLinkJson(relationship: 'updates'));

        final result = await repository.linkNoteToThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
          relationship: 'updates',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.relationship, 'updates');
      });

      test('creates a link with context relationship', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(buildLinkJson(relationship: 'context'));

        final result = await repository.linkNoteToThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
          relationship: 'context',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.relationship, 'context');
      });

      test('creates a link with thesisField targeting specific section', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.select(any()))
            .thenAnswer((_) => mockListTransform);
        when(() => mockListTransform.single())
            .thenAnswer((_) => mockSingleTransform);
        mockSingleTransform.stubFuture(
            buildLinkJson(thesisField: 'bull_case'));

        final result = await repository.linkNoteToThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
          thesisField: 'bull_case',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.thesisField, 'bull_case');

        final captured =
            verify(() => mockQueryBuilder.insert(captureAny())).captured;
        final insertData = captured.first as Map<String, dynamic>;
        expect(insertData['thesis_field'], 'bull_case');
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await repository.linkNoteToThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
        );

        expect(result.isFailure, isTrue);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any())).thenThrow(Exception('constraint'));

        final result = await repository.linkNoteToThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
        );

        expect(result.isFailure, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // unlinkNoteFromThesis
    // -----------------------------------------------------------------------
    group('unlinkNoteFromThesis', () {
      test('deletes link by note_id and thesis_id', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        final result = await repository.unlinkNoteFromThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
        );

        expect(result.isSuccess, isTrue);
        verify(() => mockSelectFilter.eq('note_id', 'note-1')).called(1);
        verify(() => mockSelectFilter.eq('thesis_id', 'thesis-1')).called(1);
      });

      test('applies thesisField filter when provided', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        final result = await repository.unlinkNoteFromThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
          thesisField: 'bear_case',
        );

        expect(result.isSuccess, isTrue);
        verify(() => mockSelectFilter.eq('thesis_field', 'bear_case'))
            .called(1);
      });

      test('does not apply thesisField filter when null', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        mockSelectFilter.stubFuture(null);

        await repository.unlinkNoteFromThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
        );

        // Only 2 eq calls (note_id, thesis_id), not 3
        verify(() => mockSelectFilter.eq('note_id', 'note-1')).called(1);
        verify(() => mockSelectFilter.eq('thesis_id', 'thesis-1')).called(1);
        verifyNever(() => mockSelectFilter.eq('thesis_field', any()));
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await repository.unlinkNoteFromThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
        );

        expect(result.isFailure, isTrue);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any()))
            .thenThrow(Exception('permission denied'));

        final result = await repository.unlinkNoteFromThesis(
          noteId: 'note-1',
          thesisId: 'thesis-1',
        );

        expect(result.isFailure, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // getLinkedNotes
    // -----------------------------------------------------------------------
    group('getLinkedNotes', () {
      test('returns all links for a given thesis', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.order(any(),
                ascending: any(named: 'ascending')))
            .thenAnswer((_) => mockListTransform);
        mockListTransform.stubFuture([
          buildLinkJson(
              id: 'link-1',
              noteId: 'note-1',
              thesisId: 'thesis-1',
              relationship: 'supports'),
          buildLinkJson(
              id: 'link-2',
              noteId: 'note-2',
              thesisId: 'thesis-1',
              relationship: 'contradicts'),
          buildLinkJson(
              id: 'link-3',
              noteId: 'note-3',
              thesisId: 'thesis-1',
              relationship: 'context',
              thesisField: 'risks'),
        ]);

        final result = await repository.getLinkedNotes('thesis-1');

        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(3));
        expect(result.data![0].relationship, 'supports');
        expect(result.data![1].relationship, 'contradicts');
        expect(result.data![2].relationship, 'context');
        expect(result.data![2].thesisField, 'risks');
      });

      test('returns empty list when no links exist', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.order(any(),
                ascending: any(named: 'ascending')))
            .thenAnswer((_) => mockListTransform);
        mockListTransform.stubFuture([]);

        final result = await repository.getLinkedNotes('thesis-empty');

        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('filters by thesis_id', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.order(any(),
                ascending: any(named: 'ascending')))
            .thenAnswer((_) => mockListTransform);
        mockListTransform.stubFuture([]);

        await repository.getLinkedNotes('thesis-42');

        verify(() => mockSelectFilter.eq('thesis_id', 'thesis-42')).called(1);
      });

      test('orders by created_at descending', () async {
        when(() => mockClient.from('note_thesis_links'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.eq(any(), any()))
            .thenAnswer((_) => mockSelectFilter);
        when(() => mockSelectFilter.order(any(),
                ascending: any(named: 'ascending')))
            .thenAnswer((_) => mockListTransform);
        mockListTransform.stubFuture([]);

        await repository.getLinkedNotes('thesis-1');

        verify(() => mockSelectFilter.order('created_at', ascending: false))
            .called(1);
      });

      test('returns failure when not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await repository.getLinkedNotes('thesis-1');

        expect(result.isFailure, isTrue);
      });

      test('returns failure on exception', () async {
        when(() => mockClient.from(any())).thenThrow(Exception('timeout'));

        final result = await repository.getLinkedNotes('thesis-1');

        expect(result.isFailure, isTrue);
      });
    });
  });
}
