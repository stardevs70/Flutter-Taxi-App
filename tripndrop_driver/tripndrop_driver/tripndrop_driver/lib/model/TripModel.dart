/// Trip Model according to Eagle Rides Development Plan Section 4.1
/// This model represents the Firestore `/trips/{tripId}` document structure

class TripModel {
  String? id;
  String? type; // "STANDARD" | "HOURLY"
  String? status; // "REQUESTED" | "ACCEPTED" | "ARRIVED" | "STARTED" | "COMPLETED" | "CANCELED" | "NO_DRIVER_FOUND"
  String? cityId;
  String? vehicleType;
  LocationData? pickup;
  LocationData? dropoff;
  DateTime? scheduledAt;
  DateTime? createdAt;
  String? riderId;
  String? acceptedBy;
  DateTime? acceptedAt;
  DateTime? arrivedAt;
  DateTime? startedAt;
  DateTime? completedAt;
  String? canceledBy; // "RIDER" | "DRIVER" | "BACKEND" | "ADMIN"
  String? cancelReason;
  bool? adminOverride;
  DispatchData? dispatch;

  // Hourly booking fields (if type == HOURLY)
  int? hoursBooked; // min 2
  PricingSnapshot? pricingSnapshot;
  num? includedMilesTotal;
  int? extensionMinutesTotal;
  FinalBilling? finalBilling;

  TripModel({
    this.id,
    this.type,
    this.status,
    this.cityId,
    this.vehicleType,
    this.pickup,
    this.dropoff,
    this.scheduledAt,
    this.createdAt,
    this.riderId,
    this.acceptedBy,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.canceledBy,
    this.cancelReason,
    this.adminOverride,
    this.dispatch,
    this.hoursBooked,
    this.pricingSnapshot,
    this.includedMilesTotal,
    this.extensionMinutesTotal,
    this.finalBilling,
  });

  TripModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'] ?? 'STANDARD';
    status = json['status'];
    cityId = json['city_id'];
    vehicleType = json['vehicle_type'];
    pickup = json['pickup'] != null ? LocationData.fromJson(json['pickup']) : null;
    dropoff = json['dropoff'] != null ? LocationData.fromJson(json['dropoff']) : null;
    scheduledAt = json['scheduled_at'] != null ? DateTime.tryParse(json['scheduled_at'].toString()) : null;
    createdAt = json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null;
    riderId = json['rider_id'];
    acceptedBy = json['accepted_by'];
    acceptedAt = json['accepted_at'] != null ? DateTime.tryParse(json['accepted_at'].toString()) : null;
    arrivedAt = json['arrived_at'] != null ? DateTime.tryParse(json['arrived_at'].toString()) : null;
    startedAt = json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null;
    completedAt = json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null;
    canceledBy = json['canceled_by'];
    cancelReason = json['cancel_reason'];
    adminOverride = json['admin_override'] ?? false;
    dispatch = json['dispatch'] != null ? DispatchData.fromJson(json['dispatch']) : null;
    hoursBooked = json['hours_booked'];
    pricingSnapshot = json['pricing_snapshot'] != null ? PricingSnapshot.fromJson(json['pricing_snapshot']) : null;
    includedMilesTotal = json['included_miles_total'];
    extensionMinutesTotal = json['extension_minutes_total'];
    finalBilling = json['final'] != null ? FinalBilling.fromJson(json['final']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    data['type'] = type ?? 'STANDARD';
    if (status != null) data['status'] = status;
    if (cityId != null) data['city_id'] = cityId;
    if (vehicleType != null) data['vehicle_type'] = vehicleType;
    if (pickup != null) data['pickup'] = pickup!.toJson();
    if (dropoff != null) data['dropoff'] = dropoff!.toJson();
    if (scheduledAt != null) data['scheduled_at'] = scheduledAt!.toIso8601String();
    if (createdAt != null) data['created_at'] = createdAt!.toIso8601String();
    if (riderId != null) data['rider_id'] = riderId;
    if (acceptedBy != null) data['accepted_by'] = acceptedBy;
    if (acceptedAt != null) data['accepted_at'] = acceptedAt!.toIso8601String();
    if (arrivedAt != null) data['arrived_at'] = arrivedAt!.toIso8601String();
    if (startedAt != null) data['started_at'] = startedAt!.toIso8601String();
    if (completedAt != null) data['completed_at'] = completedAt!.toIso8601String();
    if (canceledBy != null) data['canceled_by'] = canceledBy;
    if (cancelReason != null) data['cancel_reason'] = cancelReason;
    data['admin_override'] = adminOverride ?? false;
    if (dispatch != null) data['dispatch'] = dispatch!.toJson();
    if (hoursBooked != null) data['hours_booked'] = hoursBooked;
    if (pricingSnapshot != null) data['pricing_snapshot'] = pricingSnapshot!.toJson();
    if (includedMilesTotal != null) data['included_miles_total'] = includedMilesTotal;
    if (extensionMinutesTotal != null) data['extension_minutes_total'] = extensionMinutesTotal;
    if (finalBilling != null) data['final'] = finalBilling!.toJson();
    return data;
  }

  /// Check if driver can cancel this trip
  /// Returns true if cancellation is allowed, false if locked
  bool canDriverCancel() {
    if (adminOverride == true) return true;
    if (scheduledAt == null) return true;

    final now = DateTime.now();
    final hoursUntilPickup = scheduledAt!.difference(now).inHours;

    // Driver cannot cancel within 4 hours of scheduled pickup
    return hoursUntilPickup > 4;
  }

  /// Get cancellation lock message
  String getCancellationLockMessage() {
    if (canDriverCancel()) return '';
    return 'Cannot cancel within 4 hours of pickup. Contact admin for override.';
  }

  /// Check if this is an hourly booking
  bool get isHourlyBooking => type == 'HOURLY';

  /// Get remaining minutes for hourly booking
  int getRemainingMinutes() {
    if (!isHourlyBooking || startedAt == null || hoursBooked == null) return 0;
    final totalMinutes = (hoursBooked! * 60) + (extensionMinutesTotal ?? 0);
    final elapsedMinutes = DateTime.now().difference(startedAt!).inMinutes;
    return totalMinutes - elapsedMinutes;
  }
}

class LocationData {
  double? lat;
  double? lng;
  String? address;

  LocationData({this.lat, this.lng, this.address});

  LocationData.fromJson(Map<String, dynamic> json) {
    lat = json['lat']?.toDouble();
    lng = json['lng']?.toDouble();
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }
}

class DispatchData {
  int? cycle;
  double? radiusKm;
  int? priorityWindowSec;

  DispatchData({this.cycle, this.radiusKm, this.priorityWindowSec});

  DispatchData.fromJson(Map<String, dynamic> json) {
    cycle = json['cycle'] ?? 1;
    radiusKm = json['radius_km']?.toDouble() ?? 3.0;
    priorityWindowSec = json['priority_window_sec'] ?? 3;
  }

  Map<String, dynamic> toJson() {
    return {
      'cycle': cycle ?? 1,
      'radius_km': radiusKm ?? 3.0,
      'priority_window_sec': priorityWindowSec ?? 3,
    };
  }
}

class PricingSnapshot {
  num? baseHourPrice;
  num? includedMilesPerHour;
  num? extraMileFee;
  String? currency;

  PricingSnapshot({
    this.baseHourPrice,
    this.includedMilesPerHour,
    this.extraMileFee,
    this.currency,
  });

  PricingSnapshot.fromJson(Map<String, dynamic> json) {
    baseHourPrice = json['base_hour_price'];
    includedMilesPerHour = json['included_miles_per_hour'];
    extraMileFee = json['extra_mile_fee'] ?? 5.50; // Default $5.50 per mile over
    currency = json['currency'] ?? 'USD';
  }

  Map<String, dynamic> toJson() {
    return {
      'base_hour_price': baseHourPrice,
      'included_miles_per_hour': includedMilesPerHour,
      'extra_mile_fee': extraMileFee ?? 5.50,
      'currency': currency ?? 'USD',
    };
  }
}

class FinalBilling {
  num? actualMiles;
  num? extraMiles;
  num? extraMilesFee;
  num? extensionFee;
  num? total;

  FinalBilling({
    this.actualMiles,
    this.extraMiles,
    this.extraMilesFee,
    this.extensionFee,
    this.total,
  });

  FinalBilling.fromJson(Map<String, dynamic> json) {
    actualMiles = json['actual_miles'];
    extraMiles = json['extra_miles'];
    extraMilesFee = json['extra_miles_fee'];
    extensionFee = json['extension_fee'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    return {
      'actual_miles': actualMiles,
      'extra_miles': extraMiles,
      'extra_miles_fee': extraMilesFee,
      'extension_fee': extensionFee,
      'total': total,
    };
  }
}

/// Trip status constants per Section 6 of development plan
class TripStatus {
  static const String REQUESTED = 'REQUESTED';
  static const String ACCEPTED = 'ACCEPTED';
  static const String ARRIVED = 'ARRIVED';
  static const String STARTED = 'STARTED';
  static const String COMPLETED = 'COMPLETED';
  static const String CANCELED = 'CANCELED';
  static const String NO_DRIVER_FOUND = 'NO_DRIVER_FOUND';
}

/// Trip type constants
class TripType {
  static const String STANDARD = 'STANDARD';
  static const String HOURLY = 'HOURLY';
}

/// Cancellation party constants
class CanceledBy {
  static const String RIDER = 'RIDER';
  static const String DRIVER = 'DRIVER';
  static const String BACKEND = 'BACKEND';
  static const String ADMIN = 'ADMIN';
}
