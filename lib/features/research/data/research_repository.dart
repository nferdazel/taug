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
}
