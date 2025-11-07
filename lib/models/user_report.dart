/// Represents a user-submitted parking availability report.
class UserReport {
  final String spotId;
  final String userId;
  final int reportedCount;
  final DateTime timestamp;
  final double? userLatitude;
  final double? userLongitude;
  final List<String> imageUrls;

  UserReport({
    required this.spotId,
    required this.userId,
    required this.reportedCount,
    required this.timestamp,
    this.userLatitude,
    this.userLongitude,
    this.imageUrls = const [],
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      spotId: json['spotId'] ?? '',
      userId: json['userId'] ?? '',
      reportedCount: (json['reportedCount'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      userLatitude: (json['userLatitude'] as num?)?.toDouble(),
      userLongitude: (json['userLongitude'] as num?)?.toDouble(),
      imageUrls: json['imageUrls'] is List ? List<String>.from(json['imageUrls']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spotId': spotId,
      'userId': userId,
      'reportedCount': reportedCount,
      'timestamp': timestamp.toIso8601String(),
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'imageUrls': imageUrls,
    };
  }
}