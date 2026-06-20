import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class BinanceWebSocketService {
  WebSocketChannel? _channel;
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};
  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  void connect() {
    if (_channel != null) return;

    _channel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws'),
    );

    _reconnectAttempts = 0;

    _channel!.stream.listen(
      (data) {
        _reconnectAttempts = 0;
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        final stream = json['s'] as String?;
        if (stream != null && _controllers.containsKey(stream)) {
          _controllers[stream]!.add(json);
        }
      },
      onError: (error) {
        _handleDisconnect();
      },
      onDone: () {
        _handleDisconnect();
      },
    );
  }

  void subscribeTicker(
    String symbol,
    void Function(Map<String, dynamic>) onData,
  ) {
    final streamName = '${symbol.toLowerCase()}@ticker';

    if (!_controllers.containsKey(streamName)) {
      _controllers[streamName] =
          StreamController<Map<String, dynamic>>.broadcast();
    }

    _subscriptions[streamName]?.cancel();
    _subscriptions[streamName] = _controllers[streamName]!.stream.listen(
      onData,
    );

    _sendSubscription('SUBSCRIBE', [streamName]);
  }

  void subscribeKline(
    String symbol,
    String interval,
    void Function(Map<String, dynamic>) onData,
  ) {
    final intervalMap = {
      '1m': '1m',
      '5m': '5m',
      '15m': '15m',
      '1h': '1h',
      '1d': '1d',
      '1w': '1w',
    };
    final binanceInterval = intervalMap[interval] ?? '1d';
    final streamName = '${symbol.toLowerCase()}@kline_$binanceInterval';

    if (!_controllers.containsKey(streamName)) {
      _controllers[streamName] =
          StreamController<Map<String, dynamic>>.broadcast();
    }

    _subscriptions[streamName]?.cancel();
    _subscriptions[streamName] = _controllers[streamName]!.stream.listen(
      onData,
    );

    _sendSubscription('SUBSCRIBE', [streamName]);
  }

  void unsubscribe(String symbol, String interval) {
    final streamName = '${symbol.toLowerCase()}@kline_$interval';
    _sendSubscription('UNSUBSCRIBE', [streamName]);

    _subscriptions.remove(streamName)?.cancel();
    final controller = _controllers.remove(streamName);
    controller?.close();
  }

  void unsubscribeTicker(String symbol) {
    final streamName = '${symbol.toLowerCase()}@ticker';
    _sendSubscription('UNSUBSCRIBE', [streamName]);

    _subscriptions.remove(streamName)?.cancel();
    final controller = _controllers.remove(streamName);
    controller?.close();
  }

  void _sendSubscription(String method, List<String> streams) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({'method': method, 'params': streams}));
    }
  }

  void _handleDisconnect() {
    _reconnectTimer?.cancel();
    _channel = null;

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
        _reconnectAttempts++;
        connect();

        for (final streamName in _controllers.keys) {
          _sendSubscription('SUBSCRIBE', [streamName]);
        }
      });
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _channel?.sink.close();
    _channel = null;
  }

  bool get isConnected => _channel != null;
}
