# Superso Dart SDK

Official Dart SDK for Superso Backend.

## Install

```bash
dart pub add superso_dart
Initialize
import 'package:superso_dart/superso_dart.dart';

final client = createClient(
  SupersoClientConfig(
    projectId: "YOUR_PROJECT_ID",
    apiKey: "YOUR_API_KEY",
    baseUrl: "http://localhost:8080",
  ),
);
Auth
final result = await loginUser(
  client,
  email: "test@gmail.com",
  password: "123456",
);
Database
await createDocument(
  client,
  "posts",
  {
    "title": "Hello"
  },
);

---

# 3. LICENSE

`LICENSE` file:

```txt
MIT License