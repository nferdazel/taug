import 'package:equatable/equatable.dart';

enum PositionStatus {
  active,
  reviewNeeded,
  closed,
}

enum PositionOutcome {
  correct,
  incorrect,
  partial,
}

class PortfolioPosition extends Equatable {
  final String id;
  final String companyId;
  final String? companyName;
  final String? ticker;
  final String? thesisId;
  final String? thesisTitle;
  final String? thesisStance;
  final String conviction;
  final DateTime entryDate;
  final double? entryPrice;
  final String? notes;
  final PositionStatus status;
  final DateTime? exitDate;
  final double? exitPrice;
  final PositionOutcome? outcome;
  final String? lessonsLearned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PortfolioPosition({
    required this.id,
    required this.companyId,
    this.companyName,
    this.ticker,
    this.thesisId,
    this.thesisTitle,
    this.thesisStance,
    required this.conviction,
    required this.entryDate,
    this.entryPrice,
    this.notes,
    required this.status,
    this.exitDate,
    this.exitPrice,
    this.outcome,
    this.lessonsLearned,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == PositionStatus.active;
  bool get isReviewNeeded => status == PositionStatus.reviewNeeded;
  bool get isClosed => status == PositionStatus.closed;

  @override
  List<Object?> get props => [id];
}
