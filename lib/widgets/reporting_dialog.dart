import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../models/models.dart';

class ReportingDialog extends StatefulWidget {
  final ParkingZone zone;

  const ReportingDialog({super.key, required this.zone});

  @override
  State<ReportingDialog> createState() => _ReportingDialogState();
}

class _ReportingDialogState extends State<ReportingDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  double _currentCount = 0;
  bool _isLoading = false;
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _currentCount = widget.zone.currentOccupancy.toDouble();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }



  Future<void> _submitReport() async {
    // Validation
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to submit a report')),
      );
      return;
    }

    final reportedCount = _currentCount.toInt();
    if (reportedCount < 0 || reportedCount > widget.zone.totalCapacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reported count must be between 0 and ${widget.zone.totalCapacity}')),
      );
      return;
    }

    // Image validation
    if (_selectedImage != null) {
      final file = File(_selectedImage!.path);
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image file size must be less than 5MB')),
        );
        return;
      }
      final allowedExtensions = ['jpg', 'jpeg', 'png'];
      final extension = _selectedImage!.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only JPG, JPEG, and PNG images are allowed')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to submit a report')),
        );
        return;
      }

      final reportedCount = _currentCount.toInt();
      if (reportedCount < 0 || reportedCount > widget.zone.totalCapacity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reported count must be between 0 and ${widget.zone.totalCapacity}')),
        );
        return;
      }

      // Image validation
      List<String> imageUrls = [];
      for (final image in _selectedImages) {
        final file = File(image.path);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) { // 5MB limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image file size must be less than 5MB')),
          );
          return;
        }
        final allowedExtensions = ['jpg', 'jpeg', 'png'];
        final extension = image.path.split('.').last.toLowerCase();
        if (!allowedExtensions.contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only JPG, JPEG, and PNG images are allowed')),
          );
          return;
        }
      }

      // Upload images
      for (final image in _selectedImages) {
        try {
          final filename = image.path.split('/').last;
          final imageUrl = await _storageService.uploadImage(File(image.path), user.uid, filename);
          imageUrls.add(imageUrl);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
          return;
        }
      }

      Position? position;
      try {
        position = await _locationService.getCurrentLocation();
      } catch (e) {
        // Continue without location
      }

      final report = UserReport(
        spotId: widget.zone.id,
        userId: user.uid,
        reportedCount: _currentCount.toInt(),
        timestamp: DateTime.now(),
        userLatitude: position?.latitude,
        userLongitude: position?.longitude,
        imageUrls: imageUrls,
      );

      // Add report to Firestore
      await _firestoreService.addUserReport(report);

      final report = UserReport(
        spotId: widget.zone.id,
        userId: user.uid,
        reportedCount: _currentCount.toInt(),
        timestamp: DateTime.now(),
        userLatitude: position?.latitude,
        userLongitude: position?.longitude,
      );

      // Add report first to get the document ID
      final docRef = await _firestoreService.addUserReport(report);

      // Upload image if selected
      if (_selectedImage != null) {
        final imageUrl = await _uploadImage(docRef.id);
        if (imageUrl != null) {
          // Update report with image URL (you might need to modify the model/service)
          // For now, just log success
          print('Image uploaded: $imageUrl');
        }
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Parking Availability'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Zone: ${widget.zone.id}'),
          Text('Capacity: ${widget.zone.totalCapacity}'),
          const SizedBox(height: 16),
          Text('Current bike count: ${_currentCount.toInt()}'),
          Slider(
            value: _currentCount,
            min: 0,
            max: widget.zone.totalCapacity.toDouble(),
            divisions: widget.zone.totalCapacity,
            label: _currentCount.toInt().toString(),
            onChanged: (value) => setState(() => _currentCount = value),
          ),
           const SizedBox(height: 16),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            else
              const Text('No photos selected'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera),
              label: const Text('Add Photo'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReport,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}