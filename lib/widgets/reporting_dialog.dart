import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  double _currentCount = 0;
  bool _isLoading = false;
  XFile? _selectedImage;

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
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage(String reportId) async {
    if (_selectedImage == null) return null;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('reports')
          .child('$reportId.jpg');

      await ref.putFile(File(_selectedImage!.path));
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
           if (_selectedImage != null)
             Container(
               height: 100,
               width: 100,
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Image.file(
                 File(_selectedImage!.path),
                 fit: BoxFit.cover,
               ),
             )
           else
             const Text('No photo selected'),
           const SizedBox(height: 8),
           ElevatedButton.icon(
             onPressed: _pickImage,
             icon: const Icon(Icons.camera),
             label: const Text('Take Photo'),
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