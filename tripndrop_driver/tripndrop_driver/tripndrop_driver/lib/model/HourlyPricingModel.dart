/// Hourly Pricing Model according to Eagle Rides Development Plan Section 4.1
/// This model represents the Firestore `/pricing/hourly/{vehicleType}` document

class HourlyPricingModel {
  String? vehicleType;
  num? baseHourPrice;
  num? includedMilesPerHour;
  num? extraMileFee;
  String? currency;

  HourlyPricingModel({
    this.vehicleType,
    this.baseHourPrice,
    this.includedMilesPerHour,
    this.extraMileFee,
    this.currency,
  });

  HourlyPricingModel.fromJson(Map<String, dynamic> json) {
    vehicleType = json['vehicle_type'];
    baseHourPrice = json['base_hour_price'];
    includedMilesPerHour = json['included_miles_per_hour'];
    extraMileFee = json['extra_mile_fee'] ?? 5.50; // Default $5.50 per mile over
    currency = json['currency'] ?? 'USD';
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_type': vehicleType,
      'base_hour_price': baseHourPrice,
      'included_miles_per_hour': includedMilesPerHour,
      'extra_mile_fee': extraMileFee ?? 5.50,
      'currency': currency ?? 'USD',
    };
  }

  /// Calculate estimated price for hourly booking
  HourlyEstimate calculateEstimate(int hours) {
    if (hours < 2) hours = 2; // Minimum 2 hours

    final baseTotal = (baseHourPrice ?? 0) * hours;
    final includedMiles = (includedMilesPerHour ?? 0) * hours;

    return HourlyEstimate(
      hours: hours,
      baseTotal: baseTotal,
      includedMilesTotal: includedMiles,
      extraMileFee: extraMileFee ?? 5.50,
      currency: currency ?? 'USD',
    );
  }

  /// Calculate extension fee (rounded to 10-minute blocks)
  num calculateExtensionFee(int extraMinutes) {
    if (extraMinutes <= 0) return 0;

    // Round up to nearest 10 minutes
    final roundedMinutes = ((extraMinutes + 9) ~/ 10) * 10;
    final hourlyRate = baseHourPrice ?? 0;
    final perMinuteRate = hourlyRate / 60;

    return roundedMinutes * perMinuteRate;
  }

  /// Calculate extra miles fee
  num calculateExtraMilesFee(num actualMiles, num includedMiles) {
    if (actualMiles <= includedMiles) return 0;

    final extraMiles = actualMiles - includedMiles;
    return extraMiles * (extraMileFee ?? 5.50);
  }
}

/// Hourly booking estimate
class HourlyEstimate {
  int hours;
  num baseTotal;
  num includedMilesTotal;
  num extraMileFee;
  String currency;

  HourlyEstimate({
    required this.hours,
    required this.baseTotal,
    required this.includedMilesTotal,
    required this.extraMileFee,
    required this.currency,
  });

  String get formattedBaseTotal => '\$${baseTotal.toStringAsFixed(2)}';
  String get formattedExtraMileFee => '\$${extraMileFee.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'base_total': baseTotal,
      'included_miles_total': includedMilesTotal,
      'extra_mile_fee': extraMileFee,
      'currency': currency,
    };
  }
}

/// Extension request model for hourly bookings
class ExtensionRequest {
  String? tripId;
  int? extraMinutes;
  int? roundedMinutes;
  num? extensionFee;
  String? requestedBy; // "RIDER" | "DRIVER"
  String? status; // "PENDING" | "CONFIRMED" | "REJECTED"
  DateTime? requestedAt;
  DateTime? respondedAt;

  ExtensionRequest({
    this.tripId,
    this.extraMinutes,
    this.roundedMinutes,
    this.extensionFee,
    this.requestedBy,
    this.status,
    this.requestedAt,
    this.respondedAt,
  });

  ExtensionRequest.fromJson(Map<String, dynamic> json) {
    tripId = json['trip_id'];
    extraMinutes = json['extra_minutes'];
    roundedMinutes = json['rounded_minutes'];
    extensionFee = json['extension_fee'];
    requestedBy = json['requested_by'];
    status = json['status'] ?? 'PENDING';
    requestedAt = json['requested_at'] != null ? DateTime.tryParse(json['requested_at'].toString()) : null;
    respondedAt = json['responded_at'] != null ? DateTime.tryParse(json['responded_at'].toString()) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'extra_minutes': extraMinutes,
      'rounded_minutes': roundedMinutes,
      'extension_fee': extensionFee,
      'requested_by': requestedBy,
      'status': status ?? 'PENDING',
      'requested_at': requestedAt?.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  /// Calculate rounded minutes (to 10-minute blocks)
  static int calculateRoundedMinutes(int minutes) {
    return ((minutes + 9) ~/ 10) * 10;
  }
}

class ExtensionStatus {
  static const String PENDING = 'PENDING';
  static const String CONFIRMED = 'CONFIRMED';
  static const String REJECTED = 'REJECTED';
}
