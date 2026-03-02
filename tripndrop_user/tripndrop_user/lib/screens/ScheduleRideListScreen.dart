import 'dart:async';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:taxi_booking/components/CancelOrderDialog.dart';
import 'package:taxi_booking/main.dart';
import 'package:taxi_booking/model/CurrentRequestModel.dart';
import 'package:taxi_booking/model/ExtraChargeRequestModel.dart';
import 'package:taxi_booking/network/RestApis.dart';
import 'package:taxi_booking/screens/ChatScreen.dart';
import 'package:taxi_booking/utils/Colors.dart';
import 'package:taxi_booking/utils/Common.dart';
import 'package:taxi_booking/utils/Constants.dart';
import 'package:taxi_booking/utils/Extensions/ResponsiveWidget.dart';
import 'package:taxi_booking/utils/Extensions/context_extension.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_booking/utils/Extensions/int_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/RideService.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import 'AlertScreen.dart';
import 'ReviewScreen.dart';
import 'RidePaymentDetailScreen.dart';

class ScheduleRideListScreen extends StatefulWidget {
  final String? status;

  ScheduleRideListScreen({super.key, this.status});

  @override
  State<ScheduleRideListScreen> createState() => _ScheduleRideListScreenState();
}

class _ScheduleRideListScreenState extends State<ScheduleRideListScreen> {
  List<OnRideRequest> schedule_ride_request = [];
  List<ExtraChargeRequestModel> extraChargeList = [];
  late BitmapDescriptor driverIcon;
  late BitmapDescriptor destinationIcon;
  late BitmapDescriptor sourceIcon;
  num extraChargeAmount = 0;
  final otpController = TextEditingController();
  String endLocationAddress = '';
  double totalDistance = 0.0;
  String? otpCheck;
  RideService rideService = RideService();
  bool paymentPressed = false;

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
      setState(() {});
    }).catchError((error, stack) {
      appStore.setLoading(false);
    });
  }

  void init() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child:
                RefreshIndicator(
                  onRefresh: () async{
                    init();
                  },
                  child: ListView.builder(
                    itemCount: schedule_ride_request.length,
                    itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () {
                        // Show route map when tapping on the ride card
                        showRouteMapDialog(schedule_ride_request[i]);
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
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${language.rideId}: ${schedule_ride_request[i].id}",
                                                style: primaryTextStyle(size: 12, weight: FontWeight.bold),
                                              ),
                                              if (sharedPref.getString(OTP_STATUS).validate() == '1' && schedule_ride_request[i].otp != null)
                                                Text(
                                                  "${language.otp}: ${schedule_ride_request[i].otp}",
                                                  style: secondaryTextStyle(size: 12, weight: FontWeight.bold),
                                                ),
                                            ],
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)),
                                            child: Text(
                                              "${transPortStatusName(status: schedule_ride_request[i].status.toString())}",
                                              style: primaryTextStyle(size: 12, weight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      5.height,
                                      if (schedule_ride_request[i].driverId != null)
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(defaultRadius),
                                              child: commonCachedNetworkImage(schedule_ride_request[i].driverProfileImage, height: 38, width: 38, fit: BoxFit.cover),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('${schedule_ride_request[i].driverName!.capitalizeFirstLetter()}',
                                                      maxLines: 1, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: 14)),
                                                  SizedBox(height: 4),
                                                  Text('${schedule_ride_request[i].driverEmail.validate()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: secondaryTextStyle()),
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
                                                launchUrl(Uri.parse('tel:${schedule_ride_request[i].driverContactNumber}'), mode: LaunchMode.externalApplication);
                                              },
                                              child: chatCallWidget(Icons.call),
                                            ),
                                            SizedBox(width: 8),
                                            if (schedule_ride_request[i].driverId != null)
                                              inkWellWidget(
                                                onTap: () {
                                                  if (schedule_ride_request[i].driverId != null) {
                                                    getUserDetail(userId: schedule_ride_request[i].driverId).then(
                                                          (value) {
                                                        launchScreen(context, ChatScreen(userData: value.data, ride_id: schedule_ride_request[i].id!),
                                                            pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                                      },
                                                    );
                                                  }
                                                },
                                                child: chatCallWidget(
                                                  Icons.chat_bubble_outline,
                                                ),
                                              ),
                                          ],
                                        ),
                                      // 5.height,
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 8,),
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
                                                borderRadius: BorderRadius.circular(defaultRadius)
                                            ),
                                            padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.schedule,size: 12,color: Colors.white,),
                                                SizedBox(width: 2,),
                                                Text(
                                                  "${language.schedule_at}: ${DateFormat('dd MMM yyyy hh:mm a').format(DateTime.parse(schedule_ride_request[i].schedule_datetime.toString() + "Z").toLocal())}",
                                                  style: boldTextStyle(size: 12,color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 8,),
                                          Row(
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "${language.paymentDetails} :",
                                                    style: primaryTextStyle(
                                                        size: 12, weight: FontWeight.bold, color: Colors.black),
                                                  ),
                                                  Text(
                                                    " ${schedule_ride_request[i].paymentStatus.toString().toUpperCase()}",
                                                    style: primaryTextStyle(
                                                        size: 12, weight: FontWeight.bold, color: schedule_ride_request[i].paymentStatus == PAID ? Colors.green : Colors.red /* Colors.white*/),
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
                                            if (!schedule_ride_request[i].pickupDescription.isEmptyOrNull)
                                              Text('${language.note}: ${schedule_ride_request[i].pickupDescription}',
                                                  maxLines: 3, overflow: TextOverflow.ellipsis, style: secondaryTextStyle(size: 14)),
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
                                            if (!schedule_ride_request[i].deliveryDescription.isEmptyOrNull)
                                              Text('${language.note}: ${schedule_ride_request[i].deliveryDescription}',
                                                  maxLines: 3, overflow: TextOverflow.ellipsis, style: secondaryTextStyle(size: 14)),
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
                  },),
                ),
              ),
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
        if (servicesListData?.status != IN_PROGRESS && /*servicesListData != ACCEPTED ||*/ servicesListData?.status != COMPLETED)
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
                                await cancelRequest(reason, ride_id: servicesListData!.id);
                                appStore.setLoading(false);
                              });
                        });
                  }),
            ),
          ),
        if (servicesListData?.status == COMPLETED && servicesListData?.paymentStatus != PAID)
          Expanded(
            child:AppButtonWidget(
                text:servicesListData!.isRiderRated == 1?
           (servicesListData.paymentType == ONLINE || servicesListData.paymentType == WALLET)?
                language.payToPayment:language.waitingForDriverConformation:"${language.addReviews}",
                textColor: primaryColor,
                color: Colors.white,
                shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
                onTap: () async {
                  if(servicesListData.isRiderRated==0){
                    await launchScreen(getContext, ReviewScreen(rideRequest: servicesListData, driverData: Driver(
                      id: servicesListData.driverId,
                      firstName: servicesListData.driverName,
                      displayName: servicesListData.driverName,
                      profileImage: servicesListData.driverProfileImage,
                      email: servicesListData.driverEmail,
                    )), pageRouteAnimation: PageRouteAnimation.SlideBottomTop,);
                    init();
                    return;
                  }else{
                    launchScreen(getContext, RidePaymentDetailScreen(rideId: servicesListData.id,schedule_flow:true), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                    return;
                  }
                }),
          ),
      ],
    );
  }

  Future<void> savePaymentApi({
    required String paymentID,
    required String riderId,
    required String rideRequestId,
    required String totalAmount,
  }) async {
    if (paymentPressed == true) return;
    paymentPressed = true;
    appStore.setLoading(true);
    Map req = {
      "id": paymentID,
      "rider_id": riderId,
      "ride_request_id": rideRequestId,
      "datetime": DateTime.now().toString(),
      "total_amount": totalAmount,
      "payment_type": WALLET,
      "txn_id": "",
      "payment_status": PAID,
      "transaction_detail": ""
    };
    await savePayment(req).then((value) async {
      appStore.setLoading(false);
      init();
      paymentPressed = false;
    }).catchError((error) {
      paymentPressed = false;
      setState(() {});
      appStore.setLoading(false);
      log(error.toString());
      toast(error.toString());
    });
  }

  Future<void> saveOnlinePaymentApi({
    required String paymentID,
    required String riderId,
    required String rideRequestId,
    required String totalAmount,
  }) async {
    if (paymentPressed == true) return;
    paymentPressed = true;
    appStore.setLoading(true);
    Map req = {
      "id": paymentID,
      "rider_id": riderId,
      "ride_request_id": rideRequestId,
      "datetime": DateTime.now().toString(),
      "total_amount": totalAmount,
      "payment_type": ONLINE,
      "txn_id": "",
      "payment_status": PAID,
      "transaction_detail": ""
    };
    await savePayment(req).then((value) async {
      appStore.setLoading(false);
      init();
      paymentPressed = false;
    }).catchError((error) {
      paymentPressed = false;
      setState(() {});
      appStore.setLoading(false);
      log(error.toString());
      toast(error.toString());
    });
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
