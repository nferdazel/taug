import '../../../core/errors/result.dart';
import '../../../shared/models/econ_event.dart';
import '../../../shared/models/price_data.dart';
import '../../../shared/models/terminal_headline.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../market/data/market_repository.dart';
import '../../news/data/news_intelligence_repository.dart';
import '../domain/brief_snapshot.dart';

class BriefRepository {
  final NewsIntelligenceRepository _newsIntelligenceRepository;
  final MarketRepository _marketRepository;
  final CalendarRepository _calendarRepository;

  BriefRepository({
    NewsIntelligenceRepository? newsIntelligenceRepository,
    MarketRepository? marketRepository,
    CalendarRepository? calendarRepository,
  }) : _newsIntelligenceRepository =
           newsIntelligenceRepository ?? NewsIntelligenceRepository(),
       _marketRepository = marketRepository ?? MarketRepository(),
       _calendarRepository = calendarRepository ?? CalendarRepository();

  Future<Result<BriefSnapshot>> getBriefSnapshot() async {
    final Result<void> refreshResult = await _marketRepository
        .refreshQuoteSnapshots(limit: 120);
    if (refreshResult.isFailure) {
      return Result.failure(refreshResult.error);
    }

    final List<Result<Object>> results =
        await Future.wait(<Future<Result<Object>>>[
          _newsIntelligenceRepository
              .getTopImpactHeadlines(resultLimit: 8)
              .then(
                (Result<List<TerminalHeadline>> result) =>
                    result.map<Object>((List<TerminalHeadline> data) => data),
              ),
          _marketRepository
              .getTopMovers(limit: 8)
              .then(
                (Result<List<PriceData>> result) =>
                    result.map<Object>((List<PriceData> data) => data),
              ),
          _calendarRepository
              .getEvents(country: 'US', importance: 2)
              .then(
                (Result<List<EconEvent>> result) =>
                    result.map<Object>((List<EconEvent> data) => data),
              ),
        ]);

    for (final Result<Object> result in results) {
      if (result.isFailure) {
        return Result.failure(result.error);
      }
    }

    final List<TerminalHeadline> headlines =
        results[0].data! as List<TerminalHeadline>;
    final List<PriceData> movers = results[1].data! as List<PriceData>;
    final List<EconEvent> macroEvents = results[2].data! as List<EconEvent>;

    return Result.success(
      BriefSnapshot(
        headlines: headlines,
        movers: movers,
        macroEvents: macroEvents.take(8).toList(),
        fetchedAt: DateTime.now(),
      ),
    );
  }
}
