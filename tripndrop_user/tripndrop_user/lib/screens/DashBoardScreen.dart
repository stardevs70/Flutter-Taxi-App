import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart' as lt;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:taxi_booking/components/AnimatedBottomSheetContent.dart';
import 'package:taxi_booking/components/TaxiCourierButton.dart';
import 'package:taxi_booking/screens/OrderScreen.dart';
import 'package:taxi_booking/screens/UpComingMainScreen.dart';
import 'package:tuple/tuple.dart';

import '../components/SearchLocationComponent.dart';
import '../components/TripTypeLocationComponent.dart';
import '../components/drawer_component.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/NearByDriverListModel.dart';
import '../network/RestApis.dart';
import '../screens/ReviewScreen.dart';
import '../screens/RidePaymentDetailScreen.dart';
import '../service/RideService.dart';
import '../service/VersionServices.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/Extensions/context_extension.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'BidingScreen.dart';
import 'LocationPermissionScreen.dart';
import 'NewEstimateRideListWidget.dart';
import 'NotificationScreen.dart';

class DashBoardScreen extends StatefulWidget {
  @override
  DashBoardScreenState createState() => DashBoardScreenState();
  final String? cancelReason;
  final String? flow;

  DashBoardScreen({this.cancelReason, this.flow});
}

class DashBoardScreenState extends State<DashBoardScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RideService rideService = RideService();
  List<Marker> markers = [];
  Set<Polyline> _polyLines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;
  OnRideRequest? servicesListData;
  double cameraZoom = 17.0, cameraTilt = 0;
  double cameraBearing = 30;
  int onTapIndex = 0;
  int selectIndex = 0;
  late StreamSubscription<ServiceStatus> serviceStatusStream;
  LocationPermission? permissionData;
  late BitmapDescriptor driverIcon;
  List<NearByDriverListModel>? nearDriverModel;
  GoogleMapController? mapController;
  Offset position = Offset(200, 150);

  double? lat;
  double? long;
  String? addressTitle;

  List<OnRideRequest> schedule_ride_request = [];

  int serviceType = 0;

  String selectedTripType = tripTypeRegular;

  // Booking type: Standard or Hourly
  String selectedBookingType = 'STANDARD';
  int selectedHours = 2; // Minimum 2 hours for hourly booking

  var flightNumberController = TextEditingController();
  var terminalAddressController = TextEditingController();
  var pickupTimeController = TextEditingController();
  var pickupTimeValue /*dropTimeValue*/;

  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 0.4).animate(_animController);

    locationPermission();
    if (app_update_check != null) {
      VersionService().getVersionData(context, app_update_check);
    }
    if (widget.cancelReason != null) {
      afterBuildCreated(() {
        _triggerCanceledPopup();
      });
    } else {
      getCurrentRequest();
    }
    afterBuildCreated(() {
      init();
    });
  }

  void init() async {
    getCurrentUserLocation();
    riderIcon = await getResizedMarker(SourceIcon);
    driverIcon = await getResizedMarker(MultipleDriver);
    if (widget.flow == "order") {
      launchScreen(context, Orderscreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: false);
      return;
    }
    polylinePoints = PolylinePoints();
  }

  Future<void> getCurrentUserLocation() async {
    if (permissionData != LocationPermission.denied) {
      final geoPosition = await Geolocator.getCurrentPosition(timeLimit: Duration(seconds: 30), desiredAccuracy: LocationAccuracy.high);
      lat = geoPosition.longitude;
      long = geoPosition.longitude;

      sourceLocation = LatLng(geoPosition.latitude, geoPosition.longitude);

      try {
        List<Placemark>? placemarks = await placemarkFromCoordinates(geoPosition.latitude, geoPosition.longitude);
        Placemark places = placemarks[0];

        addressTitle = "${places.name != null ? places.name : places.subThoroughfare}, ${places.subLocality}, ${places.locality}, ${places.administrativeArea} ${places.postalCode}, ${places.country}";
        print("-----------161>>>>${addressTitle}");

        await getNearByDriver();

        ///set Country
        sharedPref.setString(COUNTRY, placemarks[0].isoCountryCode.validate(value: defaultCountry));

        Placemark place = placemarks[0];
        sourceLocationTitle =
            "${place.name != null ? place.name : place.subThoroughfare}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}, ${place.country}";
        polylineSource = LatLng(geoPosition.latitude, geoPosition.longitude);
            } catch (e) {
        throw e;
      }
      addMarker();
      startLocationTracking();

      if (mounted) setState(() {});
    } else {
      launchScreen(navigatorKey.currentState!.overlay!.context, LocationPermissionScreen());
    }
  }

  Future<void> getCurrentRequest() async {
    await getCurrentRideRequest().then((value) async {
      servicesListData = value.rideRequest ?? value.onRideRequest;
      schedule_ride_request = value.schedule_ride_request ?? [];
      if (schedule_ride_request.isEmpty) {
        schedule_ride_request = value.schedule_orders ?? [];
      }
      if (servicesListData == null) {
        sharedPref.remove(REMAINING_TIME);
        sharedPref.remove(IS_TIME);
        setState(() {});
      }
      print("169");
      if (servicesListData != null) {
        print("171");
        if ((value.ride_has_bids == 1) && (servicesListData!.status == NEW_RIDE_REQUESTED || servicesListData!.status == "bid_rejected")) {
          launchScreen(
            context,
            isNewTask: true,
            Bidingscreen(
              dt: servicesListData!.isSchedule == 1 ? servicesListData!.schedule_datetime : servicesListData!.datetime,
              ride_id: servicesListData!.id!,
              source: {},
              endLocation: {},
              multiDropObj: {},
              multiDropLocationNamesObj: {},
            ),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
          );
        } else if (servicesListData!.status != COMPLETED && servicesListData!.status != CANCELED) {
          int x = 0;
          if (value.rideRequest == null && value.onRideRequest == null) {
            x = servicesListData!.id!;
          } else {
            x = value.rideRequest != null ? value.rideRequest!.id! : value.onRideRequest!.id!;
          }
          QuerySnapshot<Object?> b = await rideService.checkIsRideExist(rideId: x);
          if (b.docs.length > 0) {
            ///   Check Condition so screen looping issue not occur
            ///   if Ride Not exist in firebase than don't navigate to next screen
            launchScreen(
              getContext,
              NewEstimateRideListWidget(
                is_taxi_service: servicesListData!.type != TRANSPORT,
                dt: servicesListData!.isSchedule == 1 ? servicesListData!.schedule_datetime : servicesListData!.datetime,
                sourceLatLog: LatLng(double.parse(servicesListData!.startLatitude!), double.parse(servicesListData!.startLongitude!)),
                destinationLatLog: LatLng(double.parse(servicesListData!.endLatitude!), double.parse(servicesListData!.endLongitude!)),
                sourceTitle: servicesListData!.startAddress!,
                destinationTitle: servicesListData!.endAddress!,
                isCurrentRequest: true,
                servicesId: servicesListData!.serviceId,
                id: servicesListData!.id,
              ),
              pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
            );
          } else {
            if (value.schedule_ride_request != null && value.schedule_ride_request!.isNotEmpty) {
              if (value.schedule_ride_request!.first.id == x) {
                return;
              }
            }
            return toast(rideNotFound);
          }
        } else if (servicesListData!.status == COMPLETED && servicesListData!.isRiderRated == 0) {
          Future.delayed(
            Duration(seconds: 1),
            () {
              launchScreen(getContext, ReviewScreen(rideRequest: servicesListData!, driverData: value.driver), pageRouteAnimation: PageRouteAnimation.SlideBottomTop, isNewTask: true);
            },
          );
        }
      } else if (value.payment != null && value.payment!.paymentStatus != "paid") {
        print("222");
        launchScreen(getContext, RidePaymentDetailScreen(rideId: value.payment!.rideRequestId), pageRouteAnimation: PageRouteAnimation.SlideBottomTop, isNewTask: true);
      }
    }).catchError((error, s) {
      print("CHecking200:::$error ===$s");
    });
  }

  Future<void> locationPermission() async {
    serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        launchScreen(navigatorKey.currentState!.overlay!.context, LocationPermissionScreen());
      } else if (status == ServiceStatus.enabled) {
        getCurrentUserLocation();
        if (locationScreenKey.currentContext != null) {
          if (Navigator.canPop(navigatorKey.currentState!.overlay!.context)) {
            Navigator.pop(navigatorKey.currentState!.overlay!.context);
          }
        }
      }
    }, onError: (error) {});
  }

  addMarker() {
    markers.add(
      Marker(
        markerId: MarkerId('Order Detail'),
        position: sourceLocation!,
        draggable: true,
        infoWindow: InfoWindow(title: sourceLocationTitle, snippet: ''),
        icon: riderIcon,
      ),
    );
  }

  Future<void> startLocationTracking() async {
    Map req = {
      "latitude": sourceLocation!.latitude.toString(),
      "longitude": sourceLocation!.longitude.toString(),
    };
    await updateStatus(req).then((value) {}).catchError((error) {
      log(error);
    });
  }


  Future<void> getNearByDriver() async {
    await getNearByDriverList(latLng: sourceLocation).then((value) async {
      value.data?.forEach((element) async {
        print("CHECKIMAGE:::${element}");
        try {
          var driverIcon1 = await getNetworkImageMarker(element.service_marker.validate());
          markers.add(
            Marker(
              markerId: MarkerId('Driver${element.id}'),
              position: LatLng(double.parse(element.latitude!.toString()), double.parse(element.longitude!.toString())),
              infoWindow: InfoWindow(title: '${element.firstName} ${element.lastName}', snippet: ''),
              icon: driverIcon1,
            ),
          );
          if (mounted) setState(() {});
        } catch (e, s) {
          print("------------323>>>:::${e.toString()}");
          print("------------324>>>:::${s.toString()}");
          markers.add(
            Marker(
              markerId: MarkerId('Driver${element.id}'),
              position: LatLng(double.parse(element.latitude!.toString()), double.parse(element.longitude!.toString())),
              infoWindow: InfoWindow(title: '${element.firstName} ${element.lastName}', snippet: ''),
              icon: driverIcon,
            ),
          );
          if (mounted) setState(() {});
        }
      });
    }).catchError((e, s) {
      print("ERROR  FOUND:::$e ++++>$s");
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void showServiceTypeBottomSheet(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _buildRideTypeSelector(context);
      },
    ).then((selectedType) {
      if (selectedType != null) {
        // Open the location component with the selected trip type
        showModalBottomSheet<Tuple2<int, int>>(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return TripTypeLocationComponent(
              trip_type: selectedType,
              tripDetail: {},
              lat: lat,
              long: long,
              addressTitle: addressTitle,
            );
          },
        ).then((value) {
          serviceType = value?.item1 ?? 0;
          setState(() {});
        });
      }
    });
  }

  Widget _buildRideTypeSelector(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              height: 5,
              width: 70,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(defaultRadius),
              ),
            ),
          ),
          Text('Select Ride Type', style: boldTextStyle(size: 18)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRideTypeButton(
                  context,
                  icon: Icons.directions_car,
                  label: 'Point to\nPoint',
                  tripType: tripTypeRegular,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildRideTypeButton(
                  context,
                  icon: Icons.flight_land,
                  label: 'Airport\nPick up',
                  tripType: tripTypeAirportPickup,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildRideTypeButton(
                  context,
                  icon: Icons.flight_takeoff,
                  label: 'Airport\nDropoff',
                  tripType: tripTypeAirport,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRideTypeButton(BuildContext context, {
    required IconData icon,
    required String label,
    required String tripType,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, tripType);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(defaultRadius),
          color: primaryColor.withValues(alpha: 0.1),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryColor, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: boldTextStyle(size: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark),
      ),
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      drawer: DrawerComponent(onClose: (value) {
        if (value == 'openBottom') {
          Future.delayed(Duration.zero).then((val) {
            showServiceTypeBottomSheet(context);
          });
        }
      }),
      body: Stack(
        children: [
          if (sharedPref.getDouble(LATITUDE) != null && sharedPref.getDouble(LONGITUDE) != null)
            GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
              },
              padding: EdgeInsets.only(top: context.statusBarHeight + 4 + 24),
              compassEnabled: true,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              markers: markers.map((e) => e).toSet(),
              polylines: _polyLines,
              initialCameraPosition: CameraPosition(
                target: sourceLocation ?? LatLng(sharedPref.getDouble(LATITUDE)!, sharedPref.getDouble(LONGITUDE)!),
                zoom: cameraZoom,
                tilt: cameraTilt,
                bearing: cameraBearing,
              ),
            ),
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
          if (serviceType == 0)
            Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    GestureDetector(
                        onTap: () {
                          showServiceTypeBottomSheet(context);
                        },
                        child: TaxiCourierButton()),
                  ],
                )),
          if (serviceType == 1)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                  ),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(defaultRadius),
                      boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2, spreadRadius: 1)],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            width: 24,
                          ),
                          Container(
                            alignment: Alignment.center,
                            margin: EdgeInsets.only(bottom: 12),
                            height: 5,
                            width: 70,
                            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                          ),
                          inkWellWidget(
                            onTap: () {
                              setState(() {
                                serviceType = 0;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(color: context.cardColor, shape: BoxShape.circle, border: Border.all(color: dividerColor)),
                              child: Icon(Icons.close, color: context.iconColor, size: 24),
                            ),
                          )
                        ],
                      ),
                      Text("${language.tripType}".capitalizeFirstLetter(), style: primaryTextStyle()),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(defaultRadius), color: Colors.grey.withValues(alpha: 0.15)),
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.only(right: 8),
                        child: DropdownButton<String>(
                          value: selectedTripType,
                          borderRadius: BorderRadius.circular(defaultRadius),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          underline: SizedBox(),
                          items: tripTypeList.map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Padding(
                                padding: EdgeInsets.only(left: 16, right: 16),
                                child: Text(getMultiLanguageTripType(e.validate()), style: primaryTextStyle()),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            selectedTripType = val ?? '';
                            pickupTimeValue = null;
                            pickupTimeController.clear();
                            flightNumberController.clear();
                            terminalAddressController.clear();
                            setState(() {});
                          },
                        ),
                      ),

                      /// Booking Type Selector: Standard vs Hourly
                      SizedBox(height: 16),
                      Text("Booking Type", style: primaryTextStyle()),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                selectedBookingType = 'STANDARD';
                                setState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(defaultRadius),
                                  color: selectedBookingType == 'STANDARD' ? primaryColor : Colors.grey.withValues(alpha: 0.15),
                                ),
                                child: Center(
                                  child: Text(
                                    'Standard',
                                    style: boldTextStyle(
                                      color: selectedBookingType == 'STANDARD' ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                selectedBookingType = 'HOURLY';
                                setState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(defaultRadius),
                                  color: selectedBookingType == 'HOURLY' ? primaryColor : Colors.grey.withValues(alpha: 0.15),
                                ),
                                child: Center(
                                  child: Text(
                                    'Hourly',
                                    style: boldTextStyle(
                                      color: selectedBookingType == 'HOURLY' ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      /// Hourly booking options
                      if (selectedBookingType == 'HOURLY')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16),
                            Text("Select Hours (Minimum 2)", style: primaryTextStyle()),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (selectedHours > 2) {
                                      selectedHours--;
                                      setState(() {});
                                    }
                                  },
                                  icon: Icon(Icons.remove_circle, color: primaryColor, size: 32),
                                ),
                                SizedBox(width: 16),
                                Text('$selectedHours hrs', style: boldTextStyle(size: 24)),
                                SizedBox(width: 16),
                                IconButton(
                                  onPressed: () {
                                    if (selectedHours < 12) {
                                      selectedHours++;
                                      setState(() {});
                                    }
                                  },
                                  icon: Icon(Icons.add_circle, color: primaryColor, size: 32),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(defaultRadius),
                                color: Colors.blue.withValues(alpha: 0.1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hourly Booking Info:', style: boldTextStyle(size: 14)),
                                  SizedBox(height: 8),
                                  Text('• Included miles: ${selectedHours * 15} miles', style: secondaryTextStyle()),
                                  Text('• Pricing varies by vehicle type', style: secondaryTextStyle()),
                                  Text('• Extra miles: \$5.50/mile over limit', style: secondaryTextStyle()),
                                  Text('• Up to 15 mins over is free, 16th min = full hour', style: secondaryTextStyle()),
                                ],
                              ),
                            ),
                          ],
                        ),

                      /// if Airport trip type selected - show flight number and terminal fields
                      if (selectedTripType == tripTypeAirport ||
                          selectedTripType == tripTypeAirportDropoff ||
                          selectedTripType == tripTypeAirportPickup ||
                          selectedTripType == tripTypeAirportToZone ||
                          selectedTripType == tripTypeZoneToAirport)
                        Column(
                          children: [
                            SizedBox(height: 12),
                            AppTextField(
                              controller: flightNumberController,
                              autoFocus: false,
                              textFieldType: TextFieldType.NAME,
                              errorThisFieldRequired: errorThisFieldRequired,
                              decoration: inputDecoration(context, label: '${language.flightNumber}', prefixIcon: Icon(Icons.flight)),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            AppTextField(
                              controller: terminalAddressController,
                              autoFocus: false,
                              textFieldType: TextFieldType.NAME,
                              errorThisFieldRequired: errorThisFieldRequired,
                              decoration: inputDecoration(context, label: '${language.terminalAddress}', prefixIcon: Icon(Icons.airport_shuttle)),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 4.0, right: 2),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    size: 12,
                                  ),
                                ),
                                Expanded(
                                    child: Text(
                                  '${language.terminalHelperText}',
                                  style: secondaryTextStyle(),
                                )),
                              ],
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            AppTextField(
                              controller: pickupTimeController,
                              autoFocus: false,
                              textFieldType: TextFieldType.NAME,
                              readOnly: true,
                              enabled: true,
                              onTap: () async {
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
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(Duration(days: 45)));

                                bool isToday = DateUtils.isSameDay(d1, DateTime.now());

                                TimeOfDay initialTime = TimeOfDay(
                                  hour: isToday ? DateTime.now().hour : 0,
                                  minute: isToday ? DateTime.now().minute : 0,
                                );

                                if (d1 != null) {
                                  TimeOfDay? t1 = await showTimePicker(
                                    initialTime: initialTime,
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
                                  );

                                  if (t1 != null) {
                                    final selectedDateTime = DateTime(d1.year, d1.month, d1.day, t1.hour, t1.minute);
                                    final now = DateTime.now();

                                    if (selectedDateTime.isAfter(now)) {
                                      setState(() {
                                        pickupTimeValue = selectedDateTime.toString();
                                        pickupTimeController.text = DateFormat('dd MMM yy hh:mm a').format(selectedDateTime);
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Please select a future time.'),
                                      ));
                                    }
                                  }

                                  /*if (t1 != null) {
                                    d1 = DateTime(d1.year, d1.month, d1.day, t1.hour, t1.minute);
                                    setState(() {
                                      pickupTimeValue = d1.toString();
                                      print("------656>>${pickupTimeValue}");
                                      pickupTimeController.text = DateFormat('dd MMM yy hh:mm a').format(d1!);
                                    });
                                  }*/
                                }
                              },
                              errorThisFieldRequired: errorThisFieldRequired,
                              decoration: inputDecoration(context, label: '${language.preferredPickupTime}', prefixIcon: Icon(Icons.access_time_rounded)),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                          ],
                        ),
                      SizedBox(height: 12),
                      AppButtonWidget(
                        color: primaryColor,
                        onTap: () async {
                          var tripDetail = {};
                          // Add booking type (STANDARD or HOURLY)
                          tripDetail['booking_type'] = selectedBookingType;
                          if (selectedBookingType == 'HOURLY') {
                            tripDetail['hours_booked'] = selectedHours;
                            tripDetail['included_miles'] = selectedHours * 15;
                          }
                          if (selectedTripType == tripTypeAirport ||
                              selectedTripType == tripTypeAirportDropoff ||
                              selectedTripType == tripTypeAirportPickup ||
                              selectedTripType == tripTypeAirportToZone ||
                              selectedTripType == tripTypeZoneToAirport) {
                            tripDetail['flight_number'] = flightNumberController.text;
                            tripDetail['pickup_point'] = terminalAddressController.text;
                            tripDetail['preferred_pickup_time'] = pickupTimeValue;
                          }
                          tripDetail['trip_type'] = getTripTypeValue(selectedTripType);
                          // Flight number is optional per client requirement - user can skip or enter later
                          // if (selectedTripType.toLowerCase().contains("airport") && flightNumberController.text.isEmpty) {
                          //   return toast("Please Provide Flight Number");
                          // }
                          if (selectedTripType.toLowerCase().contains("airport") && pickupTimeController.text.isEmpty) {
                            return toast("Please Pickup Time");
                          }
                          showModalBottomSheet(
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius)),
                            ),
                            context: context,
                            builder: (_) {
                              return TripTypeLocationComponent(
                                trip_type: selectedTripType,
                                tripDetail: tripDetail,
                                pickupTimeValue: pickupTimeValue,
                                lat: lat,
                                long: long,
                                addressTitle: addressTitle,
                              );
                            },
                          );
                        },
                        text: language.continueD,
                        textStyle: boldTextStyle(color: Colors.white),
                        width: MediaQuery.of(context).size.width,
                      ),
                    ],
                  ),
                    ),
                  ),
                ),
              ),
            ),
          if (serviceType == 2)
            SlidingUpPanel(
              backdropOpacity: 0.0,
              boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2, spreadRadius: 1)],
              padding: EdgeInsets.all(16),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius)),
              backdropTapClosesPanel: true,
              minHeight: 160 ,
              maxHeight: 140 ,
              panel: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                        width: 24,
                      ),
                      Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(bottom: 12),
                        height: 5,
                        width: 70,
                        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
                      ),
                      inkWellWidget(
                        onTap: () {
                          setState(() {
                            serviceType = 0;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(color: context.cardColor, shape: BoxShape.circle, border: Border.all(color: dividerColor)),
                          child: Icon(Icons.close, color: context.iconColor, size: 24),
                        ),
                      )
                    ],
                  ),
                  Text(language.whatWouldYouLikeToGo.capitalizeFirstLetter(), style: primaryTextStyle()),
                  SizedBox(height: 12),
                  AppTextField(
                    autoFocus: false,
                    readOnly: true,
                    onTap: () async {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius)),
                        ),
                        context: context,
                        builder: (_) {
                          return SearchLocationComponent(
                            title: sourceLocationTitle,
                          );
                        },
                      );
                    },
                    textFieldType: TextFieldType.EMAIL,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      focusColor: primaryColor,
                      prefixIcon: Icon(Feather.search),
                      filled: false,
                      isDense: true,
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: dividerColor)),
                      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: dividerColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: Colors.black)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: dividerColor)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: Colors.red)),
                      alignLabelWithHint: true,
                      hintText: language.enterYourDestination,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          Visibility(
            visible: appStore.isLoading,
            child: loaderWidget(),
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
    );
  }

  Widget topWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        inkWellWidget(
          onTap: () {
            _scaffoldKey.currentState!.openDrawer();
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
        inkWellWidget(
          onTap: () async {
            launchScreen(context, NotificationScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
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

  void _triggerCanceledPopup() {
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
                "${language.rideCanceledByDriver}",
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
                "${language.cancelledReason}",
                style: secondaryTextStyle(),
              ),
              Text(
                widget.cancelReason.validate(),
                style: primaryTextStyle(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> cancelRequest(String reason, {int? ride_id}) async {
    Map req = {
      "id": ride_id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: ride_id).then((value) async {
      getCurrentRequest();
      toast(value.message);
    }).catchError((error) {});
  }
}
