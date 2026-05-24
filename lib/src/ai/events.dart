typedef AIEventCallback =
    Function(dynamic payload);

final Map<
    String,
    List<AIEventCallback>> listeners = {};

// ======================================
// ON EVENT
// ======================================

void onAIEvent(
  String event,
  AIEventCallback callback,
) {
  if (!listeners.containsKey(
    event,
  )) {
    listeners[event] = [];
  }

  listeners[event]!
      .add(callback);
}

// ======================================
// EMIT EVENT
// ======================================

void emitAIEvent(
  String event,
  dynamic payload,
) {
  if (!listeners.containsKey(
    event,
  )) {
    return;
  }

  for (final callback
      in listeners[event]!) {
    callback(payload);
  }
}

// ======================================
// REMOVE EVENT
// ======================================

void removeAIEvent(
  String event,
) {
  listeners.remove(event);
}

// ======================================
// REMOVE SINGLE LISTENER
// ======================================

void removeAIListener(
  String event,
  AIEventCallback callback,
) {
  if (!listeners.containsKey(
    event,
  )) {
    return;
  }

  listeners[event]!
      .remove(callback);
}

// ======================================
// CLEAR EVENTS
// ======================================

void clearAIEvents() {
  listeners.clear();
}