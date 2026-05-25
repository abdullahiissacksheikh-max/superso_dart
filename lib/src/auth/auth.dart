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

  AuthResponse({this.token, this.refreshToken, this.user, this.message});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json["token"] ?? json["data"]?["token"],

      refreshToken: json["refresh_token"] ?? json["data"]?["refresh_token"],

      user: json["user"] ?? json["data"]?["user"],

      message: json["message"],
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
    "X-Superso-Project-Key": client.apiKey,
  };

  if (auth && _accessToken != null) {
    headers["Authorization"] = "Bearer $_accessToken";
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
        body: body != null ? jsonEncode(body) : null,
      );
      break;

    case "PUT":
      response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      break;

    case "PATCH":
      response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      break;

    case "DELETE":
      response = await http.delete(uri, headers: headers);
      break;

    default:
      response = await http.get(uri, headers: headers);
  }

  final data = jsonDecode(response.body);

  if (response.statusCode >= 400) {
    throw Exception(data["message"] ?? "Request failed");
  }

  return data;
}

// ======================================
// SAVE SESSION
// ======================================

void saveSession(AuthResponse response) {
  _accessToken = response.token;

  _refreshToken = response.refreshToken;

  _currentUser = response.user;
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
  String? username,
  String? displayName,
  String? avatarUrl,
  String? bannerUrl,
  String? bio,
  String? website,
  String? location,
  String? gender,
  DateTime? dateOfBirth,
}) async {
  final body = <String, dynamic>{"email": email, "password": password};

  if (username != null) {
    body["username"] = username;
  }

  if (displayName != null) {
    body["display_name"] = displayName;
  }

  if (avatarUrl != null) {
    body["avatar_url"] = avatarUrl;
  }

  if (bannerUrl != null) {
    body["banner_url"] = bannerUrl;
  }

  if (bio != null) {
    body["bio"] = bio;
  }

  if (website != null) {
    body["website"] = website;
  }

  if (location != null) {
    body["location"] = location;
  }

  if (gender != null) {
    body["gender"] = gender;
  }

  if (dateOfBirth != null) {
    body["date_of_birth"] = dateOfBirth.toIso8601String();
  }

  final result = await request(
    client,
    "/auth/register",
    method: "POST",
    body: body,
  );

  final auth = AuthResponse.fromJson(result);

  saveSession(auth);

  return auth;
}

// ======================================
// LOGIN
// ======================================
Future<AuthResponse> login(
  SupersoClient client, {
  required String identifier,
  required String password,
}) async {
  final result = await request(
    client,
    "/auth/login",
    method: "POST",
    body: {"identifier": identifier, "password": password},
  );
  print("LOGIN RESPONSE: $result");

  final auth = AuthResponse.fromJson(result);

  saveSession(auth);

  return auth;
}

// ======================================
// LOGOUT
// ======================================

Future<void> logout(SupersoClient client) async {
  try {
    print("ACCESS TOKEN: $_accessToken");
    print("REFRESH TOKEN: $_refreshToken");

    // Only call backend if refresh token exists
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      final result = await request(
        client,
        "/auth/logout",
        method: "POST",
        auth: true,
        body: {"refresh_token": _refreshToken},
      );

      print("LOGOUT RESPONSE: $result");
    } else {
      print("No refresh token found");
    }
  } catch (e) {
    print("LOGOUT ERROR: $e");
  }

  // Always clear local session
  clearSession();

  print("Local session cleared");
}
// ======================================
// CURRENT USER
// ======================================

Future<Map<String, dynamic>> getCurrentUser(SupersoClient client) async {
  final result = await request(client, "/auth/user/me", auth: true);

  return result;
}

// ======================================
// UPDATE PROFILE
// ======================================
Future<Map<String, dynamic>> updateProfile(
  SupersoClient client, {
  String? displayName,
  String? username,
  String? avatarUrl,
  String? bannerUrl,
  String? bio,
  String? website,
  String? location,
  String? gender,
  DateTime? dateOfBirth,
}) async {
  final body = <String, dynamic>{};

  // ================================
  // DISPLAY NAME
  // ================================
  if (displayName != null && displayName.trim().isNotEmpty) {
    body["display_name"] = displayName.trim();
  }

  // ================================
  // USERNAME NORMALIZATION
  // ================================
  if (username != null && username.trim().isNotEmpty) {
    body["username"] = username.trim().toLowerCase().replaceAll(' ', '');
  }

  // ================================
  // AVATAR URL VALIDATION
  // ================================
  if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
    final normalizedAvatar = avatarUrl.trim();

    if (normalizedAvatar.startsWith('http://') ||
        normalizedAvatar.startsWith('https://')) {
      body["avatar_url"] = normalizedAvatar;
    }
  }

  // ================================
  // BANNER URL VALIDATION
  // ================================
  if (bannerUrl != null && bannerUrl.trim().isNotEmpty) {
    final normalizedBanner = bannerUrl.trim();

    if (normalizedBanner.startsWith('http://') ||
        normalizedBanner.startsWith('https://')) {
      body["banner_url"] = normalizedBanner;
    }
  }

  // ================================
  // BIO
  // ================================
  if (bio != null && bio.trim().isNotEmpty) {
    body["bio"] = bio.trim();
  }

  // ================================
  // WEBSITE VALIDATION
  // ================================
  if (website != null && website.trim().isNotEmpty) {
    final normalizedWebsite = website.trim();

    if (normalizedWebsite.startsWith('http://') ||
        normalizedWebsite.startsWith('https://')) {
      body["website"] = normalizedWebsite;
    }
  }

  // ================================
  // LOCATION
  // ================================
  if (location != null && location.trim().isNotEmpty) {
    body["location"] = location.trim();
  }

  // ================================
  // GENDER NORMALIZATION
  // ================================
  if (gender != null && gender.trim().isNotEmpty) {
    body["gender"] = gender.trim().toLowerCase();
  }

  // ================================
  // DATE OF BIRTH
  // Backend-friendly format:
  // YYYY-MM-DD
  // ================================
  if (dateOfBirth != null) {
    body["date_of_birth"] = dateOfBirth.toIso8601String().split("T").first;
  }

  // ================================
  // DEBUG LOGGING
  // ================================
  print("UpdateProfile body: $body");

  final result = await request(
    client,
    "/auth/user/profile",
    method: "PUT",
    auth: true,
    body: body,
  );

  return result;
}
// ======================================
// CHANGE PASSWORD
// ======================================

Future<Map<String, dynamic>> changePassword(
  SupersoClient client, {
  required String currentPassword,
  required String newPassword,
}) async {
  return await request(
    client,
    "/auth/user/change-password",
    method: "POST",
    auth: true,
    body: {"current_password": currentPassword, "new_password": newPassword},
  );
}

// ======================================
// VERIFY EMAIL OTP
// ======================================

Future<Map<String, dynamic>> verifyEmail(
  SupersoClient client, {
  required String email,
  required String otp,
}) async {
  return await request(
    client,
    "/auth/verify-email",
    method: "POST",
    body: {"email": email, "otp": otp},
  );
}

// ======================================
// Change Email
// ======================================

Future<Map<String, dynamic>> changeEmail(
  SupersoClient client, {
  required String newEmail,
  required String password,
}) async {
  return await request(
    client,
    "/auth/user/change-email",
    method: "POST",
    auth: true,
    body: {"new_email": newEmail, "current_password": password},
  );
}

// ======================================
// GET USER BY ID
// ======================================

Future<Map<String, dynamic>> getUserById(
  SupersoClient client,
  String userId,
) async {
  final response = await request(client, "/auth/user/$userId", auth: true);

  return response;
}

// ======================================
// GET USERS LIST
// ======================================

Future<Map<String, dynamic>> getUsers(
  SupersoClient client, {
  int page = 1,
  int limit = 20,
}) async {
  final response = await request(
    client,
    "/auth/users?page=$page&limit=$limit",
    auth: true,
  );

  return response;
}
