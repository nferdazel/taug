import 'package:equatable/equatable.dart';

class ResearchCompany extends Equatable {
  final String companyId;
  final String displayName;
  final String? ticker;
  final double? qualityScore;
  final String? freshnessStatus;
  final int notesCount;
  final int thesesCount;
  final DateTime? lastActivityAt;
  final String researchStatus;

  const ResearchCompany({
    required this.companyId,
    required this.displayName,
    this.ticker,
    this.qualityScore,
    this.freshnessStatus,
    this.notesCount = 0,
    this.thesesCount = 0,
    this.lastActivityAt,
    this.researchStatus = 'not_researched',
  });

  @override
  List<Object?> get props => [companyId];
}

class ResearchThesisIndex extends Equatable {
  final String thesisId;
  final String companyId;
  final String companyName;
  final String? ticker;
  final String title;
  final String stance;
  final String conviction;
  final DateTime updatedAt;

  const ResearchThesisIndex({
    required this.thesisId,
    required this.companyId,
    required this.companyName,
    this.ticker,
    required this.title,
    required this.stance,
    required this.conviction,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [thesisId];
}

class ResearchNoteIndex extends Equatable {
  final String noteId;
  final String companyId;
  final String companyName;
  final String? ticker;
  final String title;
  final String body;
  final DateTime updatedAt;

  const ResearchNoteIndex({
    required this.noteId,
    required this.companyId,
    required this.companyName,
    this.ticker,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [noteId];
}
