import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/sql_service.dart';
import '../services/location_service.dart';
import '../services/logger_service.dart';
import '../models/models.dart';

class ReportingDialog extends StatefulWidget {
  final ParkingZone zone;
  final SqlService? sqlService;
  final LocationService? locationService;
  final ImagePicker? imagePicker;

  const ReportingDialog({
    super.key,
    required this.zone,
    this.sqlService,
    this.locationService,
    this.imagePicker,
  });

  @override
  State<ReportingDialog> createState() => _ReportingDialogState();
}

class _ReportingDialogState extends State<ReportingDialog> {
  late final SqlService _sqlService;
  late final LocationService _locationService;
  late final ImagePicker _imagePicker;

  double _currentCount = 0;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String? _error;
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    LoggerService.debug(
      'ReportingDialog initialized for zone: ${widget.zone.id}',
      component: 'ReportingDialog',
    );
    _sqlService = widget.sqlService ?? SqlService();
    _locationService = widget.locationService ?? LocationService();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _currentCount = widget.zone.currentOccupancy.toDouble();
  }

  Future<void> _pickImage() async {
    try {
      LoggerService.debug('Opening camera for image capture',
          component: 'ReportingDialog');
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        LoggerService.info(
          'Image captured: ${image.path}',
          component: 'ReportingDialog',
        );
        setState(() {
          _selectedImages.add(image);
        });
      } else {
        LoggerService.debug('Image capture cancelled',
            component: 'ReportingDialog');
      }
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to pick image',
        error: e,
        stackTrace: stackTrace,
        component: 'ReportingDialog',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  void _removeImage(int index) {
    LoggerService.debug('Removing image at index $index',
        component: 'ReportingDialog');
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    // Validation
    final reportedCount = _currentCount.toInt();
    if (reportedCount < 0 || reportedCount > widget.zone.totalCapacity) {
      LoggerService.warning(
        'Invalid reported count: $reportedCount (capacity: ${widget.zone.totalCapacity})',
        component: 'ReportingDialog',
      );
      setState(() {
        _error =
            'Reported count must be between 0 and ${widget.zone.totalCapacity}';
      });
      return;
    }

    // Image validation
    if (_selectedImages.isNotEmpty) {
      final extension =
          _selectedImages.first.path.split('.').last.toLowerCase();
      const allowedExtensions = ['jpg', 'jpeg', 'png'];
      if (!allowedExtensions.contains(extension)) {
        LoggerService.warning(
          'Invalid image extension: $extension',
          component: 'ReportingDialog',
        );
        setState(() {
          _error = 'Only JPG, JPEG, and PNG images are allowed';
        });
        return;
      }
    }

    LoggerService.info(
      'Submitting report for zone ${widget.zone.id} with count: $reportedCount',
      component: 'ReportingDialog',
    );

    setState(() {
      _isSubmitting = true;
      _error = null;
      _uploadProgress = 0.0;
    });

    try {
      // Get current location
      Position? position;
      try {
        position = await _locationService.getCurrentLocation();
        LoggerService.debug(
          'Location obtained for report: ${position.latitude}, ${position.longitude}',
          component: 'ReportingDialog',
        );
      } catch (e, stackTrace) {
        LoggerService.warning(
          'Failed to get location for report, continuing without it',
          component: 'ReportingDialog',
        );
        // Continue without location
      }

      // Create report
      final report = UserReport(
        spotId: widget.zone.id,
        userId: 'current_user', // Will be set by API from JWT token
        reportedCount: reportedCount,
        timestamp: DateTime.now(),
        userLatitude: position?.latitude,
        userLongitude: position?.longitude,
      );

      // Submit report to get report ID
      LoggerService.debug('Submitting report to API',
          component: 'ReportingDialog');
      final reportId = await _sqlService.addUserReport(report);
      LoggerService.info(
        'Report submitted successfully with ID: $reportId',
        component: 'ReportingDialog',
      );

      // Upload image if selected
      if (_selectedImages.isNotEmpty) {
        LoggerService.debug(
          'Uploading image for report $reportId',
          component: 'ReportingDialog',
        );
        final file = File(_selectedImages.first.path);
        await _sqlService.uploadImage(
          file,
          reportId,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );
        LoggerService.info(
          'Image uploaded successfully for report $reportId',
          component: 'ReportingDialog',
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Report submitted successfully!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_selectedImages.isNotEmpty)
                        const Text(
                          'Photo uploaded',
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      LoggerService.error(
        'Failed to submit report',
        error: e,
        stackTrace: stackTrace,
        component: 'ReportingDialog',
      );
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _retrySubmit() {
    LoggerService.info('Retrying report submission',
        component: 'ReportingDialog');
    setState(() {
      _error = null;
    });
    _submitReport();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Parking Availability'),
      content: SingleChildScrollView(
        child: Column(
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
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _currentCount = value),
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
              onPressed: _isSubmitting ? null : _pickImage,
              icon: const Icon(Icons.camera),
              label: const Text('Add Photo'),
            ),
            if (_isSubmitting && _uploadProgress > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text('Uploading: ${(_uploadProgress * 100).toInt()}%'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _retrySubmit,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
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
