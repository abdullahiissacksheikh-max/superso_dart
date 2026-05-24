import 'dart:convert';

import 'package:http/http.dart'
    as http;

import '../core/client.dart';

// ======================================
// TOKEN
// ======================================

String? _notificationToken;

void setNotificationToken(
  String token,
) {
  _notificationToken = token;
}

// ======================================
// REQUEST
// ======================================

Future<Map<String, dynamic>>
    _request(
  SupersoClient client,
  String endpoint, {
  String method = "GET",
  dynamic body,
  bool auth = false,
}) async {
  final headers = {
    "Content-Type":
        "application/json",
    "X-Superso-Project-Key":
        client.apiKey,
  };

  if (
    auth &&
    _notificationToken != null
  ) {
    headers["Authorization"] =
        "Bearer $_notificationToken";
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

  if (response.statusCode >=
      400) {
    throw Exception(
      data["message"] ??
          "Notification request failed",
    );
  }

  return data;
}

// ======================================
// TYPES
// ======================================

enum NotificationType {
  inApp,
  email,
  push,
  sms,
}

String notificationTypeToString(
  NotificationType type,
) {
  switch (type) {
    case NotificationType.email:
      return "email";

    case NotificationType.push:
      return "push";

    case NotificationType.sms:
      return "sms";

    default:
      return "in_app";
  }
}

// ======================================
// SEND NOTIFICATION
// ======================================

Future<Map<String, dynamic>>
    sendNotification(
  SupersoClient client, {
  NotificationType type =
      NotificationType.inApp,
  String? subject,
  String? body,
  String? recipient,
  String? authUserId,
  String? userId,
  List<String>? userIds,
  bool broadcast = false,
  dynamic data,
  String? template,
  dynamic templateVars,
  String? scheduledAt,
  String? imageUrl,
  String? collection,
  String? realtimeChannel,
}) async {
  return await _request(
    client,
    "/notifications/send",
    method: "POST",
    body: {
      "type":
          notificationTypeToString(
        type,
      ),
      "subject": subject,
      "body": body,
      "recipient":
          recipient,
      "auth_user_id":
          authUserId,
      "user_id": userId,
      "user_ids":
          userIds,
      "broadcast":
          broadcast,
      "data": data,
      "template":
          template,
      "template_vars":
          templateVars,
      "scheduled_at":
          scheduledAt,
      "image_url":
          imageUrl,
      "collection":
          collection,
      "realtime_channel":
          realtimeChannel,
    },
  );
}

// ======================================
// SEND EMAIL
// ======================================

Future<Map<String, dynamic>>
    sendEmail(
  SupersoClient client, {
  required String recipient,
  required String subject,
  required String body,
  String? scheduledAt,
}) async {
  return await sendNotification(
    client,
    type:
        NotificationType.email,
    recipient: recipient,
    subject: subject,
    body: body,
    scheduledAt:
        scheduledAt,
  );
}

// ======================================
// SEND SMS
// ======================================

Future<Map<String, dynamic>>
    sendSMS(
  SupersoClient client, {
  required String recipient,
  required String body,
  String? scheduledAt,
}) async {
  return await sendNotification(
    client,
    type:
        NotificationType.sms,
    recipient: recipient,
    body: body,
    scheduledAt:
        scheduledAt,
  );
}

// ======================================
// SEND PUSH
// ======================================

Future<Map<String, dynamic>>
    sendPush(
  SupersoClient client, {
  required String userId,
  required String subject,
  required String body,
  String? imageUrl,
  dynamic data,
  String? scheduledAt,
}) async {
  return await sendNotification(
    client,
    type:
        NotificationType.push,
    userId: userId,
    subject: subject,
    body: body,
    imageUrl: imageUrl,
    data: data,
    scheduledAt:
        scheduledAt,
  );
}

// ======================================
// SEND IN APP
// ======================================

Future<Map<String, dynamic>>
    sendInApp(
  SupersoClient client, {
  required String subject,
  required String body,
  String? userId,
  List<String>? userIds,
  bool broadcast = false,
  dynamic data,
  String? imageUrl,
  required String collection,
  required String realtimeChannel,
}) async {
  return await sendNotification(
    client,
    type:
        NotificationType.inApp,
    subject: subject,
    body: body,
    userId: userId,
    userIds: userIds,
    broadcast:
        broadcast,
    data: data,
    imageUrl: imageUrl,
    collection:
        collection,
    realtimeChannel:
        realtimeChannel,
  );
}

// ======================================
// GET LOGS
// ======================================

Future<Map<String, dynamic>>
    getNotificationLogs(
  SupersoClient client,
) async {
  return await _request(
    client,
    "/notifications/logs",
  );
}

// ======================================
// GET IN APP
// ======================================

Future<Map<String, dynamic>>
    getInAppNotifications(
  SupersoClient client,
  String collection,
) async {
  return await _request(
    client,
    "/notifications/in-app?collection=$collection",
  );
}

// ======================================
// UNREAD COUNT
// ======================================

Future<Map<String, dynamic>>
    getUnreadCount(
  SupersoClient client,
  String collection,
) async {
  return await _request(
    client,
    "/notifications/in-app/unread-count?collection=$collection",
  );
}

// ======================================
// MARK READ
// ======================================

Future<Map<String, dynamic>>
    markNotificationRead(
  SupersoClient client,
  String notificationId,
  String collection,
  String realtimeChannel,
) async {
  return await _request(
    client,
    "/notifications/in-app/$notificationId/read?collection=$collection&realtime_channel=$realtimeChannel",
    method: "POST",
  );
}

// ======================================
// MARK ALL READ
// ======================================

Future<Map<String, dynamic>>
    markAllNotificationsRead(
  SupersoClient client,
  String collection,
  String realtimeChannel,
) async {
  return await _request(
    client,
    "/notifications/in-app/read-all?collection=$collection&realtime_channel=$realtimeChannel",
    method: "POST",
  );
}

// ======================================
// DELETE NOTIFICATION
// ======================================

Future<Map<String, dynamic>>
    deleteNotification(
  SupersoClient client,
  String notificationId,
  String collection,
  String realtimeChannel,
) async {
  return await _request(
    client,
    "/notifications/in-app/$notificationId?collection=$collection&realtime_channel=$realtimeChannel",
    method: "DELETE",
  );
}

// ======================================
// PREFERENCES
// ======================================

Future<Map<String, dynamic>>
    getNotificationPreferences(
  SupersoClient client,
) async {
  return await _request(
    client,
    "/notifications/preferences",
    auth: true,
  );
}

Future<Map<String, dynamic>>
    updateNotificationPreferences(
  SupersoClient client,
  Map<String, dynamic>
      preferences,
) async {
  return await _request(
    client,
    "/notifications/preferences",
    method: "PUT",
    body: preferences,
    auth: true,
  );
}

// ======================================
// DEVICES
// ======================================

Future<Map<String, dynamic>>
    registerDevice(
  SupersoClient client, {
  required String platform,
  required String token,
  String? appVersion,
  String? deviceName,
}) async {
  return await _request(
    client,
    "/notifications/devices",
    method: "POST",
    auth: true,
    body: {
      "platform":
          platform,
      "token": token,
      "app_version":
          appVersion,
      "device_name":
          deviceName,
    },
  );
}

Future<Map<String, dynamic>>
    getDevices(
  SupersoClient client,
) async {
  return await _request(
    client,
    "/notifications/devices",
    auth: true,
  );
}

Future<Map<String, dynamic>>
    deleteDevice(
  SupersoClient client,
  String tokenId,
) async {
  return await _request(
    client,
    "/notifications/devices/$tokenId",
    method: "DELETE",
    auth: true,
  );
}