/// Offer Model according to Eagle Rides Development Plan Section 4.1
/// This model represents the Firestore `/trip_requests/{tripId}/offers/{driverId}` document

class OfferModel {
  String? id;
  String? tripId;
  String? driverId;
  String? status; // "OFFERED" | "ACCEPTED" | "REJECTED" | "EXPIRED"
  DateTime? createdAt;
  DateTime? expiresAt;
  String? priorityTier; // "PRIORITY" | "GENERAL"
  double? distanceKm;
  int? cycle;

  OfferModel({
    this.id,
    this.tripId,
    this.driverId,
    this.status,
    this.createdAt,
    this.expiresAt,
    this.priorityTier,
    this.distanceKm,
    this.cycle,
  });

  OfferModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tripId = json['trip_id'];
    driverId = json['driver_id'];
    status = json['status'] ?? OfferStatus.OFFERED;
    createdAt = json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null;
    expiresAt = json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null;
    priorityTier = json['priority_tier'] ?? PriorityTier.GENERAL;
    distanceKm = json['distance_km']?.toDouble();
    cycle = json['cycle'] ?? 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    if (tripId != null) data['trip_id'] = tripId;
    if (driverId != null) data['driver_id'] = driverId;
    data['status'] = status ?? OfferStatus.OFFERED;
    if (createdAt != null) data['created_at'] = createdAt!.toIso8601String();
    if (expiresAt != null) data['expires_at'] = expiresAt!.toIso8601String();
    data['priority_tier'] = priorityTier ?? PriorityTier.GENERAL;
    if (distanceKm != null) data['distance_km'] = distanceKm;
    data['cycle'] = cycle ?? 1;
    return data;
  }

  /// Check if offer has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if offer can be accepted
  bool get canAccept {
    return status == OfferStatus.OFFERED && !isExpired;
  }

  /// Get remaining seconds until expiration
  int get remainingSeconds {
    if (expiresAt == null) return 0;
    final remaining = expiresAt!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if this is a priority offer
  bool get isPriorityOffer => priorityTier == PriorityTier.PRIORITY;
}

/// Offer status constants
class OfferStatus {
  static const String OFFERED = 'OFFERED';
  static const String ACCEPTED = 'ACCEPTED';
  static const String REJECTED = 'REJECTED';
  static const String EXPIRED = 'EXPIRED';
}

/// Priority tier constants
class PriorityTier {
  static const String PRIORITY = 'PRIORITY';
  static const String GENERAL = 'GENERAL';
}
