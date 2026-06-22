import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import 'company_list_models.dart';

class CompanyListRepository {
  final SupabaseClient _client;

  CompanyListRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Result<CompanyListData>> getCompanies() async {
    try {
      // Fetch companies
      final companiesResponse = await _client
          .from(AppSchema.companies)
          .select('id, display_name')
          .eq('ingestion_enabled', true)
          .order('display_name');

      final companiesList = companiesResponse as List;

      // Fetch securities for tickers
      final securitiesResponse = await _client
          .from('securities')
          .select('company_id, ticker')
          .eq('is_primary_listing', true);

      final securitiesMap = <String, String>{};
      for (final s in securitiesResponse as List) {
        final cid = s['company_id'] as String?;
        final ticker = s['ticker'] as String?;
        if (cid != null && ticker != null) {
          securitiesMap[cid] = ticker;
        }
      }

      // Build company list
      final companies = companiesList.map((c) {
        final id = c['id'] as String;
        return CompanyListItem(
          id: id,
          displayName: c['display_name'] as String? ?? '',
          ticker: securitiesMap[id],
        );
      }).toList();

      return Result.success(
        CompanyListData(companies: companies, totalCompanies: companies.length),
      );
    } catch (e) {
      debugPrint('[CompanyListRepo] getCompanies: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<Map<String, double>>> getQualityScores() async {
    try {
      final response = await _client
          .from('data_quality_scores')
          .select('company_id, overall_score');

      final scores = <String, double>{};
      for (final row in response as List) {
        final cid = row['company_id'] as String?;
        final score = row['overall_score'];
        if (cid != null && score != null) {
          scores[cid] = (score as num).toDouble();
        }
      }
      return Result.success(scores);
    } catch (e) {
      debugPrint('[CompanyListRepo] getQualityScores: $e');
      return const Result.success({});
    }
  }

  Future<Result<Map<String, String>>> getFreshnessStatuses() async {
    try {
      final response = await _client
          .from('company_freshness_v')
          .select('company_id, statement_freshness');

      final statuses = <String, String>{};
      for (final row in response as List) {
        final cid = row['company_id'] as String?;
        final freshness = row['statement_freshness'] as String?;
        if (cid != null && freshness != null) {
          statuses[cid] = freshness;
        }
      }
      return Result.success(statuses);
    } catch (e) {
      debugPrint('[CompanyListRepo] getFreshnessStatuses: $e');
      return const Result.success({});
    }
  }
}
