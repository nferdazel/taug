import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/schema/app_schema.dart';

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
      if (query.isEmpty) return const Result.success([]);

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
      return Result.failure(DataSourceFailure(message: e.toString(), source: 'twelve_data'));
    }
  }

  Future<Result<List<SymbolSearchResult>>> searchLocalSymbols(String query) async {
    try {
      final response = await _client
          .from('${AppSchema.name}.${AppSchema.symbols}')
          .select('ticker, name, exchanges!inner(code)')
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
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<int?> getSymbolId(String ticker) async {
    try {
      final response = await _client
          .from('${AppSchema.name}.${AppSchema.symbols}')
          .select('id')
          .eq('ticker', ticker)
          .maybeSingle();

      return response?['id'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<Result<int>> insertSymbol(SymbolSearchResult symbol) async {
    try {
      final exchangeId = await _getExchangeId(symbol.exchange);
      if (exchangeId == null) {
        return const Result.failure(ServerFailure(message: 'Exchange not found'));
      }

      final response = await _client
          .from('${AppSchema.name}.${AppSchema.symbols}')
          .insert({
            'exchange_id': exchangeId,
            'ticker': symbol.symbol,
            'name': symbol.name,
            'asset_class': _determineAssetClass(symbol),
          })
          .select('id')
          .single();

      return Result.success(response['id'] as int);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<int?> _getExchangeId(String exchangeCode) async {
    try {
      final response = await _client
          .from('${AppSchema.name}.${AppSchema.exchanges}')
          .select('id')
          .eq('code', exchangeCode)
          .maybeSingle();

      return response?['id'] as int?;
    } catch (_) {
      return null;
    }
  }

  String _determineAssetClass(SymbolSearchResult symbol) {
    final name = symbol.name.toLowerCase();
    final ticker = symbol.symbol.toLowerCase();

    if (ticker.endsWith('/usdt') || ticker.endsWith('/btc') || ticker.endsWith('/eth')) return 'crypto';
    if (name.contains('etf') || name.contains('fund')) return 'etf';
    if (name.contains('index')) return 'index';
    return 'equity';
  }
}
