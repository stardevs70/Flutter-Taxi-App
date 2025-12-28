import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' as lt;
import 'package:pinput/pinput.dart';
import 'package:taxi_driver/model/LDBaseResponse.dart';
import 'package:taxi_driver/model/ModelBid.dart';
import 'package:taxi_driver/screens/ChatScreen.dart';
import 'package:taxi_driver/screens/DetailScreen.dart';
import 'package:taxi_driver/screens/FlightTrackingPage.dart';
import 'package:taxi_driver/screens/ReviewScreen.dart';
import 'package:taxi_driver/screens/UpComingMainScreen.dart';
import 'package:taxi_driver/utils/Extensions/extension.dart';
import 'package:taxi_driver/utils/Extensions/int_extensions.dart';
import 'package:taxi_driver/utils/TaxiCourierButton.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Services/RideService.dart';
import '../Services/VersionServices.dart';
import '../components/AlertScreen.dart';
import '../components/CancelOrderDialog.dart';
import '../components/DrawerComponent.dart';
import '../components/ExtraChargesWidget.dart';
import '../components/RideForWidget.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/ExtraChargeRequestModel.dart';
import '../model/FRideBookingModel.dart';
import '../model/RiderModel.dart';
import '../model/UserDetailModel.dart';
import '../model/WalletDetailModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Images.dart';
import 'LocationPermissionScreen.dart';
import 'NotificationScreen.dart';
import 'WalletScreen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // List<LatLng> driverToPickupPolyline = [];
  // List<LatLng> pickupToDropPolyline = [];
  // double currentHeading = 0.0;

  // StreamController _messageController = StreamController.broadcast();

  // late StreamSubscription _messageSubscription;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  RideService rideService = RideService();
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? mapController;
  final otpController = TextEditingController();
  late StreamSubscription<ServiceStatus> serviceStatusStream;

  List<RiderModel> riderList = [];
  OnRideRequest? servicesListData;
  int bidIsProcessing = 0;
  int rideHasBid = 0;
  int passengerCount = 0, luggageCount = 0;
  ModelBidData? bidData;
  UserData? riderData;
  WalletDetailModel? walletDetailModel;
  List<OnRideRequest> schedule_ride_request = [];
  List<OnRideRequest> schedule_orders = [];

  LatLng? userLatLong;
  final Set<Marker> markers = {};
  Set<Polyline> _polyLines = Set<Polyline>();
  late PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinates = [];

  List<ExtraChargeRequestModel> extraChargeList = [];
  num extraChargeAmount = 0;
  late StreamSubscription<Position> positionStream;
  LocationPermission? permissionData;
  double currentHeading = 0.0;
  LatLng? driverLocation;
  LatLng? sourceLocation;
  LatLng? destinationLocation;
  bool isOnLine = true;
  bool locationEnable = true;
  bool current_screen = true;
  String? otpCheck;
  String endLocationAddress = '';

  // double totalDistance = 0.0;
  late BitmapDescriptor driverIcon;
  late BitmapDescriptor destinationIcon;
  late BitmapDescriptor sourceIcon;
  int reqCheckCounter = 0;
  int startTime = 60;
  int end = 0;
  int duration = 0;
  int count = 0;
  int riderId = 0;
  num platformFee = 0;
  num youWillGet = 0;

  // var commission_type = '';
  // num admin_commission = 0;
  // num surge_charge = 0;
  Offset position = Offset(200, 100);

  // var estimatedTotalPrice;
  // var estimatedDistance;
  // var distance_unit;
  Timer? timerUpdateLocation;
  Timer? timerData;
  bool rideCancelDetected = false;
  bool rideDetailsFetching = false;

  String service_marker = '';

  var bidNoteController = TextEditingController();
  var bidAmountController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _animation;
  bool isCurrentRequestCalled = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 0.4).animate(_animController);

    if (sharedPref.getInt(IS_ONLINE) == 1) {
      setState(() {
        isOnLine = true;
      });
    } else {
      setState(() {
        isOnLine = false;
      });
    }
    locationPermission();
    if (app_update_check != null) {
      VersionService().getVersionData(context, app_update_check);
    }
    init();
  }

  void init() async {
    if (sharedPref.getDouble(LATITUDE) != null && sharedPref.getDouble(LONGITUDE) != null) {
      driverLocation = LatLng(sharedPref.getDouble(LATITUDE)!, sharedPref.getDouble(LONGITUDE)!);
    }
    getCurrentRequest();
    await checkPermission();
    _updateUserLocation();
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
    walletCheckApi();
    getCurrentRequest();
    polylinePoints = PolylinePoints();
    startTime = REQUEST_TIME_VAL;
    setState(() {});
    sourceIcon = await getResizedMarker(SourceIcon);
    driverIcon = await getResizedMarker(DriverIcon);
    destinationIcon = await getResizedMarker(DestinationIcon);
    if (appStore.isLoggedIn) {
      startLocationTracking();
    }
  }

  Future<void> locationPermission() async {
    serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        locationEnable = false;
        Future.delayed(
          Duration(seconds: 1),
          () {
            launchScreen(navigatorKey.currentState!.overlay!.context, LocationPermissionScreen());
          },
        );
      } else if (status == ServiceStatus.enabled) {
        locationEnable = true;
        startLocationTracking();
        if (locationScreenKey.currentContext != null) {
          if (Navigator.canPop(navigatorKey.currentState!.overlay!.context)) {
            Navigator.pop(navigatorKey.currentState!.overlay!.context);
          }
        }
      }
    });
  }

  cancelRideTimeOut() {
    Future.delayed(Duration(seconds: 1)).then((value) {
      appStore.setLoading(true);
      try {
        sharedPref.remove(ON_RIDE_MODEL);
        sharedPref.remove(IS_TIME2);
        duration = startTime;
        servicesListData = null;
        _polyLines.clear();
        setMapPins();
        setState(() {});
        FlutterRingtonePlayer().stop();
      } catch (e) {}
      Map req = {
        "id": riderId,
        "driver_id": sharedPref.getInt(USER_ID),
        "is_accept": "0",
      };
      duration = startTime;
      rideRequestResPond(request: req).then((value) {
        appStore.setLoading(false);
      }).catchError((error, s) {
        appStore.setLoading(false);
        print("ExceptionFound.E+>$error:::STACK:::$s");
      });
    });
  }

  Future<void> setTimeData() async {
    if (sharedPref.getString(IS_TIME2) == null) {
      duration = startTime;
      await sharedPref.setString(IS_TIME2, DateTime.now().add(Duration(seconds: startTime)).toString());
      startTimer(tag: "line222");
    } else {
      duration = DateTime.parse(sharedPref.getString(IS_TIME2)!).difference(DateTime.now()).inSeconds;
      await sharedPref.setString(IS_TIME2, DateTime.now().add(Duration(seconds: duration)).toString());
      if (duration < 0) {
        await sharedPref.remove(IS_TIME2);
        sharedPref.remove(ON_RIDE_MODEL);
        if (sharedPref.getString("RIDE_ID_IS") == null || sharedPref.getString("RIDE_ID_IS") == "$riderId") {
          return cancelRideTimeOut();
        } else {
          duration = startTime;
          startTimer(tag: "line248");
        }
      }
      sharedPref.setString("RIDE_ID_IS", "$riderId");
      if (duration > 0) {
        if (sharedPref.getString(ON_RIDE_MODEL) != null) {
          servicesListData = OnRideRequest.fromJson(jsonDecode(sharedPref.getString(ON_RIDE_MODEL)!));
        }

        startTimer(tag: "line238");
      } else {}
    }
  }

  Future<void> startTimer({required String tag}) async {
    try {
      timerData!.cancel();
    } catch (e) {}
    await FlutterRingtonePlayer().stop();
    await FlutterRingtonePlayer().play(
      fromAsset: ringtonePath,
      android: AndroidSounds.notification,
      ios: IosSounds.triTone,
      looping: true,
      volume: 0.1,
      asAlarm: false,
    );

    timerData = new Timer.periodic(
      Duration(seconds: 1),
      (Timer timer) {
        if (duration <= 0) {
          try {
            timerData!.cancel();
          } catch (e) {}
          Future.delayed(Duration(seconds: 1)).then((value) {
            duration = startTime;
            try {
              FlutterRingtonePlayer().stop();
              timer.cancel();
            } catch (e) {}
            sharedPref.remove(ON_RIDE_MODEL);
            sharedPref.remove(IS_TIME2);
            servicesListData = null;
            _polyLines.clear();
            setState(() {});
            Map req = {
              "id": riderId,
              "driver_id": sharedPref.getInt(USER_ID),
              "is_accept": "0",
            };

            rideRequestResPond(request: req).then((value) {}).catchError((error, s) {
              print("ExceptionFound.E+>$error:::STACK:::$s");
            });
          });
        } else {
          if (timerData != null && timerData!.isActive) {
            setState(() {
              duration--;
            });
          }
        }
      },
    );
  }

  Future<void> setSourceAndDestinationIcons() async {
    try {
      driverIcon = await getNetworkImageMarker(service_marker.validate());
    } catch (e, s) {
      print("UPDATE_MARKER_ERROR::$e ==>$s");
      driverIcon = await getResizedMarker(DriverIcon);
    }
    try {
      if (driverLocation != null) {
        markers.add(
          Marker(
            markerId: MarkerId("driver"),
            position: driverLocation!,
            icon: driverIcon,
            infoWindow: InfoWindow(title: ''),
          ),
        );
      }
    } catch (e) {
      driverIcon = await getResizedMarker(DriverIcon);
    }
    if (servicesListData != null) servicesListData!.status != IN_PROGRESS ? sourceIcon = await getResizedMarker(SourceIcon) : destinationIcon = await getResizedMarker(DestinationIcon);
  }

  onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    mapController = controller;
  }

  Future<void> driverStatus({int? status}) async {
    appStore.setLoading(true);
    Map req = {
      "is_online": status,
    };
    await updateStatus(req).then((value) {
      sharedPref.setInt(IS_ONLINE, status ?? 0);
      appStore.setLoading(false);
    }).catchError((error, s) {
      appStore.setLoading(false);
      print("ExceptionFound.E+>$error:::STACK:::$s");
    });
  }

  Future<void> getCurrentRequest() async {
    getCurrentRideRequest().then((value) async {
      print("api calling");
      if (value.schedule_ride_request != null && value.schedule_ride_request!.isNotEmpty) {
        schedule_ride_request = value.schedule_ride_request ?? [];
      }
      if (value.schedule_orders != null && value.schedule_orders!.isNotEmpty) {
        schedule_ride_request = value.schedule_orders ?? [];
      }
      service_marker = value.profileImage.validate();
      driverIcon = await getNetworkImageMarker(service_marker.validate());
      setSourceAndDestinationIcons();
      try {
        await rideService.updateStatusOfRide(rideID: value.onRideRequest!.id, req: {'on_rider_stream_api_call': 0});
      } catch (e) {
        print("EEEE${e.toString()}");
      }
      appStore.setLoading(false);
      if (value.onRideRequest != null) {
        passengerCount = value.onRideRequest?.passenger ?? 0;
        luggageCount = value.onRideRequest?.luggage ?? 0;
        appStore.currentRiderRequest = value.onRideRequest;
        servicesListData = value.onRideRequest;

        if (value.onRideRequest != null && value.onRideRequest!.multiDropLocation != null) {
          servicesListData!.multiDropLocation = value.onRideRequest!.multiDropLocation;
        }
        userDetail(driverId: value.onRideRequest?.riderId);
        setState(() {});
        if (servicesListData != null) {
          if (servicesListData!.status != COMPLETED) {
            setMapPins();
          }
          if (servicesListData!.status == COMPLETED && servicesListData!.isDriverRated == 0) {
            if (current_screen == false) return;
            current_screen = false;
            // REVIEW IS DISABLED THEN AUTO SUBMIT 0 else Navigate TO Review Screen
            if (appStore.isShowRiderReview == '0') {
              appStore.setLoading(true);
              Map req = {
                "ride_request_id": value.onRideRequest!.id!,
                "rating": 0,
                "comment": '',
              };
              await ratingReview(request: req).then((value2) async {
                await rideDetail(rideId: value.onRideRequest!.id!).then((value3) {
                  RideService rideService = RideService();

                  rideService.updateStatusOfRide(rideID: value.onRideRequest!.id!, req: {'on_rider_stream_api_call': 0});
                  if (value3.payment != null && value3.payment!.paymentStatus == PENDING) {
                    launchScreen(context, DetailScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
                  } else {
                    launchScreen(context, DashboardScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
                  }
                }).catchError((error) {
                  appStore.setLoading(false);
                  toast(error.toString());
                });
                appStore.setLoading(false);
              }).catchError((error, s) {
                appStore.setLoading(false);
                print("ExceptionFound.E+>$error:::STACK:::$s");
              });
            } else {
              launchScreen(context, ReviewScreen(rideId: value.onRideRequest!.id!, currentData: value), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
            }
          } else if (value.payment != null && value.payment!.paymentStatus == PENDING) {
            if (current_screen == false) return;
            current_screen = false;
            launchScreen(context, DetailScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
          }
        }
      } else {
        passengerCount = value.rideRequest?.passenger ?? 0;
        luggageCount = value.rideRequest?.luggage ?? 0;
        if (value.payment != null && value.payment!.paymentStatus == PENDING) {
          if (current_screen == false) return;
          current_screen = false;
          launchScreen(context, DetailScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
        }
      }
      isCurrentRequestCalled = false;
      setState(
        () {},
      );
    });/*.catchError((error, s) {
      print("ERR::::$error ===>$s");
      toast(error.toString());

      appStore.setLoading(false);

      servicesListData = null;
      setState(() {});
    });*/
  }

  getNewRideReq(int? riderID, {bool? refresh}) async {
    if (refresh != true) {
      if (servicesListData != null && servicesListData!.status == NEW_RIDE_REQUESTED) return;
    }
    await Future.delayed(Duration(seconds: 1));
    await rideDetail(rideId: riderID).then((value) async {
      rideHasBid = 0;
      bidIsProcessing = 0;
      passengerCount = value.data?.passenger ?? 0;
      luggageCount = value.data?.luggage ?? 0;

      if (value.bid_data != null && value.bid_data!.bidAmount != null) {
        bidIsProcessing = 1;
        try {
          bidData = value.bid_data!;
        } catch (e, s) {
          print("Exception FOUND:::${e}====>$s");
        }
      } else {
        bidIsProcessing = 0;
      }
      setState(() {});
      appStore.setLoading(false);
      if (value.data!.status == NEW_RIDE_REQUESTED || value.data!.status == BID_REJECTED) {
        try {
          OnRideRequest ride = OnRideRequest();
          ride.startAddress = value.data!.startAddress;
          ride.luggage = value.data!.luggage;
          ride.totalAmount = value.data!.totalAmount;
          ride.passenger = value.data!.passenger;
          ride.isSchedule = value.data!.isSchedule;
          ride.distanceUnit = value.data!.distanceUnit;
          ride.trip_type = value.data!.trip_type;
          ride.schedule_datetime = value.data!.schedule_datetime;
          ride.startLatitude = value.data!.startLatitude;
          ride.startLongitude = value.data!.startLongitude;
          ride.endAddress = value.data!.endAddress;
          ride.endLongitude = value.data!.endLongitude;
          ride.endLatitude = value.data!.endLatitude;
          ride.riderName = value.data!.riderName;
          ride.dropoff_distance_in_km = value.data!.dropoff_distance_in_km;
          ride.riderContactNumber = value.data!.riderContactNumber;
          ride.riderProfileImage = value.data!.riderProfileImage;
          ride.riderEmail = value.data!.riderEmail;
          ride.id = value.data!.id;
          ride.status = value.data!.status;
          ride.otherRiderData = value.data!.otherRiderData;
          ride.multiDropLocation = value.data!.multiDropLocation;
          ride.type = value.data!.type;
          ride.weight = value.data!.weight;
          ride.parcelDescription = value.data!.parcelDescription;
          ride.pickupContactNumber = value.data!.pickupContactNumber;
          ride.pickupPersonName = value.data!.pickupPersonName;
          ride.pickupDescription = value.data!.pickupDescription;
          ride.deliveryContactNumber = value.data!.deliveryContactNumber;
          ride.deliveryPersonName = value.data!.deliveryPersonName;
          ride.deliveryDescription = value.data!.deliveryDescription;
          servicesListData = ride;
          rideDetailsFetching = false;
          ride.otherRiderData;
          if (servicesListData != null) await rideService.updateStatusOfRide(rideID: servicesListData!.id, req: {'on_rider_stream_api_call': 0});
          sharedPref.setString(ON_RIDE_MODEL, jsonEncode(servicesListData));
          riderId = value.data!.id!;
          setState(() {});
          if (rideHasBid == 0 && value.data!.status == NEW_RIDE_REQUESTED) {
            setTimeData();
          }
        } catch (error, stack) {
          log('error:${error.toString()}  Stack ::::$stack');
        }
      }
      setMapPins();
    }).catchError((error, stack) {
      rideDetailsFetching = false;
      FirebaseCrashlytics.instance.recordError("pop_up_issue::" + error.toString(), stack, fatal: true);
      appStore.setLoading(false);
      log('ExceptionFound.E+>:${error.toString()}  Stack ::::$stack');
    });
  }

  Future<void> rideRequest({String? status}) async {
    appStore.setLoading(true);
    Map req = {
      "id": servicesListData!.id,
      "status": status,
    };
    await rideRequestUpdate(request: req, rideId: servicesListData!.id).then((value) async {
      appStore.setLoading(false);

      getCurrentRequest().then((value) async {
        if (/*status == ARRIVED ||*/ status == IN_PROGRESS) {
          _polyLines.clear();
          setMapPins();
        }
        setState(() {});
      });
    }).catchError((error, s) {
      appStore.setLoading(false);
      print("ExceptionFound.E+>$error:::STACK:::$s");
    });
  }

  Future<void> rideRequestAccept({bool deCline = false}) async {
    appStore.setLoading(true);
    Map req = {
      "id": servicesListData!.id,
      if (!deCline) "driver_id": sharedPref.getInt(USER_ID),
      "is_accept": deCline ? "0" : "1",
    };
    await rideRequestResPond(request: req).then((value) async {
      appStore.setLoading(false);
      if (deCline || servicesListData?.isSchedule == 1) {
        rideService.updateStatusOfRide(rideID: servicesListData!.id, req: {
          'on_stream_api_call': 0, /* 'driver_id': null*/
        });
        servicesListData = null;
        _polyLines.clear();
        sharedPref.remove(ON_RIDE_MODEL);
        sharedPref.remove(IS_TIME2);
        setMapPins();
      }
      getCurrentRequest();
    }).catchError((error, s) {
      setMapPins();
      appStore.setLoading(false);
      print("ExceptionFound.E+>$error:::STACK:::$s");
    });
  }

  Future<void> completeRideRequest() async {
    appStore.setLoading(true);
    var rideIdVal = servicesListData!.id;
    Map req = {
      "id": servicesListData?.id,
      "service_id": servicesListData?.serviceId,
      "start_latitude": servicesListData?.startLatitude,
      "start_longitude": servicesListData?.startLongitude,
      "end_latitude": driverLocation!.latitude,
      "end_longitude": driverLocation!.longitude,
      "end_address": endLocationAddress,
      // "distance": totalDistance,
      if (extraChargeList.isNotEmpty) "extra_charges": extraChargeList,
      if (extraChargeList.isNotEmpty) "extra_charges_amount": extraChargeAmount,
    };
    log(req);
    await completeRide(request: req).then((value) async {
      try {
        chatMessageService.exportChat(rideId: rideIdVal.toString(), senderId: sharedPref.getString(UID).validate(), receiverId: riderData!.uid.validate());
      } catch (e) {}
      await rideService.updateStatusOfRide(rideID: rideIdVal, req: {'on_rider_stream_api_call': 0});
      sourceIcon = await getResizedMarker(SourceIcon);
      appStore.setLoading(false);
      getCurrentRequest();
    }).catchError((error, s) {
      appStore.setLoading(false);
      print("ExceptionFound.E+>$error:::STACK:::$s");
    });
  }

  Future<void> setPolyLines() async {
    try {
      double? lat1, lng1;
      if (servicesListData != null && servicesListData!.multiDropLocation != null && servicesListData!.multiDropLocation!.isNotEmpty) {
        List<int> x = servicesListData!.multiDropLocation!
            .map(
              (e) => e.drop,
            )
            .toList();
        x.sort();
        for (int k = 0; k < x.length; k++) {
          if (servicesListData!.multiDropLocation!.where((element) => element.drop == x[k]).isNotEmpty && servicesListData!.multiDropLocation!.where((element) => element.drop == x[k]).first.droppedAt == null) {
            lat1 = servicesListData!.multiDropLocation!.where((element) => element.drop == x[k]).first.lat;
            lng1 = servicesListData!.multiDropLocation!.where((element) => element.drop == x[k]).first.lng;
            break;
          }
        }
      }
      if (lat1 != null && lng1 != null) {
        var result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_MAP_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(driverLocation!.latitude, driverLocation!.longitude),
              destination: servicesListData!.status != IN_PROGRESS ? PointLatLng(double.parse(servicesListData!.startLatitude.validate()), double.parse(servicesListData!.startLongitude.validate())) : PointLatLng(lat1, lng1),
              mode: TravelMode.driving),
        );
        if (result.points.isNotEmpty) {
          polylineCoordinates.clear();
          result.points.forEach((element) {
            polylineCoordinates.add(LatLng(element.latitude, element.longitude));
          });
          _polyLines.clear();
          _polyLines.add(
            Polyline(
              visible: true,
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
              jointType: JointType.round,
              width: 7,
              polylineId: PolylineId('poly'),
              color: polyLineColor,
              points: polylineCoordinates,
            ),
          );
          setState(() {});
        }
      } else {
        if (servicesListData == null) return;
        var result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: GOOGLE_MAP_API_KEY,
          request: PolylineRequest(
              origin: PointLatLng(driverLocation!.latitude, driverLocation!.longitude),
              destination: servicesListData != null && servicesListData!.status != IN_PROGRESS
                  ? PointLatLng(double.parse(servicesListData!.startLatitude.validate()), double.parse(servicesListData!.startLongitude.validate()))
                  : PointLatLng(double.parse(servicesListData!.endLatitude.validate()), double.parse(servicesListData!.endLongitude.validate())),
              mode: TravelMode.driving),
        );
        if (result.points.isNotEmpty) {
          polylineCoordinates.clear();
          result.points.forEach((element) {
            polylineCoordinates.add(LatLng(element.latitude, element.longitude));
          });
          _polyLines.clear();
          _polyLines.add(
            Polyline(
              visible: true,
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
              jointType: JointType.round,
              width: 7,
              polylineId: PolylineId('poly'),
              color: polyLineColor,
              points: polylineCoordinates,
            ),
          );
          setState(() {});
        }
      }
    } catch (e, s) {
      log("PolyLineIssue:::Detected :$e:+++>$s}");
    }
  }

  Future<void> setMapPins() async {
    try {
      if (servicesListData != null && servicesListData!.multiDropLocation != null && servicesListData!.multiDropLocation!.isNotEmpty) {
        markers.clear();
        MarkerId id = MarkerId("driver");
        markers.remove(id);
        try {
          driverIcon = await getNetworkImageMarker(service_marker.validate());
        } catch (e, s) {
          print("UPDATE_MARKER_ERROR::$e ==>$s");
          driverIcon = await getResizedMarker(DriverIcon);
        }
        markers.add(
          Marker(
            markerId: id,
            position: driverLocation!,
            icon: driverIcon,
            infoWindow: InfoWindow(title: ''),
          ),
        );
        if (servicesListData!.status != IN_PROGRESS) {
          markers.add(
            Marker(
              markerId: MarkerId('sourceLocation'),
              position: LatLng(double.parse(servicesListData!.startLatitude!), double.parse(servicesListData!.startLongitude!)),
              icon: sourceIcon,
              infoWindow: InfoWindow(title: servicesListData!.startAddress),
            ),
          );
        } else {
          servicesListData!.multiDropLocation!.forEach(
            (element) {
              if (element.droppedAt == null) {
                markers.add(
                  Marker(
                    markerId: MarkerId('destinationLocation_${element.drop}'),
                    position: LatLng(element.lat, element.lng),
                    icon: destinationIcon,
                    infoWindow: InfoWindow(title: element.address),
                  ),
                );
              }
            },
          );
        }
        setState(() {});
      } else {
        markers.clear();

        ///source pin
        MarkerId id = MarkerId("driver");
        markers.remove(id);
        markers.add(
          Marker(
            markerId: id,
            position: driverLocation!,
            icon: driverIcon,
            infoWindow: InfoWindow(title: ''),
          ),
        );
        if (servicesListData != null)
          servicesListData!.status != IN_PROGRESS
              ? markers.add(
                  Marker(
                    markerId: MarkerId('sourceLocation'),
                    position: LatLng(double.parse(servicesListData!.startLatitude!), double.parse(servicesListData!.startLongitude!)),
                    icon: sourceIcon,
                    infoWindow: InfoWindow(title: servicesListData!.startAddress),
                  ),
                )
              : markers.add(
                  Marker(
                    markerId: MarkerId('destinationLocation'),
                    position: LatLng(double.parse(servicesListData!.endLatitude!), double.parse(servicesListData!.endLongitude!)),
                    icon: destinationIcon,
                    infoWindow: InfoWindow(title: servicesListData!.endAddress),
                  ),
                );
        setState(() {});
      }
    } catch (e) {
      setState(() {});
    }
    setPolyLines();
  }

  double getBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * (pi / 180);
    double lat2 = end.latitude * (pi / 180);
    double lngDiff = (end.longitude - start.longitude) * (pi / 180);

    double y = sin(lngDiff) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lngDiff);
    double bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  /// Get Current Location
  Future<void> startLocationTracking() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((value) async {
      await Geolocator.isLocationServiceEnabled().then((value) async {
        if (locationEnable) {
          final LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 100, timeLimit: Duration(seconds: 30));
          positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((event) async {
            if (driverLocation != null) {
              bool b = isDistanceMoreThan100Meters(startLat: driverLocation!.latitude, startLng: driverLocation!.longitude, endLat: event.latitude, endLng: event.longitude);
              if (b) {
                if (appStore.isLoggedIn) {
                  driverLocation = LatLng(event.latitude, event.longitude);
                  Map req = {
                    "latitude": driverLocation!.latitude.toString(),
                    "longitude": driverLocation!.longitude.toString(),
                  };
                  sharedPref.setDouble(LATITUDE, driverLocation!.latitude);
                  sharedPref.setDouble(LONGITUDE, driverLocation!.longitude);
                  await updateStatus(req).then((value) {
                    // setState(() {});
                  }).catchError((error) {
                    log(error);
                  });
                  setMapPins();
                }
                // sharedPref.setString("UPDATE_CALL", DateTime.now().toString());
              }
            }
          }, onError: (error) {
            positionStream.cancel();
          });
        }
      });
    }).catchError((error) {
      Future.delayed(
        Duration(seconds: 1),
        () {
          launchScreen(navigatorKey.currentState!.overlay!.context, LocationPermissionScreen());
        },
      );
    });
  }

  Future<void> userDetail({int? driverId}) async {
    await getUserDetail(userId: driverId).then((value) {
      appStore.setLoading(false);
      riderData = value.data!;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
    });
  }

  /// WalletCheck
  Future<void> walletCheckApi() async {
    await walletDetailApi().then((value) async {
      if (value.totalAmount! >= value.minAmountToGetRide!) {
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return emptyWalletAlertDialog();
          },
        );
      }
    }).catchError((e) {
      log("Error $e");
    });
  }

  @override
  void setState(fn) {
    try {
      if (mounted) super.setState(fn);
    } catch (e) {}
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    _animController.dispose();
    if (timerData != null) {
      timerData!.cancel();
    }
    try {
      positionStream.cancel();
    } catch (e) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (v, t) async {
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark, statusBarColor: Colors.transparent, statusBarBrightness: Brightness.dark),
        ),
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        key: scaffoldKey,
        drawer: DrawerComponent(onCall: () async {
          await driverStatus(status: 0);
        }),
        body: Stack(
          children: [
            if (sharedPref.getDouble(LATITUDE) != null && sharedPref.getDouble(LONGITUDE) != null)
              GoogleMap(
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: true,
                compassEnabled: true,
                padding: EdgeInsets.only(top: context.statusBarHeight + 4 + 24),
                onMapCreated: onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: driverLocation ?? LatLng(sharedPref.getDouble(LATITUDE)!, sharedPref.getDouble(LONGITUDE)!),
                  zoom: 17.0,
                ),
                markers: markers,
                mapType: MapType.normal,
                polylines: _polyLines,
              ),
            onlineOfflineSwitch(),
            StreamBuilder<QuerySnapshot>(
                stream: rideService.fetchRide(userId: sharedPref.getInt(USER_ID)),
                builder: (c, snapshot) {
                  if (snapshot.hasData) {
                    List<FRideBookingModel> data = snapshot.data!.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
                    if (data.length >= 2) {
                      //here old ride of this driver remove if completed and payment is done code set
                      rideService.removeOldRideEntry(userId: sharedPref.getInt(USER_ID));
                    }
                    if (data.length != 0) {
                      if (data.length > 1) {
                        List<int> numbers = data
                            .map(
                              (e) => e.rideId ?? 0,
                            )
                            .toList();
                        int maxNumber = numbers.reduce((a, b) => a > b ? a : b);
                        data.removeWhere(
                          (element) => element.rideId != maxNumber,
                        );
                      }
                      rideCancelDetected = false;
                      if (!isCurrentRequestCalled && servicesListData == null && data.isNotEmpty && data[0].status == "assign_driver") {
                        isCurrentRequestCalled = true;
                        getCurrentRequest();
                        print("api calling 1 ${data[0].rideId}");
                      }
                      if (data[0].onStreamApiCall == 0) {
                        rideService.updateStatusOfRide(rideID: data[0].rideId, req: {'on_stream_api_call': 1});
                        if (data[0].status == NEW_RIDE_REQUESTED || data[0].status == BID_REJECTED) {
                          getNewRideReq(data[0].rideId);
                        } else {
                          getCurrentRequest();
                        }
                      }
                      if (servicesListData != null && data.isNotEmpty && data[0].rideId != servicesListData!.id) {
                        servicesListData = null;
                      }
                      if (servicesListData == null && (data[0].status == NEW_RIDE_REQUESTED || data[0].status == BID_REJECTED) && data[0].onStreamApiCall == 1) {
                        reqCheckCounter++;
                        if (reqCheckCounter < 2) {
                          rideService.updateStatusOfRide(rideID: data[0].rideId, req: {'on_stream_api_call': 0});
                        }
                      }
                      if ((servicesListData != null && servicesListData!.status != NEW_RIDE_REQUESTED && data[0].status == NEW_RIDE_REQUESTED && data[0].onStreamApiCall == 1) || (servicesListData == null && data[0].status == NEW_RIDE_REQUESTED && data[0].onStreamApiCall == 1)) {
                        if (rideDetailsFetching != true) {
                          rideDetailsFetching = true;
                          rideService.updateStatusOfRide(rideID: data[0].rideId, req: {'on_stream_api_call': 0});
                        }
                      }

                      return servicesListData != null
                          ? rideHasBid == 1 && (data[0].status == NEW_RIDE_REQUESTED || data[0].status == BID_REJECTED)
                              ? bidIsProcessing == 1 && (data[0].status == NEW_RIDE_REQUESTED || data[0].status == BID_REJECTED)
                                  ? bidProcessView()
                                  : SizedBox() /*bidAcceptView()*/
                              : servicesListData!.status != null && servicesListData!.status == NEW_RIDE_REQUESTED && rideHasBid != 1
                                  ? SizedBox.expand(
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          servicesListData != null && duration >= 0
                                              ? servicesListData!.type == TRANSPORT
                                                  ? Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.only(topLeft: Radius.circular(2 * defaultRadius), topRight: Radius.circular(2 * defaultRadius)),
                                                      ),
                                                      child: SingleChildScrollView(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Align(
                                                              alignment: Alignment.center,
                                                              child: Container(
                                                                margin: EdgeInsets.only(top: 16),
                                                                height: 6,
                                                                width: 60,
                                                                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                                                                alignment: Alignment.center,
                                                              ),
                                                            ),
                                                            SizedBox(height: 8),
                                                            Padding(
                                                              padding: EdgeInsets.symmetric(horizontal: 16),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.max,
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Text("${language.order}: #${servicesListData!.id}", style: primaryTextStyle(size: 20, weight: FontWeight.w400)),
                                                                  if (duration > 0)
                                                                    Container(
                                                                      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                                                                      padding: EdgeInsets.all(6),
                                                                      child: Text("$duration".padLeft(2, "0"), style: boldTextStyle(color: Colors.white)),
                                                                    )
                                                                ],
                                                              ),
                                                            ),
                                                            SizedBox(height: 5),
                                                            if (!(servicesListData?.schedule_datetime.isEmptyOrNull ?? false) && servicesListData?.isSchedule == 1) ...[
                                                              Padding(
                                                                padding: EdgeInsets.symmetric(horizontal: 16),
                                                                child: TaxiCourierButton(ScheduleTime: servicesListData?.schedule_datetime),
                                                              ),
                                                            ],
                                                            // SizedBox(height: 8),
                                                            Padding(
                                                              padding: EdgeInsets.all(16),
                                                              child: Column(
                                                                children: [
                                                                  SingleChildScrollView(
                                                                    scrollDirection: Axis.horizontal,
                                                                    child: Row(
                                                                      children: [
                                                                        buildInfoTile(
                                                                          icon: Icons.wallet,
                                                                          title_widget: printAmountWidget(amount: servicesListData?.totalAmount!.toStringAsFixed(digitAfterDecimal) ?? "", size: 14),
                                                                          subtitle: "${language.estAmount}",
                                                                        ),
                                                                        buildInfoTile(
                                                                          icon: Icons.route_outlined,
                                                                          title: "${servicesListData?.dropoff_distance_in_km?.toStringAsFixed(2)} ${servicesListData?.distanceUnit}",
                                                                          subtitle: "${language.distance}",
                                                                        ),
                                                                        buildInfoTile(
                                                                          icon: Icons.scale_outlined,
                                                                          title: "${servicesListData!.weight}",
                                                                          subtitle: "${language.weight}",
                                                                        ),
                                                                        buildInfoTile(
                                                                          icon: Icons.inventory_2_outlined,
                                                                          title: servicesListData!.parcelDescription.toString(),
                                                                          subtitle: "${language.parcel_type}",
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  SizedBox(height: 8),
                                                                  addressDisplayWidget(
                                                                      senderName: servicesListData!.pickupPersonName,
                                                                      receiverName: servicesListData!.deliveryPersonName,
                                                                      senderContact: servicesListData!.pickupContactNumber,
                                                                      receiverContact: servicesListData!.deliveryContactNumber,
                                                                      senderNote: servicesListData!.pickupDescription,
                                                                      receiverNote: servicesListData!.deliveryDescription,
                                                                      endLatLong: LatLng(servicesListData!.endLatitude.toDouble(), servicesListData!.endLongitude.toDouble()),
                                                                      endAddress: servicesListData!.endAddress,
                                                                      startLatLong: LatLng(servicesListData!.startLatitude.toDouble(), servicesListData!.startLongitude.toDouble()),
                                                                      startAddress: servicesListData!.startAddress),
                                                                  SizedBox(height: 8),
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: inkWellWidget(
                                                                          onTap: () {
                                                                            showConfirmDialogCustom(dialogType: DialogType.DELETE, primaryColor: primaryColor, title: language.areYouSureYouWantToCancelThisRequest, positiveText: language.yes, negativeText: language.no, context, onAccept: (v) {
                                                                              reqCheckCounter = 0;

                                                                              try {
                                                                                FlutterRingtonePlayer().stop();
                                                                                timerData!.cancel();
                                                                              } catch (e) {}
                                                                              sharedPref.remove(IS_TIME2);
                                                                              sharedPref.remove(ON_RIDE_MODEL);
                                                                              rideRequestAccept(deCline: true);
                                                                            }).then(
                                                                              (value) {
                                                                                _polyLines.clear();
                                                                                setState;
                                                                              },
                                                                            );
                                                                          },
                                                                          child: Container(
                                                                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(defaultRadius), border: Border.all(color: Colors.red)),
                                                                            child: Text(language.decline, style: boldTextStyle(color: Colors.red), textAlign: TextAlign.center),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(width: 16),
                                                                      Expanded(
                                                                        child: AppButtonWidget(
                                                                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                                                          text: language.accept,
                                                                          shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
                                                                          color: primaryColor,
                                                                          textStyle: boldTextStyle(color: Colors.white),
                                                                          onTap: () {
                                                                            reqCheckCounter = 0;
                                                                            showConfirmDialogCustom(primaryColor: primaryColor, dialogType: DialogType.ACCEPT, positiveText: language.yes, negativeText: language.no, title: language.areYouSureYouWantToAcceptThisRequest, context, onAccept: (v) {
                                                                              try {
                                                                                FlutterRingtonePlayer().stop();
                                                                                timerData!.cancel();
                                                                              } catch (e) {}
                                                                              sharedPref.remove(IS_TIME2);

                                                                              sharedPref.remove(ON_RIDE_MODEL);
                                                                              rideRequestAccept();
                                                                            });
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.only(topLeft: Radius.circular(2 * defaultRadius), topRight: Radius.circular(2 * defaultRadius)),
                                                      ),
                                                      child: SingleChildScrollView(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Align(
                                                              alignment: Alignment.center,
                                                              child: Container(
                                                                margin: EdgeInsets.only(top: 16),
                                                                height: 6,
                                                                width: 60,
                                                                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                                                                alignment: Alignment.center,
                                                              ),
                                                            ),
                                                            SizedBox(height: 8),
                                                            Padding(
                                                              padding: EdgeInsets.only(left: 16),
                                                              child: Text(language.requests, style: primaryTextStyle(size: 18)),
                                                            ),
                                                            SizedBox(height: 8),
                                                            Padding(
                                                              padding: EdgeInsets.all(16),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Row(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      ClipRRect(
                                                                        borderRadius: BorderRadius.circular(defaultRadius),
                                                                        child: commonCachedNetworkImage(servicesListData!.riderProfileImage.validate(), height: 35, width: 35, fit: BoxFit.cover),
                                                                      ),
                                                                      SizedBox(width: 12),
                                                                      Expanded(
                                                                        child: Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text('${servicesListData!.riderName.capitalizeFirstLetter()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)),
                                                                            SizedBox(height: 4),
                                                                            Text('${servicesListData!.riderEmail.validate()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: secondaryTextStyle()),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      if (duration > 0)
                                                                        Container(
                                                                          decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                                                                          padding: EdgeInsets.all(6),
                                                                          child: Text("$duration".padLeft(2, "0"), style: boldTextStyle(color: Colors.white)),
                                                                        )
                                                                    ],
                                                                  ),
                                                                  if (!(servicesListData?.schedule_datetime.isEmptyOrNull ?? false) && servicesListData?.isSchedule == 1) ...[
                                                                    TaxiCourierButton(ScheduleTime: servicesListData?.schedule_datetime),
                                                                  ],
                                                                  8.height,
                                                                  SingleChildScrollView(
                                                                    scrollDirection: Axis.horizontal,
                                                                    child: Row(
                                                                      children: [
                                                                        buildInfoTile(
                                                                          icon: Icons.wallet,
                                                                          title_widget: printAmountWidget(amount: servicesListData?.totalAmount!.toStringAsFixed(digitAfterDecimal) ?? "", size: 14),
                                                                          subtitle: "${language.estAmount}",
                                                                        ),
                                                                        buildInfoTile(
                                                                          icon: Icons.route_outlined,
                                                                          title: "${servicesListData?.dropoff_distance_in_km?.toStringAsFixed(2)} ${servicesListData?.distanceUnit}",
                                                                          subtitle: "${language.distance}",
                                                                        ),
                                                                        if (luggageCount > 0)
                                                                          buildInfoTile(
                                                                            icon: Icons.luggage,
                                                                            title: "${luggageCount}",
                                                                            subtitle: "${language.lblLuggage}",
                                                                          ),
                                                                        if (passengerCount > 0)
                                                                          buildInfoTile(
                                                                            icon: Icons.supervised_user_circle_outlined,
                                                                            title: passengerCount.toString(),
                                                                            subtitle: "${language.lblPassengers}",
                                                                          ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  addressDisplayWidget(
                                                                      endLatLong: LatLng(servicesListData!.endLatitude.toDouble(), servicesListData!.endLongitude.toDouble()),
                                                                      endAddress: servicesListData!.endAddress,
                                                                      startLatLong: LatLng(servicesListData!.startLatitude.toDouble(), servicesListData!.startLongitude.toDouble()),
                                                                      startAddress: servicesListData!.startAddress),
                                                                  if (servicesListData != null && servicesListData!.otherRiderData != null)
                                                                    Divider(
                                                                      color: Colors.grey.shade300,
                                                                      thickness: 0.7,
                                                                      height: 8,
                                                                    ),
                                                                  _bookingForView(),
                                                                  SizedBox(height: 8),
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: inkWellWidget(
                                                                          onTap: () {
                                                                            showConfirmDialogCustom(dialogType: DialogType.DELETE, primaryColor: primaryColor, title: language.areYouSureYouWantToCancelThisRequest, positiveText: language.yes, negativeText: language.no, context, onAccept: (v) {
                                                                              reqCheckCounter = 0;

                                                                              try {
                                                                                FlutterRingtonePlayer().stop();
                                                                                timerData!.cancel();
                                                                              } catch (e) {}
                                                                              sharedPref.remove(IS_TIME2);
                                                                              sharedPref.remove(ON_RIDE_MODEL);
                                                                              rideRequestAccept(deCline: true);
                                                                            }).then(
                                                                              (value) {
                                                                                _polyLines.clear();
                                                                                setState;
                                                                              },
                                                                            );
                                                                          },
                                                                          child: Container(
                                                                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(defaultRadius), border: Border.all(color: Colors.red)),
                                                                            child: Text(language.decline, style: boldTextStyle(color: Colors.red), textAlign: TextAlign.center),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(width: 16),
                                                                      Expanded(
                                                                        child: AppButtonWidget(
                                                                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                                                          text: language.accept,
                                                                          shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
                                                                          color: primaryColor,
                                                                          textStyle: boldTextStyle(color: Colors.white),
                                                                          onTap: () {
                                                                            reqCheckCounter = 0;
                                                                            showConfirmDialogCustom(primaryColor: primaryColor, dialogType: DialogType.ACCEPT, positiveText: language.yes, negativeText: language.no, title: language.areYouSureYouWantToAcceptThisRequest, context, onAccept: (v) {
                                                                              try {
                                                                                FlutterRingtonePlayer().stop();
                                                                                timerData!.cancel();
                                                                              } catch (e) {}
                                                                              sharedPref.remove(IS_TIME2);

                                                                              sharedPref.remove(ON_RIDE_MODEL);
                                                                              rideRequestAccept();
                                                                            });
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                              : SizedBox(),
                                          Observer(builder: (context) {
                                            return appStore.isLoading ? loaderWidget() : SizedBox();
                                          })
                                        ],
                                      ),
                                    )
                                  : servicesListData!.type == TRANSPORT
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: MediaQuery.of(context).size.width,
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.only(topLeft: Radius.circular(2 * defaultRadius), topRight: Radius.circular(2 * defaultRadius)),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Center(
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    height: 5,
                                                    width: 70,
                                                    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(defaultRadius),
                                                      child: commonCachedNetworkImage(servicesListData!.riderProfileImage, height: 38, width: 38, fit: BoxFit.cover),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('${language.bookedBy}', maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)),
                                                          Text('${servicesListData!.riderName.capitalizeFirstLetter()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: secondaryTextStyle()),
                                                        ],
                                                      ),
                                                    ),
                                                    inkWellWidget(
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (_) {
                                                            return AlertDialog(
                                                              contentPadding: EdgeInsets.all(0),
                                                              content: AlertScreen(rideId: servicesListData!.id, regionId: servicesListData!.regionId),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      child: chatCallWidget(Icons.sos),
                                                    ),
                                                    SizedBox(width: 8),
                                                    inkWellWidget(
                                                      onTap: () {
                                                        launchUrl(Uri.parse('tel:${servicesListData!.riderContactNumber}'), mode: LaunchMode.externalApplication);
                                                      },
                                                      child: chatCallWidget(Icons.call),
                                                    ),
                                                    SizedBox(width: 8),
                                                    inkWellWidget(
                                                      onTap: () {
                                                        if (riderData == null || (riderData != null && riderData!.uid == null)) {
                                                          init();
                                                          return;
                                                        }
                                                        if (riderData != null) {
                                                          launchScreen(
                                                              context,
                                                              ChatScreen(
                                                                userData: riderData,
                                                                ride_id: riderId,
                                                              ));
                                                        }
                                                      },
                                                      child: chatCallWidget(Icons.chat_bubble_outline, data: riderData),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    children: [
                                                      buildInfoTile(
                                                        icon: Icons.wallet,
                                                        title_widget: printAmountWidget(amount: servicesListData?.totalAmount!.toStringAsFixed(digitAfterDecimal) ?? "", size: 14),
                                                        subtitle: "${language.estAmount}",
                                                      ),
                                                      buildInfoTile(
                                                        icon: Icons.route_outlined,
                                                        title: "${servicesListData?.dropoff_distance_in_km?.toStringAsFixed(2)} ${servicesListData?.distanceUnit}",
                                                        subtitle: "${language.distance}",
                                                      ),
                                                      buildInfoTile(
                                                        icon: Icons.scale_outlined,
                                                        title: "${servicesListData!.weight} kg",
                                                        subtitle: "${language.weight}",
                                                      ),
                                                      buildInfoTile(
                                                        icon: Icons.inventory_2_outlined,
                                                        title: servicesListData!.parcelDescription.toString(),
                                                        subtitle: "${language.parcel_type}",
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                addressDisplayWidget(
                                                    senderName: servicesListData!.pickupPersonName,
                                                    receiverName: servicesListData!.deliveryPersonName,
                                                    senderContact: servicesListData!.pickupContactNumber,
                                                    receiverContact: servicesListData!.deliveryContactNumber,
                                                    senderNote: servicesListData!.pickupDescription,
                                                    receiverNote: servicesListData!.deliveryDescription,
                                                    endLatLong: LatLng(servicesListData!.endLatitude.toDouble(), servicesListData!.endLongitude.toDouble()),
                                                    endAddress: servicesListData!.endAddress,
                                                    startLatLong: LatLng(servicesListData!.startLatitude.toDouble(), servicesListData!.startLongitude.toDouble()),
                                                    startAddress: servicesListData!.startAddress),
                                                SizedBox(height: 8),
                                                servicesListData!.status != NEW_RIDE_REQUESTED
                                                    ? Padding(
                                                        padding: EdgeInsets.only(bottom: servicesListData!.status == IN_PROGRESS ? 0 : 8),
                                                        child: _bookingForView(),
                                                      )
                                                    : SizedBox(),
                                                if (servicesListData!.status == IN_PROGRESS && servicesListData != null && servicesListData!.otherRiderData != null) SizedBox(height: 8),
                                                if (servicesListData!.status == IN_PROGRESS && servicesListData?.type != TRANSPORT)
                                                  // if (appStore.extraChargeValue != null)
                                                  Observer(builder: (context) {
                                                    return Visibility(
                                                      visible: int.parse(appStore.extraChargeValue!) != 0,
                                                      child: inkWellWidget(
                                                        onTap: () async {
                                                          List<ExtraChargeRequestModel>? extraChargeListData = await showModalBottomSheet(
                                                            isScrollControlled: true,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius))),
                                                            context: context,
                                                            builder: (_) {
                                                              return Padding(
                                                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                                                child: ExtraChargesWidget(data: extraChargeList),
                                                              );
                                                            },
                                                          );
                                                          if (extraChargeListData != null) {
                                                            log("extraChargeListData   $extraChargeListData");
                                                            extraChargeAmount = 0;
                                                            extraChargeList.clear();
                                                            extraChargeListData.forEach((element) {
                                                              extraChargeAmount = extraChargeAmount + element.value!;
                                                              extraChargeList = extraChargeListData;
                                                            });
                                                            appStore.extraChargeValue = "$extraChargeAmount";
                                                            setState(
                                                              () {},
                                                            );
                                                          }
                                                        },
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding: EdgeInsets.only(bottom: 8),
                                                              child: Container(
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.max,
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    if (extraChargeAmount != 0)
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text('${language.extraCharges} : ', style: secondaryTextStyle(color: Colors.green)),
                                                                          printAmountWidget(amount: '${extraChargeAmount.toStringAsFixed(digitAfterDecimal)}', size: 14, color: Colors.green, weight: FontWeight.normal)
                                                                        ],
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                buttonWidget()
                                              ],
                                            ),
                                          ),
                                        )
                                      : Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: MediaQuery.of(context).size.width,
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.only(topLeft: Radius.circular(2 * defaultRadius), topRight: Radius.circular(2 * defaultRadius)),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Center(
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    height: 5,
                                                    width: 70,
                                                    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(defaultRadius),
                                                      child: commonCachedNetworkImage(servicesListData!.riderProfileImage, height: 38, width: 38, fit: BoxFit.cover),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('${servicesListData!.riderName.capitalizeFirstLetter()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)),
                                                          SizedBox(height: 4),
                                                          Text('${servicesListData!.riderEmail.validate()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: secondaryTextStyle()),
                                                        ],
                                                      ),
                                                    ),
                                                    inkWellWidget(
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (_) {
                                                            return AlertDialog(
                                                              contentPadding: EdgeInsets.all(0),
                                                              content: AlertScreen(rideId: servicesListData!.id, regionId: servicesListData!.regionId),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      child: chatCallWidget(Icons.sos),
                                                    ),
                                                    SizedBox(width: 8),
                                                    inkWellWidget(
                                                      onTap: () {
                                                        launchUrl(Uri.parse('tel:${servicesListData!.riderContactNumber}'), mode: LaunchMode.externalApplication);
                                                      },
                                                      child: chatCallWidget(Icons.call),
                                                    ),
                                                    SizedBox(width: 8),
                                                    inkWellWidget(
                                                      onTap: () {
                                                        if (riderData == null || (riderData != null && riderData!.uid == null)) {
                                                          init();
                                                          return;
                                                        }
                                                        if (riderData != null) {
                                                          launchScreen(
                                                              context,
                                                              ChatScreen(
                                                                userData: riderData,
                                                                ride_id: riderId,
                                                              ));
                                                        }
                                                      },
                                                      child: chatCallWidget(Icons.chat_bubble_outline, data: riderData),
                                                    ),
                                                    if (appStore.flightTracking == "1" && servicesListData!.trip_type.toString().toLowerCase().contains('airport')) SizedBox(width: 8),
                                                    if (appStore.flightTracking == "1" && servicesListData!.trip_type.toString().toLowerCase().contains('airport'))
                                                      inkWellWidget(
                                                        onTap: () {
                                                          showDialog(
                                                            barrierDismissible: false,
                                                            context: context,
                                                            builder: (context) {
                                                              return Theme(
                                                                data: Theme.of(context).copyWith(
                                                                  dialogTheme: DialogThemeData(shape: dialogShape()),
                                                                  dialogBackgroundColor: Colors.white,
                                                                  // Optional
                                                                  colorScheme: Theme.of(context).colorScheme.copyWith(
                                                                        primary: primaryColor, // Your primary color here
                                                                      ),
                                                                  textTheme: TextTheme(
                                                                    titleLarge: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                                                    bodyMedium: TextStyle(color: Colors.black87),
                                                                  ),
                                                                ),
                                                                child: AlertDialog(
                                                                  title: Text(
                                                                    '${language.flightDetails}',
                                                                    style: primaryTextStyle(color: Colors.black),
                                                                  ),
                                                                  content: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      _detailRow('${language.flightNumber}', "${servicesListData!.flight_number}").visible(!(servicesListData?.flight_number.isEmptyOrNull ?? false)),
                                                                      _detailRow('${language.terminalAddress}', "${servicesListData!.pickup_point}").visible(!(servicesListData?.pickup_point.isEmptyOrNull ?? false)),
                                                                      _detailRow('${language.preferredPickupTime}', "${servicesListData!.preferred_pickup_time}").visible(!(servicesListData?.preferred_pickup_time.isEmptyOrNull ?? false)),
                                                                      _detailRow('${language.preferredDropTime}', "${servicesListData?.preferred_dropoff_time}").visible(!(servicesListData?.preferred_dropoff_time.isEmptyOrNull ?? false)),
                                                                    ],
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.of(context).pop(),
                                                                      child: Text('${language.cancel}'),
                                                                    ),
                                                                    ElevatedButton(
                                                                      onPressed: () {
                                                                        launchScreen(context, FlightTrackingScreen(flightNumber: servicesListData?.flight_number ?? ''), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: false);
                                                                      },
                                                                      child: Text('${language.track}'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: chatCallWidget(Icons.flight, data: riderData),
                                                      ),
                                                  ],
                                                ),
                                                SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Row(
                                                    children: [
                                                      buildInfoTile(
                                                        icon: Icons.wallet,
                                                        title_widget: printAmountWidget(amount: servicesListData?.totalAmount!.toStringAsFixed(digitAfterDecimal) ?? "", size: 14),
                                                        subtitle: "${language.estAmount}",
                                                      ),
                                                      buildInfoTile(
                                                        icon: Icons.route_outlined,
                                                        title: "${servicesListData?.dropoff_distance_in_km?.toStringAsFixed(2)} ${servicesListData?.distanceUnit}",
                                                        subtitle: "${language.distance}",
                                                      ),
                                                      if (luggageCount > 0)
                                                        buildInfoTile(
                                                          icon: Icons.luggage,
                                                          title: "${luggageCount}",
                                                          subtitle: "${language.lblLuggage}",
                                                        ),
                                                      if (passengerCount > 0)
                                                        buildInfoTile(
                                                          icon: Icons.supervised_user_circle_outlined,
                                                          title: passengerCount.toString(),
                                                          subtitle: "${language.lblPassengers}",
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                addressDisplayWidget(
                                                    endLatLong: LatLng(servicesListData!.endLatitude.toDouble(), servicesListData!.endLongitude.toDouble()),
                                                    endAddress: servicesListData!.endAddress,
                                                    startLatLong: LatLng(servicesListData!.startLatitude.toDouble(), servicesListData!.startLongitude.toDouble()),
                                                    startAddress: servicesListData!.startAddress),
                                                SizedBox(height: 8),
                                                servicesListData!.status != NEW_RIDE_REQUESTED
                                                    ? Padding(
                                                        padding: EdgeInsets.only(bottom: servicesListData!.status == IN_PROGRESS ? 0 : 8),
                                                        child: _bookingForView(),
                                                      )
                                                    : SizedBox(),
                                                if (servicesListData!.status == IN_PROGRESS && servicesListData != null && servicesListData!.otherRiderData != null) SizedBox(height: 8),
                                                if (servicesListData!.status == IN_PROGRESS && servicesListData?.type != TRANSPORT)
                                                  Observer(builder: (context) {
                                                    return Visibility(
                                                      visible: int.parse(appStore.extraChargeValue!) != 0,
                                                      child: inkWellWidget(
                                                        onTap: () async {
                                                          List<ExtraChargeRequestModel>? extraChargeListData = await showModalBottomSheet(
                                                            isScrollControlled: true,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius))),
                                                            context: context,
                                                            builder: (_) {
                                                              return Padding(
                                                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                                                child: ExtraChargesWidget(data: extraChargeList),
                                                              );
                                                            },
                                                          );
                                                          if (extraChargeListData != null) {
                                                            extraChargeAmount = 0;
                                                            extraChargeList.clear();
                                                            extraChargeListData.forEach((element) {
                                                              extraChargeAmount = extraChargeAmount + element.value!;
                                                              extraChargeList = extraChargeListData;
                                                            });
                                                            appStore.extraChargeValue = "$extraChargeAmount";
                                                            setState(
                                                              () {},
                                                            );
                                                          }
                                                        },
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding: EdgeInsets.only(bottom: 8),
                                                              child: Container(
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.max,
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    if (extraChargeAmount != 0)
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text('${language.extraCharges} : ', style: secondaryTextStyle(color: Colors.green)),
                                                                          printAmountWidget(amount: '${extraChargeAmount.toStringAsFixed(digitAfterDecimal)}', size: 14, color: Colors.green, weight: FontWeight.normal)
                                                                        ],
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                buttonWidget()
                                              ],
                                            ),
                                          ),
                                        )
                          : SizedBox();
                    } else {
                      if (data.isEmpty) {
                        rideHasBid = 0;
                        bidIsProcessing = 0;
                        reqCheckCounter = 0;
                        try {
                          FlutterRingtonePlayer().stop();
                          if (timerData != null) {
                            timerData!.cancel();
                          }
                        } catch (e) {}
                      }
                      if (servicesListData != null) {
                        checkRideCancel();
                      }
                      if (riderId != 0) {
                        riderId = 0;
                        try {
                          sharedPref.remove(IS_TIME2);
                          timerData!.cancel();
                        } catch (e) {}
                      }
                      servicesListData = null;
                      _polyLines.clear();
                      return SizedBox();
                    }
                  } else {
                    return snapWidgetHelper(snapshot, loadingWidget: loaderWidget());
                  }
                }),
            Positioned(
              top: context.statusBarHeight + 4,
              right: 14,
              left: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  topWidget(),
                  SizedBox(
                    height: 8,
                  ),
                  inkWellWidget(
                    onTap: () async {
                      final geoPosition = await Geolocator.getCurrentPosition(timeLimit: Duration(seconds: 30), desiredAccuracy: LocationAccuracy.high);
                      mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(geoPosition.latitude, geoPosition.longitude)));
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
                      child: Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
            Observer(
              builder: (context) {
                return Visibility(
                  visible: appStore.isLoading,
                  child: loaderWidget(),
                );
              },
            ),
            if (schedule_ride_request.isNotEmpty)
              Positioned(
                left: position.dx,
                top: position.dy,
                child: Draggable(
                  feedback: buildFloatingWidget(),
                  childWhenDragging: Container(),
                  onDragEnd: (details) {
                    final newOffset = details.offset;
                    final screenSize = MediaQuery.of(context).size;
                    final safeX = newOffset.dx.clamp(0.0, screenSize.width - 150);
                    final safeY = newOffset.dy.clamp(0.0, screenSize.height - 56);
                    setState(() {
                      position = Offset(safeX, safeY);
                    });
                  },
                  child: GestureDetector(
                    onTap: () {
                      launchScreen(context, UpcomingMainScreen());
                    },
                    child: buildFloatingWidget(),
                  ),
                ),
              ),
            Observer(builder: (context) => Visibility(visible: appStore.isLoading, child: Positioned.fill(child: loaderWidget()))),
          ],
        ),
      ),
    );
  }

  Future<void> getUserLocation() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(driverLocation!.latitude, driverLocation!.longitude);
    Placemark place = placemarks[0];
    endLocationAddress = '${place.street},${place.subLocality},${place.thoroughfare},${place.locality}';
  }

  Widget topWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        inkWellWidget(
          onTap: () {
            scaffoldKey.currentState!.openDrawer();
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
            child: Icon(Icons.drag_handle),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), spreadRadius: 1),
                ],
                borderRadius: BorderRadius.circular(defaultRadius),
                border: Border.all(color: isOnLine ? Colors.green : Colors.red)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
              /*  lt.Lottie.asset(
                  taxiAnim,
                  height: 25,
                  fit: BoxFit.cover,
                  animate: isOnLine,
                ),
                SizedBox(width: 8),*/
                Text(isOnLine ? language.youAreOnlineNow : language.youAreOfflineNow, style: secondaryTextStyle(color: primaryColor)),
              ],
            ),
          ),
        ),
        inkWellWidget(
          onTap: () {
            launchScreen(
              getContext,
              NotificationScreen(),
            );
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
            child: Icon(Ionicons.notifications_outline),
          ),
        ),
      ],
    );
  }

  Widget onlineOfflineSwitch() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                await showConfirmDialogCustom(dialogType: DialogType.CONFIRMATION, primaryColor: primaryColor, title: isOnLine ? language.areYouCertainOffline : language.areYouCertainOnline, context, onAccept: (v) {
                  driverStatus(status: isOnLine ? 0 : 1);
                  isOnLine = !isOnLine;
                  setState(() {});
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 600),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isOnLine ? Colors.green : Colors.red,
                    )),
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    isOnLine
                        ? Text(
                            language.online,
                            style: boldTextStyle(color: Colors.green, size: 18, weight: FontWeight.w700),
                          )
                        : ImageIcon(AssetImage(ic_red_car), color: Colors.red, size: 30),
                    SizedBox(width: 8),
                    isOnLine
                        ? ImageIcon(AssetImage(ic_green_car), color: Colors.green, size: 30)
                        : Text(
                            language.offLine,
                            style: boldTextStyle(color: Colors.red, size: 18, weight: FontWeight.w700),
                          )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buttonWidget() {
    return Row(
      children: [
        if (servicesListData!.status != IN_PROGRESS)
          Expanded(
            flex: 0,
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: AppButtonWidget(
                  text: language.cancel,
                  textColor: primaryColor,
                  color: Colors.white,
                  shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        isDismissible: false,
                        builder: (context) {
                          return CancelOrderDialog(
                              service_type: servicesListData?.type ?? '',
                              onCancel: (reason) async {
                                Navigator.pop(context);
                                appStore.setLoading(true);
                                await cancelRequest(reason);
                                appStore.setLoading(false);
                              });
                        });
                  }),
            ),
          ),
        if (servicesListData!.status == IN_PROGRESS && servicesListData!.type != TRANSPORT)
          Expanded(
            flex: 0,
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: AppButtonWidget(
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        language.extraFees,
                        style: boldTextStyle(
                          color: primaryColor,
                        ),
                      )
                    ],
                  ),
                  text: language.extraFees,
                  textColor: primaryColor,
                  color: Colors.white,
                  shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
                  onTap: () async {
                    List<ExtraChargeRequestModel>? extraChargeListData = await showModalBottomSheet(
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius))),
                      context: context,
                      builder: (_) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: ExtraChargesWidget(data: extraChargeList),
                        );
                      },
                    );
                    if (extraChargeListData != null) {
                      log("extraChargeListData   $extraChargeListData");
                      extraChargeAmount = 0;
                      extraChargeList.clear();
                      extraChargeListData.forEach((element) {
                        extraChargeAmount = extraChargeAmount + element.value!;
                        extraChargeList = extraChargeListData;
                      });
                      appStore.extraChargeValue = "$extraChargeAmount";
                      setState(
                        () {},
                      );
                    }
                  }),
            ),
          ),
        if (servicesListData?.status != COMPLETED)
          Expanded(
            flex: 1,
            child: AppButtonWidget(
              text: buttonText(status: servicesListData?.status),
              color: primaryColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ImageIcon(
                    AssetImage(statusTypeIconForButton(
                        type: servicesListData!.status == IN_PROGRESS && servicesListData!.multiDropLocation != null && servicesListData!.multiDropLocation!.isNotEmpty && servicesListData!.multiDropLocation!.where((element) => element.droppedAt == null).length > 1
                            ? IN_PROGRESS
                            : servicesListData!.status.validate())),
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Text(
                      servicesListData!.status == ARRIVED && servicesListData!.type == TRANSPORT && servicesListData!.paymentStatus != PAYMENT_PAID
                          ? "${language.collectAmount}"
                          : servicesListData!.status == ARRIVED && servicesListData!.type == TRANSPORT
                              ? "${language.collectOrder}"
                              : servicesListData!.status == IN_PROGRESS && servicesListData!.type == TRANSPORT
                                  ? "${language.completeDelivery}"
                                  : servicesListData!.status == IN_PROGRESS && servicesListData!.multiDropLocation != null && servicesListData!.multiDropLocation!.isNotEmpty && servicesListData!.multiDropLocation!.where((element) => element.droppedAt == null).length > 1
                                      ? language.updateDrop
                                      : servicesListData!.type == TRANSPORT
                                          ? buttonTransportText(status: servicesListData?.status, paymentStatus: servicesListData?.paymentStatus, paymentType: servicesListData?.paymentType)
                                          : buttonText(status: servicesListData?.status),
                      style: boldTextStyle(color: Colors.white)),
                ],
              ),
              textStyle: boldTextStyle(color: Colors.white),
              onTap: () async {
                if (await checkPermission()) {
                  if (servicesListData!.status == ARRIVED && servicesListData!.type == TRANSPORT && servicesListData!.paymentStatus != PAYMENT_PAID) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) {
                        return AlertDialog(
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${language.paymentReceive}", style: boldTextStyle(), textAlign: TextAlign.center),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: inkWellWidget(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                                        child: Icon(Icons.close, size: 20, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text("${language.paymentReceiveDesc}", style: secondaryTextStyle(size: 12), textAlign: TextAlign.center),
                              SizedBox(height: 16),
                              AppButtonWidget(
                                width: MediaQuery.of(context).size.width,
                                text: language.confirm,
                                onTap: () async {
                                  Navigator.pop(context);
                                  appStore.setLoading(true);
                                  Map req = {
                                    "rider_id": servicesListData!.riderId,
                                    "ride_request_id": servicesListData!.id,
                                    "datetime": DateTime.now().toString(),
                                    "total_amount": servicesListData!.totalAmount,
                                    "payment_type": "cash",
                                    "txn_id": "",
                                    "payment_status": PAYMENT_PAID,
                                    "transaction_detail": ""
                                  };
                                  await savePayment(req).then((value) async {
                                    appStore.setLoading(false);
                                    getCurrentRequest();
                                  }).catchError((error, s) {
                                    appStore.setLoading(false);
                                    print("ExceptionFound.E+>$error:::STACK:::$s");
                                  });
                                },
                              )
                            ],
                          ),
                        );
                      },
                    );
                    //   Here for delivery case call first payment api then update ride status
                  } else if (servicesListData!.status == ACCEPTED || servicesListData!.status == 'assign_driver') {
                    otpController.clear();
                    if (sharedPref.getString(OTP_STATUS).validate() == '0') {
                      if (servicesListData?.paymentStatus == 'pending' && servicesListData?.paymentType == 'cash' && servicesListData?.type == TRANSPORT) {
                        //first payment
                        appStore.setLoading(true);
                        Map req = {"rider_id": servicesListData!.riderId, "ride_request_id": servicesListData!.id, "datetime": DateTime.now().toString(), "total_amount": servicesListData!.totalAmount, "payment_type": "cash", "txn_id": "", "payment_status": PAYMENT_PAID, "transaction_detail": ""};
                        await savePayment(req).then((value) async {
                          appStore.setLoading(false);
                          servicesListData?.paymentStatus = PAYMENT_PAID;
                          setState(() {});
                        }).catchError((error, s) {
                          appStore.setLoading(false);
                          print("ExceptionFound.E+>$error:::STACK:::$s");
                        });
                      } else {
                        rideRequest(status: IN_PROGRESS);
                      }
                    } else {
                      if (servicesListData?.paymentStatus == 'pending' && servicesListData?.paymentType == 'cash' && servicesListData?.type == TRANSPORT) {
                        //first payment
                        appStore.setLoading(true);
                        Map req = {"rider_id": servicesListData?.riderId, "ride_request_id": servicesListData?.id, "datetime": DateTime.now().toString(), "total_amount": servicesListData!.totalAmount, "payment_type": "cash", "txn_id": "", "payment_status": PAYMENT_PAID, "transaction_detail": ""};
                        await savePayment(req).then((value) async {
                          appStore.setLoading(false);
                          servicesListData?.paymentStatus = PAYMENT_PAID;
                          setState(() {});
                        }).catchError((error, s) {
                          appStore.setLoading(false);
                          print("ExceptionFound.E+>$error:::STACK:::$s");
                        });
                      } else {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) {
                            return AlertDialog(
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(language.enterOtp, style: boldTextStyle(), textAlign: TextAlign.center),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: inkWellWidget(
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                                            child: Icon(Icons.close, size: 20, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Text(language.startRideAskOTP, style: secondaryTextStyle(size: 12), textAlign: TextAlign.center),
                                  SizedBox(height: 16),
                                  Center(
                                    child: Pinput(
                                      keyboardType: TextInputType.number,
                                      readOnly: false,
                                      autofocus: true,
                                      length: 4,
                                      onTap: () {},
                                      onLongPress: () {},
                                      cursor: Text(
                                        "|",
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                                      ),
                                      focusedPinTheme: PinTheme(
                                        width: 40,
                                        height: 44,
                                        textStyle: TextStyle(
                                          fontSize: 18,
                                        ),
                                        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.all(Radius.circular(8)), border: Border.all(color: primaryColor)),
                                      ),
                                      toolbarEnabled: true,
                                      useNativeKeyboard: true,
                                      defaultPinTheme: PinTheme(
                                        width: 40,
                                        height: 44,
                                        textStyle: TextStyle(
                                          fontSize: 18,
                                        ),
                                        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.all(Radius.circular(8)), border: Border.all(color: dividerColor)),
                                      ),
                                      isCursorAnimationEnabled: true,
                                      showCursor: true,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      closeKeyboardWhenCompleted: false,
                                      enableSuggestions: false,
                                      autofillHints: [],
                                      controller: otpController,
                                      onCompleted: (val) {
                                        otpCheck = val;
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  AppButtonWidget(
                                    width: MediaQuery.of(context).size.width,
                                    text: language.confirm,
                                    onTap: () {
                                      if (otpCheck == null || otpCheck != servicesListData!.otp) {
                                        return toast(language.pleaseEnterValidOtp);
                                      } else {
                                        Navigator.pop(context);
                                        rideRequest(status: IN_PROGRESS);
                                      }
                                    },
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      }
                    }
                  } else if (servicesListData!.status == IN_PROGRESS) {
                    // check is all drop location passed
                    if (servicesListData!.multiDropLocation != null && servicesListData!.multiDropLocation!.isNotEmpty && servicesListData!.multiDropLocation!.where((element) => element.droppedAt == null).length > 1) {
                      for (int i = 0; i < servicesListData!.multiDropLocation!.length; i++) {
                        if (servicesListData!.multiDropLocation![i].droppedAt == null) {
                          await dropOupUpdate(rideId: '${servicesListData!.id}', dropIndex: '${servicesListData!.multiDropLocation![i].drop}').then(
                            (v) {
                              servicesListData!.multiDropLocation![i].droppedAt = DateTime.now().toString();
                              if (v != null && v['message'] != null) {
                                toast(v['message'].toString());
                              }
                            },
                          );
                          getCurrentRequest();
                          break;
                        }
                      }
                      setMapPins();
                    } else {
                      showConfirmDialogCustom(primaryColor: primaryColor, dialogType: DialogType.ACCEPT, title: language.finishMsg, context, positiveText: language.yes, negativeText: language.no, onAccept: (v) {
                        appStore.setLoading(true);
                        getUserLocation().then((value2) async {
                          // totalDistance = calculateDistance(
                          //     double.parse(servicesListData!.startLatitude.validate()), double.parse(servicesListData!.startLongitude.validate()), driverLocation!.latitude, driverLocation!.longitude);
                          await completeRideRequest();
                        });
                      });
                    }
                  }
                }
              },
            ),
          ),
      ],
    );
  }

  Widget addressDisplayWidget({String? startAddress, String? endAddress, required LatLng startLatLong, required LatLng endLatLong, bool? isMultiple, String? senderName, String? receiverName, String? senderContact, String? receiverContact, String? senderNote, String? receiverNote}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.near_me, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!senderName.isEmptyOrNull) Text('$senderName', maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)),
                Text(startAddress ?? ''.validate(), style: primaryTextStyle(size: 14), maxLines: 2),
                if (!senderNote.isEmptyOrNull) Text('Note: $senderNote', maxLines: 3, overflow: TextOverflow.ellipsis, style: secondaryTextStyle(size: 14)),
              ],
            )),
            SizedBox(width: 8),
            if (!senderContact.isEmptyOrNull)
              inkWellWidget(
                onTap: () {
                  launchUrl(Uri.parse('tel:${senderContact}'), mode: LaunchMode.externalApplication);
                },
                child: Icon(Icons.call),
              ),
            if (!senderContact.isEmptyOrNull) SizedBox(width: 8),
            mapRedirectionWidget(latLong: LatLng(startLatLong.latitude.toDouble(), startLatLong.longitude.toDouble()))
          ],
        ),
        Row(
          children: [
            SizedBox(width: 8),
            SizedBox(
              height: 24,
              child: DottedLine(
                direction: Axis.vertical,
                lineLength: double.infinity,
                lineThickness: 1,
                dashLength: 2,
                dashColor: primaryColor,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!receiverName.isEmptyOrNull) Text('$receiverName', maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)),
                Text(endAddress ?? '', style: primaryTextStyle(size: 14), maxLines: 2),
                if (!receiverNote.isEmptyOrNull) Text('Note: $receiverNote', maxLines: 3, overflow: TextOverflow.ellipsis, style: secondaryTextStyle(size: 14)),
              ],
            )),
            SizedBox(width: 8),
            if (!receiverName.isEmptyOrNull)
              inkWellWidget(
                onTap: () {
                  launchUrl(Uri.parse('tel:${receiverContact}'), mode: LaunchMode.externalApplication);
                },
                child: Icon(Icons.call),
              ),
            if (!receiverName.isEmptyOrNull) SizedBox(width: 8),
            mapRedirectionWidget(latLong: LatLng(endLatLong.latitude.toDouble(), endLatLong.longitude.toDouble()))
          ],
        ),
        if (servicesListData != null && servicesListData!.multiDropLocation != null && servicesListData!.multiDropLocation!.isNotEmpty)
          Row(
            children: [
              SizedBox(width: 8),
              SizedBox(
                height: 24,
                child: DottedLine(
                  direction: Axis.vertical,
                  lineLength: double.infinity,
                  lineThickness: 1,
                  dashLength: 2,
                  dashColor: primaryColor,
                ),
              ),
            ],
          ),
        if (servicesListData != null && servicesListData!.multiDropLocation != null && servicesListData!.multiDropLocation!.isNotEmpty)
          AppButtonWidget(
            textColor: primaryColor,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            height: 30,
            shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  color: primaryColor,
                  size: 12,
                ),
                Text(
                  language.viewMore,
                  style: primaryTextStyle(size: 14),
                ),
              ],
            ),
            onTap: () {
              showOnlyDropLocationsDialog(context: context, multiDropData: servicesListData!.multiDropLocation!);
            },
          )
      ],
    );
  }

  Widget emptyWalletAlertDialog() {
    return AlertDialog(
      backgroundColor: Colors.white,
      content: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            lt.Lottie.asset(walletAnim, height: 150, fit: BoxFit.contain),
            SizedBox(height: 8),
            Text(language.lessWalletAmountMsg, style: primaryTextStyle(), textAlign: TextAlign.left),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppButtonWidget(
                    padding: EdgeInsets.zero,
                    color: Colors.red,
                    text: language.no,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: AppButtonWidget(
                    padding: EdgeInsets.zero,
                    text: language.yes,
                    onTap: () {
                      Navigator.pop(context);
                      launchScreen(context, WalletScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  _bookingForView() {
    if (servicesListData != null && servicesListData!.otherRiderData != null) {
      return Rideforwidget(name: servicesListData!.otherRiderData!.name.validate(), contact: servicesListData!.otherRiderData!.conatctNumber.validate());
    }
    return SizedBox();
  }

  void rejectBid() async {
    Map req = {"id": "${servicesListData!.id}", "driver_id": sharedPref.getInt(USER_ID), "is_bid_accept": "2"};
    LDBaseResponse b = await responseBidListing(req);
    toast(b.message.toString());
  }

  Future<void> cancelRequest(String? reason) async {
    Map req = {
      "id": servicesListData!.id,
      "cancel_by": DRIVER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: servicesListData!.id).then((value) async {
      toast(value.message);
      chatMessageService.exportChat(rideId: "", senderId: sharedPref.getString(UID).validate(), receiverId: riderData!.uid.validate(), onlyDelete: true);
      setMapPins();
    }).catchError((error, s) {
      setMapPins();
      try {
        chatMessageService.exportChat(rideId: "", senderId: sharedPref.getString(UID).validate(), receiverId: riderData!.uid.validate(), onlyDelete: true);
      } catch (e) {
        throw e;
      }
      print("ExceptionFound.E+>$error:::STACK:::$s");
    });
  }

  void checkRideCancel() async {
    if (rideCancelDetected) return;
    rideCancelDetected = true;
    appStore.setLoading(true);
    sharedPref.remove(ON_RIDE_MODEL);
    sharedPref.remove(IS_TIME2);
    await rideDetail(rideId: servicesListData!.id).then((value) {
      appStore.setLoading(false);
      if (value.data!.status == CANCELED && value.data!.cancelBy == RIDER) {
        _polyLines.clear();
        setMapPins();
        _triggerCanceledPopup(reason: value.data!.reason.validate());
      }
    }).catchError((error, s) {
      appStore.setLoading(false);
      print("ExceptionFound.E+>$error:::STACK:::$s");
    });
  }

  void _triggerCanceledPopup({required String reason}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(
                language.rideCanceledByRider,
                maxLines: 2,
                style: boldTextStyle(),
              )),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.clear),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                language.cancelledReason,
                style: secondaryTextStyle(),
              ),
              Text(
                reason,
                style: primaryTextStyle(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget bidProcessView() {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          servicesListData != null
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(2 * defaultRadius), topRight: Radius.circular(2 * defaultRadius)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            margin: EdgeInsets.only(top: 16),
                            height: 6,
                            width: 60,
                            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                            alignment: Alignment.center,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(language.bid_under_review, style: primaryTextStyle(size: 18, weight: FontWeight.w700)),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(language.bid_under_review_note, style: secondaryTextStyle()),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Divider(),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(defaultRadius),
                                child: commonCachedNetworkImage(servicesListData!.riderProfileImage.validate(), height: 35, width: 35, fit: BoxFit.cover),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${servicesListData!.riderName.capitalizeFirstLetter()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)),
                                    SizedBox(height: 4),
                                    Text('${servicesListData!.riderEmail.validate()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: secondaryTextStyle()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: addressDisplayWidget(
                              endLatLong: LatLng(servicesListData!.endLatitude.toDouble(), servicesListData!.endLongitude.toDouble()),
                              endAddress: servicesListData!.endAddress,
                              startLatLong: LatLng(servicesListData!.startLatitude.toDouble(), servicesListData!.startLongitude.toDouble()),
                              startAddress: servicesListData!.startAddress),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("${language.amount}: ", style: primaryTextStyle(size: 16, weight: FontWeight.w400)),
                              printAmountWidget(amount: bidData!.bidAmount.toString()),
                            ],
                          ),
                        ),
                        if (bidData!.notes != null && bidData!.notes!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(bidData!.notes.toString(), style: secondaryTextStyle()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (bidData!.notes != null && bidData!.notes!.isNotEmpty) SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: AppButtonWidget(
                              width: MediaQuery.of(context).size.width,
                              text: language.cancel_my_bid,
                              textColor: primaryColor,
                              color: Colors.white,
                              shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
                              onTap: () {
                                rejectBid();
                              }),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                )
              : SizedBox(),
          Observer(builder: (context) {
            return appStore.isLoading ? loaderWidget() : SizedBox();
          })
        ],
      ),
    );
  }

  // void calculateFees({var refreshCall}) {
  //   num x = num.tryParse(bidAmountController.text.toString()) ?? 0;
  //   if (commission_type == "fixed") {
  //     platformFee = admin_commission;
  //     youWillGet = x - platformFee;
  //     refreshCall();
  //     if (x < platformFee) return;
  //   } else if (commission_type == "percentage") {
  //     if (x < surge_charge) {
  //       bidAmountController.text = (surge_charge + 10).toString();
  //     }
  //     num price = x;
  //     platformFee = admin_commission * price / 100;
  //     youWillGet = x - platformFee;
  //     refreshCall();
  //     if (x < platformFee) return;
  //   }
  //   youWillGet = x - platformFee;
  //   refreshCall();
  // }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget buildFloatingWidget() {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: 56,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2, spreadRadius: 1)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            lt.Lottie.asset(
              messageDetect,
              height: 30,
              width: 30,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 8),
            Text(
              '${language.lblUpcomingService}',
              style: boldTextStyle(size: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _updateUserLocation() async {
    Position b = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    driverLocation = LatLng(b.latitude, b.longitude);
    Map req = {
      "latitude": driverLocation!.latitude.toString(),
      "longitude": driverLocation!.longitude.toString(),
    };
    sharedPref.setDouble(LATITUDE, driverLocation!.latitude);
    sharedPref.setDouble(LONGITUDE, driverLocation!.longitude);
    await updateStatus(req).then((value) {
      setMapPins();
    }).catchError((error) {
      log(error);
    });
  }

// _buildPassengerAndLuggageView() {
//   if (/*servicesListData!=null && servicesListData!.passenger!=null && servicesListData!.luggage!=null*/ true) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 8),
//       padding: EdgeInsets.symmetric(vertical: 0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         mainAxisSize: MainAxisSize.max,
//         children: [
//           Expanded(
//             child: Row(
//               children: [
//                 Text('${language.lblPassengers}:', style: secondaryTextStyle(size: 16)),
//                 SizedBox(width: 4),
//                 Text('${passengerCount}', style: primaryTextStyle(size: 16)),
//               ],
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             mainAxisSize: MainAxisSize.max,
//             children: [
//               Text('${language.lblLuggage}:', style: secondaryTextStyle(size: 16)),
//               SizedBox(width: 4),
//               Text('${luggageCount}', style: primaryTextStyle(size: 16)),
//             ],
//           ),
//         ],
//       ),
//       width: context.width(),
//     );
//   } else {
//     return SizedBox();
//   }
// }
}
