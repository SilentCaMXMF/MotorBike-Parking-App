import 'package:motorbike_parking_app/services/storage_service.dart';

class MockStorageService implements StorageService {
  String? _uploadResponse;
  Exception? _uploadException;

  @override
  bool _isInitialized = true;

  void setupUploadSuccess(String url) {
    _uploadResponse = url;
    _uploadException = null;
  }

  void setupUploadFailure(Exception exception) {
    _uploadException = exception;
    _uploadResponse = null;
  }

  @override
  Future<String> uploadImage(dynamic imageFile, String userId, String filename) async {
    if (_uploadException != null) {
      throw _uploadException!;
    }
    return _uploadResponse ?? 'https://example.com/default.jpg';
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    // No-op for mock
  }

  @override
  static Future<void> initialize() async {
    // No-op for mock
  }
}
