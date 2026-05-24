import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart'
    as http;

import '../core/client.dart';

// ======================================
// TYPES
// ======================================

class UploadOptions {
  final String? path;
  final String? altText;
  final String? caption;
  final String? token;

  const UploadOptions({
    this.path,
    this.altText,
    this.caption,
    this.token,
  });
}

class StorageAsset {
  final String id;
  final String? url;
  final String? secureUrl;
  final String? publicId;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final String? provider;
  final String? folder;
  final String? altText;
  final String? caption;
  final dynamic metadata;
  final String? createdAt;

  StorageAsset({
    required this.id,
    this.url,
    this.secureUrl,
    this.publicId,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.width,
    this.height,
    this.provider,
    this.folder,
    this.altText,
    this.caption,
    this.metadata,
    this.createdAt,
  });

  factory StorageAsset.fromJson(
    Map<String, dynamic> json,
  ) {
    return StorageAsset(
      id: json["id"],
      url: json["url"],
      secureUrl:
          json["secure_url"],
      publicId:
          json["public_id"],
      fileName:
          json["file_name"],
      mimeType:
          json["mime_type"],
      sizeBytes:
          json["size_bytes"],
      width: json["width"],
      height:
          json["height"],
      provider:
          json["provider"],
      folder:
          json["folder"],
      altText:
          json["alt_text"],
      caption:
          json["caption"],
      metadata:
          json["metadata"],
      createdAt:
          json["created_at"],
    );
  }
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
  String? token,
}) async {
  final headers = {
    "Content-Type":
        "application/json",
    "X-Superso-Project-Key":
        client.apiKey,
  };

  if (token != null) {
    headers["Authorization"] =
        "Bearer $token";
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
          "Storage request failed",
    );
  }

  return data;
}

// ======================================
// UPLOAD FILE
// ======================================

Future<Map<String, dynamic>>
    uploadFile(
  SupersoClient client,
  File file, {
  UploadOptions? options,
}) async {
  validateFile(file);

  final uri = Uri.parse(
    "${client.baseUrl}/api/project/${client.projectId}/storage/upload",
  );

  final request =
      http.MultipartRequest(
    "POST",
    uri,
  );

  request.headers[
          "X-Superso-Project-Key"] =
      client.apiKey;

  if (options?.token !=
      null) {
    request.headers[
            "Authorization"] =
        "Bearer ${options!.token}";
  }

  request.files.add(
    await http.MultipartFile
        .fromPath(
      "file",
      file.path,
    ),
  );

  if (options?.path !=
      null) {
    request.fields["path"] =
        options!.path!;
  }

  if (options?.altText !=
      null) {
    request.fields[
            "alt_text"] =
        options!.altText!;
  }

  if (options?.caption !=
      null) {
    request.fields[
            "caption"] =
        options!.caption!;
  }

  final response =
      await request.send();

  final body =
      await response.stream
          .bytesToString();

  final data =
      jsonDecode(body);

  if (response.statusCode >=
      400) {
    throw Exception(
      data["message"] ??
          "Upload failed",
    );
  }

  return data;
}

// ======================================
// UPLOAD MULTIPLE
// ======================================

Future<List<dynamic>>
    uploadFiles(
  SupersoClient client,
  List<File> files, {
  UploadOptions? options,
}) async {
  return Future.wait(
    files.map(
      (file) => uploadFile(
        client,
        file,
        options: options,
      ),
    ),
  );
}

// ======================================
// LIST ASSETS
// ======================================

Future<Map<String, dynamic>>
    listAssets(
  SupersoClient client, {
  String? token,
}) async {
  return await _request(
    client,
    "/storage/assets",
    token: token,
  );
}

// ======================================
// GET ASSET
// ======================================

Future<Map<String, dynamic>>
    getAsset(
  SupersoClient client,
  String assetId, {
  String? token,
}) async {
  return await _request(
    client,
    "/storage/assets/$assetId",
    token: token,
  );
}

// ======================================
// DELETE ASSET
// ======================================

Future<Map<String, dynamic>>
    deleteAsset(
  SupersoClient client,
  String assetId, {
  String? token,
}) async {
  return await _request(
    client,
    "/storage/assets/$assetId",
    method: "DELETE",
    token: token,
  );
}

// ======================================
// STORAGE USAGE
// ======================================

Future<Map<String, dynamic>>
    getStorageUsage(
  SupersoClient client, {
  String? token,
}) async {
  return await _request(
    client,
    "/storage/usage",
    token: token,
  );
}

// ======================================
// FILE HELPERS
// ======================================

String? getFileExtension(
  String fileName,
) {
  final parts =
      fileName.split(".");

  if (parts.length < 2) {
    return null;
  }

  return parts.last
      .toLowerCase();
}

String formatBytes(
  int bytes, [
  int decimals = 2,
]) {
  if (bytes <= 0) {
    return "0 Bytes";
  }

  const sizes = [
    "Bytes",
    "KB",
    "MB",
    "GB",
    "TB",
  ];

  double size =
      bytes.toDouble();

  int index = 0;

  while (
      size >= 1024 &&
      index <
          sizes.length -
              1) {
    size /= 1024;
    index++;
  }

  return "${size.toStringAsFixed(decimals)} ${sizes[index]}";
}

// ======================================
// MIME HELPERS
// ======================================

bool isImage(
  String mimeType,
) {
  return mimeType.startsWith(
    "image/",
  );
}

bool isVideo(
  String mimeType,
) {
  return mimeType.startsWith(
    "video/",
  );
}

bool isAudio(
  String mimeType,
) {
  return mimeType.startsWith(
    "audio/",
  );
}

bool isPDF(
  String mimeType,
) {
  return mimeType ==
      "application/pdf";
}

// ======================================
// VALIDATION
// ======================================

bool validateFile(
  File file,
) {
  if (!file.existsSync()) {
    throw Exception(
      "File not found",
    );
  }

  final size =
      file.lengthSync();

  if (size <= 0) {
    throw Exception(
      "Invalid file",
    );
  }

  return true;
}

// ======================================
// IMAGE HELPERS
// ======================================

String optimizeImage(
  String url,
) {
  return url.replaceFirst(
    "/upload/",
    "/upload/q_auto/",
  );
}

String convertToWebP(
  String url,
) {
  return url.replaceFirst(
    "/upload/",
    "/upload/f_webp/",
  );
}

String resizeImage(
  String url,
  int width, [
  int? height,
]) {
  final transform =
      height != null
          ? "w_${width},h_${height},c_fill"
          : "w_$width";

  return url.replaceFirst(
    "/upload/",
    "/upload/$transform/",
  );
}

String thumbnail(
  String url, [
  int size = 150,
]) {
  return url.replaceFirst(
    "/upload/",
    "/upload/w_${size},h_${size},c_thumb/",
  );
}

String cropImage(
  String url,
  int width,
  int height,
) {
  return url.replaceFirst(
    "/upload/",
    "/upload/w_${width},h_${height},c_crop/",
  );
}

// ======================================
// URL HELPERS
// ======================================

String getSecureUrl(
  StorageAsset asset,
) {
  return asset.secureUrl ??
      asset.url ??
      "";
}

String getPublicUrl(
  StorageAsset asset,
) {
  return asset.url ?? "";
}