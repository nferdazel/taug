abstract final class AppConstants {
  static const String appName = 'Taug';
  static const String appVersion = '1.0.0';
  static const String supabaseSchema = 'taug';
  static const String defaultTimezone = 'Asia/Jakarta';
  static const String defaultCurrency = 'USD';
  static const int defaultPageSize = 50;
  static const int maxWatchlistItems = 100;
  static const int maxWatchlists = 10;
  static const Duration priceUpdateInterval = Duration(milliseconds: 100);
  static const Duration newsRefreshInterval = Duration(minutes: 15);
  static const Duration calendarRefreshInterval = Duration(hours: 24);
  static const Duration priceCacheDuration = Duration(minutes: 5);

  // External API URLs
  static const String binanceWebSocketUrl = 'wss://stream.binance.com:9443/ws';
  static const String twelveDataApiUrl = 'https://api.twelvedata.com';
}
