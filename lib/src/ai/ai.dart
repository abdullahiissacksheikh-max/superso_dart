import 'dart:convert';

import 'package:http/http.dart'
    as http;

import '../core/client.dart';

// ======================================
// TYPES
// ======================================

class AIChatOptions {
  final String agent;
  final String message;
  final String? conversationId;
  final bool streaming;
  final double? temperature;
  final bool memory;
  final dynamic metadata;

  const AIChatOptions({
    required this.agent,
    required this.message,
    this.conversationId,
    this.streaming = false,
    this.temperature,
    this.memory = true,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      "agent": agent,
      "message": message,
      "conversation_id":
          conversationId,
      "streaming":
          streaming,
      "temperature":
          temperature,
      "memory": memory,
      "metadata":
          metadata,
    };
  }
}

class AIChatResponse {
  final String response;
  final int? tokensUsed;
  final String? model;
  final String? provider;
  final String? agent;
  final String? projectUid;

  AIChatResponse({
    required this.response,
    this.tokensUsed,
    this.model,
    this.provider,
    this.agent,
    this.projectUid,
  });

  factory AIChatResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return AIChatResponse(
      response:
          json["response"] ??
              "",
      tokensUsed:
          json["tokens_used"],
      model: json["model"],
      provider:
          json["provider"],
      agent: json["agent"],
      projectUid:
          json["project_uid"],
    );
  }
}

class AIProvider {
  final String? id;
  final String providerName;
  final String baseUrl;
  final String? apiKey;
  final String? organizationId;
  final dynamic headersJson;
  final int? priority;
  final bool? enabled;

  const AIProvider({
    this.id,
    required this.providerName,
    required this.baseUrl,
    this.apiKey,
    this.organizationId,
    this.headersJson,
    this.priority,
    this.enabled,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "provider_name":
          providerName,
      "base_url": baseUrl,
      "api_key": apiKey,
      "organization_id":
          organizationId,
      "headers_json":
          headersJson,
      "priority": priority,
      "enabled": enabled,
    };
  }
}

class AIModel {
  final String? id;
  final String providerId;
  final String modelName;
  final int? contextWindow;
  final double? inputCost;
  final double? outputCost;
  final bool? supportsVision;
  final bool? supportsTools;
  final bool?
      supportsStreaming;
  final bool? enabled;

  const AIModel({
    this.id,
    required this.providerId,
    required this.modelName,
    this.contextWindow,
    this.inputCost,
    this.outputCost,
    this.supportsVision,
    this.supportsTools,
    this.supportsStreaming,
    this.enabled,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "provider_id":
          providerId,
      "model_name":
          modelName,
      "context_window":
          contextWindow,
      "input_cost":
          inputCost,
      "output_cost":
          outputCost,
      "supports_vision":
          supportsVision,
      "supports_tools":
          supportsTools,
      "supports_streaming":
          supportsStreaming,
      "enabled": enabled,
    };
  }
}

class AIAgent {
  final String? id;
  final String agentName;
  final String? description;
  final String? systemPrompt;
  final String? providerId;
  final String? modelId;
  final double? temperature;
  final bool? memoryEnabled;
  final dynamic toolPermissions;
  final String? visibility;
  final int? rateLimit;
  final String? status;

  const AIAgent({
    this.id,
    required this.agentName,
    this.description,
    this.systemPrompt,
    this.providerId,
    this.modelId,
    this.temperature,
    this.memoryEnabled,
    this.toolPermissions,
    this.visibility,
    this.rateLimit,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "agent_name":
          agentName,
      "description":
          description,
      "system_prompt":
          systemPrompt,
      "provider_id":
          providerId,
      "model_id": modelId,
      "temperature":
          temperature,
      "memory_enabled":
          memoryEnabled,
      "tool_permissions":
          toolPermissions,
      "visibility":
          visibility,
      "rate_limit":
          rateLimit,
      "status": status,
    };
  }
}

// ======================================
// REQUEST
// ======================================

Future<dynamic> _request(
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
          "AI request failed",
    );
  }

  return data;
}

// ======================================
// CHAT
// ======================================

Future<AIChatResponse>
    aiChat(
  SupersoClient client,
  AIChatOptions options,
) async {
  final response =
      await _request(
    client,
    "/ai/chat",
    method: "POST",
    body: options.toJson(),
  );

  return AIChatResponse
      .fromJson(response);
}

// ======================================
// STREAM CHAT
// ======================================

Future<void> aiStreamChat(
  SupersoClient client,
  AIChatOptions options,
  Function(String chunk)
      onChunk,
) async {
  final uri = Uri.parse(
    "${client.baseUrl}/api/project/${client.projectId}/ai/chat",
  );

  final request =
      http.Request(
    "POST",
    uri,
  );

  request.headers.addAll({
    "Content-Type":
        "application/json",
    "X-Superso-Project-Key":
        client.apiKey,
  });

  request.body = jsonEncode({
    ...options.toJson(),
    "streaming": true,
  });

  final streamed =
      await request.send();

  streamed.stream
      .transform(utf8.decoder)
      .listen(
    (chunk) {
      onChunk(chunk);
    },
  );
}

// ======================================
// PROVIDERS
// ======================================

Future<dynamic>
    getAIProviders(
  SupersoClient client,
  String token,
) async {
  return _request(
    client,
    "/ai/providers",
    token: token,
  );
}

Future<dynamic>
    createAIProvider(
  SupersoClient client,
  AIProvider data,
  String token,
) async {
  return _request(
    client,
    "/ai/providers",
    method: "POST",
    body: data.toJson(),
    token: token,
  );
}

Future<dynamic>
    updateAIProvider(
  SupersoClient client,
  String providerId,
  Map<String, dynamic> data,
  String token,
) async {
  return _request(
    client,
    "/ai/providers/$providerId",
    method: "PUT",
    body: data,
    token: token,
  );
}

Future<dynamic>
    deleteAIProvider(
  SupersoClient client,
  String providerId,
  String token,
) async {
  return _request(
    client,
    "/ai/providers/$providerId",
    method: "DELETE",
    token: token,
  );
}

// ======================================
// MODELS
// ======================================

Future<dynamic> getAIModels(
  SupersoClient client,
  String token,
) async {
  return _request(
    client,
    "/ai/models",
    token: token,
  );
}

Future<dynamic> createAIModel(
  SupersoClient client,
  AIModel data,
  String token,
) async {
  return _request(
    client,
    "/ai/models",
    method: "POST",
    body: data.toJson(),
    token: token,
  );
}

Future<dynamic> updateAIModel(
  SupersoClient client,
  String modelId,
  Map<String, dynamic> data,
  String token,
) async {
  return _request(
    client,
    "/ai/models/$modelId",
    method: "PUT",
    body: data,
    token: token,
  );
}

Future<dynamic> deleteAIModel(
  SupersoClient client,
  String modelId,
  String token,
) async {
  return _request(
    client,
    "/ai/models/$modelId",
    method: "DELETE",
    token: token,
  );
}

// ======================================
// AGENTS
// ======================================

Future<dynamic> getAIAgents(
  SupersoClient client,
  String token,
) async {
  return _request(
    client,
    "/ai/agents",
    token: token,
  );
}

Future<dynamic> createAIAgent(
  SupersoClient client,
  AIAgent data,
  String token,
) async {
  return _request(
    client,
    "/ai/agents",
    method: "POST",
    body: data.toJson(),
    token: token,
  );
}

Future<dynamic> updateAIAgent(
  SupersoClient client,
  String agentId,
  Map<String, dynamic> data,
  String token,
) async {
  return _request(
    client,
    "/ai/agents/$agentId",
    method: "PUT",
    body: data,
    token: token,
  );
}

Future<dynamic> deleteAIAgent(
  SupersoClient client,
  String agentId,
  String token,
) async {
  return _request(
    client,
    "/ai/agents/$agentId",
    method: "DELETE",
    token: token,
  );
}

// ======================================
// SETTINGS
// ======================================

Future<dynamic>
    getAISettings(
  SupersoClient client,
  String token,
) async {
  return _request(
    client,
    "/ai/settings",
    token: token,
  );
}

Future<dynamic>
    updateAISettings(
  SupersoClient client,
  dynamic data,
  String token,
) async {
  return _request(
    client,
    "/ai/settings",
    method: "PUT",
    body: data,
    token: token,
  );
}

// ======================================
// HELPERS
// ======================================

int estimateTokens(
  String text,
) {
  return (text.length / 4)
      .ceil();
}

double estimateCost({
  required int inputTokens,
  required int outputTokens,
  required double inputCost,
  required double outputCost,
}) {
  return ((inputTokens /
                  1000000) *
              inputCost) +
          ((outputTokens /
                  1000000) *
              outputCost);
}

bool supportsVision(
  AIModel model,
) {
  return model
          .supportsVision ==
      true;
}

bool supportsTools(
  AIModel model,
) {
  return model
          .supportsTools ==
      true;
}

bool supportsStreaming(
  AIModel model,
) {
  return model
          .supportsStreaming ==
      true;
}