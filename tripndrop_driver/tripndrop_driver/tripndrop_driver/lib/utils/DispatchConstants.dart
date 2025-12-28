/// Dispatch Constants according to Eagle Rides Development Plan
/// Section 5 and Appendix A - Recommended defaults

class DispatchConstants {
  /// Priority threshold: drivers with rating >= 4.8 get priority window
  static const double priorityRatingThreshold = 4.8;

  /// Minimum rating required for dispatch eligibility
  static const double minimumRatingThreshold = 4.2;

  /// Priority window duration in seconds (2-5 seconds, default 3)
  static const int priorityWindowSeconds = 3;

  /// Offer countdown duration in seconds
  static const int offerCountdownSeconds = 20;

  /// Cycle length - rider wait time per cycle in seconds
  static const int cycleLengthSeconds = 30;

  /// Maximum number of dispatch cycles before NO_DRIVER_FOUND
  static const int maxDispatchCycles = 3;

  /// Radius expansion per cycle (in km)
  static const List<double> radiusPerCycle = [3.0, 5.0, 8.0];

  /// Get radius for specific cycle (1-indexed)
  static double getRadiusForCycle(int cycle) {
    if (cycle < 1) cycle = 1;
    if (cycle > radiusPerCycle.length) {
      return radiusPerCycle.last;
    }
    return radiusPerCycle[cycle - 1];
  }

  /// RTDB location freshness threshold in seconds
  static const int locationFreshnessSeconds = 15;

  /// Driver location update frequency in seconds
  static const int locationUpdateIntervalSeconds = 3;

  /// Minimum distance change to trigger location update (in meters)
  static const int minLocationDistanceMeters = 20;

  /// Maximum distance change to trigger location update (in meters)
  static const int maxLocationDistanceMeters = 30;

  /// Cancellation lock threshold in hours
  /// Driver cannot cancel within this many hours before scheduled pickup
  static const int cancellationLockHours = 4;
}

/// Hourly Booking Constants per Section 8
class HourlyBookingConstants {
  /// Minimum hours for hourly booking
  static const int minimumHours = 2;

  /// Default included miles per hour
  static const int defaultIncludedMilesPerHour = 20;

  /// Default extra mile fee
  static const double defaultExtraMileFee = 5.50;

  /// Extension rounding block in minutes
  static const int extensionRoundingMinutes = 10;

  /// Calculate rounded extension minutes
  static int calculateRoundedMinutes(int extraMinutes) {
    if (extraMinutes <= 0) return 0;
    return ((extraMinutes + extensionRoundingMinutes - 1) ~/ extensionRoundingMinutes) * extensionRoundingMinutes;
  }
}

/// Trip Event Types for audit logging
class TripEventTypes {
  static const String CREATED = 'CREATED';
  static const String OFFER_SENT = 'OFFER_SENT';
  static const String OFFER_ACCEPTED = 'OFFER_ACCEPTED';
  static const String OFFER_REJECTED = 'OFFER_REJECTED';
  static const String OFFER_EXPIRED = 'OFFER_EXPIRED';
  static const String DISPATCH_CYCLE = 'DISPATCH_CYCLE';
  static const String ACCEPTED = 'ACCEPTED';
  static const String ARRIVED = 'ARRIVED';
  static const String STARTED = 'STARTED';
  static const String COMPLETED = 'COMPLETED';
  static const String CANCELED = 'CANCELED';
  static const String NO_DRIVER_FOUND = 'NO_DRIVER_FOUND';
  static const String EXTENSION_REQUESTED = 'EXTENSION_REQUESTED';
  static const String EXTENSION_CONFIRMED = 'EXTENSION_CONFIRMED';
  static const String ADMIN_OVERRIDE = 'ADMIN_OVERRIDE';
}
