import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/client.dart';

// ======================================
// STORAGE (TEMP MEMORY)
// ======================================

String? _accessToken;

String? _refreshToken;

Map<String, dynamic>? _currentUser;

// ======================================
// TYPES
// ======================================

class AuthResponse {
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final String? message;

  AuthResponse({
    this.token,
    this.refreshToken,
    this.user,
    this.message,
  });

  factory AuthResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthResponse(
      token:
          json["token"] ??
          json["data"]?["token"],

      refreshToken:
          json["refresh_token"] ??
          json["data"]?["refresh_token"],

      user:
          json["user"] ??
          json["data"]?["user"],

      message:
          json["message"],
    );
  }
}

// ======================================
// REQUEST
// ======================================

Future<Map<String, dynamic>> request(
  SupersoClient client,
  String endpoint, {
  String method = "GET",
  Map<String, dynamic>? body,
  bool auth = false,
}) async {
  final headers = {
    "Content-Type": "application/json",
    "X-Superso-Project-Key":
        client.apiKey,
  };

  if (
    auth &&
    _accessToken != null
  ) {
    headers["Authorization"] =
        "Bearer $_accessToken";
  }

  final uri = Uri.parse(
    "${client.baseUrl}/api/project/${client.projectId}$endpoint",
  );

  http.Response response;

  switch (method) {
    case "POST":
      response = await http.post(
        uri,
        headers: headers,
        body: body != null
            ? jsonEncode(body)
            : null,
      );
      break;

    case "PUT":
      response = await http.put(
        uri,
        headers: headers,
        body: body != null
            ? jsonEncode(body)
            : null,
      );
      break;

    case "PATCH":
      response = await http.patch(
        uri,
        headers: headers,
        body: body != null
            ? jsonEncode(body)
            : null,
      );
      break;

    case "DELETE":
      response = await http.delete(
        uri,
        headers: headers,
      );
      break;

    default:
      response = await http.get(
        uri,
        headers: headers,
      );
  }

  final data =
      jsonDecode(response.body);

if (response.statusCode >= 400) {
  throw Exception(
    data["message"] ??
        "Request failed",
  );
}

  return data;
}

// ======================================
// SAVE SESSION
// ======================================

void saveSession(
  AuthResponse response,
) {
  _accessToken =
      response.token;

  _refreshToken =
      response.refreshToken;

  _currentUser =
      response.user;
}

// ======================================
// GET SESSION
// ======================================

String? getAccessToken() {
  return _accessToken;
}

String? getRefreshToken() {
  return _refreshToken;
}

Map<String, dynamic>? getCurrentUserLocal() {
  return _currentUser;
}

// ======================================
// CLEAR SESSION
// ======================================

void clearSession() {
  _accessToken = null;
  _refreshToken = null;
  _currentUser = null;
}

// ======================================
// REGISTER
// ======================================

Future<AuthResponse> register(
  SupersoClient client, {
  required String email,
  required String password,
  String? displayName,
}) async {
  final result = await request(
    client,
    "/auth/register",
    method: "POST",
    body: {
      "email": email,
      "password": password,
      "display_name":
          displayName,
    },
  );

  final auth =
      AuthResponse.fromJson(
    result,
  );

  saveSession(auth);

  return auth;
}

// ======================================
// LOGIN
// ======================================

Future<AuthResponse> login(
  SupersoClient client, {
  required String email,
  required String password,
}) async {
  final result = await request(
    client,
    "/auth/login",
    method: "POST",
    body: {
      "email": email,
      "password": password,
    },
  );

  final auth =
      AuthResponse.fromJson(
    result,
  );

  saveSession(auth);

  return auth;
}

// ======================================
// LOGOUT
// ======================================

Future<void> logout(
  SupersoClient client,
) async {
  try {
    await request(
      client,
      "/auth/logout",
      method: "POST",
      auth: true,
    );
  } catch (_) {}

  clearSession();
}

// ======================================
// CURRENT USER
// ======================================

Future<Map<String, dynamic>>
    getCurrentUser(
  SupersoClient client,
) async {
  final result = await request(
    client,
    "/auth/user/me",
    auth: true,
  );

  return result;
}

// ======================================
// UPDATE PROFILE
// ======================================

Future<Map<String, dynamic>>
    updateProfile(
  SupersoClient client, {
  String? displayName,
  String? bio,
  String? avatarUrl,
}) async {
  final result = await request(
    client,
    "/auth/user/profile",
    method: "PUT",
    auth: true,
    body: {
      "display_name":
          displayName,
      "bio": bio,
      "avatar_url":
          avatarUrl,
    },
  );

  return result;
}

// ======================================
// CHANGE PASSWORD
// ======================================

Future<Map<String, dynamic>>
    changePassword(
  SupersoClient client, {
  required String
      currentPassword,
  required String
      newPassword,
}) async {
  return await request(
    client,
    "/auth/user/change-password",
    method: "POST",
    auth: true,
    body: {
      "current_password":
          currentPassword,
      "new_password":
          newPassword,
    },
  );
}

// ======================================
// VERIFY EMAIL OTP
// ======================================

Future<Map<String, dynamic>>
    verifyEmail(
  SupersoClient client, {
  required String email,
  required String otp,
}) async {
  return await request(
    client,
    "/auth/verify-email",
    method: "POST",
    body: {
      "email": email,
      "otp": otp,
    },
  );
}