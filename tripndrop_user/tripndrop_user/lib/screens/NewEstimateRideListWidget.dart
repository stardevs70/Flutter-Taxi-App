import 'dart:async';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:taxi_booking/screens/PaymentScreen.dart';
import 'package:taxi_booking/screens/RideDetailScreen.dart';
import 'package:taxi_booking/utils/Extensions/WidgetExtension.dart';
import 'package:taxi_booking/utils/Extensions/int_extensions.dart';

import '../../components/CouPonWidget.dart';
import '../../components/RideAcceptWidget.dart';
import '../../main.dart';
import '../../network/RestApis.dart';
import '../../utils/Colors.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';
import '../../utils/Extensions/app_textfield.dart';
import '../components/BookingWidget.dart';
import '../components/CarDetailWidget.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../model/CurrentRequestModel.dart';
import '../model/EstimatePriceModel.dart';
import '../model/FRideBookingModel.dart';
import '../screens/ReviewScreen.dart';
import '../screens/WalletScreen.dart';
import '../service/RideService.dart';
import '../utils/Extensions/context_extension.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'BidingScreen.dart';
import 'DashBoardScreen.dart';
import 'RidePaymentDetailScreen.dart';
import '../model/HourlyPricingModel.dart';
import '../service/NotificationService.dart';
// ignore: must_be_immutable
class NewEstimateRideListWidget extends StatefulWidget {
  final LatLng sourceLatLog;
  final LatLng destinationLatLog;
  final String sourceTitle;
  final String destinationTitle;
  bool isCurrentRequest;
  final int? servicesId;
  final int? id;
  Map? multiDropLocationNamesObj;
  Map? multiDropObj;
  String? dt;
  String? pickupTimeValue;
  bool is_taxi_service;
  var tripDetail;
  var parcel_detail;

  NewEstimateRideListWidget(
      {required this.sourceLatLog,
      required this.destinationLatLog,
      required this.sourceTitle,
      required this.destinationTitle,
      this.isCurrentRequest = false,
      this.servicesId,
      this.id,
      this.pickupTimeValue,
      this.multiDropLocationNamesObj,
      this.multiDropObj,
      this.dt,
      required this.is_taxi_service,
      this.tripDetail,
      this.parcel_detail});

  @override
  NewEstimateRideListWidgetState createState() => NewEstimateRideListWidgetState();
}

class NewEstimateRideListWidgetState extends State<NewEstimateRideListWidget> with WidgetsBindingObserver {
  bool showDeliveryService = false;
  var deliveryDataJson;
  int passengers = 1;
  int luggage = 1;
  int setPassengers = 1;
  String serviceMarker = '';
  RideService rideService = RideService();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController promoCode = TextEditingController();
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? googleMapController;
  final Set<Marker> markers = {};
  String countryCode = defaultCountryCode;
  Set<Polyline> polyLines = Set<Polyline>();
  late PolylinePoints polylinePoints;
  late Marker sourceMarker;
  late Marker destinationMarker;
  late LatLng userLatLong;
  late DateTime scheduleData;
  String? distanceUnit = DISTANCE_TYPE_KM;
  bool isBooking = false;
  bool isRideSelection = false;
  bool bidingEnabled = false;
  bool bidRaised = false;
  bool isRideForOther = true;
  int selectedIndex = 0;
  int rideRequestId = 0;
  num mTotalAmount = 0;
  double? durationOfDrop = 0.0;
  bool rideCancelDetected = false;
  double? distance = 0;
  double locationDistance = 0.0;
  String? mSelectServiceAmount;
  String? mSelectServiceSubTotal;
  List<String> _modeOfPayments = [];
  List<ServicesListData> serviceList = [];
  List<LatLng> polylineCoordinates = [];
  LatLng? driverLatitudeLocation;
  String paymentMethodType = '';
  String? oldPaymentType;
  ServicesListData? servicesListData;
  OnRideRequest? rideRequestData;
  Driver? driverData;
  Timer? timer;
  DateTime? schduleRideDateTime;
  var key = GlobalKey<ScaffoldState>();
  late BitmapDescriptor sourceIcon;
  late BitmapDescriptor destinationIcon;
  late BitmapDescriptor driverIcon;
  bool currentScreen = true;
  String? formattedTime;
  late FocusNode myFocusNode;
  TextEditingController bidAmountController = TextEditingController();
  String? parsedDate;
  bool statusMismatchApiCall = false;

  // Extra booking options
  bool tripProtectionEnabled = false;
  bool meetAndGreetEnabled = false;
  bool travelingWithPetEnabled = false;
  bool childSeatEnabled = false;
  TextEditingController meetGreetNameController = TextEditingController();
  TextEditingController meetGreetCommentsController = TextEditingController();
  int boosterSeatCount = 0;
  int rearFacingInfantSeatCount = 0;
  int forwardFacingToddlerSeatCount = 0;

  // Extra options pricing
  static const double TRIP_PROTECTION_PRICE = 15.0;
  static const double MEET_AND_GREET_PRICE = 35.0;  // Updated per client request
  static const double TRAVELING_WITH_PET_PRICE = 15.0;
  static const double CHILD_SEAT_PRICE = 25.0;

  // Calculate total extras price
  double get extrasTotal {
    double total = 0;
    if (tripProtectionEnabled) total += TRIP_PROTECTION_PRICE;
    if (meetAndGreetEnabled) total += MEET_AND_GREET_PRICE;
    if (travelingWithPetEnabled) total += TRAVELING_WITH_PET_PRICE;
    if (childSeatEnabled) total += CHILD_SEAT_PRICE;
    return total;
  }

  // Hourly booking properties
  bool get isHourlyBooking => widget.tripDetail != null && widget.tripDetail['booking_type'] == 'HOURLY';
  int get hoursBooked => widget.tripDetail?['hours_booked'] ?? 2;

  /// Calculate hourly price for a service based on vehicle type
  num getHourlyPrice(ServicesListData service) {
    String vehicleName = service.name?.toUpperCase() ?? 'SEDAN';
    HourlyPricingModel pricing;

    if (vehicleName.contains('SUV') && vehicleName.contains('XL')) {
      pricing = HourlyPricingModel.getDefaultPricing('SUV_XL');
    } else if (vehicleName.contains('SUV')) {
      pricing = HourlyPricingModel.getDefaultPricing('SUV');
    } else {
      pricing = HourlyPricingModel.getDefaultPricing('SEDAN');
    }

    return (pricing.baseHourPrice ?? 105) * hoursBooked;
  }

  /// Get the display price - hourly price if hourly booking, otherwise standard price
  num getDisplayPrice(ServicesListData service) {
    if (isHourlyBooking) {
      return getHourlyPrice(service);
    }
    return service.totalAmount ?? 0;
  }

  @override
  void initState() {
    super.initState();
    print("CHeckStartLat:::${widget.sourceLatLog}");
    print("CHeckEndLat:::${widget.destinationLatLog}");
    print("----------148>>${widget.tripDetail.toString()}");
    myFocusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    init();
    getNewService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (key.currentContext != null) {
      if (state == AppLifecycleState.resumed) {
        final GoogleMapController controller = await _controller.future;
        onMapCreated(controller);
      }
    }
  }

  void _changePassengerCount(int delta) {
    setState(() {
      passengers = (passengers + delta).clamp(1, setPassengers);
    });
  }

  void _changeLuggageCount(int delta) {
    setState(() {
      luggage = (luggage + delta).clamp(0, 100);
    });
  }

  void init() async {
    sourceIcon = await getResizedMarker(SourceIcon);
    riderIcon = await getResizedMarker(SourceIcon);
    driverIcon = await getResizedMarker(DriverIcon);
    destinationIcon = await getResizedMarker(DestinationIcon);
    getCurrentRequest();
    isBooking = widget.isCurrentRequest;
    getWalletDataApi();
  }

  getCurrentRequest() async {
    try {
      timer?.cancel();
    } catch (e) {}
    print("getCurrentRequest.call.detected");
    await getCurrentRideRequest().then((value) {
      // Reset the flag to allow future status change updates
      statusMismatchApiCall = false;
      serviceMarker = value.service_marker.validate();
      rideRequestData = value.rideRequest ?? value.onRideRequest;
      if (value.driver != null) {
        driverData = value.driver!;
        getUserDetailLocation();
      } else {
        getServiceList();
      }
      if (rideRequestData != null) {
        widget.is_taxi_service = rideRequestData!.type != TRANSPORT;
        if (rideRequestData != null) {
          if (driverData != null && rideRequestData!.status != COMPLETED) {
            timer = Timer.periodic(Duration(seconds: 10), (Timer t) {
              DateTime? d = DateTime.tryParse(sharedPref.getString("UPDATE_CALL").toString());
              if (d != null && DateTime.now().difference(d).inSeconds > 10) {
                if (rideRequestData != null && (rideRequestData!.status == ACCEPTED || rideRequestData!.status == ARRIVING || rideRequestData!.status == ARRIVED)) {
                  getUserDetailLocation();
                } else {
                  try {
                    timer!.cancel();
                  } catch (e) {}
                }
                sharedPref.setString("UPDATE_CALL", DateTime.now().toString());
              } else if (d == null) {
                sharedPref.setString("UPDATE_CALL", DateTime.now().toString());
              }
            });
          } else {
            timer?.cancel();
            timer = null;
          }
        }
        setState(() {});
        if (rideRequestData!.status == COMPLETED && rideRequestData != null && driverData != null) {
          if (timer != null) {
            timer!.cancel();
          }
          timer = null;
          if (currentScreen != false) {
            currentScreen = false;
            launchScreen(context, ReviewScreen(rideRequest: rideRequestData!, driverData: driverData), pageRouteAnimation: PageRouteAnimation.SlideBottomTop, isNewTask: true);
          }
        }
      } else if (appStore.isRiderForAnother == "1" && value.payment != null && value.payment!.paymentStatus == SUCCESS) {
        if (currentScreen != false) {
          currentScreen = false;
          Future.delayed(
            Duration(seconds: 1),
            () {
              launchScreen(context, RidePaymentDetailScreen(rideId: value.payment!.rideRequestId), pageRouteAnimation: PageRouteAnimation.SlideBottomTop, isNewTask: true);
            },
          );
        }
      }
    }).catchError((error, stack) {
      FirebaseCrashlytics.instance.recordError("review_navigate_issue::" + error.toString(), stack, fatal: true);
      log("Error-- " + error.toString());
    });
  }

  Future<void> getServiceList() async {
    markers.clear();
    polylinePoints = PolylinePoints();
    setPolyLines(
      sourceLocation: LatLng(widget.sourceLatLog.latitude, widget.sourceLatLog.longitude),
      destinationLocation: LatLng(widget.destinationLatLog.latitude, widget.destinationLatLog.longitude),
      driverLocation: driverLatitudeLocation,
    );
    MarkerId id = MarkerId('Source');
    markers.add(
      Marker(
        markerId: id,
        position: LatLng(widget.sourceLatLog.latitude, widget.sourceLatLog.longitude),
        infoWindow: InfoWindow(title: widget.sourceTitle),
        icon: sourceIcon,
      ),
    );
    MarkerId id2 = MarkerId('DriverLocation');
    markers.remove(id2);

    if (rideRequestData != null &&
        rideRequestData!.multiDropLocation != null &&
        rideRequestData!.multiDropLocation!.isNotEmpty &&
        rideRequestData!.status != ACCEPTED &&
        rideRequestData!.status != ARRIVING &&
        rideRequestData!.status != ARRIVED) {
    } else {
      MarkerId id3 = MarkerId('Destination');
      markers.remove(id3);
      if (rideRequestData != null && (rideRequestData!.status == ACCEPTED || rideRequestData!.status == ARRIVING || rideRequestData!.status == ARRIVED)) {
        try {
          var driverIcon1 = await getNetworkImageMarker(serviceMarker.validate());
          markers.add(
            Marker(
              markerId: id2,
              position: LatLng(driverLatitudeLocation!.latitude, driverLatitudeLocation!.longitude),
              icon: driverIcon1,
            ),
          );
          setState(() {});
        } catch (e) {
          markers.add(
            Marker(
              markerId: id2,
              position: LatLng(driverLatitudeLocation!.latitude, driverLatitudeLocation!.longitude),
              icon: driverIcon,
            ),
          );
        }
      } else {
        markers.add(
          Marker(
            markerId: id3,
            position: LatLng(widget.destinationLatLog.latitude, widget.destinationLatLog.longitude),
            infoWindow: InfoWindow(title: widget.destinationTitle),
            icon: destinationIcon,
          ),
        );
      }
    }
    setState(() {});
  }

  Future<void> getNewService({bool coupon = false}) async {
    appStore.setLoading(true);
    Map req = {
      "pick_lat": widget.sourceLatLog.latitude,
      "pick_lng": widget.sourceLatLog.longitude,
      "drop_lat": widget.destinationLatLog.latitude,
      "drop_lng": widget.destinationLatLog.longitude,
      "service_type": widget.is_taxi_service == true ? BOOK_RIDE : TRANSPORT,
      "pickup_zone_id": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["pickup_zone_id"],
      "drop_zone_id": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["drop_zone_id"],
      "pickup_airport_id": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["pickup_airport_id"],
      "drop_airport_id": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["drop_airport_id"],
      "trip_type": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["trip_type"],
      if (coupon) "coupon_code": promoCode.text.trim(),
    };
    var dataJustCheck = [];
    dataJustCheck.add({"lat": widget.sourceLatLog.latitude, "lng": widget.sourceLatLog.longitude});
    if (widget.multiDropObj != null && widget.multiDropObj!.isNotEmpty) {
      widget.multiDropObj!.forEach(
        (key, value) {
          LatLng s = value as LatLng;
          dataJustCheck.add({
            "lat": s.latitude,
            "lng": s.longitude,
          });
        },
      );
      req['multi_location'] = dataJustCheck;
    }
    if (widget.is_taxi_service == false) {
      deliveryDataJson = widget.parcel_detail;
      req['weight'] = deliveryDataJson['weight'];
    }

    await estimatePriceList(req).then((value) {
      appStore.setLoading(false);
      serviceList.clear();
      value.data!.sort((a, b) => a.totalAmount!.compareTo(b.totalAmount!));
      serviceList.addAll(value.data ?? []);
      if (serviceList.isNotEmpty && serviceList.first.capacity != null) {
        setPassengers = serviceList.first.capacity?.toInt() ?? 0;
      }
      if (serviceList.isNotEmpty) {
        locationDistance = serviceList[0].dropoffDistanceInKm!.toDouble();
        if (serviceList[0].distanceUnit == DISTANCE_TYPE_KM) {
          locationDistance = serviceList[0].dropoffDistanceInKm!.toDouble();
          distanceUnit = DISTANCE_TYPE_KM;
        } else {
          locationDistance = serviceList[0].dropoffDistanceInKm!.toDouble() * 0.621371;
          distanceUnit = DISTANCE_TYPE_MILE;
        }
        durationOfDrop = serviceList[0].duration!.toDouble();
      }

      if (serviceList.isNotEmpty) servicesListData = serviceList[0];

      _modeOfPayments = serviceList[0].paymentMethod ?? [];
      if (paymentMethodType.isNotEmpty && _modeOfPayments.contains(paymentMethodType)) {
        paymentMethodType = _modeOfPayments[_modeOfPayments.indexOf(paymentMethodType)];
      } else {
        if (_modeOfPayments.isNotEmpty) paymentMethodType = _modeOfPayments[0];
      }
      if (serviceList.isNotEmpty) {
        // Use hourly price if hourly booking
        if (isHourlyBooking) {
          mSelectServiceAmount = getHourlyPrice(serviceList[0]).toStringAsFixed(fixedDecimal);
          mSelectServiceSubTotal = getHourlyPrice(serviceList[0]).toStringAsFixed(fixedDecimal);
        } else if (serviceList[0].discountAmount != 0) {
          mSelectServiceAmount = serviceList[0].subtotal!.toStringAsFixed(fixedDecimal);
          mSelectServiceSubTotal=serviceList[0].subtotal!.toStringAsFixed(fixedDecimal);
        } else {
          mSelectServiceAmount = serviceList[0].totalAmount!.toStringAsFixed(fixedDecimal);
          mSelectServiceSubTotal=serviceList[0].subtotal!.toStringAsFixed(fixedDecimal);
        }
      }
      if (oldPaymentType != null) {
        paymentMethodType = oldPaymentType ?? '';
      }
      setState(() {});
    }).catchError((error,s) {
      print("ERR::$error:::stack:::$s");
      throw error;
    });
  }

  Future<void> getCouponNewService() async {
    appStore.setLoading(true);
    Map req = {
      "pick_lat": widget.sourceLatLog.latitude,
      "pick_lng": widget.sourceLatLog.longitude,
      "drop_lat": widget.destinationLatLog.latitude,
      "drop_lng": widget.destinationLatLog.longitude,
      "pickup_zone_id": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["pickup_zone_id"],
      "drop_zone_id": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["drop_zone_id"],
      "pickup_airport_id": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["pickup_airport_id"],
      "drop_airport_id": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["drop_airport_id"],
      "trip_type": widget.is_taxi_service != true || widget.tripDetail == null ? "" : widget.tripDetail["trip_type"],
      "coupon_code": promoCode.text.trim(),
      "service_type": widget.is_taxi_service == true ? BOOK_RIDE : TRANSPORT,
    };
    if (widget.is_taxi_service == false) {
      deliveryDataJson = widget.parcel_detail;
      req['weight'] = deliveryDataJson['weight'];
    }

    if (widget.multiDropObj != null) {
      var dataJustCheck = [];
      dataJustCheck.add({"lat": widget.sourceLatLog.latitude, "lng": widget.sourceLatLog.longitude});
      widget.multiDropObj!.forEach(
        (key, value) {
          LatLng s = value as LatLng;
          dataJustCheck.add({
            "lat": s.latitude,
            "lng": s.longitude,
          });
        },
      );
      req['multi_location'] = dataJustCheck;
    }

    await estimatePriceList(req).then((value) {
      appStore.setLoading(false);
      serviceList.clear();
      value.data!.sort((a, b) => a.totalAmount!.compareTo(b.totalAmount!));
      serviceList.addAll(value.data!);
      if (serviceList.isNotEmpty) {
        locationDistance = serviceList[selectedIndex].dropoffDistanceInKm!.toDouble();

        if (serviceList[selectedIndex].distanceUnit == DISTANCE_TYPE_KM) {
          locationDistance = serviceList[selectedIndex].dropoffDistanceInKm!.toDouble();
          distanceUnit = DISTANCE_TYPE_KM;
        } else {
          locationDistance = serviceList[selectedIndex].dropoffDistanceInKm!.toDouble() * 0.621371;
          distanceUnit = DISTANCE_TYPE_MILE;
        }
        durationOfDrop = serviceList[selectedIndex].duration!.toDouble();
      }
      if (serviceList.isNotEmpty) servicesListData = serviceList[selectedIndex];
      _modeOfPayments = serviceList[selectedIndex].paymentMethod!;
      if (paymentMethodType.isNotEmpty && _modeOfPayments.contains(paymentMethodType)) {
        paymentMethodType = _modeOfPayments[_modeOfPayments.indexOf(paymentMethodType)];
      } else {
        if (_modeOfPayments.isNotEmpty) paymentMethodType = _modeOfPayments[selectedIndex];
      }
      if (serviceList.isNotEmpty) {
        if (serviceList[selectedIndex].discountAmount != 0) {
          mSelectServiceAmount = serviceList[selectedIndex].subtotal!.toStringAsFixed(fixedDecimal);
          mSelectServiceSubTotal=serviceList[selectedIndex].subtotal!.toStringAsFixed(fixedDecimal);
        } else {
          mSelectServiceAmount = serviceList[selectedIndex].totalAmount!.toStringAsFixed(fixedDecimal);
          mSelectServiceSubTotal=serviceList[selectedIndex].subtotal!.toStringAsFixed(fixedDecimal);
        }
      }
      setState(() {});
      Navigator.pop(context);
    }).catchError((error) {
      throw error;
    });
  }

  Future<void> setPolyLinesDriver({required LatLng sourceLocation, LatLng? driverLocation}) async {
    try {
      for (int i = 0; i < rideRequestData!.multiDropLocation!.length; i++) {
        PolylineResult b = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_MAP_API_KEY,
          request: PolylineRequest(
              origin:
                  i == 0 ? PointLatLng(sourceLocation.latitude, sourceLocation.longitude) : PointLatLng(rideRequestData!.multiDropLocation![i - 1].lat, rideRequestData!.multiDropLocation![i - 1].lng),
              destination: PointLatLng(rideRequestData!.multiDropLocation![i].lat, rideRequestData!.multiDropLocation![i].lng),
              mode: TravelMode.driving),
        );
        List<LatLng> routeCoordinates = [];
        markers.add(
          Marker(
            markerId: MarkerId("multi_drop_$i"),
            position: LatLng(rideRequestData!.multiDropLocation![i].lat, rideRequestData!.multiDropLocation![i].lng),
            infoWindow: InfoWindow(title: "${rideRequestData!.multiDropLocation![i].address}"),
            icon: destinationIcon,
          ),
        );
        b.points.forEach((element) {
          routeCoordinates.add(LatLng(element.latitude, element.longitude));
        });
        polyLines.add(Polyline(
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
          jointType: JointType.round,
          visible: true,
          width: 7,
          polylineId: PolylineId('multi_poly_$i'),
          color: polyLineColor,
          points: routeCoordinates,
        ));
      }
      setState(() {});
    } catch (e) {
      throw e;
    }
  }

  Future<void> setPolyLines({required LatLng sourceLocation, required LatLng destinationLocation, LatLng? driverLocation}) async {
    print("PolyLineCreatedCall");
    polyLines.clear();
    polylineCoordinates.clear();
    PolylineResult result;
    if (rideRequestData != null &&
        rideRequestData!.multiDropLocation != null &&
        rideRequestData!.multiDropLocation!.isNotEmpty &&
        rideRequestData!.status != ACCEPTED &&
        rideRequestData!.status != ARRIVING &&
        rideRequestData!.status != ARRIVED) {
      print("PolyLineCreatedCall410");
      await setPolyLinesDriver(sourceLocation: sourceLocation, driverLocation: driverLocation);
    } else if (widget.multiDropObj != null && widget.multiDropObj!.isNotEmpty && rideRequestData == null) {
      print("PolyLineCreatedCall414");
      try {
        for (int i = 0; i < widget.multiDropObj!.length; i++) {
          PolylineResult b = await polylinePoints.getRouteBetweenCoordinates(
            googleApiKey: GOOGLE_MAP_API_KEY,
            request: PolylineRequest(
                origin: i == 0 ? PointLatLng(sourceLocation.latitude, sourceLocation.longitude) : PointLatLng(widget.multiDropObj![i - 1].latitude, widget.multiDropObj![i - 1].longitude),
                destination: PointLatLng(widget.multiDropObj![i].latitude, widget.multiDropObj![i].longitude),
                mode: TravelMode.driving),
          );
          List<LatLng> routeCoordinates = [];
          markers.add(
            Marker(
              markerId: MarkerId("multi_drop_$i"),
              position: LatLng(widget.multiDropObj![i].latitude, widget.multiDropObj![i].longitude),
              infoWindow: InfoWindow(title: "${widget.multiDropLocationNamesObj![i]}"),
              icon: destinationIcon,
            ),
          );
          b.points.forEach((element) {
            routeCoordinates.add(LatLng(element.latitude, element.longitude));
          });
          polyLines.add(Polyline(
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            jointType: JointType.round,
            visible: true,
            width: 7,
            polylineId: PolylineId('multi_poly_$i'),
            color: polyLineColor,
            points: routeCoordinates,
          ));
        }
        setState(() {});
      } catch (e) {
        throw e;
      }
    } else {
      try {
        result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_MAP_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
              destination: rideRequestData != null && (rideRequestData!.status == ACCEPTED || rideRequestData!.status == ARRIVING || rideRequestData!.status == ARRIVED)
                  ? PointLatLng(driverLocation!.latitude, driverLocation.longitude)
                  : PointLatLng(destinationLocation.latitude, destinationLocation.longitude),
              mode: TravelMode.driving),
        );
        if (result.points.isNotEmpty) {
          polylineCoordinates.clear();
          result.points.forEach((element) {
            polylineCoordinates.add(LatLng(element.latitude, element.longitude));
          });
          polyLines.clear();
          polyLines.add(Polyline(
            visible: true,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            jointType: JointType.round,
            width: 7,
            polylineId: PolylineId('poly'),
            color: polyLineColor,
            points: polylineCoordinates,
          ));
          setState(() {});
        }
      } catch (e) {}
    }
  }

  onMapCreated(GoogleMapController controller) async {
    try {
      googleMapController = controller;
      _controller.complete(controller);
      await Future.delayed(Duration(milliseconds: 50));
      await googleMapController!.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(
              southwest: LatLng(widget.sourceLatLog.latitude <= widget.destinationLatLog.latitude ? widget.sourceLatLog.latitude : widget.destinationLatLog.latitude,
                  widget.sourceLatLog.longitude <= widget.destinationLatLog.longitude ? widget.sourceLatLog.longitude : widget.destinationLatLog.longitude),
              northeast: LatLng(widget.sourceLatLog.latitude <= widget.destinationLatLog.latitude ? widget.destinationLatLog.latitude : widget.sourceLatLog.latitude,
                  widget.sourceLatLog.longitude <= widget.destinationLatLog.longitude ? widget.destinationLatLog.longitude : widget.sourceLatLog.longitude)),
          100));
      setState(() {});
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  getWalletDataApi() {
    getWalletData().then((value) {
      mTotalAmount = value.totalAmount ?? 0.0;
    }).catchError((error) {
      throw error;
    });
  }

  Future<void> getUserDetailLocation() async {
    if (rideRequestData?.status != COMPLETED) {
      if (driverData == null) return;
      getUserDetail(userId: driverData!.id).then((value) {
        driverLatitudeLocation = LatLng(double.parse(value.data!.latitude!), double.parse(value.data!.longitude!));
        getServiceList();
      }).catchError((error) {
        throw error;
      });
    } else {
      if (timer != null) timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (timer != null) timer!.cancel();
    myFocusNode.dispose();
    nameController.dispose();
    phoneController.dispose();
    promoCode.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mSomeOnElse() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(language.lblRideInformation, style: boldTextStyle()),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(Icons.close),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppTextField(
              controller: nameController,
              autoFocus: false,
              isValidationRequired: false,
              textFieldType: TextFieldType.NAME,
              keyboardType: TextInputType.name,
              errorThisFieldRequired: language.thisFieldRequired,
              decoration: inputDecoration(context, label: language.enterName),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppTextField(
              controller: phoneController,
              autoFocus: false,
              isValidationRequired: false,
              textFieldType: TextFieldType.PHONE,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorThisFieldRequired: language.thisFieldRequired,
              decoration: inputDecoration(
                context,
                label: language.enterContactNumber,
                prefixIcon: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountryCodePicker(
                        padding: EdgeInsets.zero,
                        initialSelection: countryCode,
                        showCountryOnly: false,
                        dialogSize: Size(MediaQuery.of(context).size.width - 60, MediaQuery.of(context).size.height * 0.6),
                        showFlag: true,
                        showFlagDialog: true,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                        textStyle: primaryTextStyle(),
                        dialogBackgroundColor: Theme.of(context).cardColor,
                        barrierColor: Colors.black12,
                        dialogTextStyle: primaryTextStyle(),
                        searchDecoration: InputDecoration(
                          focusColor: primaryColor,
                          iconColor: Theme.of(context).dividerColor,
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                        ),
                        searchStyle: primaryTextStyle(),
                        onInit: (c) {
                          countryCode = c!.dialCode!;
                        },
                        onChanged: (c) {
                          countryCode = c.dialCode!;
                        },
                      ),
                      VerticalDivider(color: Colors.grey.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: AppButtonWidget(
              width: MediaQuery.of(context).size.width,
              text: language.done,
              textStyle: boldTextStyle(color: Colors.white),
              color: primaryColor,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (isBooking) {
          SystemNavigator.pop();
          return false;
        } else {
          launchScreen(getContext, DashBoardScreen(), isNewTask: true);
          return false;
        }
      },
      child: Scaffold(
        key: key,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.dark,
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.dark),
          leadingWidth: 50,
          leading: Visibility(
            visible: !isBooking,
            child: inkWellWidget(
              onTap: () {
                launchScreen(getContext, DashBoardScreen(), isNewTask: true);
              },
              child: Container(
                margin: EdgeInsets.only(left: 12, bottom: 16),
                padding: EdgeInsets.all(0),
                decoration: BoxDecoration(color: context.cardColor, shape: BoxShape.circle, border: Border.all(color: dividerColor)),
                child: Icon(Icons.close, color: context.iconColor, size: 20),
              ),
            ),
          ),
          actions: [
            inkWellWidget(
              onTap: () async {
                final geoPosition = await Geolocator.getCurrentPosition(timeLimit: Duration(seconds: 30), desiredAccuracy: LocationAccuracy.high);
                googleMapController!.animateCamera(CameraUpdate.newLatLng(LatLng(geoPosition.latitude, geoPosition.longitude)));
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), spreadRadius: 1),
                  ],
                  borderRadius: BorderRadius.circular(defaultRadius),
                ),
                margin: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  Icons.my_location,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (sharedPref.getDouble(LATITUDE) != null && sharedPref.getDouble(LONGITUDE) != null)
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: GoogleMap(
                  padding: EdgeInsets.only(top: context.statusBarHeight + 4 + 24),
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: /*rideRequestData != null && (rideRequestData!.status == IN_PROGRESS) ? true : false*/ false,
                  compassEnabled: true,
                  onMapCreated: onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: widget.sourceLatLog,
                    zoom: 17,
                  ),
                  markers: markers,
                  mapType: MapType.normal,
                  polylines: polyLines,
                ),
              ),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(2 * defaultRadius), topRight: Radius.circular(2 * defaultRadius))),
              child: !isBooking
                  ? bookRideWidget()
                  : StreamBuilder(
                      stream: rideService.fetchRide(rideId: rideRequestId == 0 ? widget.id : rideRequestId),
                      builder: (context, snap) {
                        if (snap.hasData) {
                          List<FRideBookingModel> data = snap.data!.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
                          if (data.isEmpty) {
                            Future.delayed(
                              Duration(seconds: 1),
                              () {
                                if (currentScreen == false) return;
                                currentScreen = false;
                                checkRideCancel();
                              },
                            );
                          }
                          if (data.length != 0) {
                            if (data[0].onRiderStreamApiCall == 0) {
                              getCurrentRequest();
                              rideService.updateStatusOfRide(rideID: rideRequestId == 0 ? widget.id : rideRequestId, req: {'on_rider_stream_api_call': 1});
                            }

                            try {
                              if (rideRequestData != null && rideRequestData!.status != data[0].status) {
                                print("assign_ride_issue_case1: Firebase status=${data[0].status}, local status=${rideRequestData!.status}");
                                // Immediately update local status from Firebase for instant UI update
                                rideRequestData!.status = data[0].status;
                                if (statusMismatchApiCall != true) {
                                  print("assign_ride_issue_case2: Calling getCurrentRequest");
                                  statusMismatchApiCall = true;
                                  getCurrentRequest();
                                }
                              }
                            } catch (e) {
                              print("Status update error: $e");
                            }
                            if (rideRequestData != null && rideRequestData!.status == COMPLETED) {
                              if (currentScreen != false) {
                                currentScreen = false;
                                if (rideRequestData!.isRiderRated == 1) {
                                  launchScreen(context, RideDetailScreen(orderId: rideRequestData!.id!), pageRouteAnimation: PageRouteAnimation.SlideBottomTop, isNewTask: true);
                                } else {
                                  Future.delayed(
                                    Duration(seconds: 1),
                                    () {
                                      launchScreen(context, ReviewScreen(rideRequest: rideRequestData!, driverData: driverData),
                                          pageRouteAnimation: PageRouteAnimation.SlideBottomTop, isNewTask: true);
                                    },
                                  );
                                }
                              }
                              ;
                            }

                            return rideRequestData != null
                                ? rideRequestData!.status == NEW_RIDE_REQUESTED
                                    ? BookingWidget(
                                        service_type: widget.is_taxi_service == true ? BOOK_RIDE : TRANSPORT,
                                        id: rideRequestId == 0 ? widget.id : rideRequestId,
                                        isLast: true,
                                        dt: widget.dt,
                                      )
                                    : RideAcceptWidget(
                                        key: ValueKey('ride_${rideRequestData!.id}_${rideRequestData!.status}'),
                                        rideRequest: rideRequestData,
                                        driverData: driverData,
                                      )
                                : data[0].status == NEW_RIDE_REQUESTED
                                    ? BookingWidget(
                                        service_type: widget.is_taxi_service == true ? BOOK_RIDE : TRANSPORT,
                                        id: rideRequestId == 0 ? widget.id : rideRequestId,
                                        isLast: true,
                                        dt: widget.dt,
                                      )
                                    : loaderWidget();
                          } else {
                            return SizedBox();
                          }
                        } else {
                          return SizedBox();
                        }
                      }),
            ),
            Observer(builder: (context) {
              return Visibility(visible: appStore.isLoading, child: loaderWidget());
            }),
          ],
        ),
      ),
    );
  }

  Widget bookRideWidget() {
    return Stack(
      children: [
        Visibility(
          visible: serviceList.isNotEmpty,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(2 * defaultRadius), topRight: Radius.circular(2 * defaultRadius))),
            child: SingleChildScrollView(
              child: deliveryDataJson != null
                  ? serviceSelectWidget()
                  : /*isServiceTypeSelected == false
                  ? deliveryOrRideView()
                  : */
                  isRideSelection == false && appStore.isRiderForAnother == "1" && widget.is_taxi_service == true
                      ? riderSelectionWidget()
                      : serviceSelectWidget(),
            ),
          ),
        ),
        Visibility(
          visible: !appStore.isLoading && serviceList.isEmpty,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(2 * defaultRadius), topRight: Radius.circular(2 * defaultRadius))),
            child: /*isServiceTypeSelected == false
                ? SingleChildScrollView(child: deliveryOrRideView())
                : */
                Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                emptyWidget(),
                Text(language.servicesNotFound, style: boldTextStyle()),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget riderSelectionWidget() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.only(bottom: 16),
              height: 5,
              width: 70,
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
            ),
          ),
          Text(language.whoWillBeSeated, style: primaryTextStyle(size: 18)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              inkWellWidget(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: textSecondaryColorGlobal, width: 1)),
                            padding: EdgeInsets.all(12),
                            child: Image.asset(ic_add_user, fit: BoxFit.fill),
                          ),
                          if (!isRideForOther)
                            Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(language.lblSomeoneElse, style: primaryTextStyle()),
                    ],
                  ),
                  onTap: () {
                    isRideForOther = false;
                    showDialog(
                      context: context,
                      builder: (_) {
                        return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            contentPadding: EdgeInsets.all(0),
                            content: mSomeOnElse(),
                          );
                        });
                      },
                    ).then((value) {
                      setState(() {});
                    });
                    setState(() {});
                  }),
              SizedBox(width: 30),
              inkWellWidget(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: commonCachedNetworkImage(appStore.userProfile.validate(), height: 70, width: 70, fit: BoxFit.cover),
                          ),
                          if (isRideForOther)
                            Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(language.lblYou, style: primaryTextStyle()),
                    ],
                  ),
                  onTap: () {
                    isRideForOther = true;
                    setState(() {});
                  })
            ],
          ),
          SizedBox(height: 12),
          Text(language.lblWhoRidingMsg, style: secondaryTextStyle()),
          SizedBox(height: 8),
          AppButtonWidget(
            color: primaryColor,
            onTap: () async {
              if (!isRideForOther) {
                if (nameController.text.isEmptyOrNull || phoneController.text.isEmptyOrNull) {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          contentPadding: EdgeInsets.all(0),
                          content: mSomeOnElse(),
                        );
                      });
                    },
                  ).then((value) {
                    setState(() {});
                  });
                } else {
                  isRideSelection = true;
                }
              } else {
                isRideSelection = true;
              }
              setState(() {});
            },
            text: language.lblNext,
            textStyle: boldTextStyle(color: Colors.white),
            width: MediaQuery.of(context).size.width,
          ),
        ],
      ),
    );
  }

  Widget serviceSelectWidget() {
    if (!widget.pickupTimeValue.isEmptyOrNull) {
      DateTime parsedDate = DateTime.parse(widget.pickupTimeValue ?? "");

      formattedTime = DateFormat('yyyy-MM-dd hh:mm a').format(parsedDate);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(bottom: 8, top: 16),
            height: 5,
            width: 70,
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
          ),
        ),
        SingleChildScrollView(
          padding: EdgeInsets.only(left: 8, right: 8),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: serviceList.map((e) {
              return GestureDetector(
                onTap: () {
                  if (servicesListData == e) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: false,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(2 * defaultRadius), topLeft: Radius.circular(2 * defaultRadius))),
                      builder: (_) {
                        return CarDetailWidget(service: e);
                      },
                    );
                    return;
                  }
                  // Use hourly price if hourly booking
                  if (isHourlyBooking) {
                    mSelectServiceAmount = getHourlyPrice(e).toStringAsFixed(fixedDecimal);
                    mSelectServiceSubTotal = getHourlyPrice(e).toStringAsFixed(fixedDecimal);
                  } else if (e.discountAmount != 0) {
                    mSelectServiceAmount = e.subtotal!.toStringAsFixed(fixedDecimal);
                    mSelectServiceSubTotal=e.subtotal!.toStringAsFixed(fixedDecimal);
                  } else {
                    mSelectServiceAmount = e.totalAmount!.toStringAsFixed(fixedDecimal);
                    mSelectServiceSubTotal=e.subtotal!.toStringAsFixed(fixedDecimal);
                  }
                  selectedIndex = serviceList.indexOf(e);
                  servicesListData = e;
                  if (selectedIndex == serviceList.indexOf(e)) {
                    setPassengers = e.capacity?.toInt() ?? 0;
                    if (passengers > setPassengers) {
                      passengers = setPassengers;
                    }
                    setState(() {});
                  }
                  if (e.distanceUnit == DISTANCE_TYPE_KM) {
                    locationDistance = e.dropoffDistanceInKm!.toDouble();
                    distanceUnit = DISTANCE_TYPE_KM;
                  } else {
                    locationDistance = e.dropoffDistanceInKm!.toDouble() * 0.621371;
                    distanceUnit = DISTANCE_TYPE_MILE;
                  }
                  durationOfDrop = serviceList[0].duration!.toDouble();

                  _modeOfPayments = e.paymentMethod ?? [];
                  if (_modeOfPayments.isNotEmpty) {
                    paymentMethodType = _modeOfPayments.first;
                  }
                  if (e.paymentMethod == CASH_WALLET && oldPaymentType != null) {
                    paymentMethodType = oldPaymentType!;
                  }
                  setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  margin: EdgeInsets.only(top: 16, left: 8, right: 8),
                  decoration: BoxDecoration(
                    color: selectedIndex == serviceList.indexOf(e) ? primaryColor : Colors.white,
                    border: Border.all(color: dividerColor),
                    borderRadius: BorderRadius.circular(defaultRadius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      commonCachedNetworkImage(e.serviceImage.validate(), height: 50, width: 100, fit: BoxFit.contain, alignment: Alignment.center),
                      Text(e.name.validate(), style: boldTextStyle(color: selectedIndex == serviceList.indexOf(e) ? Colors.white : textPrimaryColorGlobal)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(language.capacity, style: secondaryTextStyle(size: 12, color: selectedIndex == serviceList.indexOf(e) ? Colors.white : textPrimaryColorGlobal)),
                          SizedBox(width: 4),
                          Text(e.capacity.toString() + " + 1", style: secondaryTextStyle(color: selectedIndex == serviceList.indexOf(e) ? Colors.white : textPrimaryColorGlobal)),
                        ],
                      ).visible(e.capacity != null),
                      SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Show hourly price if hourly booking, otherwise show standard price
                              if (isHourlyBooking) ...[
                                printAmountWidget(
                                  amount: '${getHourlyPrice(e).toStringAsFixed(digitAfterDecimal)}',
                                  weight: FontWeight.bold,
                                  color: selectedIndex == serviceList.indexOf(e) ? Colors.white : textPrimaryColorGlobal,
                                ),
                                Text(
                                  '${hoursBooked} hrs',
                                  style: secondaryTextStyle(
                                    size: 10,
                                    color: selectedIndex == serviceList.indexOf(e) ? Colors.white70 : textSecondaryColorGlobal,
                                  ),
                                ),
                              ] else ...[
                                printAmountWidget(
                                  amount: '${e.totalAmount!.toStringAsFixed(digitAfterDecimal)}',
                                  weight: e.discountAmount != 0 ? FontWeight.normal : FontWeight.bold,
                                  textDecoration: e.discountAmount != 0 ? TextDecoration.lineThrough : TextDecoration.none,
                                  color: selectedIndex == serviceList.indexOf(e) ? Colors.white : textPrimaryColorGlobal,
                                ),
                                if (e.discountAmount != 0)
                                  printAmountWidget(
                                    amount: '${e.subtotal?.toStringAsFixed(digitAfterDecimal)}',
                                    color: selectedIndex == serviceList.indexOf(e) ? Colors.white : textPrimaryColorGlobal,
                                  ),
                              ],
                            ],
                          ),
                          SizedBox(width: 8),
                          inkWellWidget(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: false,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(2 * defaultRadius), topLeft: Radius.circular(2 * defaultRadius))),
                                builder: (_) {
                                  return CarDetailWidget(service: e);
                                },
                              );
                            },
                            child: Icon(Icons.info_outline_rounded, size: 16, color: selectedIndex == serviceList.indexOf(e) ? Colors.white : textPrimaryColorGlobal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8),
        if (widget.is_taxi_service == true)
          _buildCounter(
            '${language.lblPassengers}',
            Icons.person,
            passengers,
            () => _changePassengerCount(-1),
            () => _changePassengerCount(1),
          ),
        if (widget.is_taxi_service == true)
          _buildCounter(
            '${language.lblLuggage}',
            Icons.luggage,
            luggage,
            () => _changeLuggageCount(-1),
            () => _changeLuggageCount(1),
          ),
        SizedBox(height: 8),
        // Extra options section
        if (widget.is_taxi_service == true) _buildExtrasSection(),
        SizedBox(height: 8),
        if (mSelectServiceAmount != null && paymentMethodType != CASH_WALLET && paymentMethodType == WALLET && double.parse(mSelectServiceAmount!) >= mTotalAmount.toDouble())
          Padding(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: dividerColor), borderRadius: BorderRadius.circular(defaultRadius)),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text(language.lblLessWalletAmount, style: boldTextStyle(size: 12, color: Colors.red, letterSpacing: 0.5, weight: FontWeight.w500))),
                  if (mSelectServiceAmount != null && paymentMethodType != CASH_WALLET && paymentMethodType == WALLET && double.parse(mSelectServiceAmount!) >= mTotalAmount.toDouble())
                    inkWellWidget(
                      onTap: () {
                        oldPaymentType = paymentMethodType;
                        launchScreen(context, WalletScreen()).then((value) {
                          init();
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: dividerColor), color: primaryColor, borderRadius: radius()),
                        child: Text(language.addMoney, style: primaryTextStyle(size: 14, color: Colors.white)),
                      ),
                    )
                ],
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: inkWellWidget(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                        return Observer(builder: (context) {
                          return Stack(
                            children: [
                              AlertDialog(
                                contentPadding: EdgeInsets.all(16),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(language.paymentMethod, style: boldTextStyle()),
                                          inkWellWidget(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                                              child: Icon(Icons.close, color: Colors.white),
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(language.chooseYouPaymentLate, style: secondaryTextStyle()),
                                      Column(
                                        children: _modeOfPayments.map((e) {
                                          return RadioListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity: ListTileControlAffinity.trailing,
                                            activeColor: primaryColor,
                                            value: e,
                                            groupValue: /*paymentMethodType == CASH_WALLET ? CASH :*/ paymentMethodType,
                                            title: Text(paymentStatus(e), style: boldTextStyle()),
                                            onChanged: (String? val) {
                                              paymentMethodType = val ?? '';
                                              setState(() {});
                                            },
                                          );
                                        }).toList(),
                                      ),
                                      SizedBox(height: 16),
                                      AppTextField(
                                        controller: promoCode,
                                        autoFocus: false,
                                        textFieldType: TextFieldType.EMAIL,
                                        keyboardType: TextInputType.emailAddress,
                                        errorThisFieldRequired: language.thisFieldRequired,
                                        readOnly: true,
                                        onTap: () async {
                                          var data = await showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.white,
                                            builder: (_) {
                                              return CouPonWidget(is_taxi_service: widget.is_taxi_service);
                                            },
                                          );
                                          if (data != null) {
                                            promoCode.text = data;
                                            setState(() {});
                                          }
                                        },
                                        decoration: inputDecoration(context,
                                            label: language.enterPromoCode,
                                            suffixIcon: promoCode.text.isNotEmpty
                                                ? inkWellWidget(
                                                    onTap: () {
                                                      getNewService(coupon: false);
                                                      promoCode.clear();
                                                      setState(() {});
                                                    },
                                                    child: Icon(Icons.close, color: Colors.black, size: 25),
                                                  )
                                                : null),
                                      ),
                                      SizedBox(height: 16),
                                      AppButtonWidget(
                                        width: MediaQuery.of(context).size.width,
                                        text: language.confirm,
                                        textStyle: boldTextStyle(color: Colors.white),
                                        color: primaryColor,
                                        onTap: () {
                                          if (promoCode.text.isNotEmpty) {
                                            getCouponNewService();
                                          } else {
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Observer(builder: (context) {
                                return Visibility(visible: appStore.isLoading, child: loaderWidget());
                              }),
                            ],
                          );
                        });
                      });
                    },
                  ).then((value) {
                    setState(() {});
                  });
                },
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, 8, appStore.isScheduleRide == "1" ? 4 : 16, 16),
                  decoration: BoxDecoration(border: Border.all(color: dividerColor), borderRadius: BorderRadius.circular(defaultRadius)),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(language.paymentVia, style: secondaryTextStyle(size: 12, weight: FontWeight.bold)),
                            Container(
                              child: Icon(
                                Icons.cancel_outlined,
                                color: Colors.transparent,
                              ),
                            )
                          ],
                        ),
                        Divider(
                          height: 8,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              margin: EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                              child: Icon(paymentMethodType == CASH_WALLET || paymentMethodType == CASH || paymentMethodType == ONLINE ? Icons.attach_money : Icons.wallet_outlined,
                                  size: 20, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isRideForOther == false
                                              ? language.cash
                                              : paymentMethodType == CASH_WALLET
                                                  ? language.cash
                                                  : paymentStatus(paymentMethodType),
                                          style: boldTextStyle(size: 14),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    widget.is_taxi_service == false && paymentMethodType == CASH
                                        ? language.timeOfPickup
                                        : paymentMethodType != CASH_WALLET
                                            ? language.forInstantPayment
                                            : language.lblPayWhenEnds,
                                    style: secondaryTextStyle(size: 12),
                                    maxLines: 2,
                                  ),
                                  SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (appStore.isScheduleRide == "1")
              Expanded(
                child: inkWellWidget(
                  onTap: (widget.pickupTimeValue.isEmptyOrNull)
                      ? () async {
                          DateTime? d1 = await showDatePicker(
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    primaryColor: primaryColor,
                                    hintColor: primaryColor,
                                    colorScheme: ColorScheme.light(primary: primaryColor),
                                    buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                  ),
                                  child: child!,
                                );
                              },
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 45)));
                          if (d1 != null) {
                            TimeOfDay? t1 = await showTimePicker(
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      primaryColor: primaryColor,
                                      hintColor: primaryColor,
                                      colorScheme: ColorScheme.light(primary: primaryColor),
                                      buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                    ),
                                    child: child!,
                                  );
                                },
                                context: context,
                                initialTime: TimeOfDay(hour: 0, minute: 0));
                            if (t1 != null) {
                              d1 = DateTime(d1.year, d1.month, d1.day, t1.hour, t1.minute);
                              setState(() {
                                schduleRideDateTime = d1;
                              });
                            }
                          }
                        }
                      : null,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(4, 8, 16, 16),
                    decoration: BoxDecoration(border: Border.all(color: dividerColor), borderRadius: BorderRadius.circular(defaultRadius)),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(language.schedule, style: secondaryTextStyle(size: 12, weight: FontWeight.bold)),
                            if (schduleRideDateTime != null)
                              inkWellWidget(
                                onTap: () {
                                  setState(() {
                                    schduleRideDateTime = null;
                                  });
                                },
                                child: Container(
                                  child: Icon(
                                    Icons.cancel_outlined,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            if (schduleRideDateTime == null)
                              Container(
                                child: Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.transparent,
                                ),
                              )
                          ],
                        ),
                        Divider(
                          height: 8,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              margin: EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                              child: Icon(Icons.access_time_filled_outlined, size: 20, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          language.schedule_at,
                                          style: boldTextStyle(size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  if (!widget.pickupTimeValue.isEmptyOrNull) ...[
                                    Text(formattedTime ?? '', style: secondaryTextStyle(size: 12)),
                                  ] else ...[
                                    Text(schduleRideDateTime != null ? "${DateFormat('dd MMM yyyy hh:mm a').format(schduleRideDateTime!)}" : "${language.now}\n", style: secondaryTextStyle(size: 12)),
                                  ],
                                  SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 0),
          child: Row(
            children: [
              Expanded(
                child: AppButtonWidget(
                  onTap: () async {
                    if (mSelectServiceAmount != null && paymentMethodType != CASH_WALLET && paymentMethodType == WALLET && double.parse(mSelectServiceAmount!) >= mTotalAmount.toDouble()) {
                      return toast(language.noBalanceValidate);
                    }
                    // Payment at start of trip: require online payment before booking for non-cash payments
                    if (paymentMethodType == 'online') {
                      bool res = await launchScreen(context, PaymentScreen(amount: num.parse(mSelectServiceAmount ?? ''), flow: 'online'), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                      if (res == true) {
                        saveBookingData(isPaidInAdvance: true);
                      }
                    } else {
                      saveBookingData();
                    }
                  },
                  text: widget.is_taxi_service == true ? language.bookNow : "Create Order",
                  textStyle: boldTextStyle(color: Colors.white),
                  width: double.infinity,
                ),
              ),
              if (appStore.isBidEnable == "1" && schduleRideDateTime == null) 8.width,
              if (appStore.isBidEnable == "1" && schduleRideDateTime == null)
                Expanded(
                  child: AppButtonWidget(
                    onTap: () {
                      if (mSelectServiceAmount != null && paymentMethodType != CASH_WALLET && paymentMethodType == WALLET && double.parse(mSelectServiceAmount!) >= mTotalAmount.toDouble()) {
                        return toast(language.noBalanceValidate);
                      }
                      saveBookingData(ride_type: "with_bidding");
                    },
                    text: language.bid_book,
                    textStyle: boldTextStyle(color: Colors.white),
                    width: double.infinity,
                  ),
                )
            ],
          ),
        ),
        SizedBox(
          height: 12,
        )
      ],
    );
  }

  Future<void> saveBookingData({String? ride_type, bool isPaidInAdvance = false}) async {
    // Schedule datetime is required for all bookings
    if (schduleRideDateTime == null && formattedTime.isEmptyOrNull) {
      return toast("Please select a schedule date and time for your ride");
    }
    if (schduleRideDateTime != null && schduleRideDateTime!.isBefore(DateTime.now())) {
      return toast("Enter Valid Schedule Time");
    }
    DateFormat format = DateFormat("yyyy-MM-dd hh:mm a");
    if (formattedTime != null && format.parse(formattedTime.toString()).isBefore(DateTime.now())) {
      return toast("Enter Valid Schedule Time");
    }
    if (isRideForOther == false && nameController.text.isEmpty) {
      return toast(language.nameFieldIsRequired);
    } else if (isRideForOther == false && phoneController.text.isEmpty) {
      return toast(language.phoneNumberIsRequired);
    }
    appStore.setLoading(true);
    widget.dt = DateTime.now().toUtc().toString().replaceAll("Z", "");
    if (!formattedTime.isEmptyOrNull) {
      DateFormat inputFormat = DateFormat("yyyy-MM-dd hh:mm a");
      DateTime fixDate = inputFormat.parse(formattedTime ?? "");
      parsedDate = fixDate.toUtc().toIso8601String().replaceAll("Z", "");
    }
    Map req = {
      "rider_id": sharedPref.getInt(USER_ID).toString(),
      "service_id": servicesListData?.id.toString(),
      "datetime": DateTime.now().toUtc().toString().replaceAll("Z", ""),
      "start_latitude": widget.sourceLatLog.latitude.toString(),
      "start_longitude": widget.sourceLatLog.longitude.toString(),
      "start_address": widget.sourceTitle,
      "type": widget.is_taxi_service == true ? BOOK_RIDE : TRANSPORT,
      "end_latitude": widget.destinationLatLog.latitude.toString(),
      "end_longitude": widget.destinationLatLog.longitude.toString(),
      "end_address": widget.destinationTitle,
      if (widget.is_taxi_service == false) "total_amount": num.parse(mSelectServiceAmount ?? ''),
      if (widget.is_taxi_service == false) "subtotal": num.parse(mSelectServiceSubTotal ?? ''),
      "status": NEW_RIDE_REQUESTED,
      "payment_type": paymentMethodType == CASH_WALLET ? CASH : paymentMethodType,
      // Payment at start: set payment_status as paid if payment was made in advance
      if (isPaidInAdvance) "payment_status": PAID,
      if (promoCode.text.isNotEmpty) "coupon_code": promoCode.text,
      "is_schedule": schduleRideDateTime == null && formattedTime.isEmptyOrNull ? 0 : 1,
      "schedule_datetime": schduleRideDateTime == null && formattedTime.isEmptyOrNull
          ? null
          : schduleRideDateTime == null
              ? parsedDate
              : schduleRideDateTime?.toUtc().toString().replaceAll("Z", ""),
      if (isRideForOther == false) "is_ride_for_other": 1,
      if (isRideForOther == false)
        "other_rider_data": {
          "name": nameController.text.trim(),
          "contact_number": '${countryCode}${phoneController.text.trim()}',
        }
    };
    if (ride_type != null) {
      req['ride_type'] = ride_type;
    }
    if (widget.is_taxi_service == true) {
      req['passenger'] = passengers;
      req['luggage'] = luggage;
    }
    if (widget.tripDetail != null) {
      print("----------2146>>>${widget.tripDetail["flight_number"]}");
      req['flight_number'] = widget.tripDetail["flight_number"];
      req['pickup_point'] = widget.tripDetail["pickup_point"];
      req['preferred_pickup_time'] = widget.tripDetail["preferred_pickup_time"];
      req['preferred_dropoff_time'] = widget.tripDetail["preferred_dropoff_time"];
      req['trip_type'] = widget.tripDetail["trip_type"];
      req['airport_pickup'] = widget.tripDetail["airport_pickup"];
      req['airport_name'] = widget.tripDetail["airport_name"];
      req['pickup_airport_id'] = widget.tripDetail["pickup_airport_id"];
      req['drop_airport_id'] = widget.tripDetail["drop_airport_id"];
      req['drop_zone_id'] = widget.tripDetail["drop_zone_id"];
      req['pickup_zone_id'] = widget.tripDetail["pickup_zone_id"];
      // Add hourly booking data
      req['booking_type'] = widget.tripDetail["booking_type"] ?? 'STANDARD';
      if (widget.tripDetail["booking_type"] == 'HOURLY') {
        req['hours_booked'] = widget.tripDetail["hours_booked"];
        req['included_miles'] = widget.tripDetail["included_miles"];
      }
    }
    if (widget.is_taxi_service == false) {
      deliveryDataJson = widget.parcel_detail;
      req['weight'] = deliveryDataJson['weight'];
      req['parcel_description'] = deliveryDataJson['parcel_type'] ?? '';
      req['pickup_person_name'] = deliveryDataJson['sender_name'];
      req['pickup_contact_number'] = deliveryDataJson['sender_contact'];
      req['pickup_description'] = deliveryDataJson['sender_desc'];
      req['delivery_person_name'] = deliveryDataJson['receiver_name'];
      req['delivery_contact_number'] = deliveryDataJson['receiver_contact'];
      req['delivery_description'] = deliveryDataJson['receiver_desc'];
    }
    req['distance'] = servicesListData?.distance ?? '';
    req['duration'] = servicesListData?.duration;
    req['base_fare'] = servicesListData?.baseFare;
    req['discount'] = servicesListData?.discountAmount;
    req['dropoff_distance_in_km'] = servicesListData?.dropoffDistanceInKm ?? '';

    // Add extra booking options with prices
    if (tripProtectionEnabled) {
      req['trip_protection'] = 1;
      req['trip_protection_price'] = TRIP_PROTECTION_PRICE;
    }
    if (meetAndGreetEnabled) {
      req['meet_and_greet'] = 1;
      req['meet_and_greet_price'] = MEET_AND_GREET_PRICE;
      req['meet_greet_name'] = meetGreetNameController.text.trim();
      req['meet_greet_comments'] = meetGreetCommentsController.text.trim();
    }
    if (travelingWithPetEnabled) {
      req['traveling_with_pet'] = 1;
      req['traveling_with_pet_price'] = TRAVELING_WITH_PET_PRICE;
    }
    if (childSeatEnabled) {
      req['child_seat'] = 1;
      req['child_seat_price'] = CHILD_SEAT_PRICE;
      req['booster_seat_count'] = boosterSeatCount;
      req['rear_facing_infant_seat_count'] = rearFacingInfantSeatCount;
      req['forward_facing_toddler_seat_count'] = forwardFacingToddlerSeatCount;
    }

    // Add extras total to request
    req['extras_amount'] = extrasTotal;

    // Use hourly price if hourly booking, add extras to total
    if (isHourlyBooking && servicesListData != null) {
      req['total_amount'] = getHourlyPrice(servicesListData!) + extrasTotal;
      req['subtotal'] = getHourlyPrice(servicesListData!);
    } else {
      double baseAmount = (servicesListData?.totalAmount ?? 0).toDouble();
      req['total_amount'] = baseAmount + extrasTotal;
      req['subtotal'] = servicesListData?.subtotal ?? '';
    }
    var abc = [];
    if (widget.multiDropObj != null) {
      widget.multiDropObj!.forEach(
        (key, value) {
          LatLng s = value as LatLng;
          abc.add({"drop": key, "lat": s.latitude, "lng": s.longitude, "dropped_at": null, "address": widget.multiDropLocationNamesObj![key]});
        },
      );
      req['multi_location'] = abc;
    }
    FRideBookingModel rideBookingModel = FRideBookingModel();
    rideBookingModel.riderId = sharedPref.getInt(USER_ID);
    rideBookingModel.status = NEW_RIDE_REQUESTED;
    // Set payment status as PAID if payment was made in advance
    rideBookingModel.paymentStatus = isPaidInAdvance ? PAID : null;
    rideBookingModel.paymentType = isRideForOther == false
        ? CASH
        : paymentMethodType == CASH_WALLET
            ? CASH
            : paymentMethodType;
    log('$req');
    await saveRideRequest(req).then((value) async {
      rideRequestId = value.rideRequestId!;
      rideBookingModel.rideId = rideRequestId;

      // Get nearby drivers and add ride to Firestore so drivers can see it
      try {
        final nearbyDrivers = await getNearByDriverList(latLng: widget.sourceLatLog);
        if (nearbyDrivers.data != null && nearbyDrivers.data!.isNotEmpty) {
          // Get IDs of online and available drivers
          List<int> driverIds = nearbyDrivers.data!
              .where((d) => d.isOnline == 1 && d.isAvailable == 1 && d.id != null)
              .map((d) => d.id!)
              .toList();

          if (driverIds.isNotEmpty) {
            rideBookingModel.driver_ids = driverIds;
            print("Adding ride to Firestore with ${driverIds.length} nearby drivers: $driverIds");
          }

          // Send push notifications directly to drivers with player IDs
          NotificationService notificationService = NotificationService();
          String riderName = sharedPref.getString(USER_NAME) ?? 'A rider';
          String notificationTitle = 'New Ride Request';
          String notificationContent = '$riderName needs a ride from ${widget.sourceTitle} to ${widget.destinationTitle}';

          for (var driver in nearbyDrivers.data!) {
            if (driver.isOnline == 1 && driver.isAvailable == 1 && driver.playerId != null && driver.playerId!.isNotEmpty) {
              try {
                await notificationService.sendPushNotifications(
                  notificationTitle,
                  notificationContent,
                  receiverPlayerId: driver.playerId,
                  rideId: rideRequestId,
                  notificationType: 'new_ride_request',
                );
                print("Notification sent to driver ${driver.id} (player_id: ${driver.playerId})");
              } catch (e) {
                print("Failed to send notification to driver ${driver.id}: $e");
              }
            }
          }
        }
      } catch (e) {
        print("Error getting nearby drivers: $e");
      }

      // Add ride to Firestore so drivers can see it via their stream
      await rideService.addRide(rideBookingModel, rideRequestId);
      print("Ride added to Firestore: ride_$rideRequestId");

      Future.delayed(
        Duration(seconds: 3),
        () {
          rideService.updateStatusOfRide(rideID: rideRequestId, req: {'on_stream_api_call': 0});
        },
      );
      widget.isCurrentRequest = true;
      if (schduleRideDateTime != null || formattedTime != null) {
        appStore.setLoading(false);
        launchScreen(
          context,
          isNewTask: true,
          DashBoardScreen(),
          pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
        );
        toast(value.message.validate());
        return;
      }
      if (ride_type != null) {
        appStore.setLoading(false);
        setState(() {});
        launchScreen(
          context,
          isNewTask: true,
          Bidingscreen(
            dt: widget.dt,
            ride_id: value.rideRequestId!,
            source: {
              "start_latitude": widget.sourceLatLog.latitude.toString(),
              "start_longitude": widget.sourceLatLog.longitude.toString(),
              "start_address": widget.sourceTitle,
            },
            endLocation: {
              "end_latitude": widget.destinationLatLog.latitude.toString(),
              "end_longitude": widget.destinationLatLog.longitude.toString(),
              "end_address": widget.destinationTitle,
            },
            multiDropObj: widget.multiDropObj,
            multiDropLocationNamesObj: widget.multiDropLocationNamesObj,
          ),
          pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
        );
      } else {
        isBooking = true;
        appStore.setLoading(false);
        setState(() {});
      }
    }).catchError((error) {
      appStore.setLoading(false);
      toast(error.toString());
    });
  }

  void checkRideCancel() async {
    if (rideCancelDetected) return;
    rideCancelDetected = true;
    appStore.setLoading(true);
    sharedPref.remove(IS_TIME);
    sharedPref.remove(REMAINING_TIME);
    await rideDetail(orderId: rideRequestId == 0 ? widget.id : rideRequestId).then((value) {
      appStore.setLoading(false);
      if (value.data!.status == CANCELED && value.data!.cancelBy == DRIVER) {
        launchScreen(getContext, DashBoardScreen(cancelReason: value.data!.reason), isNewTask: true);
      } else {
        launchScreen(getContext, DashBoardScreen(), isNewTask: true);
      }
    }).catchError((error) {
      appStore.setLoading(false);
      launchScreen(getContext, DashBoardScreen(), isNewTask: true);
      log(error.toString());
    });
  }

  Widget _buildCounter(String label, IconData icon, int count, VoidCallback onDecrement, VoidCallback onIncrement) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - 50,
            child: Row(
              children: [
                Icon(icon, size: 18),
                SizedBox(width: 4),
                Expanded(child: Text(label, style: boldTextStyle(size: 16, weight: FontWeight.w500))),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - 50,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: onDecrement,
                ),
                Text('$count', style: boldTextStyle(size: 18)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: onIncrement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the extras section with Trip Protection, Meet & Greet, Pet, Child Seat options
  Widget _buildExtrasSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(defaultRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text('Extras', style: boldTextStyle(size: 16)),
          ),
          Divider(height: 1),
          // Trip Protection
          _buildExtraOption(
            title: 'Trip Protection',
            icon: Icons.shield_outlined,
            value: tripProtectionEnabled,
            price: TRIP_PROTECTION_PRICE,
            onChanged: (val) => setState(() => tripProtectionEnabled = val),
            infoText: 'Protect your trip with additional coverage',
          ),
          // Arrival Meet and Greet
          _buildExtraOption(
            title: 'Arrival Meet and Greet',
            icon: Icons.handshake_outlined,
            value: meetAndGreetEnabled,
            price: MEET_AND_GREET_PRICE,
            onChanged: (val) => setState(() => meetAndGreetEnabled = val),
            infoText: 'Driver will meet you at arrival with a name sign',
            expandedContent: meetAndGreetEnabled ? Column(
              children: [
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: meetGreetNameController,
                    decoration: InputDecoration(
                      labelText: 'Passenger Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: meetGreetCommentsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Additional Comments',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ) : null,
          ),
          // Traveling with Pet
          _buildExtraOption(
            title: 'Traveling with Pet',
            icon: Icons.pets,
            value: travelingWithPetEnabled,
            price: TRAVELING_WITH_PET_PRICE,
            onChanged: (val) => setState(() => travelingWithPetEnabled = val),
            infoText: 'Let your driver know you are traveling with a pet',
          ),
          // Child Seat
          _buildExtraOption(
            title: 'Child Seat',
            icon: Icons.child_care,
            value: childSeatEnabled,
            price: CHILD_SEAT_PRICE,
            onChanged: (val) => setState(() => childSeatEnabled = val),
            infoText: 'Request child seats for your trip',
            expandedContent: childSeatEnabled ? Column(
              children: [
                _buildSeatCounter('Booster Seat', boosterSeatCount,
                  () => setState(() => boosterSeatCount = (boosterSeatCount - 1).clamp(0, 5)),
                  () => setState(() => boosterSeatCount = (boosterSeatCount + 1).clamp(0, 5)),
                ),
                _buildSeatCounter('Rear facing infant seat', rearFacingInfantSeatCount,
                  () => setState(() => rearFacingInfantSeatCount = (rearFacingInfantSeatCount - 1).clamp(0, 5)),
                  () => setState(() => rearFacingInfantSeatCount = (rearFacingInfantSeatCount + 1).clamp(0, 5)),
                ),
                _buildSeatCounter('Forward facing toddler seat', forwardFacingToddlerSeatCount,
                  () => setState(() => forwardFacingToddlerSeatCount = (forwardFacingToddlerSeatCount - 1).clamp(0, 5)),
                  () => setState(() => forwardFacingToddlerSeatCount = (forwardFacingToddlerSeatCount + 1).clamp(0, 5)),
                ),
              ],
            ) : null,
          ),
          // Show extras total if any selected
          if (extrasTotal > 0)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(defaultRadius - 1),
                  bottomRight: Radius.circular(defaultRadius - 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Extras Total:', style: boldTextStyle(size: 14)),
                  Text('\$${extrasTotal.toStringAsFixed(2)}', style: boldTextStyle(size: 14, color: primaryColor)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExtraOption({
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    double? price,
    String? infoText,
    Widget? expandedContent,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: primaryTextStyle(size: 14)),
                    if (price != null)
                      Text('+\$${price.toStringAsFixed(0)}', style: secondaryTextStyle(size: 12, color: Colors.green)),
                  ],
                ),
              ),
              if (infoText != null)
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(title),
                        content: Text(infoText),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                      ),
                    );
                  },
                  child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
                ),
              SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: primaryColor,
              ),
            ],
          ),
        ),
        if (expandedContent != null) expandedContent,
        Divider(height: 1),
      ],
    );
  }

  Widget _buildSeatCounter(String label, int count, VoidCallback onDecrement, VoidCallback onIncrement) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: secondaryTextStyle(size: 13))),
          Row(
            children: [
              InkWell(
                onTap: onDecrement,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.remove, size: 16, color: Colors.grey),
                ),
              ),
              SizedBox(width: 16),
              Text('$count', style: boldTextStyle(size: 14)),
              SizedBox(width: 16),
              InkWell(
                onTap: onIncrement,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.add, size: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
