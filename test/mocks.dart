import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';

export './mocks/mock_auth_service.dart';
export './mocks/mock_firestore_service.dart';
export './mocks/mock_location_service.dart';
export './mocks/mock_notification_service.dart';
export './mocks/mock_storage_service.dart';
export './mocks/mock_sql_service.dart';

// Mock ImagePicker
class MockImagePicker extends Mock implements ImagePicker {}

// Mock XFile
class MockXFile extends Mock implements XFile {
  @override
  String get path => 'test_image.jpg';
}
