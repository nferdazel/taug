import 'package:equatable/equatable.dart';

enum TerminalHeadlineKind { news, policy }

final class TerminalHeadline extends Equatable {
  final TerminalHeadlineKind kind;
  final String id;
  final String title;
  final String? summary;
  final String url;
  final String sourceLabel;
  final String tag;
  final DateTime publishedAt;
  final int importance;
  final double impactScore;
  final bool isBreaking;
  final bool isOfficial;

  const TerminalHeadline({
    required this.kind,
    required this.id,
    required this.title,
    this.summary,
    required this.url,
    required this.sourceLabel,
    required this.tag,
    required this.publishedAt,
    required this.importance,
    required this.impactScore,
    required this.isBreaking,
    required this.isOfficial,
  });

  @override
  List<Object?> get props => <Object?>[
    kind,
    id,
    title,
    summary,
    url,
    sourceLabel,
    tag,
    publishedAt,
    importance,
    impactScore,
    isBreaking,
    isOfficial,
  ];
}
