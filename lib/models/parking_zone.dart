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

  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    return ParkingZone(
      id: json['id'],
      googlePlacesId: json['googlePlacesId'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      totalCapacity: json['totalCapacity'],
      currentOccupancy: json['currentOccupancy'],
      confidenceScore: json['confidenceScore'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      userReports: (json['userReports'] as List)
          .map((report) => UserReport.fromJson(report))
          .toList(),
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