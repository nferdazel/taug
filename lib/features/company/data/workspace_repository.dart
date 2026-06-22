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
          .select('id, company_id, title, stance, summary, bull_case, bear_case, assumptions, catalysts, risks, exit_conditions, conviction, created_at, updated_at, last_reviewed_at')
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
              assumptions: t['assumptions'] as String?,
              catalysts: t['catalysts'] as String?,
              risks: t['risks'] as String?,
              exitConditions: t['exit_conditions'] as String?,
              conviction: t['conviction'] as String? ?? 'low',
              createdAt: DateTime.parse(t['created_at'] as String),
              updatedAt: DateTime.parse(t['updated_at'] as String),
              lastReviewedAt: t['last_reviewed_at'] != null
                  ? DateTime.parse(t['last_reviewed_at'] as String)
                  : null,
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

  // ── Note-Thesis Links ──────────────────────────────────────────────

  Future<Result<NoteThesisLink>> linkNoteToThesis({
    required String noteId,
    required String thesisId,
    String relationship = 'supports',
    String? thesisField,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] linkNoteToThesis: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.noteThesisLinks)
          .insert({
            'note_id': noteId,
            'thesis_id': thesisId,
            'relationship': relationship,
            'thesis_field': thesisField,
          })
          .select()
          .single();

      return Result.success(
        NoteThesisLink(
          id: response['id'] as String,
          noteId: response['note_id'] as String,
          thesisId: response['thesis_id'] as String,
          relationship: response['relationship'] as String? ?? 'supports',
          thesisField: response['thesis_field'] as String?,
          createdAt: DateTime.parse(response['created_at'] as String),
        ),
      );
    } catch (e) {
      debugPrint('[WorkspaceRepo] linkNoteToThesis: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> unlinkNoteFromThesis({
    required String noteId,
    required String thesisId,
    String? thesisField,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] unlinkNoteFromThesis: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      var query = _client
          .from(AppSchema.noteThesisLinks)
          .delete()
          .eq('note_id', noteId)
          .eq('thesis_id', thesisId);

      if (thesisField != null) {
        query = query.eq('thesis_field', thesisField);
      }

      await query;
      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] unlinkNoteFromThesis: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<NoteThesisLink>>> getLinkedNotes(String thesisId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] getLinkedNotes: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.noteThesisLinks)
          .select('id, note_id, thesis_id, relationship, thesis_field, created_at')
          .eq('thesis_id', thesisId)
          .order('created_at', ascending: false);

      final links = (response as List)
          .map(
            (l) => NoteThesisLink(
              id: l['id'] as String,
              noteId: l['note_id'] as String,
              thesisId: l['thesis_id'] as String,
              relationship: l['relationship'] as String? ?? 'supports',
              thesisField: l['thesis_field'] as String?,
              createdAt: DateTime.parse(l['created_at'] as String),
            ),
          )
          .toList();

      return Result.success(links);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getLinkedNotes: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  // ── Invalidation Conditions ────────────────────────────────────────

  Future<Result<InvalidationCondition>> addInvalidationCondition({
    required String thesisId,
    required String description,
    String? metricCode,
    required String operator,
    double? thresholdLow,
    double? thresholdHigh,
    String severity = 'warning',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] addInvalidationCondition: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.invalidationConditions)
          .insert({
            'thesis_id': thesisId,
            'user_id': userId,
            'description': description,
            'metric_code': metricCode,
            'operator': operator,
            'threshold_low': thresholdLow,
            'threshold_high': thresholdHigh,
            'severity': severity,
          })
          .select()
          .single();

      return Result.success(_parseInvalidationCondition(response));
    } catch (e) {
      debugPrint('[WorkspaceRepo] addInvalidationCondition: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<InvalidationCondition>>> getInvalidationConditions(
    String thesisId,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] getInvalidationConditions: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.invalidationConditions)
          .select('*')
          .eq('thesis_id', thesisId)
          .order('created_at', ascending: false);

      final conditions = (response as List)
          .map((c) => _parseInvalidationCondition(c))
          .toList();

      return Result.success(conditions);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getInvalidationConditions: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> updateInvalidationCondition({
    required String conditionId,
    String? description,
    String? metricCode,
    String? operator,
    double? thresholdLow,
    double? thresholdHigh,
    String? severity,
    String? status,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] updateInvalidationCondition: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final update = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (description != null) update['description'] = description;
      if (metricCode != null) update['metric_code'] = metricCode;
      if (operator != null) update['operator'] = operator;
      if (thresholdLow != null) update['threshold_low'] = thresholdLow;
      if (thresholdHigh != null) update['threshold_high'] = thresholdHigh;
      if (severity != null) update['severity'] = severity;
      if (status != null) update['status'] = status;

      await _client
          .from(AppSchema.invalidationConditions)
          .update(update)
          .eq('id', conditionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] updateInvalidationCondition: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> deleteInvalidationCondition(String conditionId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] deleteInvalidationCondition: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from(AppSchema.invalidationConditions)
          .delete()
          .eq('id', conditionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] deleteInvalidationCondition: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  // ── Thesis Assumptions ─────────────────────────────────────────────

  Future<Result<ThesisAssumption>> addThesisAssumption({
    required String thesisId,
    required String description,
    String? metricCode,
    String? operator,
    double? thresholdLow,
    double? thresholdHigh,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] addThesisAssumption: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.thesisAssumptions)
          .insert({
            'thesis_id': thesisId,
            'user_id': userId,
            'description': description,
            'metric_code': metricCode,
            'operator': operator,
            'threshold_low': thresholdLow,
            'threshold_high': thresholdHigh,
          })
          .select()
          .single();

      return Result.success(_parseThesisAssumption(response));
    } catch (e) {
      debugPrint('[WorkspaceRepo] addThesisAssumption: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<ThesisAssumption>>> getThesisAssumptions(
    String thesisId,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] getThesisAssumptions: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.thesisAssumptions)
          .select('*')
          .eq('thesis_id', thesisId)
          .order('created_at', ascending: false);

      final assumptions = (response as List)
          .map((a) => _parseThesisAssumption(a))
          .toList();

      return Result.success(assumptions);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getThesisAssumptions: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<AssumptionCheckResult>>> checkAssumptions(
    String thesisId,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] checkAssumptions: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.assumptionCheckV)
          .select('*')
          .eq('thesis_id', thesisId)
          .eq('user_id', userId);

      final results = (response as List)
          .map(
            (r) => AssumptionCheckResult(
              assumptionId: r['assumption_id'] as String,
              thesisId: r['thesis_id'] as String,
              description: r['description'] as String? ?? '',
              metricCode: r['metric_code'] as String?,
              operator: r['operator'] as String?,
              thresholdLow: (r['threshold_low'] as num?)?.toDouble(),
              thresholdHigh: (r['threshold_high'] as num?)?.toDouble(),
              assumptionStatus: r['assumption_status'] as String? ?? 'active',
              currentValue: (r['current_value'] as num?)?.toDouble(),
              computationStatus: r['computation_status'] as String?,
              isBreached: r['is_breached'] as bool?,
            ),
          )
          .toList();

      return Result.success(results);
    } catch (e) {
      debugPrint('[WorkspaceRepo] checkAssumptions: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> updateThesisAssumption({
    required String assumptionId,
    String? description,
    String? metricCode,
    String? operator,
    double? thresholdLow,
    double? thresholdHigh,
    String? status,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] updateThesisAssumption: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final update = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (description != null) update['description'] = description;
      if (metricCode != null) update['metric_code'] = metricCode;
      if (operator != null) update['operator'] = operator;
      if (thresholdLow != null) update['threshold_low'] = thresholdLow;
      if (thresholdHigh != null) update['threshold_high'] = thresholdHigh;
      if (status != null) update['status'] = status;

      await _client
          .from(AppSchema.thesisAssumptions)
          .update(update)
          .eq('id', assumptionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] updateThesisAssumption: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> deleteThesisAssumption(String assumptionId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] deleteThesisAssumption: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from(AppSchema.thesisAssumptions)
          .delete()
          .eq('id', assumptionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] deleteThesisAssumption: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────

  InvalidationCondition _parseInvalidationCondition(Map<String, dynamic> r) {
    return InvalidationCondition(
      id: r['id'] as String,
      thesisId: r['thesis_id'] as String,
      description: r['description'] as String? ?? '',
      metricCode: r['metric_code'] as String?,
      operator: r['operator'] as String? ?? '>',
      thresholdLow: (r['threshold_low'] as num?)?.toDouble(),
      thresholdHigh: (r['threshold_high'] as num?)?.toDouble(),
      severity: r['severity'] as String? ?? 'warning',
      status: r['status'] as String? ?? 'active',
      triggeredAt: r['triggered_at'] != null
          ? DateTime.parse(r['triggered_at'] as String)
          : null,
      triggeredValue: (r['triggered_value'] as num?)?.toDouble(),
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
    );
  }

  ThesisAssumption _parseThesisAssumption(Map<String, dynamic> r) {
    return ThesisAssumption(
      id: r['id'] as String,
      thesisId: r['thesis_id'] as String,
      description: r['description'] as String? ?? '',
      metricCode: r['metric_code'] as String?,
      operator: r['operator'] as String?,
      thresholdLow: (r['threshold_low'] as num?)?.toDouble(),
      thresholdHigh: (r['threshold_high'] as num?)?.toDouble(),
      status: r['status'] as String? ?? 'active',
      lastCheckedAt: r['last_checked_at'] != null
          ? DateTime.parse(r['last_checked_at'] as String)
          : null,
      lastCheckedValue: (r['last_checked_value'] as num?)?.toDouble(),
      breachDetectedAt: r['breach_detected_at'] != null
          ? DateTime.parse(r['breach_detected_at'] as String)
          : null,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
    );
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

  Future<Result<void>> markThesisReviewed(String thesisId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] markThesisReviewed: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from(AppSchema.investmentTheses)
          .update({
            'last_reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', thesisId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] markThesisReviewed: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<ResearchReview>> createReview({
    required String thesisId,
    String? reviewNotes,
    String? convictionBefore,
    String? convictionAfter,
    String? stanceBefore,
    String? stanceAfter,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] createReview: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final now = DateTime.now().toIso8601String();

      final insertData = <String, dynamic>{
        'user_id': userId,
        'thesis_id': thesisId,
        'reviewed_at': now,
      };
      if (reviewNotes != null) insertData['review_notes'] = reviewNotes;
      if (convictionBefore != null) insertData['conviction_before'] = convictionBefore;
      if (convictionAfter != null) insertData['conviction_after'] = convictionAfter;
      if (stanceBefore != null) insertData['stance_before'] = stanceBefore;
      if (stanceAfter != null) insertData['stance_after'] = stanceAfter;

      final response = await _client
          .from(AppSchema.researchReviews)
          .insert(insertData)
          .select()
          .single();

      // Also bump the thesis last_reviewed_at
      await markThesisReviewed(thesisId);

      return Result.success(
        ResearchReview(
          id: response['id'] as String,
          userId: response['user_id'] as String,
          thesisId: response['thesis_id'] as String,
          reviewedAt: DateTime.parse(response['reviewed_at'] as String),
          reviewNotes: response['review_notes'] as String?,
          convictionBefore: response['conviction_before'] as String?,
          convictionAfter: response['conviction_after'] as String?,
          stanceBefore: response['stance_before'] as String?,
          stanceAfter: response['stance_after'] as String?,
          createdAt: DateTime.parse(response['created_at'] as String),
        ),
      );
    } catch (e) {
      debugPrint('[WorkspaceRepo] createReview: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<ResearchReview>>> getReviews(String thesisId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] getReviews: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.researchReviews)
          .select('id, user_id, thesis_id, reviewed_at, review_notes, conviction_before, conviction_after, stance_before, stance_after, created_at')
          .eq('thesis_id', thesisId)
          .eq('user_id', userId)
          .order('reviewed_at', ascending: false);

      final reviews = (response as List)
          .map(
            (r) => ResearchReview(
              id: r['id'] as String,
              userId: r['user_id'] as String,
              thesisId: r['thesis_id'] as String,
              reviewedAt: DateTime.parse(r['reviewed_at'] as String),
              reviewNotes: r['review_notes'] as String?,
              convictionBefore: r['conviction_before'] as String?,
              convictionAfter: r['conviction_after'] as String?,
              stanceBefore: r['stance_before'] as String?,
              stanceAfter: r['stance_after'] as String?,
              createdAt: DateTime.parse(r['created_at'] as String),
            ),
          )
          .toList();

      return Result.success(reviews);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getReviews: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<List<CompanyQuestion>>> getQuestions(String companyId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] getQuestions: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.researchQuestions)
          .select('id, company_id, thesis_id, question, priority, status, answer, answered_at, created_at, updated_at')
          .eq('company_id', companyId)
          .eq('user_id', userId)
          .order('status')
          .order('updated_at', ascending: false);

      final questions = (response as List)
          .map(
            (q) => CompanyQuestion(
              id: q['id'] as String,
              companyId: q['company_id'] as String?,
              thesisId: q['thesis_id'] as String?,
              question: q['question'] as String? ?? '',
              priority: q['priority'] as String? ?? 'medium',
              status: q['status'] as String? ?? 'open',
              answer: q['answer'] as String?,
              answeredAt: q['answered_at'] != null
                  ? DateTime.parse(q['answered_at'] as String)
                  : null,
              createdAt: DateTime.parse(q['created_at'] as String),
              updatedAt: DateTime.parse(q['updated_at'] as String),
            ),
          )
          .toList();

      return Result.success(questions);
    } catch (e) {
      debugPrint('[WorkspaceRepo] getQuestions: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<CompanyQuestion>> createQuestion({
    required String companyId,
    required String question,
    String priority = 'medium',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] createQuestion: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      final response = await _client
          .from(AppSchema.researchQuestions)
          .insert({
            'user_id': userId,
            'company_id': companyId,
            'question': question,
            'priority': priority,
          })
          .select()
          .single();

      return Result.success(
        CompanyQuestion(
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
        ),
      );
    } catch (e) {
      debugPrint('[WorkspaceRepo] createQuestion: $e');
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
        debugPrint('[WorkspaceRepo] answerQuestion: Not authenticated');
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
      debugPrint('[WorkspaceRepo] answerQuestion: $e');
      return Result.failure(Exception(e.toString()));
    }
  }

  Future<Result<void>> deleteQuestion(String questionId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[WorkspaceRepo] deleteQuestion: Not authenticated');
        return Result.failure(Exception('Not authenticated'));
      }

      await _client
          .from(AppSchema.researchQuestions)
          .delete()
          .eq('id', questionId)
          .eq('user_id', userId);

      return const Result.success(null);
    } catch (e) {
      debugPrint('[WorkspaceRepo] deleteQuestion: $e');
      return Result.failure(Exception(e.toString()));
    }
  }
}
