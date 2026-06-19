import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';

class SymbolSearchResult {
  final String symbol;
  final String name;
  final String exchange;
  final String? country;
  final String? type;

  const SymbolSearchResult({
    required this.symbol,
    required this.name,
    required this.exchange,
    this.country,
    this.type,
  });

  factory SymbolSearchResult.fromJson(Map<String, dynamic> json) {
    return SymbolSearchResult(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      exchange: json['exchange'] as String,
      country: json['country'] as String?,
      type: json['type'] as String?,
    );
  }
}

class SymbolRepository {
  final SupabaseClient _client;

  SymbolRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Result<List<SymbolSearchResult>>> searchSymbols(String query) async {
    try {
      if (query.isEmpty) {
        return const Result.success([]);
      }

      final response = await _client.functions.invoke(
        'search-symbols',
        body: {'query': query},
      );

      if (response.data != null) {
        final data = response.data as List;
        final results = data
            .map((json) => SymbolSearchResult.fromJson(json as Map<String, dynamic>))
            .toList();
        return Result.success(results);
      }

      return const Result.success([]);
    } catch (e) {
      return Result.failure(
        DataSourceFailure(
          message: e.toString(),
          source: 'twelve_data',
        ),
      );
    }
  }

  Future<Result<List<SymbolSearchResult>>> searchLocalSymbols(String query) async {
    try {
      final response = await _client
          .from('taug.symbols')
          .select('''
            ticker, name,
            exchanges!inner(code)
          ''')
          .or('ticker.ilike.%$query%,name.ilike.%$query%')
          .limit(20);

      final results = response.map((json) {
        final exchanges = json['exchanges'] as Map<String, dynamic>;
        return SymbolSearchResult(
          symbol: json['ticker'] as String,
          name: json['name'] as String,
          exchange: exchanges['code'] as String,
        );
      }).toList();

      return Result.success(results);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
