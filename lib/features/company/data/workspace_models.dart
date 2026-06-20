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
  });

  @override
  List<Object?> get props => [id];
}
