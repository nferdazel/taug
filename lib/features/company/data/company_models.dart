class CompanyResearchSummary {
  final String companyId;
  final String displayName;
  final String? legalName;
  final String? domicileCountryCode;
  final String? securityId;
  final String? primaryTicker;
  final String? cik;
  final String? latestFilingType;
  final String? latestFilingDate;
  final int filingCount;
  final int statementCount;
  final String statementFreshnessStatus;

  const CompanyResearchSummary({
    required this.companyId,
    required this.displayName,
    this.legalName,
    this.domicileCountryCode,
    this.securityId,
    this.primaryTicker,
    this.cik,
    this.latestFilingType,
    this.latestFilingDate,
    this.filingCount = 0,
    this.statementCount = 0,
    this.statementFreshnessStatus = 'missing',
  });

  factory CompanyResearchSummary.fromMap(Map<String, dynamic> map) {
    return CompanyResearchSummary(
      companyId: map['company_id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      legalName: map['legal_name'] as String?,
      domicileCountryCode: map['domicile_country_code'] as String?,
      securityId: map['security_id'] as String?,
      primaryTicker: map['primary_ticker'] as String?,
      cik: map['cik'] as String?,
      latestFilingType: map['latest_filing_type'] as String?,
      latestFilingDate: map['latest_filing_date'] as String?,
      filingCount: map['filing_count'] as int? ?? 0,
      statementCount: map['statement_count'] as int? ?? 0,
      statementFreshnessStatus:
          map['statement_freshness_status'] as String? ?? 'missing',
    );
  }
}

class CompanyStatementRow {
  final String statementType;
  final int statementVersion;
  final String? periodStart;
  final String periodEnd;
  final String? publishedAt;
  final bool isRestated;
  final String? currencyCode;
  final double? revenue;
  final double? grossProfit;
  final double? operatingIncome;
  final double? netIncome;
  final double? totalAssets;
  final double? totalLiabilities;
  final double? stockholdersEquity;
  final double? cashAndEquivalents;
  final double? operatingCashFlow;
  final double? capex;
  final double? depreciationAmortization;
  final double? rdExpense;
  final double? sgaExpense;
  final double? currentAssets;
  final double? currentLiabilities;
  final double? longTermDebt;
  final double? sharesOutstanding;
  final double? epsBasic;
  final double? epsDiluted;

  const CompanyStatementRow({
    required this.statementType,
    required this.statementVersion,
    this.periodStart,
    required this.periodEnd,
    this.publishedAt,
    this.isRestated = false,
    this.currencyCode,
    this.revenue,
    this.grossProfit,
    this.operatingIncome,
    this.netIncome,
    this.totalAssets,
    this.totalLiabilities,
    this.stockholdersEquity,
    this.cashAndEquivalents,
    this.operatingCashFlow,
    this.capex,
    this.depreciationAmortization,
    this.rdExpense,
    this.sgaExpense,
    this.currentAssets,
    this.currentLiabilities,
    this.longTermDebt,
    this.sharesOutstanding,
    this.epsBasic,
    this.epsDiluted,
  });

  factory CompanyStatementRow.fromMap(Map<String, dynamic> map) {
    return CompanyStatementRow(
      statementType: map['statement_type'] as String? ?? '',
      statementVersion: map['statement_version'] as int? ?? 1,
      periodStart: map['period_start'] as String?,
      periodEnd: map['period_end'] as String? ?? '',
      publishedAt: map['published_at'] as String?,
      isRestated: map['is_restated'] as bool? ?? false,
      currencyCode: map['currency_code'] as String?,
      revenue: _toDouble(map['revenue']),
      grossProfit: _toDouble(map['gross_profit']),
      operatingIncome: _toDouble(map['operating_income']),
      netIncome: _toDouble(map['net_income']),
      totalAssets: _toDouble(map['total_assets']),
      totalLiabilities: _toDouble(map['total_liabilities']),
      stockholdersEquity: _toDouble(map['stockholders_equity']),
      cashAndEquivalents: _toDouble(map['cash_and_equivalents']),
      operatingCashFlow: _toDouble(map['operating_cash_flow']),
      capex: _toDouble(map['capex']),
      depreciationAmortization: _toDouble(map['depreciation_amortization']),
      rdExpense: _toDouble(map['rd_expense']),
      sgaExpense: _toDouble(map['sga_expense']),
      currentAssets: _toDouble(map['current_assets']),
      currentLiabilities: _toDouble(map['current_liabilities']),
      longTermDebt: _toDouble(map['long_term_debt']),
      sharesOutstanding: _toDouble(map['shares_outstanding']),
      epsBasic: _toDouble(map['eps_basic']),
      epsDiluted: _toDouble(map['eps_diluted']),
    );
  }
}

class CompanyMetricSnapshot {
  final String metricCode;
  final String metricName;
  final String metricCategory;
  final double? valueNumeric;
  final String computationStatus;
  final String asOfDate;
  final String? formulaExpression;

  const CompanyMetricSnapshot({
    required this.metricCode,
    required this.metricName,
    required this.metricCategory,
    this.valueNumeric,
    required this.computationStatus,
    required this.asOfDate,
    this.formulaExpression,
  });

  factory CompanyMetricSnapshot.fromMap(Map<String, dynamic> map) {
    return CompanyMetricSnapshot(
      metricCode: map['metric_code'] as String? ?? '',
      metricName: map['metric_name'] as String? ?? '',
      metricCategory: map['metric_category'] as String? ?? '',
      valueNumeric: _toDouble(map['value_numeric']),
      computationStatus: map['computation_status'] as String? ?? 'missing_input',
      asOfDate: map['as_of_date'] as String? ?? '',
      formulaExpression: map['formula_expression'] as String?,
    );
  }
}

class CompanyDataQuality {
  final String companyId;
  final String displayName;
  final String? primaryTicker;
  final String? cik;
  final int totalFilings;
  final int annualQuarterlyFilings;
  final int amendmentFilings;
  final int totalStatements;
  final int restatedStatements;
  final String? latestStatementPublishedAt;
  final int totalFactItems;
  final int statementTypesCovered;
  final int passedValidations;
  final int failedValidations;
  final String statementFreshness;
  final String filingCoverageStatus;
  final String validationHealthStatus;
  final String factCoverageStatus;

  const CompanyDataQuality({
    required this.companyId,
    required this.displayName,
    this.primaryTicker,
    this.cik,
    this.totalFilings = 0,
    this.annualQuarterlyFilings = 0,
    this.amendmentFilings = 0,
    this.totalStatements = 0,
    this.restatedStatements = 0,
    this.latestStatementPublishedAt,
    this.totalFactItems = 0,
    this.statementTypesCovered = 0,
    this.passedValidations = 0,
    this.failedValidations = 0,
    this.statementFreshness = 'missing',
    this.filingCoverageStatus = 'no_filings',
    this.validationHealthStatus = 'no_validations',
    this.factCoverageStatus = 'empty',
  });

  factory CompanyDataQuality.fromMap(Map<String, dynamic> map) {
    return CompanyDataQuality(
      companyId: map['company_id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      primaryTicker: map['primary_ticker'] as String?,
      cik: map['cik'] as String?,
      totalFilings: map['total_filings'] as int? ?? 0,
      annualQuarterlyFilings: map['annual_quarterly_filings'] as int? ?? 0,
      amendmentFilings: map['amendment_filings'] as int? ?? 0,
      totalStatements: map['total_statements'] as int? ?? 0,
      restatedStatements: map['restated_statements'] as int? ?? 0,
      latestStatementPublishedAt:
          map['latest_statement_published_at'] as String?,
      totalFactItems: map['total_fact_items'] as int? ?? 0,
      statementTypesCovered: map['statement_types_covered'] as int? ?? 0,
      passedValidations: map['passed_validations'] as int? ?? 0,
      failedValidations: map['failed_validations'] as int? ?? 0,
      statementFreshness:
          map['statement_freshness'] as String? ?? 'missing',
      filingCoverageStatus:
          map['filing_coverage_status'] as String? ?? 'no_filings',
      validationHealthStatus:
          map['validation_health_status'] as String? ?? 'no_validations',
      factCoverageStatus:
          map['fact_coverage_status'] as String? ?? 'empty',
    );
  }
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
