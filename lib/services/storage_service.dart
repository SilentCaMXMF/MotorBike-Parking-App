/// Service for handling image uploads to Firebase Storage.
/// 
/// NOTE: This service is currently disabled in favor of API-based uploads.
/// To re-enable Firebase Storage:
/// 1. Add firebase_storage to pubspec.yaml dependencies
/// 2. Uncomment the imports and re-enable functionality
class StorageService {
  static StorageService? _instance;
  
  factory StorageService() {
    _instance ??= StorageService._internal();
    return _instance!;
  }
  
  StorageService._internal();

  bool _isInitialized = false;

  void _throwIfDisabled() {
    if (!_isInitialized) {
      throw Exception(
        'Firebase Storage is disabled. Using API-based uploads instead.\n'
        'To enable Firebase Storage: add firebase_storage to pubspec.yaml'
      );
    }
  }

  /// Uploads an image file to storage and returns the download URL.
  Future<String> uploadImage(dynamic imageFile, String userId, String filename) async {
    _throwIfDisabled();
    throw UnimplementedError('Firebase Storage is disabled');
  }

  /// Deletes an image from storage given its URL.
  Future<void> deleteImage(String imageUrl) async {
    _throwIfDisabled();
    throw UnimplementedError('Firebase Storage is disabled');
  }

  /// Initialize the service (call when re-enabling Firebase)
  static Future<void> initialize() async {
    _instance = StorageService._internal();
    _instance!._isInitialized = true;
  }
}
