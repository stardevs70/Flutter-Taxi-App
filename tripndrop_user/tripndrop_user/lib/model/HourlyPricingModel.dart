/// Hourly Pricing Model for Rider App
/// Per Eagle Rides Development Plan Section 4.1 and Client Pricing Requirements
///
/// Pricing Structure (Rider pays):
/// - SUV XL: $130/hr
/// - SUV:    $115/hr
/// - Sedan:  $105/hr
///
/// Extra charges:
/// - Extra miles: $5.50/mile over included
/// - Over hour limit: 16th minute = full hour charge (15 min grace period)
/// - Included miles: 15 miles per hour

class HourlyPricingModel {
  String? vehicleType;
  num? baseHourPrice;        // What rider pays per hour
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
    baseHourPrice = json['rider_hour_price'] ?? json['base_hour_price'];
    includedMilesPerHour = json['included_miles_per_hour'];
    extraMileFee = json['extra_mile_fee'] ?? 5.50;
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

  /// Calculate extension fee (rounded to half-hour blocks)
  /// Per client: Even 5 minutes over = half hour charge
  num calculateExtensionFee(int extraMinutes) {
    if (extraMinutes <= 0) return 0;

    final halfHourRate = (baseHourPrice ?? 0) / 2;
    // Round up to nearest 30 minutes
    final halfHours = ((extraMinutes + 29) ~/ 30);

    return halfHours * halfHourRate;
  }

  /// Calculate extra miles fee
  num calculateExtraMilesFee(num actualMiles, num includedMiles) {
    if (actualMiles <= includedMiles) return 0;

    final extraMiles = actualMiles - includedMiles;
    return extraMiles * (extraMileFee ?? 5.50);
  }

  /// Get default pricing for vehicle types
  static HourlyPricingModel getDefaultPricing(String vehicleType) {
    switch (vehicleType.toUpperCase()) {
      case 'SUV_XL':
      case 'SUV XL':
        return HourlyPricingModel(
          vehicleType: 'SUV_XL',
          baseHourPrice: 130,
          includedMilesPerHour: 15,
          extraMileFee: 5.50,
          currency: 'USD',
        );
      case 'SUV':
        return HourlyPricingModel(
          vehicleType: 'SUV',
          baseHourPrice: 115,
          includedMilesPerHour: 15,
          extraMileFee: 5.50,
          currency: 'USD',
        );
      case 'SEDAN':
      default:
        return HourlyPricingModel(
          vehicleType: 'SEDAN',
          baseHourPrice: 105,
          includedMilesPerHour: 15,
          extraMileFee: 5.50,
          currency: 'USD',
        );
    }
  }
}

/// Hourly booking estimate for rider
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

/// Hourly booking constants
class HourlyBookingConstants {
  static const int minimumHours = 2;
  static const int defaultIncludedMilesPerHour = 15;
  static const double defaultExtraMileFee = 5.50;
  static const int graceMinutes = 15; // 15 min grace period, 16th min = full hour
}
