import 'dart:async';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:pinput/pinput.dart';
import 'package:taxi_driver/Services/RideService.dart';
import 'package:taxi_driver/components/AlertScreen.dart';
import 'package:taxi_driver/components/CancelOrderDialog.dart';
import 'package:taxi_driver/components/ExtraChargesWidget.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/model/CurrentRequestModel.dart';
import 'package:taxi_driver/model/ExtraChargeRequestModel.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/screens/ChatScreen.dart';
// import 'package:taxi_driver/screens/DetailScreen.dart';
import 'package:taxi_driver/screens/FlightTrackingPage.dart';
import 'package:taxi_driver/screens/ReviewScreen.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/extension.dart';
import 'package:taxi_driver/utils/Extensions/int_extensions.dart';
import 'package:taxi_driver/utils/Images.dart';
import 'package:url_launcher/url_launcher.dart';
import 'DetailScreen.dart';

class ScheduleRideListScreen extends StatefulWidget {
  final String? status;

  ScheduleRideListScreen({super.key, this.status});

  @override
  State<ScheduleRideListScreen> createState() => _ScheduleRideListScreenState();
}

class _ScheduleRideListScreenState extends State<ScheduleRideListScreen> {
  List<OnRideRequest> schedule_ride_request = [];
  LatLng? driverLocation;
  // List<ExtraChargeRequestModel> extraChargeList = [];
  // StreamController _messageController = StreamController.broadcast();
  late BitmapDescriptor driverIcon;
  late BitmapDescriptor destinationIcon;
  late BitmapDescriptor sourceIcon;
  // num extraChargeAmount = 0;
  final otpController = TextEditingController();
  String endLocationAddress = '';
  String? otpCheck;
  RideService rideService = RideService();
  bool paymentPressed = false;
  var extra_charges_map = {};

  @override
  void initState() {
    super.initState();
    init();
  }

  getCurrentRequest({OnRideRequest? servicesListData}) async {
    appStore.setLoading(true);
    await getCurrentRideRequest().then((value) {
      appStore.setLoading(false);
      schedule_ride_request = widget.status == language.rides ? value.schedule_ride_request ?? [] : value.schedule_orders ?? [];
      // if (servicesListData?.paymentStatus == "pending") {
      //   if (/*value.payment != null && */ servicesListData?.paymentStatus == PENDING) {
      //     // launchScreen(context, DetailScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      //   } else {
      //     launchScreen(context, DashboardScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      //   }
      // }
      setState(() {});
    }).catchError((error, stack) {
      appStore.setLoading(false);
    });
  }

  void init() async {
    if (sharedPref.getDouble(LATITUDE) != null && sharedPref.getDouble(LONGITUDE) != null) {
      driverLocation = LatLng(sharedPref.getDouble(LATITUDE)!, sharedPref.getDouble(LONGITUDE)!);
    }
    await checkPermission();
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });

    getCurrentRequest();
  }

  // Show map dialog with route from pickup to drop location
  void showRouteMapDialog(OnRideRequest ride) {
    if (ride.startLatitude == null || ride.startLongitude == null ||
        ride.endLatitude == null || ride.endLongitude == null) {
      toast('Location coordinates not available');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Route Map', style: boldTextStyle(color: Colors.white, size: 18)),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RouteMapWidget(
                    startLat: double.parse(ride.startLatitude.toString()),
                    startLng: double.parse(ride.startLongitude.toString()),
                    endLat: double.parse(ride.endLatitude.toString()),
                    endLng: double.parse(ride.endLongitude.toString()),
                    startAddress: ride.startAddress ?? 'Pickup',
                    endAddress: ride.endAddress ?? 'Drop-off',
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 12),
                          SizedBox(width: 8),
                          Expanded(child: Text(ride.startAddress ?? 'Pickup Location', style: primaryTextStyle(size: 12), maxLines: 2)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.red, size: 12),
                          SizedBox(width: 8),
                          Expanded(child: Text(ride.endAddress ?? 'Drop-off Location', style: primaryTextStyle(size: 12), maxLines: 2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> rideRequest({OnRideRequest? servicesListData, String? status}) async {
    appStore.setLoading(true);
    Map req = {
      "id": servicesListData!.id,
      "status": status,
    };
    await rideRequestUpdate(request: req, rideId: servicesListData.id).then((value) async {
      appStore.setLoading(false);

      // Update Firebase with status to notify user app
      rideService.updateStatusOfRide(rideID: servicesListData.id, req: {
        'status': status,
        'on_rider_stream_api_call': 0,
      });

      getCurrentRequest().then((value) async {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> completeRideRequest(OnRideRequest? servicesListData) async {
    appStore.setLoading(true);
    Map req = {
      "id": servicesListData?.id,
      "service_id": servicesListData?.serviceId,
      "end_latitude": driverLocation?.latitude,
      "end_longitude": driverLocation?.longitude,
      "end_address": endLocationAddress,
      "start_latitude": servicesListData?.startLatitude,
      "start_longitude": servicesListData?.startLongitude,
      // "distance": totalDistance,
      // if (extraChargeList.isNotEmpty) "extra_charges": extraChargeList,
      // if (extraChargeList.isNotEmpty) "extra_charges_amount": extraChargeAmount,
    };
    if (extra_charges_map['${servicesListData?.id}'] != null && extra_charges_map['${servicesListData?.id}'].isNotEmpty) {
      req['extra_charges'] = extra_charges_map['${servicesListData?.id}']['charge_details'];
      req['extra_charges_amount'] = extra_charges_map['${servicesListData?.id}']['total_charge'];
    }
    await completeRide(request: req).then((value) async {
      chatMessageService.exportChat(rideId: servicesListData?.id.toString() ?? "", senderId: sharedPref.getString(UID).validate(), receiverId: servicesListData?.riderId.toString() ?? '');
      try {
        await rideService.updateStatusOfRide(rideID: servicesListData?.id, req: {'on_rider_stream_api_call': 0});
      } catch (e) {}
      sourceIcon = await getResizedMarker(SourceIcon);
      appStore.setLoading(false);
      getCurrentRequest(servicesListData: servicesListData);
    }).catchError((error) {
      if (servicesListData != null) {
        chatMessageService.exportChat(rideId: servicesListData.id.toString(), senderId: sharedPref.getString(UID).validate(), receiverId: servicesListData.riderId.toString());
      }
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> getUserLocation() async {
    Position b = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    driverLocation = LatLng(b.latitude, b.longitude);
    // driverLocation = LatLng(event.latitude, event.longitude);
    List<Placemark> placemarks = await placemarkFromCoordinates(driverLocation?.latitude ?? 0.0, driverLocation?.longitude ?? 0.0);
    Placemark place = placemarks[0];
    endLocationAddress = '${place.street},${place.subLocality},${place.thoroughfare},${place.locality}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                  child: RefreshIndicator(
                onRefresh: () async {
                  init();
                },
                child: ListView.builder(
                  itemCount: schedule_ride_request.length,
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () {
                        // if (schedule_ride_request[i].type == TRANSPORT) {
                        //   // launchScreen(context, OrderDetailScheduleScreen(orderData: schedule_ride_request[i]), pageRouteAnimation: PageRouteAnimation.Slide);
                        // }
                      },
                      child: Container(
                        width: context.width(),
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: primaryColor),
                          borderRadius: BorderRadius.circular(defaultRadius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${language.rideId}: ${schedule_ride_request[i].id}",
                                            style: primaryTextStyle(size: 12, weight: FontWeight.bold),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)),
                                            child: Text(
                                              "${statusName(status: schedule_ride_request[i].status.toString())}",
                                              style: primaryTextStyle(size: 12, weight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      5.height,
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(defaultRadius),
                                            child: commonCachedNetworkImage(schedule_ride_request[i].riderProfileImage, height: 38, width: 38, fit: BoxFit.cover),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${schedule_ride_request[i].riderName.capitalizeFirstLetter()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)),
                                                // Email hidden per client request
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
                                                    content: AlertScreen(rideId: schedule_ride_request[i].id, regionId: schedule_ride_request[i].regionId),
                                                  );
                                                },
                                              );
                                            },
                                            child: chatCallWidget(Icons.sos),
                                          ),
                                          SizedBox(width: 8),
                                          inkWellWidget(
                                            onTap: () {
                                              launchUrl(Uri.parse('tel:${schedule_ride_request[i].riderContactNumber}'), mode: LaunchMode.externalApplication);
                                            },
                                            child: chatCallWidget(Icons.call),
                                          ),
                                          SizedBox(width: 8),
                                          inkWellWidget(
                                            onTap: () {
                                              if (schedule_ride_request[i].riderId != null) {
                                                getUserDetail(userId: schedule_ride_request[i].riderId).then(
                                                  (value) {
                                                    launchScreen(context, ChatScreen(userData: value.data, ride_id: schedule_ride_request[i].id!), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                                  },
                                                );
                                              }
                                            },
                                            child: chatCallWidget(
                                              Icons.chat_bubble_outline,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          // Navigation button to open Google Maps with route
                                          inkWellWidget(
                                            onTap: () {
                                              if (schedule_ride_request[i].startLatitude != null &&
                                                  schedule_ride_request[i].startLongitude != null &&
                                                  schedule_ride_request[i].endLatitude != null &&
                                                  schedule_ride_request[i].endLongitude != null) {
                                                openMap(
                                                  double.parse(schedule_ride_request[i].startLatitude.toString()),
                                                  double.parse(schedule_ride_request[i].startLongitude.toString()),
                                                  double.parse(schedule_ride_request[i].endLatitude.toString()),
                                                  double.parse(schedule_ride_request[i].endLongitude.toString()),
                                                );
                                              }
                                            },
                                            child: chatCallWidget(Icons.navigation_outlined),
                                          ),
                                          if (appStore.flightTracking == "1" && schedule_ride_request[i].trip_type.toString().toLowerCase().contains('airport')) SizedBox(width: 8),
                                          if (appStore.flightTracking == "1" && schedule_ride_request[i].trip_type.toString().toLowerCase().contains('airport'))
                                            inkWellWidget(
                                              onTap: () {
                                                showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (context) {
                                                    return Theme(
                                                      data: Theme.of(context).copyWith(
                                                        dialogTheme: DialogThemeData(shape: dialogShape()),
                                                        dialogBackgroundColor: Colors.white, // Optional
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
                                                            _detailRow('${language.flightNumber}', "${schedule_ride_request[i].flight_number}").visible(!(schedule_ride_request[i].flight_number.isEmptyOrNull)),
                                                            _detailRow('${language.terminalAddress}', "${schedule_ride_request[i].pickup_point}").visible(!(schedule_ride_request[i].pickup_point.isEmptyOrNull)),
                                                            _detailRow('${language.preferredPickupTime}', "${schedule_ride_request[i].preferred_pickup_time}").visible(!(schedule_ride_request[i].preferred_pickup_time.isEmptyOrNull)),
                                                            _detailRow('${language.preferredDropTime}', "${schedule_ride_request[i].preferred_dropoff_time}").visible(!(schedule_ride_request[i].preferred_dropoff_time.isEmptyOrNull)),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(context).pop(),
                                                            child: Text('${language.cancel}'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              launchScreen(context, FlightTrackingScreen(flightNumber: schedule_ride_request[i].flight_number ?? ''), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: false);
                                                            },
                                                            child: Text('${language.track}'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: chatCallWidget(
                                                Icons.flight,
                                              ),
                                            ),
                                        ],
                                      ),
                                      // 5.height,
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: 8,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                                color: secondaryColor,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    offset: Offset(2, 2),
                                                    blurRadius: 1,
                                                  ),
                                                ],
                                                borderRadius: BorderRadius.circular(defaultRadius)),
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.schedule,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(
                                                  width: 2,
                                                ),
                                                Text(
                                                  "${language.schedule_at}: ${DateFormat('dd MMM yyyy hh:mm a').format(DateTime.parse(schedule_ride_request[i].schedule_datetime.toString() + "Z").toLocal())}",
                                                  style: boldTextStyle(size: 12, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 8,
                                          ),
                                          Row(
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "${language.paymentDetails} :",
                                                    style: primaryTextStyle(size: 12, weight: FontWeight.bold, color: Colors.black),
                                                  ),
                                                  Text(
                                                    " ${schedule_ride_request[i].paymentStatus.toString().toUpperCase()}",
                                                    style: primaryTextStyle(size: 12, weight: FontWeight.bold, color: schedule_ride_request[i].paymentStatus == PAYMENT_PAID ? Colors.green : Colors.red /* Colors.white*/),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: schedule_ride_request[i].type == TRANSPORT
                                    ? [
                                        buildInfoTile(
                                          icon: Icons.wallet,
                                          title_widget: printAmountWidget(amount: schedule_ride_request[i].totalAmount!.toStringAsFixed(digitAfterDecimal), size: 14),
                                          subtitle: "${language.estAmount}",
                                        ),
                                        buildInfoTile(
                                          icon: Icons.route_outlined,
                                          title: "${schedule_ride_request[i].dropoff_distance_in_km?.toStringAsFixed(2)} ${schedule_ride_request[i].distanceUnit}",
                                          subtitle: "${language.distance}",
                                        ),
                                        buildInfoTile(
                                          icon: Icons.scale_outlined,
                                          title: "${schedule_ride_request[i].weight}",
                                          subtitle: "${language.weight}",
                                        ),
                                        buildInfoTile(
                                          icon: Icons.inventory_2_outlined,
                                          title: schedule_ride_request[i].parcelDescription.toString(),
                                          subtitle: "${language.parcel_type}",
                                        ),
                                      ]
                                    : [
                                        buildInfoTile(
                                          icon: Icons.wallet,
                                          title_widget: printAmountWidget(amount: schedule_ride_request[i].totalAmount!.toStringAsFixed(digitAfterDecimal), size: 14),
                                          subtitle: "${language.estAmount}",
                                        ),
                                        buildInfoTile(
                                          icon: Icons.route_outlined,
                                          title: "${schedule_ride_request[i].dropoff_distance_in_km?.toStringAsFixed(2)} ${schedule_ride_request[i].distanceUnit}",
                                          subtitle: "${language.distance}",
                                        ),
                                      ],
                              ),
                            ),
                            Divider(),
                            Column(
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
                                        if (!schedule_ride_request[i].pickupPersonName.isEmptyOrNull)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${schedule_ride_request[i].pickupPersonName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)).expand(),
                                              if (!schedule_ride_request[i].pickupContactNumber.isEmptyOrNull)
                                                GestureDetector(
                                                    onTap: () {
                                                      launchUrl(Uri.parse('tel:${schedule_ride_request[i].pickupContactNumber}'), mode: LaunchMode.externalApplication);
                                                    },
                                                    child: chatCallWidget(Icons.call)),
                                            ],
                                          ),
                                        Text(schedule_ride_request[i].startAddress.validate(), style: primaryTextStyle(size: 14), maxLines: 2),
                                        if (!schedule_ride_request[i].pickupDescription.isEmptyOrNull) Text('${language.note}: ${schedule_ride_request[i].pickupDescription}', maxLines: 3, overflow: TextOverflow.ellipsis, style: secondaryTextStyle(size: 14)),
                                      ],
                                    )),
                                  ],
                                ),
                                Row(
                                  children: [
                                    SizedBox(width: 8),
                                    SizedBox(
                                      height: 12,
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
                                        if (!schedule_ride_request[i].deliveryPersonName.isEmptyOrNull)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${schedule_ride_request[i].deliveryPersonName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)).expand(),
                                              if (!schedule_ride_request[i].deliveryContactNumber.isEmptyOrNull)
                                                GestureDetector(
                                                    onTap: () {
                                                      launchUrl(Uri.parse('tel:${schedule_ride_request[i].deliveryContactNumber}'), mode: LaunchMode.externalApplication);
                                                    },
                                                    child: chatCallWidget(Icons.call)),
                                            ],
                                          ),
                                        Text(schedule_ride_request[i].endAddress.validate(), style: primaryTextStyle(size: 14), maxLines: 2),
                                        if (!schedule_ride_request[i].deliveryDescription.isEmptyOrNull) Text('${language.note}: ${schedule_ride_request[i].deliveryDescription}', maxLines: 3, overflow: TextOverflow.ellipsis, style: secondaryTextStyle(size: 14)),
                                      ],
                                    )),
                                  ],
                                ),
                                // View Route button
                                SizedBox(height: 12),
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      showRouteMapDialog(schedule_ride_request[i]);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: primaryColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.map_outlined, color: primaryColor, size: 18),
                                          SizedBox(width: 8),
                                          Text('View Route on Map', style: boldTextStyle(size: 12, color: primaryColor)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (schedule_ride_request[i].multiDropLocation != null && schedule_ride_request[i].multiDropLocation!.isNotEmpty)
                                  Row(
                                    children: [
                                      SizedBox(width: 8),
                                      SizedBox(
                                        height: 12,
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
                                // Extra booking options display
                                _buildExtrasWidget(schedule_ride_request[i]),
                                if (schedule_ride_request[i].multiDropLocation != null && schedule_ride_request[i].multiDropLocation!.isNotEmpty)
                                  AppButtonWidget(
                                    textColor: primaryColor,
                                    color: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                                      showOnlyDropLocationsRiderDialog(context, schedule_ride_request[i].multiDropLocation!.map((e) => e.address).whereType<String>().toList());
                                    },
                                  ),
                                5.height,
                                buttonWidget(schedule_ride_request[i]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )),
            ],
          ),
          Observer(builder: (context) {
            if (!appStore.isLoading && schedule_ride_request.isEmpty) {
              return emptyWidget();
            }
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          }),
        ],
      ),
    );
  }

  Future<void> cancelRequest(String reason, {int? ride_id}) async {
    Map req = {
      "id": ride_id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    appStore.setLoading(true);
    await rideRequestUpdate(request: req, rideId: ride_id).then((value) async {
      appStore.setLoading(false);
      toast(value.message);
      schedule_ride_request.removeWhere(
        (element) => element.id == ride_id,
      );
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
    });
  }

  Widget buttonWidget(OnRideRequest? servicesListData) {
    return Row(
      children: [
        // Cancel button replaced with contact admin message per client request
        if (servicesListData?.status != IN_PROGRESS && servicesListData?.status != COMPLETED)
          Expanded(
            flex: 0,
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: AppButtonWidget(
                  text: language.cancel,
                  textColor: Colors.grey,
                  color: Colors.white,
                  shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: Colors.grey)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Cannot Cancel', style: boldTextStyle()),
                          content: Text('Please contact administrator to cancel this ride.', style: primaryTextStyle()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK', style: boldTextStyle(color: primaryColor)),
                            ),
                          ],
                        );
                      },
                    );
                  }),
            ),
          ),
        // Apply Extra Fees button removed - only admin can add extra fees
        if (servicesListData!.status != COMPLETED)
          Expanded(
            flex: 1,
            child: AppButtonWidget(
              text: buttonText(status: servicesListData.status),
              color: primaryColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ImageIcon(
                    AssetImage(statusTypeIconForButton(type: servicesListData.status == IN_PROGRESS ? ARRIVED : servicesListData.status.validate())),
                    color: Colors.white,
                    size: 18,
                  ),
                  4.width,
                  Text(
                      // Only show "Collect Amount" for CASH payments that haven't been paid
                      servicesListData.status == ARRIVED && servicesListData.type == TRANSPORT && servicesListData.paymentType == CASH && servicesListData.paymentStatus != PAYMENT_PAID
                          ? "${language.collectAmount}"
                          : servicesListData.status == ARRIVED && servicesListData.type == TRANSPORT
                              ? "${language.collectOrder}"
                              : servicesListData.status == IN_PROGRESS && servicesListData.type == TRANSPORT
                                  ? "${language.completeDelivery}"
                                  : servicesListData.status == IN_PROGRESS && servicesListData.multiDropLocation != null && servicesListData.multiDropLocation!.isNotEmpty && servicesListData.multiDropLocation!.where((element) => element.droppedAt == null).length > 1
                                      ? language.updateDrop
                                      : servicesListData.type == TRANSPORT
                                          ? buttonTransportText(status: servicesListData.status, paymentStatus: servicesListData.paymentStatus, paymentType: servicesListData.paymentType)
                                          : buttonText(status: servicesListData.status, paymentStatus: servicesListData.paymentStatus, paymentType: servicesListData.paymentType),
                      style: boldTextStyle(color: Colors.white)),
                ],
              ),
              textStyle: boldTextStyle(color: Colors.white),
              onTap: () async {
                DateTime date1 = DateTime.parse(servicesListData.schedule_datetime.toString() + "Z").toLocal();
                DateTime date2 = DateTime.now();
                Duration diff = date1.difference(date2);
                if (diff.inMinutes <= 60) {
                  if (await checkPermission()) {
                    // Only show payment collection dialog for CASH payments
                    if (servicesListData.status == ARRIVED && servicesListData.type == TRANSPORT && servicesListData.paymentType == CASH && servicesListData.paymentStatus != PAYMENT_PAID) {
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
                                      "rider_id": servicesListData.riderId,
                                      "ride_request_id": servicesListData.id,
                                      "datetime": DateTime.now().toString(),
                                      "total_amount": servicesListData.totalAmount,
                                      "payment_type": "cash",
                                      "txn_id": "",
                                      "payment_status": PAYMENT_PAID,
                                      "transaction_detail": ""
                                    };
                                    await savePayment(req).then((value) async {
                                      appStore.setLoading(false);
                                      getCurrentRequest();
                                    }).catchError((error) {
                                      appStore.setLoading(false);
                                      log(error.toString());
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        },
                      );
                    } else if (servicesListData.status == ACCEPTED || servicesListData.status == 'assign_driver') {
                      // First mark as ARRIVED, then user can start ride
                      rideRequest(servicesListData: servicesListData, status: ARRIVED);
                    } else if (servicesListData.status == ARRIVED) {
                      // Now start the ride (change to IN_PROGRESS)
                      if (servicesListData.paymentStatus == 'pending' && servicesListData.paymentType == 'cash' && servicesListData.type == TRANSPORT) {
                        appStore.setLoading(true);
                        Map req = {"rider_id": servicesListData.riderId, "ride_request_id": servicesListData.id, "datetime": DateTime.now().toString(), "total_amount": servicesListData.totalAmount, "payment_type": "cash", "txn_id": "", "payment_status": PAYMENT_PAID, "transaction_detail": ""};
                        await savePayment(req).then((value) async {
                          appStore.setLoading(false);
                          servicesListData.paymentStatus = PAYMENT_PAID;
                          setState(() {});
                        }).catchError((error) {
                          appStore.setLoading(false);
                          log(error.toString());
                        });
                      } else {
                        rideRequest(servicesListData: servicesListData, status: IN_PROGRESS);
                      }
                    } else if (servicesListData.status == IN_PROGRESS) {
                      // check is all drop location passed
                      if (servicesListData.multiDropLocation != null && servicesListData.multiDropLocation!.isNotEmpty && servicesListData.multiDropLocation!.where((element) => element.droppedAt == null).length > 1) {
                        for (int i = 0; i < servicesListData.multiDropLocation!.length; i++) {
                          if (servicesListData.multiDropLocation![i].droppedAt == null) {
                            await dropOupUpdate(rideId: '${servicesListData.id}', dropIndex: '${servicesListData.multiDropLocation![i].drop}').then(
                              (v) {
                                servicesListData.multiDropLocation![i].droppedAt = DateTime.now().toString();
                                if (v != null && v['message'] != null) {
                                  toast(v['message'].toString());
                                }
                              },
                            );
                            getCurrentRequest(servicesListData: servicesListData);
                            break;
                          }
                        }
                        // setMapPins();
                      } else {
                        showConfirmDialogCustom(primaryColor: primaryColor, dialogType: DialogType.ACCEPT, title: language.finishMsg, context, positiveText: language.yes, negativeText: language.no, onAccept: (v) {
                          appStore.setLoading(true);
                          getUserLocation().then((value2) async {
                            await completeRideRequest(servicesListData);
                          });
                        });
                      }
                    } else if (servicesListData.status == COMPLETED && servicesListData.paymentStatus != PAYMENT_PAID) {
                      if (servicesListData.paymentType == CASH) {
                        showConfirmDialogCustom(primaryColor: primaryColor, positiveText: language.yes, negativeText: language.no, dialogType: DialogType.CONFIRMATION, title: language.areYouSureCollectThisPayment, context, onAccept: (v) async {
                          if (paymentPressed == true) return;
                          paymentPressed = true;
                          appStore.setLoading(true);
                          Map req = {
                            "id": servicesListData.paymentId,
                            "rider_id": servicesListData.riderId,
                            "ride_request_id": servicesListData.id,
                            "datetime": DateTime.now().toString(),
                            "total_amount": servicesListData.totalAmount,
                            "payment_type": servicesListData.paymentType,
                            "txn_id": "",
                            "payment_status": PAYMENT_PAID,
                            "transaction_detail": ""
                          };
                          await savePayment(req).then((value) async {
                            appStore.setLoading(false);
                            getCurrentRequest();
                            showDialog(
                              context: context,
                              builder: (context) => Wrap(
                                alignment: WrapAlignment.center,
                                runAlignment: WrapAlignment.center,
                                children: [
                                  Container(
                                      width: context.width(),
                                      margin: EdgeInsets.symmetric(horizontal: 40),
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(defaultRadius),
                                        boxShadow: [
                                          BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 0, offset: Offset(0.0, 0.0)),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Lottie.asset(paymentSuccessful, width: 120, height: 120, fit: BoxFit.contain),
                                          Text(
                                            "${language.paymentSuccess}",
                                            style: boldTextStyle(color: Colors.green, size: 24),
                                          )
                                        ],
                                      )),
                                ],
                              ),
                            );
                            Future.delayed(
                              Duration(seconds: 3),
                              () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                            );
                          }).catchError((error) {
                            appStore.setLoading(false);
                            log(error.toString());
                          });
                        });
                      } else {
                        toast(language.waitingForDriverConformation);
                      }
                    }
                  }
                } else {
                  return toast("You can update the ride status only on the scheduled time.");
                }
              },
            ),
          ),
        // Only show "Cash Collected" button for CASH payments that haven't been paid
        // For online payments (PayPal, Stripe, etc.), payment is already done at booking
        if (servicesListData.status == COMPLETED && servicesListData.paymentType == CASH && servicesListData.paymentStatus != PAYMENT_PAID)
          Expanded(
            child: AppButtonWidget(
                text: servicesListData.isDriverRated == 1
                    ? language.cashCollected
                    : appStore.isShowRiderReview == '1'
                        ? "${language.addReviews}"
                        : language.cashCollected,
                textColor: primaryColor,
                color: Colors.white,
                shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
                onTap: () async {
                  if (servicesListData.isDriverRated == 0 && appStore.isShowRiderReview == '1') {
                    await launchScreen(
                      getContext,
                      ReviewScreen(
                        schedule_ride: true,
                        rideId: servicesListData.id!,
                        currentData: CurrentRequestModel(
                          rider: UserData(
                            profileImage: servicesListData.riderProfileImage,
                            firstName: servicesListData.riderName,
                            email: servicesListData.riderEmail,
                          ),
                        ),
                      ),
                      pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
                    );
                    init();
                    return;
                  } else {
                    if (servicesListData.isDriverRated == 0 && appStore.isShowRiderReview == '0') {
                      appStore.setLoading(true);
                      Map req = {
                        "ride_request_id": servicesListData.id!,
                        "rating": 0,
                        "comment": '',
                      };
                      await ratingReview(request: req).then((value2) async {
                        appStore.setLoading(false);
                      }).catchError((error, s) {
                        appStore.setLoading(false);
                      });
                    }
                    launchScreen(getContext, DetailScreen(rideId: servicesListData.id), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                    return;
                  }
                }),
          ),
      ],
    );
  }

  Widget _buildExtrasWidget(OnRideRequest ride) {
    List<Widget> extras = [];

    if (ride.tripProtection == 1) {
      extras.add(_buildExtraItem('Trip Protection', ride.tripProtectionPrice));
    }
    if (ride.meetAndGreet == 1) {
      String meetGreetInfo = 'Meet & Greet';
      if (ride.meetGreetName != null && ride.meetGreetName!.isNotEmpty) {
        meetGreetInfo += ': ${ride.meetGreetName}';
      }
      extras.add(_buildExtraItem(meetGreetInfo, ride.meetAndGreetPrice));
    }
    if (ride.travelingWithPet == 1) {
      extras.add(_buildExtraItem('Traveling with Pet', ride.travelingWithPetPrice));
    }
    if (ride.childSeat == 1) {
      String seatInfo = 'Child Seat';
      List<String> seatDetails = [];
      if ((ride.boosterSeatCount ?? 0) > 0) seatDetails.add('${ride.boosterSeatCount} Booster');
      if ((ride.rearFacingInfantSeatCount ?? 0) > 0) seatDetails.add('${ride.rearFacingInfantSeatCount} Infant');
      if ((ride.forwardFacingToddlerSeatCount ?? 0) > 0) seatDetails.add('${ride.forwardFacingToddlerSeatCount} Toddler');
      if (seatDetails.isNotEmpty) seatInfo += ' (${seatDetails.join(', ')})';
      extras.add(_buildExtraItem(seatInfo, ride.childSeatPrice));
    }

    if (extras.isEmpty) return SizedBox();

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Extras:', style: boldTextStyle(size: 12, color: Colors.blue)),
          SizedBox(height: 4),
          ...extras,
          if (ride.extrasAmount != null && ride.extrasAmount! > 0)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Extras Total:', style: boldTextStyle(size: 12)),
                  Text('\$${ride.extrasAmount!.toStringAsFixed(2)}', style: boldTextStyle(size: 12, color: Colors.green)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExtraItem(String title, num? price) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green),
          SizedBox(width: 4),
          Expanded(child: Text(title, style: primaryTextStyle(size: 11))),
          if (price != null) Text('+\$${price.toStringAsFixed(0)}', style: secondaryTextStyle(size: 11, color: Colors.green)),
        ],
      ),
    );
  }

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
}

// Widget to display route map with polyline
class RouteMapWidget extends StatefulWidget {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String startAddress;
  final String endAddress;

  const RouteMapWidget({
    Key? key,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.startAddress,
    required this.endAddress,
  }) : super(key: key);

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupMap();
  }

  Future<void> _setupMap() async {
    // Add markers for pickup and drop-off
    markers.add(
      Marker(
        markerId: MarkerId('pickup'),
        position: LatLng(widget.startLat, widget.startLng),
        infoWindow: InfoWindow(title: 'Pickup', snippet: widget.startAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    markers.add(
      Marker(
        markerId: MarkerId('dropoff'),
        position: LatLng(widget.endLat, widget.endLng),
        infoWindow: InfoWindow(title: 'Drop-off', snippet: widget.endAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Get polyline route
    await _getPolyline();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getPolyline() async {
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: GOOGLE_MAP_API_KEY,
        request: PolylineRequest(
          origin: PointLatLng(widget.startLat, widget.startLng),
          destination: PointLatLng(widget.endLat, widget.endLng),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            color: primaryColor,
            points: polylineCoordinates,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
    } catch (e) {
      print('Error getting polyline: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng centerPoint = LatLng(
      (widget.startLat + widget.endLat) / 2,
      (widget.startLng + widget.endLng) / 2,
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: centerPoint,
            zoom: 12,
          ),
          markers: markers,
          polylines: polylines,
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
            // Fit bounds to show both markers
            _fitBounds();
          },
          myLocationEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        ),
        if (isLoading)
          Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
      ],
    );
  }

  void _fitBounds() {
    if (mapController == null) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        widget.startLat < widget.endLat ? widget.startLat : widget.endLat,
        widget.startLng < widget.endLng ? widget.startLng : widget.endLng,
      ),
      northeast: LatLng(
        widget.startLat > widget.endLat ? widget.startLat : widget.endLat,
        widget.startLng > widget.endLng ? widget.startLng : widget.endLng,
      ),
    );

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }
}
