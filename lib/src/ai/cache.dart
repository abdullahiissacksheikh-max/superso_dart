import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String PREFIX =
    "superso_ai_";

// ======================================
// CACHE
// ======================================

Future<void> setAICache(
  String key,
  dynamic value,
) async {
  final prefs =
      await SharedPreferences
          .getInstance();

  await prefs.setString(
    PREFIX + key,
    jsonEncode(value),
  );
}

Future<dynamic> getAICache(
  String key,
) async {
  final prefs =
      await SharedPreferences
          .getInstance();

  final raw =
      prefs.getString(
    PREFIX + key,
  );

  if (raw == null) {
    return null;
  }

  try {
    return jsonDecode(raw);
  } catch (_) {
    return raw;
  }
}

Future<void> removeAICache(
  String key,
) async {
  final prefs =
      await SharedPreferences
          .getInstance();

  await prefs.remove(
    PREFIX + key,
  );
}

Future<void> clearAICache()
    async {
  final prefs =
      await SharedPreferences
          .getInstance();

  final keys =
      prefs.getKeys();

  for (final key in keys) {
    if (key.startsWith(
      PREFIX,
    )) {
      await prefs.remove(
        key,
      );
    }
  }
}