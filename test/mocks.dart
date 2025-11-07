import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';

export './mock_auth_service.dart';
export './mock_firestore_service.dart';
export './mock_location_service.dart';
export './mock_notification_service.dart';
export './mock_storage_service.dart';

// Mock ImagePicker
class MockImagePicker extends Mock implements ImagePicker {}

// Mock XFile
class MockXFile extends Mock implements XFile {
  @override
  String get path => 'test_image.jpg';
}