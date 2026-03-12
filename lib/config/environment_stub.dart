// Stub for flutter_dotenv on web platform
// This file is used when building for web to avoid loading .env files

class DotEnvStub {
  Map<String, String?> get env => {};
  
  Future<void> load({String? fileName, bool? fromCache}) async {
    // Do nothing on web - we use hardcoded values instead
  }
}

final dotenv = DotEnvStub();
