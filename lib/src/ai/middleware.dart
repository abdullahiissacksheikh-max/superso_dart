final Map<
    String,
    List<int>> requests = {};

// ======================================
// RATE LIMIT
// ======================================

bool rateLimit(
  String key, {
  int limit = 60,
  int windowMs = 60000,
}) {
  final now =
      DateTime.now()
          .millisecondsSinceEpoch;

  if (!requests.containsKey(
    key,
  )) {
    requests[key] = [];
  }

  requests[key] =
      requests[key]!
          .where(
            (timestamp) =>
                now -
                    timestamp <
                windowMs,
          )
          .toList();

  if (requests[key]!
          .length >=
      limit) {
    throw Exception(
      "Rate limit exceeded",
    );
  }

  requests[key]!.add(now);

  return true;
}

// ======================================
// REQUIRE AUTH
// ======================================

bool requireAuth(
  String? token,
) {
  if (token == null ||
      token.isEmpty) {
    throw Exception(
      "Authentication required",
    );
  }

  return true;
}

// ======================================
// REQUIRE ROLE
// ======================================

bool requireRole(
  String userRole,
  List<String> allowed,
) {
  if (!allowed.contains(
    userRole,
  )) {
    throw Exception(
      "Permission denied",
    );
  }

  return true;
}

// ======================================
// REQUIRE VERIFIED
// ======================================

bool requireVerified(
  bool verified,
) {
  if (!verified) {
    throw Exception(
      "Email verification required",
    );
  }

  return true;
}

// ======================================
// REQUIRE OWNER
// ======================================

bool requireOwner(
  String ownerId,
  String currentUserId,
) {
  if (ownerId !=
      currentUserId) {
    throw Exception(
      "Access denied",
    );
  }

  return true;
}

// ======================================
// VALIDATE INPUT
// ======================================

bool validateInput(
  dynamic value,
  String fieldName,
) {
  if (value == null) {
    throw Exception(
      "$fieldName is required",
    );
  }

  if (value is String &&
      value.trim().isEmpty) {
    throw Exception(
      "$fieldName is required",
    );
  }

  return true;
}

// ======================================
// SANITIZE STRING
// ======================================

String sanitizeString(
  String value,
) {
  return value.trim();
}

// ======================================
// EMAIL VALIDATION
// ======================================

bool validateEmail(
  String email,
) {
  final regex = RegExp(
    r'^[^@]+@[^@]+\.[^@]+',
  );

  if (!regex.hasMatch(
    email,
  )) {
    throw Exception(
      "Invalid email address",
    );
  }

  return true;
}

// ======================================
// PASSWORD VALIDATION
// ======================================

bool validatePassword(
  String password,
) {
  if (password.length <
      6) {
    throw Exception(
      "Password must be at least 6 characters",
    );
  }

  return true;
}