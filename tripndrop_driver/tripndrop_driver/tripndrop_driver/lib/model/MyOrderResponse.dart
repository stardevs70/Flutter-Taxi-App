import 'RideHistory.dart';

class MyOrderResponse {
  Pagination? pagination;
  List<MyOrderData>? data;

  MyOrderResponse({this.pagination, this.data});

  MyOrderResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
    if (json['data'] != null) {
      data = <MyOrderData>[];
      json['data'].forEach((v) {
        data!.add(new MyOrderData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Pagination {
  int? totalItems;
  int? perPage;
  int? currentPage;
  int? totalPages;

  Pagination(
      {this.totalItems, this.perPage, this.currentPage, this.totalPages});

  Pagination.fromJson(Map<String, dynamic> json) {
    totalItems = json['total_items'];
    perPage = json['per_page'];
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_items'] = this.totalItems;
    data['per_page'] = this.perPage;
    data['currentPage'] = this.currentPage;
    data['totalPages'] = this.totalPages;
    return data;
  }
}

class MyOrderData {
  int? id;
  String? type;
  int? riderId;
  int? serviceId;
  String? datetime;
  int? isSchedule;
  String? scheduleDatetime;
  int? rideAttempt;
  String? otp;
  num? totalAmount;
  num? subtotal;
  int? extraChargesAmount;
  num? driverId;
  String? driverName;
  String? riderName;
  String? driverEmail;
  String? riderEmail;
  String? driverContactNumber;
  String? riderContactNumber;
  String? driverProfileImage;
  String? riderProfileImage;
  String? startLatitude;
  String? startLongitude;
  String? startAddress;
  String? endLatitude;
  String? endLongitude;
  String? endAddress;
  String? distanceUnit;
  String? startTime;
  String? endTime;
  num? riderequestInDriverId;
  num? distance;
  num? duration;
  int? seatCount;
  String? reason;
  String? status;
  num? tips;
  num? baseFare;
  num? minimumFare;
  num? perDistance;
  num? perDistanceCharge;
  num? perMinuteDrive;
  num? perMinuteDriveCharge;
  num? perMinuteWaiting;
  num? waitingTime;
  num? waitingTimeLimit;
  num? perMinuteWaitingCharge;
  num? cancelationCharges;
  String? cancelBy;
  num? paymentId;
  String? paymentType;
  String? paymentStatus;
  List<ExtraCharges>? extraCharges;
  num? fixedCharge;
  num? couponDiscount;
  num? couponCode;
  // String? couponData;
  int? isRiderRated;
  int? isDriverRated;
  num? maxTimeForFindDriverForRideRequest;
  String? travelerInfo;
  String? contactNumber;
  String? firstName;
  String? lastName;
  String? email;
  num? passenger;
  String? driverNote;
  String? internalNote;
  num? surcharge;
  num? corporateId;
  String? corporateName;
  num? weight;
  String? parcelDescription;
  String? pickupContactNumber;
  String? pickupPersonName;
  String? pickupDescription;
  String? deliveryContactNumber;
  String? deliveryPersonName;
  String? deliveryDescription;
  num? discount;
  String? createdAt;
  String? updatedAt;
  int? regionId;
  int? isRideForOther;
  String? otherRiderData;
  String? invoiceUrl;
  String? invoiceName;
  List<RideHistory>? rideHistory;

  MyOrderData(
      {this.id,
        this.rideHistory,
        this.type,
        this.riderId,
        this.serviceId,
        this.datetime,
        this.isSchedule,
        this.scheduleDatetime,
        this.rideAttempt,
        this.otp,
        this.totalAmount,
        this.subtotal,
        this.extraChargesAmount,
        this.driverId,
        this.driverName,
        this.riderName,
        this.driverEmail,
        this.riderEmail,
        this.driverContactNumber,
        this.riderContactNumber,
        this.driverProfileImage,
        this.riderProfileImage,
        this.startLatitude,
        this.startLongitude,
        this.startAddress,
        this.endLatitude,
        this.endLongitude,
        this.endAddress,
        this.distanceUnit,
        this.startTime,
        this.endTime,
        this.riderequestInDriverId,
        this.distance,
        this.duration,
        this.seatCount,
        this.reason,
        this.status,
        this.tips,
        this.baseFare,
        this.minimumFare,
        this.perDistance,
        this.perDistanceCharge,
        this.perMinuteDrive,
        this.perMinuteDriveCharge,
        this.perMinuteWaiting,
        this.waitingTime,
        this.waitingTimeLimit,
        this.perMinuteWaitingCharge,
        this.cancelationCharges,
        this.cancelBy,
        this.paymentId,
        this.paymentType,
        this.paymentStatus,
        this.extraCharges,
        this.fixedCharge,
        this.couponDiscount,
        this.couponCode,
        // this.couponData,
        this.isRiderRated,
        this.isDriverRated,
        this.maxTimeForFindDriverForRideRequest,
        this.travelerInfo,
        this.contactNumber,
        this.firstName,
        this.lastName,
        this.email,
        this.passenger,
        this.driverNote,
        this.internalNote,
        this.surcharge,
        this.corporateId,
        this.corporateName,
        this.weight,
        this.parcelDescription,
        this.pickupContactNumber,
        this.pickupPersonName,
        this.pickupDescription,
        this.deliveryContactNumber,
        this.deliveryPersonName,
        this.deliveryDescription,
        this.discount,
        this.createdAt,
        this.updatedAt,
        this.regionId,
        this.isRideForOther,
        this.otherRiderData,
        this.invoiceUrl,
        this.invoiceName});

  MyOrderData.fromJson(Map<String, dynamic> json) {
    rideHistory= json['ride_history'] != null ? (json['ride_history'] as List).map((i) => RideHistory.fromJson(i)).toList() : null;
    id = json['id'];
    type = json['type'];
    riderId = json['rider_id'];
    serviceId = json['service_id'];
    datetime = json['datetime'];
    isSchedule = json['is_schedule'];
    scheduleDatetime = json['schedule_datetime'];
    rideAttempt = json['ride_attempt'];
    otp = json['otp'];
    totalAmount = json['total_amount'];
    subtotal = json['subtotal'];
    extraChargesAmount = json['extra_charges_amount'];
    driverId = json['driver_id'];
    driverName = json['driver_name'];
    riderName = json['rider_name'];
    driverEmail = json['driver_email'];
    riderEmail = json['rider_email'];
    driverContactNumber = json['driver_contact_number'];
    riderContactNumber = json['rider_contact_number'];
    driverProfileImage = json['driver_profile_image'];
    riderProfileImage = json['rider_profile_image'];
    startLatitude = json['start_latitude'];
    startLongitude = json['start_longitude'];
    startAddress = json['start_address'];
    endLatitude = json['end_latitude'];
    endLongitude = json['end_longitude'];
    endAddress = json['end_address'];
    distanceUnit = json['distance_unit'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    riderequestInDriverId = json['riderequest_in_driver_id'];
    distance = json['distance'];
    duration = json['duration'];
    seatCount = json['seat_count'];
    reason = json['reason'];
    status = json['status'];
    tips = json['tips'];
    baseFare = json['base_fare'];
    minimumFare = json['minimum_fare'];
    perDistance = json['per_distance'];
    perDistanceCharge = json['per_distance_charge'];
    perMinuteDrive = json['per_minute_drive'];
    perMinuteDriveCharge = json['per_minute_drive_charge'];
    perMinuteWaiting = json['per_minute_waiting'];
    waitingTime = json['waiting_time'];
    waitingTimeLimit = json['waiting_time_limit'];
    perMinuteWaitingCharge = json['per_minute_waiting_charge'];
    cancelationCharges = json['cancelation_charges'];
    cancelBy = json['cancel_by'];
    paymentId = json['payment_id'];
    paymentType = json['payment_type'];
    paymentStatus = json['payment_status'];
    if (json['extra_charges'] != null) {
      extraCharges = <ExtraCharges>[];
      json['extra_charges'].forEach((v) {
        extraCharges!.add(new ExtraCharges.fromJson(v));
      });
    }
    fixedCharge = json['fixed_charge'];
    couponDiscount = json['coupon_discount'];
    couponCode = json['coupon_code'];
    // couponData = json['coupon_data'];
    isRiderRated = json['is_rider_rated'];
    isDriverRated = json['is_driver_rated'];
    maxTimeForFindDriverForRideRequest =
    json['max_time_for_find_driver_for_ride_request'];
    travelerInfo = json['traveler_info'];
    contactNumber = json['contact_number'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    passenger = json['passenger'];
    driverNote = json['driver_note'];
    internalNote = json['internal_note'];
    surcharge = json['surcharge'];
    corporateId = json['corporate_id'];
    corporateName = json['corporate_name'];
    weight = json['weight'];
    parcelDescription = json['parcel_description'];
    pickupContactNumber = json['pickup_contact_number'];
    pickupPersonName = json['pickup_person_name'];
    pickupDescription = json['pickup_description'];
    deliveryContactNumber = json['delivery_contact_number'];
    deliveryPersonName = json['delivery_person_name'];
    deliveryDescription = json['delivery_description'];
    discount = json['discount'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    regionId = json['region_id'];
    isRideForOther = json['is_ride_for_other'];
    otherRiderData = json['other_rider_data'];
    invoiceUrl = json['invoice_url'];
    invoiceName = json['invoice_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.rideHistory != null) {
      data['ride_history'] = this.rideHistory!.map((v) => v.toJson()).toList();
    }
    data['id'] = this.id;
    data['type'] = this.type;
    data['rider_id'] = this.riderId;
    data['service_id'] = this.serviceId;
    data['datetime'] = this.datetime;
    data['is_schedule'] = this.isSchedule;
    data['schedule_datetime'] = this.scheduleDatetime;
    data['ride_attempt'] = this.rideAttempt;
    data['otp'] = this.otp;
    data['total_amount'] = this.totalAmount;
    data['subtotal'] = this.subtotal;
    data['extra_charges_amount'] = this.extraChargesAmount;
    data['driver_id'] = this.driverId;
    data['driver_name'] = this.driverName;
    data['rider_name'] = this.riderName;
    data['driver_email'] = this.driverEmail;
    data['rider_email'] = this.riderEmail;
    data['driver_contact_number'] = this.driverContactNumber;
    data['rider_contact_number'] = this.riderContactNumber;
    data['driver_profile_image'] = this.driverProfileImage;
    data['rider_profile_image'] = this.riderProfileImage;
    data['start_latitude'] = this.startLatitude;
    data['start_longitude'] = this.startLongitude;
    data['start_address'] = this.startAddress;
    data['end_latitude'] = this.endLatitude;
    data['end_longitude'] = this.endLongitude;
    data['end_address'] = this.endAddress;
    data['distance_unit'] = this.distanceUnit;
    data['start_time'] = this.startTime;
    data['end_time'] = this.endTime;
    data['riderequest_in_driver_id'] = this.riderequestInDriverId;
    data['distance'] = this.distance;
    data['duration'] = this.duration;
    data['seat_count'] = this.seatCount;
    data['reason'] = this.reason;
    data['status'] = this.status;
    data['tips'] = this.tips;
    data['base_fare'] = this.baseFare;
    data['minimum_fare'] = this.minimumFare;
    data['per_distance'] = this.perDistance;
    data['per_distance_charge'] = this.perDistanceCharge;
    data['per_minute_drive'] = this.perMinuteDrive;
    data['per_minute_drive_charge'] = this.perMinuteDriveCharge;
    data['per_minute_waiting'] = this.perMinuteWaiting;
    data['waiting_time'] = this.waitingTime;
    data['waiting_time_limit'] = this.waitingTimeLimit;
    data['per_minute_waiting_charge'] = this.perMinuteWaitingCharge;
    data['cancelation_charges'] = this.cancelationCharges;
    data['cancel_by'] = this.cancelBy;
    data['payment_id'] = this.paymentId;
    data['payment_type'] = this.paymentType;
    data['payment_status'] = this.paymentStatus;
    if (this.extraCharges != null) {
      data['extra_charges'] =
          this.extraCharges!.map((v) => v.toJson()).toList();
    }
    data['fixed_charge'] = this.fixedCharge;
    data['coupon_discount'] = this.couponDiscount;
    data['coupon_code'] = this.couponCode;
    // data['coupon_data'] = this.couponData;
    data['is_rider_rated'] = this.isRiderRated;
    data['is_driver_rated'] = this.isDriverRated;
    data['max_time_for_find_driver_for_ride_request'] =
        this.maxTimeForFindDriverForRideRequest;
    data['traveler_info'] = this.travelerInfo;
    data['contact_number'] = this.contactNumber;
    data['first_name'] = this.firstName;
    data['last_name'] = this.lastName;
    data['email'] = this.email;
    data['passenger'] = this.passenger;
    data['driver_note'] = this.driverNote;
    data['internal_note'] = this.internalNote;
    data['surcharge'] = this.surcharge;
    data['corporate_id'] = this.corporateId;
    data['corporate_name'] = this.corporateName;
    data['weight'] = this.weight;
    data['parcel_description'] = this.parcelDescription;
    data['pickup_contact_number'] = this.pickupContactNumber;
    data['pickup_person_name'] = this.pickupPersonName;
    data['pickup_description'] = this.pickupDescription;
    data['delivery_contact_number'] = this.deliveryContactNumber;
    data['delivery_person_name'] = this.deliveryPersonName;
    data['delivery_description'] = this.deliveryDescription;
    data['discount'] = this.discount;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['region_id'] = this.regionId;
    data['is_ride_for_other'] = this.isRideForOther;
    data['other_rider_data'] = this.otherRiderData;
    data['invoice_url'] = this.invoiceUrl;
    data['invoice_name'] = this.invoiceName;
    return data;
  }
}
class ExtraCharges {
  int? id;
  String? title;
  String? chargesType;
  num? charges;
  int? countryId;
  int? cityId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  ExtraCharges({
    this.id,
    this.title,
    this.chargesType,
    this.charges,
    this.countryId,
    this.cityId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  ExtraCharges.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    chargesType = json['charges_type'];
    charges = json['charges'];
    countryId = json['country_id'];
    cityId = json['city_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    //  chargeAmount = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['charges_type'] = this.chargesType;
    data['charges'] = this.charges;
    data['country_id'] = this.countryId;
    data['city_id'] = this.cityId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    return data;
  }
}