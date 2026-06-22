import 'package:equatable/equatable.dart';

class CompanyListItem extends Equatable {
  final String id;
  final String displayName;
  final String? ticker;
  final String? sector;
  final double? qualityScore;
  final String? freshnessStatus;
  final String researchStatus;

  const CompanyListItem({
    required this.id,
    required this.displayName,
    this.ticker,
    this.sector,
    this.qualityScore,
    this.freshnessStatus,
    this.researchStatus = 'not_researched',
  });

  @override
  List<Object?> get props => [id, displayName, ticker, sector, qualityScore, freshnessStatus, researchStatus];
}

class CompanyListData {
  final List<CompanyListItem> companies;
  final int totalCompanies;
  final int researchQueueCount;

  const CompanyListData({
    required this.companies,
    required this.totalCompanies,
    this.researchQueueCount = 0,
  });
}
