// Mock StorageService
import 'package:motorbike_parking_app/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {
  // Setup upload success
  void setupUploadSuccess(String expectedUrl) {
    when(this.uploadImage(any, any, any))
        .thenAnswer((_) async => expectedUrl);
  }

  // Setup upload failure
  void setupUploadFailure(Exception exception) {
    when(this.uploadImage(any, any, any))
        .thenThrow(exception);
  }

  // Setup delete success
  void setupDeleteSuccess() {
    when(this.deleteImage(any)).thenAnswer((_) async {});
  }
}