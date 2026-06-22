import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketManager {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 3);

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _reconnectAttempts = 0;
    _startHeartbeat();

    _channelSubscription = _channel!.stream.listen(
      (data) {
        _reconnectAttempts = 0;
        for (final controller in _controllers.values) {
          controller.add(data);
        }
      },
      onError: (error) {
        _handleDisconnect(url);
      },
      onDone: () {
        _handleDisconnect(url);
      },
    );
  }

  void subscribe(String channel, void Function(dynamic) onData) {
    if (!_controllers.containsKey(channel)) {
      _controllers[channel] = StreamController<dynamic>.broadcast();
    }
    _subscriptions[channel]?.cancel();
    _subscriptions[channel] = _controllers[channel]!.stream.listen(onData);
  }

  void unsubscribe(String channel) {
    _subscriptions.remove(channel)?.cancel();
    final controller = _controllers.remove(channel);
    controller?.close();
  }

  void send(dynamic data) {
    _channel?.sink.add(data);
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    _channelSubscription = null;
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

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      send('ping');
    });
  }

  void _handleDisconnect(String url) {
    _heartbeatTimer?.cancel();
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
        _reconnectAttempts++;
        connect(url);

        for (final channel in _controllers.keys) {
          _subscriptions[channel]?.cancel();
          _subscriptions.remove(channel);
        }
      });
    }
  }

  bool get isConnected => _channel != null;

  StreamController<dynamic>? getController(String channel) {
    return _controllers[channel];
  }
}
