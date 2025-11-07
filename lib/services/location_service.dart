import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
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