/// Trip Track Model according to Eagle Rides Development Plan Section 8.4
/// This model represents GPS breadcrumb tracking during STARTED → COMPLETED
/// Stored in Firestore `/trips/{tripId}/track/{pointId}`

import 'dart:math' as math;

class TripTrackPoint {
  String? id;
  double? lat;
  double? lng;
  int? ts; // Unix timestamp in milliseconds

  TripTrackPoint({
    this.id,
    this.lat,
    this.lng,
    this.ts,
  });

  TripTrackPoint.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    lat = json['lat']?.toDouble();
    lng = json['lng']?.toDouble();
    ts = json['ts'];
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'lat': lat,
      'lng': lng,
      'ts': ts ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  DateTime? get timestamp {
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts!);
  }
}

/// Trip Track Summary for calculating total distance
class TripTrackSummary {
  String? tripId;
  List<TripTrackPoint> points;
  num? totalDistanceMiles;
  num? totalDistanceKm;
  DateTime? startTime;
  DateTime? endTime;

  TripTrackSummary({
    this.tripId,
    this.points = const [],
    this.totalDistanceMiles,
    this.totalDistanceKm,
    this.startTime,
    this.endTime,
  });

  /// Calculate total distance from track points using Haversine formula
  static TripTrackSummary calculateFromPoints(String tripId, List<TripTrackPoint> points) {
    if (points.isEmpty) {
      return TripTrackSummary(
        tripId: tripId,
        points: points,
        totalDistanceKm: 0,
        totalDistanceMiles: 0,
      );
    }

    // Sort points by timestamp
    final sortedPoints = List<TripTrackPoint>.from(points)
      ..sort((a, b) => (a.ts ?? 0).compareTo(b.ts ?? 0));

    double totalDistanceKm = 0;

    for (int i = 1; i < sortedPoints.length; i++) {
      final prev = sortedPoints[i - 1];
      final curr = sortedPoints[i];

      if (prev.lat != null && prev.lng != null && curr.lat != null && curr.lng != null) {
        totalDistanceKm += _calculateHaversineDistance(
          prev.lat!,
          prev.lng!,
          curr.lat!,
          curr.lng!,
        );
      }
    }

    // Convert km to miles (1 km = 0.621371 miles)
    final totalDistanceMiles = totalDistanceKm * 0.621371;

    return TripTrackSummary(
      tripId: tripId,
      points: sortedPoints,
      totalDistanceKm: totalDistanceKm,
      totalDistanceMiles: totalDistanceMiles,
      startTime: sortedPoints.first.timestamp,
      endTime: sortedPoints.last.timestamp,
    );
  }

  /// Haversine formula to calculate distance between two points
  static double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Get duration of the trip in minutes
  int get durationMinutes {
    if (startTime == null || endTime == null) return 0;
    return endTime!.difference(startTime!).inMinutes;
  }

  /// Get formatted distance string
  String get formattedDistanceMiles => '${totalDistanceMiles?.toStringAsFixed(2) ?? '0.00'} mi';
  String get formattedDistanceKm => '${totalDistanceKm?.toStringAsFixed(2) ?? '0.00'} km';

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'total_distance_miles': totalDistanceMiles,
      'total_distance_km': totalDistanceKm,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'points_count': points.length,
    };
  }
}

/// Configuration for track point recording
class TrackPointConfig {
  /// Minimum interval between track points (in seconds)
  static const int minIntervalSeconds = 3;

  /// Maximum interval between track points (in seconds)
  static const int maxIntervalSeconds = 5;

  /// Minimum distance change to record new point (in meters)
  static const int minDistanceMeters = 20;

  /// Maximum distance change to record new point (in meters)
  static const int maxDistanceMeters = 30;

  /// Check if we should record a new track point based on time elapsed
  static bool shouldRecordByTime(DateTime? lastRecordTime) {
    if (lastRecordTime == null) return true;
    final elapsed = DateTime.now().difference(lastRecordTime).inSeconds;
    return elapsed >= minIntervalSeconds;
  }

  /// Check if we should record a new track point based on distance
  static bool shouldRecordByDistance(
    double? lastLat,
    double? lastLng,
    double currentLat,
    double currentLng,
  ) {
    if (lastLat == null || lastLng == null) return true;

    final distanceKm = TripTrackSummary._calculateHaversineDistance(
      lastLat,
      lastLng,
      currentLat,
      currentLng,
    );

    final distanceMeters = distanceKm * 1000;
    return distanceMeters >= minDistanceMeters;
  }

  /// Determine if a new track point should be recorded
  static bool shouldRecord(
    DateTime? lastRecordTime,
    double? lastLat,
    double? lastLng,
    double currentLat,
    double currentLng,
  ) {
    // Record if either time or distance threshold is met
    return shouldRecordByTime(lastRecordTime) ||
        shouldRecordByDistance(lastLat, lastLng, currentLat, currentLng);
  }
}
