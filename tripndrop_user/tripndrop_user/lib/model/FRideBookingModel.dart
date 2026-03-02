class FRideBookingModel {
  int? riderId;
  int? driverID;
  List<int>? driver_ids; // Array of driver IDs for ride offers (snake_case to match driver app)
  int? rideId;
  String? status;
  String? paymentType;
  int? onStreamApiCall;
  int? onRiderStreamApiCall;
  int? tips;
  String? paymentStatus;

  FRideBookingModel({
    this.riderId,
    this.driverID,
    this.driver_ids,
    this.rideId,
    this.paymentStatus,
    this.status,
    this.paymentType,
    this.tips,
    this.onStreamApiCall = 0,
    this.onRiderStreamApiCall = 0,
  });

  FRideBookingModel.fromJson(Map<String, dynamic> json) {
    riderId = int.tryParse(json["rider_id"].toString());
    driverID = int.tryParse(json["driver_id"].toString());
    if (json["driver_ids"] != null) {
      driver_ids = List<int>.from(json["driver_ids"].map((e) => int.tryParse(e.toString()) ?? 0));
    }
    rideId = int.tryParse(json["ride_id"].toString());
    paymentStatus = json['payment_status'];
    status = json["status"];
    tips = int.tryParse(json["tips"].toString()) ?? null;
    paymentType = json["payment_type"];
    onStreamApiCall = json["on_stream_api_call"];
    onRiderStreamApiCall = json["on_rider_stream_api_call"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["rider_id"] = this.riderId;
    data["ride_id"] = this.rideId;
    data["driver_id"] = this.driverID;
    data["driver_ids"] = this.driver_ids ?? [];
    data['payment_status'] = this.paymentStatus;
    data["status"] = this.status;
    data["tips"] = this.tips;
    data["payment_type"] = this.paymentType;
    data["on_stream_api_call"] = this.onStreamApiCall;
    data["on_rider_stream_api_call"] = this.onRiderStreamApiCall;
    return data;
  }
}
