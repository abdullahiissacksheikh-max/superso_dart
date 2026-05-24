import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/client.dart';

// =====================================
// TOKEN
// =====================================

String? _databaseAccessToken;

void setDatabaseToken(String token) {
  _databaseAccessToken = token;
}

// =====================================
// REQUEST
// =====================================

Future<Map<String, dynamic>> _request(
  SupersoClient client,
  String endpoint, {
  String method = "GET",
  dynamic body,
  bool auth = false,
}) async {
  final headers = {
    "Content-Type": "application/json",
    "X-Superso-Project-Key": client.apiKey,
  };

  if (auth && _databaseAccessToken != null) {
    headers["Authorization"] = "Bearer $_databaseAccessToken";
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
      response = await http.delete(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      break;

    default:
      response = await http.get(uri, headers: headers);
  }

  final data = jsonDecode(response.body);

  if (response.statusCode >= 400) {
    throw Exception(data["message"] ?? "Database request failed");
  }

  return data;
}

// =====================================
// QUERY OPTIONS
// =====================================

class QueryOptions {
  final int? limit;
  final int? offset;
  final String? sort;
  final String? order;
  final Map<String, dynamic>? filters;

  QueryOptions({this.limit, this.offset, this.sort, this.order, this.filters});
}

// =====================================
// BUILD QUERY
// =====================================

String buildQuery(QueryOptions? query) {
  if (query == null) {
    return "";
  }

  final params = <String, String>{};

  if (query.limit != null) {
    params["limit"] = query.limit.toString();
  }

  if (query.offset != null) {
    params["offset"] = query.offset.toString();
  }

  if (query.sort != null) {
    params["sort"] = query.sort!;
  }

  if (query.order != null) {
    params["order"] = query.order!;
  }

  query.filters?.forEach((key, value) {
    params[key] = value.toString();
  });

  if (params.isEmpty) {
    return "";
  }

  return "?${Uri(queryParameters: params).query}";
}

// =====================================
// CREATE DOCUMENT
// =====================================

Future<Map<String, dynamic>> createDocument(
  SupersoClient client,
  String collection,
  Map<String, dynamic> data, {
  bool auth = false,
}) async {
  return await _request(
    client,
    "/db/$collection",
    method: "POST",
    body: data,
    auth: auth,
  );
}

// =====================================
// GET DOCUMENTS
// =====================================

Future<Map<String, dynamic>> getDocuments(
  SupersoClient client,
  String collection, {
  QueryOptions? query,
  bool auth = false,
}) async {
  return await _request(
    client,
    "/db/$collection${buildQuery(query)}",
    auth: auth,
  );
}

// =====================================
// GET DOCUMENT
// =====================================

Future<Map<String, dynamic>> getDocument(
  SupersoClient client,
  String collection,
  String documentId, {
  bool auth = false,
}) async {
  return await _request(client, "/db/$collection/$documentId", auth: auth);
}

// =====================================
// UPDATE DOCUMENT
// =====================================

Future<Map<String, dynamic>> updateDocument(
  SupersoClient client,
  String collection,
  String documentId,
  Map<String, dynamic> data, {
  bool auth = false,
}) async {
  return await _request(
    client,
    "/db/$collection/$documentId",
    method: "PATCH",
    body: data,
    auth: auth,
  );
}

// =====================================
// REPLACE DOCUMENT
// =====================================

Future<Map<String, dynamic>> replaceDocument(
  SupersoClient client,
  String collection,
  String documentId,
  Map<String, dynamic> data, {
  bool auth = false,
}) async {
  return await _request(
    client,
    "/db/$collection/$documentId",
    method: "PUT",
    body: data,
    auth: auth,
  );
}

// =====================================
// DELETE DOCUMENT
// =====================================

Future<Map<String, dynamic>> deleteDocument(
  SupersoClient client,
  String collection,
  String documentId, {
  bool auth = false,
}) async {
  return await _request(
    client,
    "/db/$collection/$documentId",
    method: "DELETE",
    auth: auth,
  );
}

// =====================================
// QUERY DOCUMENTS
// =====================================

Future<Map<String, dynamic>> queryDocuments(
  SupersoClient client,
  String collection,
  Map<String, dynamic> query, {
  bool auth = false,
}) async {
  return await _request(
    client,
    "/db/$collection/query",
    method: "POST",
    body: query,
    auth: auth,
  );
}

// =====================================
// COUNT DOCUMENTS
// =====================================

Future<Map<String, dynamic>> countDocuments(
  SupersoClient client,
  String collection, {
  QueryOptions? query,
  bool auth = false,
}) async {
  return await _request(
    client,
    "/db/$collection/count${buildQuery(query)}",
    auth: auth,
  );
}

// =====================================
// EXISTS DOCUMENT
// =====================================

Future<bool> existsDocument(
  SupersoClient client,
  String collection,
  String documentId, {
  bool auth = false,
}) async {
  final headers = {"X-Superso-Project-Key": client.apiKey};

  if (auth && _databaseAccessToken != null) {
    headers["Authorization"] = "Bearer $_databaseAccessToken";
  }

  final response = await http.head(
    Uri.parse(
      "${client.baseUrl}/api/project/${client.projectId}/db/$collection/$documentId/exists",
    ),
    headers: headers,
  );

  return response.statusCode == 200;
}

// =====================================
// BULK CREATE
// =====================================

Future<Map<String, dynamic>> bulkCreate(
  SupersoClient client,
  String collection,
  List<dynamic> documents, {
  bool auth = false,
}) async {
  return await _request(
    client,
    "/db/$collection/bulk-insert",
    method: "POST",
    body: {"documents": documents},
    auth: auth,
  );
}

// =====================================
// BULK DELETE
// =====================================

Future<Map<String, dynamic>> bulkDelete(
  SupersoClient client,
  String collection,
  List<String> ids, {
  bool auth = false,
}) async {
  return await _request(
    client,
    "/db/$collection/bulk-delete",
    method: "DELETE",
    body: {"ids": ids},
    auth: auth,
  );
}

// =====================================
// SEARCH DOCUMENTS
// =====================================

Future<Map<String, dynamic>> searchDocuments(
  SupersoClient client,
  String collection,
  String search, {
  bool auth = false,
}) async {
  return await queryDocuments(client, collection, {
    "search": search,
  }, auth: auth);
}
