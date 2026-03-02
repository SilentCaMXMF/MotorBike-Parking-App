import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';

export './mocks/mocks.mocks.dart';

// Mock ImagePicker
class MockImagePicker extends Mock implements ImagePicker {}

// Mock XFile
class MockXFile extends Mock implements XFile {
  @override
  String get path => 'test_image.jpg';
}
