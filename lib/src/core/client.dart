class SupersoClientConfig {
  final String projectId;
  final String apiKey;
  final String? baseUrl;

  const SupersoClientConfig({
    required this.projectId,
    required this.apiKey,
    this.baseUrl,
  });
}

class SupersoClient {
  final String projectId;
  final String apiKey;
  final String baseUrl;

  SupersoClient(
    SupersoClientConfig config,
  )   : projectId = config.projectId,
        apiKey = config.apiKey,
        baseUrl =
            config.baseUrl ??
            "http://localhost:8080";
}

// initialize sdk

SupersoClient createClient(
  SupersoClientConfig config,
) {
  return SupersoClient(config);
}