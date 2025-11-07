import '../models/models.dart';

class AvailabilityEngine {
  /// Calculates the current parking occupancy based on user reports.
  /// Uses weighted averaging with recency and user reputation factors.
  /// Returns 0 if no valid reports are provided.
  static int calculateCurrentOccupancy(List<UserReport> reports) {
    if (reports.isEmpty) return 0;

    // Filter out invalid reports
    final validReports = reports.where((r) => r.reportedCount >= 0 && r.userId.isNotEmpty).toList();
    if (validReports.isEmpty) return 0;

    // Group reports by user to calculate reputation (more reports = higher trust)
    final Map<String, int> userReportCounts = <String, int>{};
    for (final UserReport report in validReports) {
      userReportCounts[report.userId] = (userReportCounts[report.userId] ?? 0) + 1;
    }

    // Weight reports by recency (recent = higher weight) and user reputation
    final now = DateTime.now();
    final weightedSum = validReports.map((report) {
      final age = now.difference(report.timestamp).inMinutes;
      final recencyWeight = age <= 30 ? 1.0 : age <= 60 ? 0.5 : 0.2;
      final userReputation = (userReportCounts[report.userId] ?? 1).clamp(1, 5).toDouble() / 5.0; // Max 5 reports for full reputation
      final totalWeight = recencyWeight * userReputation;
      return report.reportedCount * totalWeight;
    }).reduce((a, b) => a + b);

    final totalWeight = validReports.map((report) {
      final age = now.difference(report.timestamp).inMinutes;
      final recencyWeight = age <= 30 ? 1.0 : age <= 60 ? 0.5 : 0.2;
      final userReputation = (userReportCounts[report.userId] ?? 1).clamp(1, 5).toDouble() / 5.0;
      return recencyWeight * userReputation;
    }).reduce((a, b) => a + b);

    if (totalWeight == 0) return 0;

    return (weightedSum / totalWeight).round();
  }

  /// Calculates a confidence score (0.0-1.0) for the occupancy estimate.
  /// Factors in recency, consistency, and volume of reports.
  /// Returns 0.0 for invalid inputs or no reports.
  static double calculateConfidenceScore(List<UserReport> reports, int capacity) {
    if (reports.isEmpty || capacity <= 0) return 0.0;

    final validReports = reports.where((r) => r.reportedCount >= 0).toList();
    if (validReports.isEmpty) return 0.0;

    final now = DateTime.now();
    double recencyScore = 0.0;
    double consistencyScore = 0.0;
    double volumeScore = 0.0;

    // Recency weight (reports in last 30 min)
    final recentReports = validReports.where((r) => now.difference(r.timestamp).inMinutes <= 30).toList();
    recencyScore = recentReports.length / 3.0; // Max 3 reports for full score

    // Consistency (variance in reports)
    if (validReports.length > 1) {
      final counts = validReports.map((r) => r.reportedCount).toList();
      final mean = counts.reduce((a, b) => a + b) / counts.length;
      final variance = counts.map((c) => (c - mean) * (c - mean)).reduce((a, b) => a + b) / counts.length;
      final stdDev = variance.sqrt();
      consistencyScore = capacity > 0 ? 1.0 - (stdDev / capacity).clamp(0.0, 1.0) : 0.0;
    } else {
      consistencyScore = 0.5; // Neutral for single report
    }

    // Volume score (more reports = higher confidence)
    volumeScore = (validReports.length / 5.0).clamp(0.0, 1.0); // Max 5 reports for full score

    // Weighted average
    return (recencyScore * 0.5 + consistencyScore * 0.3 + volumeScore * 0.2).clamp(0.0, 1.0);
  }

  /// Updates a parking zone with new occupancy calculations from user reports.
  /// Returns the original zone if capacity is invalid.
  static ParkingZone updateZoneWithReports(ParkingZone zone, List<UserReport> reports) {
    if (zone.totalCapacity <= 0) {
      // Invalid capacity, return zone unchanged
      return zone;
    }

    final newOccupancy = calculateCurrentOccupancy(reports);
    final newConfidence = calculateConfidenceScore(reports, zone.totalCapacity);
    final newLastUpdated = DateTime.now();

    return ParkingZone(
      id: zone.id,
      googlePlacesId: zone.googlePlacesId,
      latitude: zone.latitude,
      longitude: zone.longitude,
      totalCapacity: zone.totalCapacity,
      currentOccupancy: newOccupancy.clamp(0, zone.totalCapacity),
      confidenceScore: newConfidence,
      lastUpdated: newLastUpdated,
      userReports: reports,
    );
  }
}

extension on double {
  double sqrt() => this < 0 ? 0 : this == 0 ? 0 : (this * 0.5 + this / (this * 0.5)) * 0.5; // Approximation
}