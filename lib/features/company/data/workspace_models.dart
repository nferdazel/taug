import 'package:equatable/equatable.dart';

class CompanyProfile extends Equatable {
  final String id;
  final String displayName;
  final String? ticker;
  final String? sector;
  final String? industry;
  final String? domicileCountryCode;
  final String? description;
  final double? qualityScore;
  final String? freshnessStatus;
  final String researchStatus;

  const CompanyProfile({
    required this.id,
    required this.displayName,
    this.ticker,
    this.sector,
    this.industry,
    this.domicileCountryCode,
    this.description,
    this.qualityScore,
    this.freshnessStatus,
    this.researchStatus = 'not_researched',
  });

  @override
  List<Object?> get props => [id, displayName, ticker, sector, industry];
}

class MetricSnapshot extends Equatable {
  final String metricCode;
  final String metricName;
  final String metricCategory;
  final double? valueNumeric;
  final String computationStatus;
  final String? unitType;
  final int displayPrecision;

  const MetricSnapshot({
    required this.metricCode,
    required this.metricName,
    required this.metricCategory,
    this.valueNumeric,
    required this.computationStatus,
    this.unitType,
    this.displayPrecision = 2,
  });

  bool get isOk => computationStatus == 'ok' && valueNumeric != null;

  @override
  List<Object?> get props => [metricCode, computationStatus, valueNumeric];
}

class StatementRow extends Equatable {
  final String statementType;
  final String periodEnd;
  final int? statementVersion;
  final bool isRestated;
  final Map<String, double?> items;

  const StatementRow({
    required this.statementType,
    required this.periodEnd,
    this.statementVersion,
    this.isRestated = false,
    required this.items,
  });

  @override
  List<Object?> get props => [statementType, periodEnd];
}

class CompanyNote extends Equatable {
  final String id;
  final String companyId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompanyNote({
    required this.id,
    required this.companyId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id];
}

class CompanyThesis extends Equatable {
  final String id;
  final String companyId;
  final String title;
  final String stance;
  final String? summary;
  final String? bullCase;
  final String? bearCase;
  final String? assumptions;
  final String? catalysts;
  final String? risks;
  final String? exitConditions;
  final String conviction;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewedAt;
  final String? researchFreshness;

  const CompanyThesis({
    required this.id,
    required this.companyId,
    required this.title,
    required this.stance,
    this.summary,
    this.bullCase,
    this.bearCase,
    this.assumptions,
    this.catalysts,
    this.risks,
    this.exitConditions,
    this.conviction = 'low',
    required this.createdAt,
    required this.updatedAt,
    this.lastReviewedAt,
    this.researchFreshness,
  });

  /// Computed freshness based on lastReviewedAt or createdAt fallback.
  String get freshnessStatus {
    final reference = lastReviewedAt ?? createdAt;
    final age = DateTime.now().difference(reference);
    if (age.inDays <= 7) return 'fresh';
    if (age.inDays <= 30) return 'aging';
    if (age.inDays <= 90) return 'stale';
    return 'expired';
  }

  @override
  List<Object?> get props => [id, lastReviewedAt, updatedAt];
}

class ResearchReview extends Equatable {
  final String id;
  final String userId;
  final String thesisId;
  final DateTime reviewedAt;
  final String? reviewNotes;
  final String? convictionBefore;
  final String? convictionAfter;
  final String? stanceBefore;
  final String? stanceAfter;
  final DateTime createdAt;

  const ResearchReview({
    required this.id,
    required this.userId,
    required this.thesisId,
    required this.reviewedAt,
    this.reviewNotes,
    this.convictionBefore,
    this.convictionAfter,
    this.stanceBefore,
    this.stanceAfter,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}

class NoteThesisLink extends Equatable {
  final String id;
  final String noteId;
  final String thesisId;
  final String relationship;
  final String? thesisField;
  final DateTime createdAt;

  const NoteThesisLink({
    required this.id,
    required this.noteId,
    required this.thesisId,
    this.relationship = 'supports',
    this.thesisField,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}

class InvalidationCondition extends Equatable {
  final String id;
  final String thesisId;
  final String description;
  final String? metricCode;
  final String operator;
  final double? thresholdLow;
  final double? thresholdHigh;
  final String severity;
  final String status;
  final DateTime? triggeredAt;
  final double? triggeredValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvalidationCondition({
    required this.id,
    required this.thesisId,
    required this.description,
    this.metricCode,
    required this.operator,
    this.thresholdLow,
    this.thresholdHigh,
    this.severity = 'warning',
    this.status = 'active',
    this.triggeredAt,
    this.triggeredValue,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTriggered => status == 'triggered';
  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [id, status, triggeredAt];
}

class ThesisAssumption extends Equatable {
  final String id;
  final String thesisId;
  final String description;
  final String? metricCode;
  final String? operator;
  final double? thresholdLow;
  final double? thresholdHigh;
  final String status;
  final DateTime? lastCheckedAt;
  final double? lastCheckedValue;
  final DateTime? breachDetectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ThesisAssumption({
    required this.id,
    required this.thesisId,
    required this.description,
    this.metricCode,
    this.operator,
    this.thresholdLow,
    this.thresholdHigh,
    this.status = 'active',
    this.lastCheckedAt,
    this.lastCheckedValue,
    this.breachDetectedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isBreached => status == 'breached';
  bool get isActive => status == 'active';
  bool get hasQuantitativeBound => metricCode != null && operator != null;

  @override
  List<Object?> get props => [id, status, breachDetectedAt];
}

class AssumptionCheckResult extends Equatable {
  final String assumptionId;
  final String thesisId;
  final String description;
  final String? metricCode;
  final String? operator;
  final double? thresholdLow;
  final double? thresholdHigh;
  final String assumptionStatus;
  final double? currentValue;
  final String? computationStatus;
  final bool? isBreached;

  const AssumptionCheckResult({
    required this.assumptionId,
    required this.thesisId,
    required this.description,
    this.metricCode,
    this.operator,
    this.thresholdLow,
    this.thresholdHigh,
    required this.assumptionStatus,
    this.currentValue,
    this.computationStatus,
    this.isBreached,
  });

  @override
  List<Object?> get props => [assumptionId, isBreached, currentValue];
}

class QualityScoreDetail extends Equatable {
  final double overallScore;
  final double? historicalCoverageScore;
  final double? completenessScore;
  final double? validationScore;
  final double? verificationScore;
  final double? freshnessScore;
  final double? restatementSupportScore;
  final Map<String, double>? componentDetails;
  final DateTime? scoreDate;

  const QualityScoreDetail({
    required this.overallScore,
    this.historicalCoverageScore,
    this.completenessScore,
    this.validationScore,
    this.verificationScore,
    this.freshnessScore,
    this.restatementSupportScore,
    this.componentDetails,
    this.scoreDate,
  });

  @override
  List<Object?> get props => [overallScore, scoreDate];
}

class CompanyQuestion extends Equatable {
  final String id;
  final String? companyId;
  final String? thesisId;
  final String question;
  final String priority;
  final String status;
  final String? answer;
  final DateTime? answeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompanyQuestion({
    required this.id,
    this.companyId,
    this.thesisId,
    required this.question,
    this.priority = 'medium',
    this.status = 'open',
    this.answer,
    this.answeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == 'open';
  bool get isCritical => priority == 'critical';
  bool get isHigh => priority == 'high' || priority == 'critical';
  int get daysOpen => DateTime.now().difference(createdAt).inDays;

  @override
  List<Object?> get props => [id];
}
