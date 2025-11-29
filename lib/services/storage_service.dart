import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
import 'logger_service.dart';

/// Service for handling image uploads to Firebase Storage.
// ============================================================================
// FIREBASE STORAGE SERVICE - COMMENTED OUT FOR API MIGRATION
// ============================================================================
// This service is preserved for potential scaling back to Firebase if the local
// Raspberry Pi backend reaches capacity limits.
//
// The app has been migrated to use a custom REST API backend with MariaDB
// instead of Firebase Storage. This service is kept in the project to enable
// quick rollback if needed.
//
// CURRENT STATUS: Inactive (commented out)
// MIGRATION DATE: November 2025
// REASON: Cost reduction and data ownership via local backend
// ============================================================================
/*
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
      LoggerService.error('Failed to delete image $imageUrl: $e', component: 'StorageService');
    }
  }
}
*/
