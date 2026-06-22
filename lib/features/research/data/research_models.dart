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

class ResearchQuestion extends Equatable {
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

  const ResearchQuestion({
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

class ResearchQuestionIndex extends Equatable {
  final String questionId;
  final String? companyId;
  final String? companyName;
  final String? ticker;
  final String? thesisId;
  final String? thesisTitle;
  final String question;
  final String priority;
  final String status;
  final int notesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ResearchQuestionIndex({
    required this.questionId,
    this.companyId,
    this.companyName,
    this.ticker,
    this.thesisId,
    this.thesisTitle,
    required this.question,
    this.priority = 'medium',
    this.status = 'open',
    this.notesCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == 'open';
  bool get isCritical => priority == 'critical';
  bool get isHigh => priority == 'high' || priority == 'critical';
  int get daysOpen => DateTime.now().difference(createdAt).inDays;

  @override
  List<Object?> get props => [questionId];
}
