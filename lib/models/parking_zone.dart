/// Represents a parking zone with capacity, occupancy, and confidence data.
import 'package:geolocator/geolocator.dart';
import 'package:motorbike_parking_app/models/user_report.dart';

class ParkingZone {
  final String id;
  final String? googlePlacesId;
  final double latitude;
  final double longitude;
  final int totalCapacity;
  final int currentOccupancy;
  final double confidenceScore;
  final DateTime lastUpdated;
  final List<UserReport> userReports;

  ParkingZone({
    required this.id,
    this.googlePlacesId,
    required this.latitude,
    required this.longitude,
    required this.totalCapacity,
    required this.currentOccupancy,
    required this.confidenceScore,
    required this.lastUpdated,
    required this.userReports,
  });

  int get availableSlots => totalCapacity - currentOccupancy;

  /// Creates a ParkingZone from JSON data with safe parsing.
  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    return ParkingZone(
      id: json['id'] ?? '',
      googlePlacesId: json['googlePlacesId'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      totalCapacity: (json['totalCapacity'] as num?)?.toInt() ?? 0,
      currentOccupancy: (json['currentOccupancy'] as num?)?.toInt() ?? 0,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : DateTime.now(),
      userReports: json['userReports'] is List
          ? (json['userReports'] as List).map((report) => UserReport.fromJson(report)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'googlePlacesId': googlePlacesId,
      'latitude': latitude,
      'longitude': longitude,
      'totalCapacity': totalCapacity,
      'currentOccupancy': currentOccupancy,
      'confidenceScore': confidenceScore,
      'lastUpdated': lastUpdated.toIso8601String(),
      'userReports': userReports.map((report) => report.toJson()).toList(),
    };
  }
}