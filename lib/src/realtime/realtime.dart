import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/client.dart';

// ======================================
// TYPES
// ======================================

class RealtimeEvent {
  final String? id;
  final String? channel;
  final String? eventName;
  final dynamic payload;
  final dynamic data;
  final String? status;
  final dynamic timestamp;

  RealtimeEvent({
    this.id,
    this.channel,
    this.eventName,
    this.payload,
    this.data,
    this.status,
    this.timestamp,
  });

  factory RealtimeEvent.fromJson(
    Map<String, dynamic> json,
  ) {
    return RealtimeEvent(
      id: json["id"],
      channel: json["channel"],
      eventName:
          json["event_name"] ??
          json["event"],
      payload: json["payload"],
      data: json["data"],
      status: json["status"],
      timestamp:
          json["timestamp"],
    );
  }
}

class RealtimeOptions {
  final String? token;
  final bool reconnect;
  final int reconnectInterval;
  final int maxRetries;
  final bool heartbeat;
  final int heartbeatInterval;

  const RealtimeOptions({
    this.token,
    this.reconnect = true,
    this.reconnectInterval = 3000,
    this.maxRetries = 10,
    this.heartbeat = true,
    this.heartbeatInterval = 30000,
  });
}

// ======================================
// REALTIME CLASS
// ======================================

class SupersoRealtime {
  final SupersoClient client;

  WebSocketChannel? _socket;

  String _channel = "";

  final Map<
      String,
      List<Function>> _handlers = {};

  bool _reconnect = true;

  int _reconnectInterval =
      3000;

  int _maxRetries = 10;

  int _retryCount = 0;

  String? _token;

  bool _heartbeat = true;

  int _heartbeatInterval =
      30000;

  Timer? _heartbeatTimer;

  SupersoRealtime(this.client);

  // ======================================
  // CONNECT
  // ======================================

  void connect(
    String channel, {
    RealtimeOptions? options,
  }) {
    _channel = channel;

    _token = options?.token;

    _reconnect =
        options?.reconnect ??
            true;

    _reconnectInterval =
        options
                ?.reconnectInterval ??
            3000;

    _maxRetries =
        options?.maxRetries ??
            10;

    _heartbeat =
        options?.heartbeat ??
            true;

    _heartbeatInterval =
        options
                ?.heartbeatInterval ??
            30000;

    final protocol =
        client.baseUrl.startsWith(
                "https")
            ? "wss"
            : "ws";

    final cleanBase =
        client.baseUrl
            .replaceAll(
              "https://",
              "",
            )
            .replaceAll(
              "http://",
              "",
            );

    String wsUrl =
        "$protocol://$cleanBase/ws/project/${client.projectId}/channel/$channel?key=${client.apiKey}";

    if (_token != null) {
      wsUrl +=
          "&token=$_token";
    }

    _socket =
        WebSocketChannel.connect(
      Uri.parse(wsUrl),
    );

    _socket!.stream.listen(
      (message) {
        try {
          final parsed =
              jsonDecode(
            message,
          );

          final event =
              RealtimeEvent
                  .fromJson(
            parsed,
          );

          final eventName =
              event.eventName ??
                  "message";

          if (eventName ==
              "pong") {
            return;
          }

          _emit(
            eventName,
            event,
          );

          _emit(
            "*",
            event,
          );
        } catch (error) {
          _emit(
            "error",
            error,
          );
        }
      },

      onDone: () {
        _stopHeartbeat();

        _emit(
          "disconnected",
          {
            "channel":
                _channel,
          },
        );

        if (_reconnect &&
            _retryCount <
                _maxRetries) {
          _retryCount++;

          Future.delayed(
            Duration(
              milliseconds:
                  _reconnectInterval,
            ),
            () {
              connect(
                _channel,
                options:
                    options,
              );
            },
          );
        }
      },

      onError: (error) {
        _emit(
          "error",
          error,
        );
      },
    );

    _retryCount = 0;

    _emit(
      "connected",
      {
        "channel":
            channel,
      },
    );

    if (_heartbeat) {
      _startHeartbeat();
    }
  }

  // ======================================
  // HEARTBEAT
  // ======================================

  void _startHeartbeat() {
    _stopHeartbeat();

    _heartbeatTimer =
        Timer.periodic(
      Duration(
        milliseconds:
            _heartbeatInterval,
      ),
      (_) {
        ping();
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ======================================
  // EVENTS
  // ======================================

  void _emit(
    String event,
    dynamic payload,
  ) {
    if (!_handlers.containsKey(
      event,
    )) {
      return;
    }

    for (final callback
        in _handlers[event]!) {
      callback(payload);
    }
  }

  void on(
    String event,
    Function callback,
  ) {
    _handlers.putIfAbsent(
      event,
      () => [],
    );

    _handlers[event]!
        .add(callback);
  }

  void off(
    String event, [
    Function? callback,
  ]) {
    if (!_handlers.containsKey(
      event,
    )) {
      return;
    }

    if (callback == null) {
      _handlers.remove(event);
      return;
    }

    _handlers[event]!
        .remove(callback);
  }

  // ======================================
  // SEND
  // ======================================

  void send(
    String event, [
    dynamic data,
  ]) {
    final payload = {
      "event": event,
      "data": data,
    };

    _socket?.sink.add(
      jsonEncode(payload),
    );
  }

  // ======================================
  // PING
  // ======================================

  void ping() {
    send("ping");
  }

  // ======================================
  // TOKEN REFRESH
  // ======================================

  void refreshToken(
    String refreshToken,
  ) {
    send(
      "token_refresh",
      {
        "refresh_token":
            refreshToken,
      },
    );
  }

  // ======================================
  // TYPING
  // ======================================

  void startTyping() {
    send(
      "typing",
      {
        "is_typing": true,
      },
    );
  }

  void stopTyping() {
    send(
      "typing",
      {
        "is_typing": false,
      },
    );
  }

  // ======================================
  // DISCONNECT
  // ======================================

  void disconnect() {
    _reconnect = false;

    _stopHeartbeat();

    _socket?.sink.close();

    _socket = null;
  }

  // ======================================
  // GETTERS
  // ======================================

  bool isConnected() {
    return _socket != null;
  }

  String getChannel() {
    return _channel;
  }
}

// ======================================
// COLLECTION SUBSCRIBE
// ======================================

void subscribeCollection(
  SupersoRealtime realtime,
  String collection, {
  RealtimeOptions? options,
}) {
  realtime.connect(
    "$collection-realtime",
    options: options,
  );
}

// ======================================
// LIVE QUERY
// ======================================

void liveQuery(
  SupersoRealtime realtime,
  Function callback,
) {
  realtime.on(
    "document_created",
    callback,
  );

  realtime.on(
    "document_updated",
    callback,
  );

  realtime.on(
    "document_deleted",
    callback,
  );
}

// ======================================
// PRESENCE
// ======================================

void subscribePresence(
  SupersoRealtime realtime,
  Function callback,
) {
  realtime.on(
    "user_presence",
    callback,
  );
}

// ======================================
// TYPING
// ======================================

void subscribeTyping(
  SupersoRealtime realtime,
  Function callback,
) {
  realtime.on(
    "typing",
    callback,
  );
}