import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../mocks.dart';

void main() {
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
  });

  group('StorageService', () {
    test('uploadImage success returns download URL', () async {
      const expectedUrl = 'https://example.com/image.jpg';
      mockStorageService.setupUploadSuccess(expectedUrl);

      final file = File('test_image.jpg');
      final result = await mockStorageService.uploadImage(file, 'user123', 'test.jpg');

      expect(result, expectedUrl);
      verify(mockStorageService.uploadImage(file, 'user123', 'test.jpg')).called(1);
    });

    test('uploadImage failure throws exception', () async {
      final exception = Exception('Upload failed');
      mockStorageService.setupUploadFailure(exception);

      final file = File('test_image.jpg');

      expect(
        () => mockStorageService.uploadImage(file, 'user123', 'test.jpg'),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteImage success completes without error', () async {
      mockStorageService.setupDeleteSuccess();

      await mockStorageService.deleteImage('https://example.com/image.jpg');

      verify(mockStorageService.deleteImage('https://example.com/image.jpg')).called(1);
    });
  });
}