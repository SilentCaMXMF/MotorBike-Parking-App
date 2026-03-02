import 'package:flutter_test/flutter_test.dart';
import 'package:motorbike_parking_app/services/storage_service.dart';

void main() {
  late StorageService storageService;

  setUpAll(() async {
    await StorageService.initialize();
    storageService = StorageService();
  });

  group('StorageService', () {
    test('uploadImage throws because Firebase is disabled', () async {
      expect(
        () => storageService.uploadImage(null, 'user123', 'test.jpg'),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteImage throws because Firebase is disabled', () async {
      expect(
        () => storageService.deleteImage('https://example.com/image.jpg'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
