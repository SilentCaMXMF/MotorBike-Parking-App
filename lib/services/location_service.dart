import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'logger_service.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    if (kIsWeb) {
      return _getWebLocation();
    }
    return _getMobileLocation();
  }

  Future<Position> _getWebLocation() async {
    try {
      LoggerService.debug('Getting web location...', component: 'LocationService');
      
      // Check if browser supports geolocation
      if (!kIsWeb) {
        throw Exception('Geolocation not supported on this platform');
      }
      
      LocationPermission? permission;
      try {
        permission = await Geolocator.checkPermission();
      } catch (e) {
        LoggerService.error('Error checking permission: $e', component: 'LocationService');
        // Try to request permission directly
        permission = await Geolocator.requestPermission();
      }
      
      LoggerService.debug('Web permission status: $permission', component: 'LocationService');
      
      if (permission == null || permission == LocationPermission.denied) {
        try {
          final requestedPermission = await Geolocator.requestPermission();
          LoggerService.debug('Web requested permission: $requestedPermission', component: 'LocationService');
          if (requestedPermission == LocationPermission.denied ||
              requestedPermission == LocationPermission.deniedForever) {
            throw Exception('Location permissions are denied. Please grant location permission to use this feature.');
          }
          permission = requestedPermission;
        } catch (e) {
          throw Exception('Location permissions are denied. Please grant location permission to use this feature.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in browser settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      LoggerService.debug('Web location obtained: ${position.latitude}, ${position.longitude}', component: 'LocationService');
      return position;
    } catch (e) {
      LoggerService.error('Web location error: $e', component: 'LocationService');
      if (e is LocationServiceDisabledException) {
        throw Exception('Location services are disabled. Please enable them to continue.');
      } else if (e is PermissionDeniedException) {
        throw Exception('Location permission denied. Please grant permission to access your location.');
      } else if (e is TimeoutException) {
        throw Exception('Location request timed out. Please try again.');
      } else {
        throw Exception('Unable to get current location: ${e.toString()}');
      }
    }
  }

  Future<Position> _getMobileLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services to continue.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please grant location permission to use this feature.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable location permissions in your device settings.');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      if (e is LocationServiceDisabledException) {
        throw Exception('Location services are disabled. Please enable them to continue.');
      } else if (e is PermissionDeniedException) {
        throw Exception('Location permission denied. Please grant permission to access your location.');
      } else if (e is TimeoutException) {
        throw Exception('Location request timed out. Please try again.');
      } else {
        throw Exception('Unable to get current location: ${e.toString()}');
      }
    }
  }
}