class UserReport {
  final String spotId;
  final String userId;
  final int reportedCount;
  final DateTime timestamp;
  final double? userLatitude;
  final double? userLongitude;

  UserReport({
    required this.spotId,
    required this.userId,
    required this.reportedCount,
    required this.timestamp,
    this.userLatitude,
    this.userLongitude,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      spotId: json['spotId'],
      userId: json['userId'],
      reportedCount: json['reportedCount'],
      timestamp: DateTime.parse(json['timestamp']),
      userLatitude: json['userLatitude'],
      userLongitude: json['userLongitude'],
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
    };
  }
}