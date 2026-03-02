/// Hourly Pricing Model according to Eagle Rides Development Plan Section 4.1
/// This model represents the Firestore `/pricing/hourly/{vehicleType}` document
///
/// Pricing Structure:
/// - SUV XL: Rider pays $130/hr, Driver earns $80/hr
/// - SUV:    Rider pays $115/hr, Driver earns $70/hr
/// - Sedan:  Rider pays $105/hr, Driver earns $65/hr
///
/// Extra charges:
/// - Extra miles: $5.50/mile
/// - Over hour limit: Half-hour charge (even if only 5 mins over)

class HourlyPricingModel {
  String? vehicleType;
  num? riderHourPrice;      // What rider/customer pays
  num? driverHourPrice;     // What driver earns/sees
  num? includedMilesPerHour;
  num? extraMileFee;
  String? currency;

  // Legacy support
  num? get baseHourPrice => riderHourPrice;

  HourlyPricingModel({
    this.vehicleType,
    this.riderHourPrice,
    this.driverHourPrice,
    this.includedMilesPerHour,
    this.extraMileFee,
    this.currency,
  });

  HourlyPricingModel.fromJson(Map<String, dynamic> json) {
    vehicleType = json['vehicle_type'];
    riderHourPrice = json['rider_hour_price'] ?? json['base_hour_price'];
    driverHourPrice = json['driver_hour_price'];
    includedMilesPerHour = json['included_miles_per_hour'];
    extraMileFee = json['extra_mile_fee'] ?? 5.50; // Default $5.50 per mile over
    currency = json['currency'] ?? 'USD';
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_type': vehicleType,
      'rider_hour_price': riderHourPrice,
      'driver_hour_price': driverHourPrice,
      'base_hour_price': riderHourPrice, // Legacy support
      'included_miles_per_hour': includedMilesPerHour,
      'extra_mile_fee': extraMileFee ?? 5.50,
      'currency': currency ?? 'USD',
    };
  }

  /// Calculate estimated price for hourly booking (rider view)
  HourlyEstimate calculateEstimate(int hours) {
    if (hours < 2) hours = 2; // Minimum 2 hours

    final riderTotal = (riderHourPrice ?? 0) * hours;
    final driverTotal = (driverHourPrice ?? 0) * hours;
    final includedMiles = (includedMilesPerHour ?? 0) * hours;

    return HourlyEstimate(
      hours: hours,
      baseTotal: riderTotal,
      driverEarnings: driverTotal,
      includedMilesTotal: includedMiles,
      extraMileFee: extraMileFee ?? 5.50,
      currency: currency ?? 'USD',
    );
  }

  /// Calculate overtime fee - HALF HOUR charge for any time over
  /// Even if 5 minutes over the hour, charge half hour
  num calculateOvertimeFee(int extraMinutes, {bool forDriver = false}) {
    if (extraMinutes <= 0) return 0;

    // Any overtime = half hour charge
    final hourlyRate = forDriver ? (driverHourPrice ?? 0) : (riderHourPrice ?? 0);
    final halfHourRate = hourlyRate / 2;

    // Calculate number of half-hours (round up)
    final halfHours = ((extraMinutes + 29) ~/ 30);

    return halfHours * halfHourRate;
  }

  /// Calculate extension fee (rounded to half-hour blocks as per client requirement)
  num calculateExtensionFee(int extraMinutes, {bool forDriver = false}) {
    return calculateOvertimeFee(extraMinutes, forDriver: forDriver);
  }

  /// Calculate extra miles fee
  num calculateExtraMilesFee(num actualMiles, num includedMiles) {
    if (actualMiles <= includedMiles) return 0;

    final extraMiles = actualMiles - includedMiles;
    return extraMiles * (extraMileFee ?? 5.50);
  }

  /// Get default pricing for vehicle types (admin can override in Firebase)
  static HourlyPricingModel getDefaultPricing(String vehicleType) {
    switch (vehicleType.toUpperCase()) {
      case 'SUV_XL':
      case 'SUV XL':
        return HourlyPricingModel(
          vehicleType: 'SUV_XL',
          riderHourPrice: 130,
          driverHourPrice: 80,
          includedMilesPerHour: 30,
          extraMileFee: 5.50,
          currency: 'USD',
        );
      case 'SUV':
        return HourlyPricingModel(
          vehicleType: 'SUV',
          riderHourPrice: 115,
          driverHourPrice: 70,
          includedMilesPerHour: 30,
          extraMileFee: 5.50,
          currency: 'USD',
        );
      case 'SEDAN':
      default:
        return HourlyPricingModel(
          vehicleType: 'SEDAN',
          riderHourPrice: 105,
          driverHourPrice: 65,
          includedMilesPerHour: 30,
          extraMileFee: 5.50,
          currency: 'USD',
        );
    }
  }
}

/// Hourly booking estimate
class HourlyEstimate {
  int hours;
  num baseTotal;          // What rider pays
  num driverEarnings;     // What driver earns
  num includedMilesTotal;
  num extraMileFee;
  String currency;

  HourlyEstimate({
    required this.hours,
    required this.baseTotal,
    required this.driverEarnings,
    required this.includedMilesTotal,
    required this.extraMileFee,
    required this.currency,
  });

  String get formattedBaseTotal => '\$${baseTotal.toStringAsFixed(2)}';
  String get formattedDriverEarnings => '\$${driverEarnings.toStringAsFixed(2)}';
  String get formattedExtraMileFee => '\$${extraMileFee.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'base_total': baseTotal,
      'driver_earnings': driverEarnings,
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

  /// Calculate rounded minutes (to 30-minute/half-hour blocks)
  /// Per client requirement: Any time over = half hour charge
  static int calculateRoundedMinutes(int minutes) {
    if (minutes <= 0) return 0;
    // Round up to nearest 30 minutes (half hour)
    return ((minutes + 29) ~/ 30) * 30;
  }
}

class ExtensionStatus {
  static const String PENDING = 'PENDING';
  static const String CONFIRMED = 'CONFIRMED';
  static const String REJECTED = 'REJECTED';
}
