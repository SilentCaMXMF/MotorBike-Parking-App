import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for handling image uploads to Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image file to Firebase Storage and returns the download URL.
  /// Uses a unique path: reports/{userId}/{timestamp}_{filename}
  Future<String> uploadImage(File imageFile, String userId, String filename) async {
    try {
      // Create unique path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'reports/$userId/${timestamp}_$filename';

      // Create reference
      final ref = _storage.ref().child(path);

      // Upload file
      final uploadTask = ref.putFile(imageFile);

      // Wait for completion
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Deletes an image from Firebase Storage given its URL.
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Log but don't throw - deletion failures are not critical
      print('Failed to delete image $imageUrl: $e');
    }
  }
}