/// Driver Location Model according to Eagle Rides Development Plan Section 4.2
/// This model represents the RTDB `/drivers_locations/{driverId}` path

class DriverLocationModel {
  String? driverId;
  double? lat;
  double? lng;
  double? heading;
  int? updatedAt; // Unix milliseconds

  DriverLocationModel({
    this.driverId,
    this.lat,
    this.lng,
    this.heading,
    this.updatedAt,
  });

  DriverLocationModel.fromJson(Map<String, dynamic> json) {
    driverId = json['driver_id'];
    lat = json['lat']?.toDouble();
    lng = json['lng']?.toDouble();
    heading = json['heading']?.toDouble();
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    return {
      if (driverId != null) 'driver_id': driverId,
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Check if location is fresh (within 15 seconds)
  bool get isFresh {
    if (updatedAt == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - updatedAt!) <= 15000; // 15 seconds in milliseconds
  }

  /// Get age of location update in seconds
  int get ageInSeconds {
    if (updatedAt == null) return -1;
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now - updatedAt!) / 1000).round();
  }

  /// Get DateTime of last update
  DateTime? get lastUpdateTime {
    if (updatedAt == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(updatedAt!);
  }
}

/// Driver Profile Model according to Eagle Rides Development Plan Section 4.1
/// This model represents the Firestore `/drivers/{driverId}` document
class DriverProfileModel {
  String? id;
  bool? active;
  bool? documentsVerified;
  String? cityId;
  String? vehicleType;
  double? rating;
  String? status; // "AVAILABLE" | "ON_TRIP" | "PAUSED"
  bool? online;
  PushTokens? pushTokens;

  // Additional driver info
  String? firstName;
  String? lastName;
  String? email;
  String? contactNumber;
  String? profileImage;

  DriverProfileModel({
    this.id,
    this.active,
    this.documentsVerified,
    this.cityId,
    this.vehicleType,
    this.rating,
    this.status,
    this.online,
    this.pushTokens,
    this.firstName,
    this.lastName,
    this.email,
    this.contactNumber,
    this.profileImage,
  });

  DriverProfileModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    active = json['active'] ?? false;
    documentsVerified = json['documents_verified'] ?? false;
    cityId = json['city_id'];
    vehicleType = json['vehicle_type'];
    rating = json['rating']?.toDouble();
    status = json['status'] ?? DriverStatus.PAUSED;
    online = json['online'] ?? false;
    pushTokens = json['push_tokens'] != null ? PushTokens.fromJson(json['push_tokens']) : null;
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    contactNumber = json['contact_number'];
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'active': active ?? false,
      'documents_verified': documentsVerified ?? false,
      if (cityId != null) 'city_id': cityId,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (rating != null) 'rating': rating,
      'status': status ?? DriverStatus.PAUSED,
      'online': online ?? false,
      if (pushTokens != null) 'push_tokens': pushTokens!.toJson(),
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (profileImage != null) 'profile_image': profileImage,
    };
  }

  /// Get full name
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  /// Check if driver is eligible for priority dispatch (rating >= 4.8)
  bool get isPriorityDriver => (rating ?? 0) >= 4.8;

  /// Check if driver is available for dispatch
  bool get isAvailableForDispatch {
    return active == true &&
        documentsVerified == true &&
        online == true &&
        status == DriverStatus.AVAILABLE;
  }
}

class PushTokens {
  String? fcm;
  String? apns;

  PushTokens({this.fcm, this.apns});

  PushTokens.fromJson(Map<String, dynamic> json) {
    fcm = json['fcm'];
    apns = json['apns'];
  }

  Map<String, dynamic> toJson() {
    return {
      if (fcm != null) 'fcm': fcm,
      if (apns != null) 'apns': apns,
    };
  }
}

/// Driver status constants
class DriverStatus {
  static const String AVAILABLE = 'AVAILABLE';
  static const String ON_TRIP = 'ON_TRIP';
  static const String PAUSED = 'PAUSED';
}
