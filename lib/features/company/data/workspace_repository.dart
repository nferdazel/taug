import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import 'workspace_models.dart';

class WorkspaceRepository {
  final SupabaseClient _client;

  WorkspaceRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Result<CompanyProfile>> getCompanyProfile(String companyId) async {
    try {
      final response = await _client
          .from(AppSchema.companies)
          .select('id, display_name, domicile_country_code')
          .eq('id', companyId)
          .single();

      final secResponse = await _client
          .from('securities')
          .select('ticker')
          .eq('company_id', companyId)
          .limit(1);

      String? ticker;
      if (secResponse.isNotEmpty) {
        ticker = secResponse[0]['ticker'] as String?;
      }

      return Result.success(
        CompanyProfile(
          id: response['id'] as String,
          displayName: response['display_name'] as String? ?? '',
          ticker: ticker,
          domicileCountryCode: response['domicile_country_code'] as String?,
        ),
      );
    } catch (e) {
      debugPrint('[WorkspaceRepo] getCompanyProfile: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<MetricSnapshot>>> getMetrics(String companyId) async {
    try {
      final response = await _client
          .from(AppSchema.companyMetricSnapshot)
          .select(
            'metric_code, metric_name, metric_category, value_numeric, computation_status, unit_type, display_precision',
          )
          .eq('company_id', companyId);

      final metrics = (response as List)
          .map(
            (m) => MetricSnapshot(
              metricCode: m['metric_code'] as String? ?? '',
              metricName: m['metric_name'] as String? ?? '',
              metricCategory: m['metric_category'] as String? ?? '',
              valueNumeric: (m['value_numeric'] as num?)?.toDouble(),
              computationStatus:
                  m['computation_status'] as String? ?? 'unknown',
              unitType: m['unit_type'] as String?,
              displayPrecision: m['display_precision'] as int? ?? 2,
            ),
          )
          .toList();

      return Result.success(metrics);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getMetrics: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<StatementRow>>> getFinancialStatements(
    String companyId,
  ) async {
    try {
      final response = await _client
          .from(AppSchema.companyStatementHistory)
          .select('*')
          .eq('company_id', companyId)
          .order('period_end', ascending: false)
          .limit(50);

      final rows = (response as List).map((r) {
        final items = <String, double?>{};
        for (final key in [
          'revenue',
          'gross_profit',
          'operating_income',
          'net_income',
          'total_assets',
          'total_liabilities',
          'stockholders_equity',
          'cash_and_equivalents',
          'operating_cash_flow',
          'capex',
          'long_term_debt',
          'current_assets',
          'current_liabilities',
        ]) {
          items[key] = (r[key] as num?)?.toDouble();
        }

        return StatementRow(
          statementType: r['statement_type'] as String? ?? '',
          periodEnd: r['period_end'] as String? ?? '',
          statementVersion: r['statement_version'] as int?,
          isRestated: r['is_restated'] as bool? ?? false,
          items: items,
        );
      }).toList();

      return Result.success(rows);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getFinancialStatements: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<CompanyNote>>> getNotes(String companyId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] getNotes: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.researchNotes)
          .select('id, company_id, title, body, created_at, updated_at')
          .eq('company_id', companyId)
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final notes = (response as List)
          .map(
            (n) => CompanyNote(
              id: n['id'] as String,
              companyId: n['company_id'] as String,
              title: n['title'] as String? ?? '',
              body: n['body'] as String? ?? '',
              createdAt: DateTime.parse(n['created_at'] as String),
              updatedAt: DateTime.parse(n['updated_at'] as String),
            ),
          )
          .toList();

      return Result.success(notes);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getNotes: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<CompanyNote>> createNote({
    required String companyId,
    required String title,
    required String body,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] createNote: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.researchNotes)
          .insert({'user_id': userId, 'company_id': companyId, 'title': title, 'body': body})
          .select()
          .single();

      return Result.success(
        CompanyNote(
          id: response['id'] as String,
          companyId: response['company_id'] as String,
          title: response['title'] as String? ?? '',
          body: response['body'] as String? ?? '',
          createdAt: DateTime.parse(response['created_at'] as String),
          updatedAt: DateTime.parse(response['updated_at'] as String),
        ),
      );
    } catch (e) {
      debugPrint('[WorkspaceRepo] createNote: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> updateNote({
    required String noteId,
    required String title,
    required String body,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] updateNote: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from(AppSchema.researchNotes)
          .update({
            'title': title,
            'body': body,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', noteId)
          .eq('user_id', userId);
      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] updateNote: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> deleteNote(String noteId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] deleteNote: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from(AppSchema.researchNotes)
          .delete()
          .eq('id', noteId)
          .eq('user_id', userId);
      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] deleteNote: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<CompanyThesis>>> getTheses(String companyId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] getTheses: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.investmentTheses)
          .select('*')
          .eq('company_id', companyId)
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final theses = (response as List)
          .map(
            (t) => CompanyThesis(
              id: t['id'] as String,
              companyId: t['company_id'] as String,
              title: t['title'] as String? ?? '',
              stance: t['stance'] as String? ?? 'neutral',
              summary: t['summary'] as String?,
              bullCase: t['bull_case'] as String?,
              bearCase: t['bear_case'] as String?,
              conviction: t['conviction'] as String? ?? 'low',
              createdAt: DateTime.parse(t['created_at'] as String),
              updatedAt: DateTime.parse(t['updated_at'] as String),
            ),
          )
          .toList();

      return Result.success(theses);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getTheses: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<CompanyThesis>> createThesis({
    required String companyId,
    required String title,
    required String stance,
    String? summary,
    String? bullCase,
    String? bearCase,
    String? assumptions,
    String? catalysts,
    String? risks,
    String? exitConditions,
    String conviction = 'low',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] createThesis: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.investmentTheses)
          .insert({
            'user_id': userId,
            'company_id': companyId,
            'title': title,
            'stance': stance,
            'summary': summary,
            'bull_case': bullCase,
            'bear_case': bearCase,
            'assumptions': assumptions,
            'catalysts': catalysts,
            'risks': risks,
            'exit_conditions': exitConditions,
            'conviction': conviction,
          })
          .select()
          .single();

      return Result.success(
        CompanyThesis(
          id: response['id'] as String,
          companyId: response['company_id'] as String,
          title: response['title'] as String? ?? '',
          stance: response['stance'] as String? ?? 'neutral',
          summary: response['summary'] as String?,
          bullCase: response['bull_case'] as String?,
          bearCase: response['bear_case'] as String?,
          assumptions: response['assumptions'] as String?,
          catalysts: response['catalysts'] as String?,
          risks: response['risks'] as String?,
          exitConditions: response['exit_conditions'] as String?,
          conviction: response['conviction'] as String? ?? 'low',
          createdAt: DateTime.parse(response['created_at'] as String),
          updatedAt: DateTime.parse(response['updated_at'] as String),
        ),
      );
    } catch (e) {
      debugPrint('[WorkspaceRepo] createThesis: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> updateThesis({
    required String thesisId,
    required String title,
    required String stance,
    String? summary,
    String? bullCase,
    String? bearCase,
    String? assumptions,
    String? catalysts,
    String? risks,
    String? exitConditions,
    String? conviction,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] updateThesis: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final update = <String, dynamic>{
        'title': title,
        'stance': stance,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (summary != null) update['summary'] = summary;
      if (bullCase != null) update['bull_case'] = bullCase;
      if (bearCase != null) update['bear_case'] = bearCase;
      if (assumptions != null) update['assumptions'] = assumptions;
      if (catalysts != null) update['catalysts'] = catalysts;
      if (risks != null) update['risks'] = risks;
      if (exitConditions != null) update['exit_conditions'] = exitConditions;
      if (conviction != null) update['conviction'] = conviction;

      await _client
          .from(AppSchema.investmentTheses)
          .update(update)
          .eq('id', thesisId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] updateThesis: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> deleteThesis(String thesisId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] deleteThesis: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from(AppSchema.investmentTheses)
          .delete()
          .eq('id', thesisId)
          .eq('user_id', userId);
      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] deleteThesis: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<QualityScoreDetail?>> getQualityScore(String companyId) async {
    try {
      final response = await _client
          .from('data_quality_scores')
          .select('overall_score, historical_coverage_score, completeness_score, validation_score, verification_score, freshness_score, restatement_support_score, component_details, score_date')
          .eq('company_id', companyId)
          .order('score_date', ascending: false)
          .limit(1);

      if (response.isEmpty) return const Result.success(null);
      
      final row = response[0];
      return Result.success(
        QualityScoreDetail(
          overallScore: (row['overall_score'] as num?)?.toDouble() ?? 0,
          historicalCoverageScore: (row['historical_coverage_score'] as num?)?.toDouble(),
          completenessScore: (row['completeness_score'] as num?)?.toDouble(),
          validationScore: (row['validation_score'] as num?)?.toDouble(),
          verificationScore: (row['verification_score'] as num?)?.toDouble(),
          freshnessScore: (row['freshness_score'] as num?)?.toDouble(),
          restatementSupportScore: (row['restatement_support_score'] as num?)?.toDouble(),
          componentDetails: row['component_details'] as Map<String, dynamic>?,
          scoreDate: row['score_date'] != null ? DateTime.parse(row['score_date'] as String) : null,
        ),
      );
    } catch (e) {
      debugPrint('[WorkspaceRepo] getQualityScore: $e');
      return const Result.success(null);
    }
  }

  Future<Result<String?>> getFreshnessStatus(String companyId) async {
    try {
      final response = await _client
          .from('company_freshness_v')
          .select('statement_freshness')
          .eq('company_id', companyId)
          .limit(1);

      if (response.isEmpty) return const Result.success(null);
      return Result.success(response[0]['statement_freshness'] as String?);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getFreshnessStatus: $e');
      return const Result.success(null);
    }
  }
}
