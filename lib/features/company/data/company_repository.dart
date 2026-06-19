import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';
import 'company_models.dart';

class CompanyRepository {
  final SupabaseClient _client;

  CompanyRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<CompanyResearchSummary>> getCompanySummary({
    required String companyId,
  }) async {
    try {
      final response = await _client
          .from(AppSchema.companyResearchSummary)
          .select()
          .eq('company_id', companyId)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return const Result.failure(
          ServerFailure(message: 'Company not found'),
        );
      }
      return Result.success(CompanyResearchSummary.fromMap(response));
    } catch (e) {
      debugPrint('[CompanyRepo] getCompanySummary: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<List<CompanyStatementRow>>> getStatementHistory({
    required String companyId,
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from(AppSchema.companyStatementHistory)
          .select()
          .eq('company_id', companyId)
          .order('period_end', ascending: false)
          .limit(limit);

      final rows = (response as List<dynamic>)
          .map((row) => CompanyStatementRow.fromMap(
              Map<String, dynamic>.from(row as Map)))
          .toList();
      return Result.success(rows);
    } catch (e) {
      debugPrint('[CompanyRepo] getStatementHistory: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<List<CompanyMetricSnapshot>>> getMetricSnapshots({
    required String companyId,
  }) async {
    try {
      final response = await _client
          .from(AppSchema.companyMetricSnapshot)
          .select()
          .eq('company_id', companyId)
          .order('metric_code');

      final rows = (response as List<dynamic>)
          .map((row) => CompanyMetricSnapshot.fromMap(
              Map<String, dynamic>.from(row as Map)))
          .toList();
      return Result.success(rows);
    } catch (e) {
      debugPrint('[CompanyRepo] getMetricSnapshots: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<CompanyDataQuality>> getDataQuality({
    required String companyId,
  }) async {
    try {
      final response = await _client
          .from(AppSchema.companyDataQuality)
          .select()
          .eq('company_id', companyId)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return const Result.failure(
          ServerFailure(message: 'Quality data not found'),
        );
      }
      return Result.success(CompanyDataQuality.fromMap(response));
    } catch (e) {
      debugPrint('[CompanyRepo] getDataQuality: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<List<StatementItem>>> getStatementItems({
    required String companyId,
    String? statementType,
    String? periodEnd,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from(AppSchema.companyStatementItems)
          .select()
          .eq('company_id', companyId);

      if (statementType != null) {
        query = query.eq('statement_type', statementType);
      }
      if (periodEnd != null) {
        query = query.eq('period_end', periodEnd);
      }

      final response = await query
          .order('taxonomy_code')
          .limit(limit);

      final rows = (response as List<dynamic>)
          .map((row) => StatementItem.fromMap(
              Map<String, dynamic>.from(row as Map)))
          .toList();
      return Result.success(rows);
    } catch (e) {
      debugPrint('[CompanyRepo] getStatementItems: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<CompanyFullProfile>> getFullProfile({
    required String companyId,
  }) async {
    final List<Result<dynamic>> results = await Future.wait([
      getCompanySummary(companyId: companyId).then(
        (r) => r.map<Object>((d) => d),
      ),
      getStatementHistory(companyId: companyId).then(
        (r) => r.map<Object>((d) => d),
      ),
      getMetricSnapshots(companyId: companyId).then(
        (r) => r.map<Object>((d) => d),
      ),
      getDataQuality(companyId: companyId).then(
        (r) => r.map<Object>((d) => d),
      ),
    ]);

    final failures = results.where((r) => r.isFailure).toList();
    if (failures.isNotEmpty) {
      return Result.failure(failures.first.error);
    }

    return Result.success(CompanyFullProfile(
      summary: results[0].data! as CompanyResearchSummary,
      statements: results[1].data! as List<CompanyStatementRow>,
      metrics: results[2].data! as List<CompanyMetricSnapshot>,
      quality: results[3].data! as CompanyDataQuality,
    ));
  }
}

class CompanyFullProfile {
  final CompanyResearchSummary summary;
  final List<CompanyStatementRow> statements;
  final List<CompanyMetricSnapshot> metrics;
  final CompanyDataQuality quality;

  const CompanyFullProfile({
    required this.summary,
    required this.statements,
    required this.metrics,
    required this.quality,
  });
}
