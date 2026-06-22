import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import 'research_models.dart';

class ResearchRepository {
  final SupabaseClient _client;

  ResearchRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<List<ResearchCompany>>> getResearchCompanies() async {
    try {
      final companiesResponse = await _client
          .from(AppSchema.companies)
          .select('id, display_name')
          .eq('ingestion_enabled', true)
          .order('display_name');

      final securitiesResponse = await _client
          .from('securities')
          .select('company_id, ticker')
          .eq('is_primary_listing', true);

      final securitiesMap = <String, String>{};
      for (final s in securitiesResponse as List) {
        final cid = s['company_id'] as String?;
        final ticker = s['ticker'] as String?;
        if (cid != null && ticker != null) securitiesMap[cid] = ticker;
      }

      // Get notes count per company
      final notesResponse = await _client
          .from(AppSchema.researchNotes)
          .select('company_id');

      final notesCount = <String, int>{};
      for (final n in notesResponse as List) {
        final cid = n['company_id'] as String?;
        if (cid != null) notesCount[cid] = (notesCount[cid] ?? 0) + 1;
      }

      // Get theses count per company
      final thesesResponse = await _client
          .from(AppSchema.investmentTheses)
          .select('company_id');

      final thesesCount = <String, int>{};
      for (final t in thesesResponse as List) {
        final cid = t['company_id'] as String?;
        if (cid != null) thesesCount[cid] = (thesesCount[cid] ?? 0) + 1;
      }

      final companies = (companiesResponse as List).map((c) {
        final id = c['id'] as String;
        final notes = notesCount[id] ?? 0;
        final theses = thesesCount[id] ?? 0;
        String status = 'not_researched';
        if (theses > 0 || notes > 0) status = 'researching';

        return ResearchCompany(
          companyId: id,
          displayName: c['display_name'] as String? ?? '',
          ticker: securitiesMap[id],
          notesCount: notes,
          thesesCount: theses,
          researchStatus: status,
        );
      }).toList();

      return Result.success(companies);
    } catch (e) {
      debugPrint('[ResearchRepo] getResearchCompanies: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<ResearchThesisIndex>>> getAllTheses() async {
    try {
      final response = await _client
          .from(AppSchema.investmentTheses)
          .select('id, company_id, title, stance, conviction, updated_at');

      final companiesResponse = await _client
          .from(AppSchema.companies)
          .select('id, display_name');

      final securitiesResponse = await _client
          .from('securities')
          .select('company_id, ticker')
          .eq('is_primary_listing', true);

      final companyMap = <String, String>{};
      for (final c in companiesResponse as List) {
        companyMap[c['id'] as String] = c['display_name'] as String? ?? '';
      }

      final tickerMap = <String, String>{};
      for (final s in securitiesResponse as List) {
        final cid = s['company_id'] as String?;
        final ticker = s['ticker'] as String?;
        if (cid != null && ticker != null) tickerMap[cid] = ticker;
      }

      final theses = (response as List).map((t) {
        final cid = t['company_id'] as String;
        return ResearchThesisIndex(
          thesisId: t['id'] as String,
          companyId: cid,
          companyName: companyMap[cid] ?? '',
          ticker: tickerMap[cid],
          title: t['title'] as String? ?? '',
          stance: t['stance'] as String? ?? 'neutral',
          conviction: t['conviction'] as String? ?? 'low',
          updatedAt: DateTime.parse(t['updated_at'] as String),
        );
      }).toList();

      theses.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Result.success(theses);
    } catch (e) {
      debugPrint('[ResearchRepo] getAllTheses: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<ResearchNoteIndex>>> getAllNotes() async {
    try {
      final response = await _client
          .from(AppSchema.researchNotes)
          .select('id, company_id, title, body, updated_at');

      final companiesResponse = await _client
          .from(AppSchema.companies)
          .select('id, display_name');

      final securitiesResponse = await _client
          .from('securities')
          .select('company_id, ticker')
          .eq('is_primary_listing', true);

      final companyMap = <String, String>{};
      for (final c in companiesResponse as List) {
        companyMap[c['id'] as String] = c['display_name'] as String? ?? '';
      }

      final tickerMap = <String, String>{};
      for (final s in securitiesResponse as List) {
        final cid = s['company_id'] as String?;
        final ticker = s['ticker'] as String?;
        if (cid != null && ticker != null) tickerMap[cid] = ticker;
      }

      final notes = (response as List).map((n) {
        final cid = n['company_id'] as String;
        return ResearchNoteIndex(
          noteId: n['id'] as String,
          companyId: cid,
          companyName: companyMap[cid] ?? '',
          ticker: tickerMap[cid],
          title: n['title'] as String? ?? '',
          body: n['body'] as String? ?? '',
          updatedAt: DateTime.parse(n['updated_at'] as String),
        );
      }).toList();

      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Result.success(notes);
    } catch (e) {
      debugPrint('[ResearchRepo] getAllNotes: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<ResearchQuestionIndex>>> getOpenQuestions() async {
    try {
      final response = await _client
          .from(AppSchema.researchQuestions)
          .select('id, company_id, thesis_id, question, priority, status, created_at, updated_at')
          .eq('status', 'open')
          .order('updated_at', ascending: false);

      final companiesResponse = await _client
          .from(AppSchema.companies)
          .select('id, display_name');

      final securitiesResponse = await _client
          .from('securities')
          .select('company_id, ticker')
          .eq('is_primary_listing', true);

      final thesesResponse = await _client
          .from(AppSchema.investmentTheses)
          .select('id, title');

      final companyMap = <String, String>{};
      for (final c in companiesResponse as List) {
        companyMap[c['id'] as String] = c['display_name'] as String? ?? '';
      }

      final tickerMap = <String, String>{};
      for (final s in securitiesResponse as List) {
        final cid = s['company_id'] as String?;
        final ticker = s['ticker'] as String?;
        if (cid != null && ticker != null) tickerMap[cid] = ticker;
      }

      final thesisMap = <String, String>{};
      for (final t in thesesResponse as List) {
        thesisMap[t['id'] as String] = t['title'] as String? ?? '';
      }

      final questions = (response as List).map((q) {
        final cid = q['company_id'] as String?;
        return ResearchQuestionIndex(
          questionId: q['id'] as String,
          companyId: cid,
          companyName: cid != null ? companyMap[cid] : null,
          ticker: cid != null ? tickerMap[cid] : null,
          thesisId: q['thesis_id'] as String?,
          thesisTitle: q['thesis_id'] != null ? thesisMap[q['thesis_id'] as String] : null,
          question: q['question'] as String? ?? '',
          priority: q['priority'] as String? ?? 'medium',
          status: q['status'] as String? ?? 'open',
          createdAt: DateTime.parse(q['created_at'] as String),
          updatedAt: DateTime.parse(q['updated_at'] as String),
        );
      }).toList();

      return Result.success(questions);
    } catch (e) {
      debugPrint('[ResearchRepo] getOpenQuestions: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<ResearchQuestion>> createQuestion({
    String? companyId,
    String? thesisId,
    required String question,
    String priority = 'medium',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[ResearchRepo] createQuestion: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final insertData = <String, dynamic>{
        'user_id': userId,
        'question': question,
        'priority': priority,
      };
      if (companyId != null) insertData['company_id'] = companyId;
      if (thesisId != null) insertData['thesis_id'] = thesisId;

      final response = await _client
          .from(AppSchema.researchQuestions)
          .insert(insertData)
          .select()
          .single();

      return Result.success(ResearchQuestion(
        id: response['id'] as String,
        companyId: response['company_id'] as String?,
        thesisId: response['thesis_id'] as String?,
        question: response['question'] as String? ?? '',
        priority: response['priority'] as String? ?? 'medium',
        status: response['status'] as String? ?? 'open',
        answer: response['answer'] as String?,
        answeredAt: response['answered_at'] != null
            ? DateTime.parse(response['answered_at'] as String)
            : null,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      ));
    } catch (e) {
      debugPrint('[ResearchRepo] createQuestion: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> updateQuestion({
    required String questionId,
    String? question,
    String? priority,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[ResearchRepo] updateQuestion: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final update = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (question != null) update['question'] = question;
      if (priority != null) update['priority'] = priority;

      await _client
          .from(AppSchema.researchQuestions)
          .update(update)
          .eq('id', questionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[ResearchRepo] updateQuestion: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> answerQuestion({
    required String questionId,
    required String answer,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[ResearchRepo] answerQuestion: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final now = DateTime.now().toIso8601String();
      await _client
          .from(AppSchema.researchQuestions)
          .update({
            'answer': answer,
            'status': 'answered',
            'answered_at': now,
            'updated_at': now,
          })
          .eq('id', questionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[ResearchRepo] answerQuestion: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> deleteQuestion(String questionId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[ResearchRepo] deleteQuestion: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from(AppSchema.researchQuestions)
          .delete()
          .eq('id', questionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[ResearchRepo] deleteQuestion: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
}
