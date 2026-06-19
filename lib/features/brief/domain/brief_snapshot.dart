import 'package:equatable/equatable.dart';

import '../../../shared/models/econ_event.dart';
import '../../../shared/models/price_data.dart';
import '../../../shared/models/terminal_headline.dart';

final class BriefSnapshot extends Equatable {
  final List<TerminalHeadline> headlines;
  final List<PriceData> movers;
  final List<EconEvent> macroEvents;
  final DateTime fetchedAt;

  const BriefSnapshot({
    required this.headlines,
    required this.movers,
    required this.macroEvents,
    required this.fetchedAt,
  });

  @override
  List<Object?> get props => <Object?>[
    headlines,
    movers,
    macroEvents,
    fetchedAt,
  ];
}
