import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_booking/utils/Extensions/int_extensions.dart';

import '../main.dart';
import '../model/PlaceSearchAutoCompleteModel.dart';
import '../network/RestApis.dart';
import '../screens/ChooseAirportOrZoneScreen.dart';
import '../screens/GoogleMapScreen.dart';
import '../screens/NewEstimateRideListWidget.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import 'package:intl/intl.dart';
// ignore: must_be_immutable
class TripTypeLocationComponent extends StatefulWidget {
  String trip_type;
  String? addressTitle;
  String? pickupTimeValue;
  double? lat;
  double? long;
  var tripDetail;

  TripTypeLocationComponent({required this.trip_type, this.tripDetail, this.lat, this.long, this.addressTitle, this.pickupTimeValue});

  @override
  TripTypeLocationComponentState createState() => TripTypeLocationComponentState();
}

class TripTypeLocationComponentState extends State<TripTypeLocationComponent> {
  TextEditingController sourceLocation = TextEditingController();
  TextEditingController destinationLocation = TextEditingController();
  TextEditingController flightNumberController = TextEditingController();
  TextEditingController terminalAddressController = TextEditingController();
  TextEditingController pickupTimeController = TextEditingController();
  String? pickupTimeValue;
  var sourceId, destinationId;
  FocusNode sourceFocus = FocusNode();
  FocusNode desFocus = FocusNode();
  List<TextEditingController> multipleDropPoints = [];
  var multiDropLatLng = {};
  List<FocusNode> multipleDropPointsFocus = [];
  int multiDropFieldPosition = 0;
  String mLocation = "";
  bool isDone = true;
  bool isLocationLoading = false;
  double? totalAmount;

  // Booking type: Standard or Hourly
  String selectedBookingType = 'STANDARD';
  int selectedHours = 2;

  List<Suggestion> listAddress = [];

  @override
  void initState() {
    super.initState();
    // Initialize tripDetail if null
    widget.tripDetail ??= {};
    // Initialize hourly booking values from tripDetail if they exist
    if (widget.tripDetail['booking_type'] != null) {
      selectedBookingType = widget.tripDetail['booking_type'];
    }
    if (widget.tripDetail['hours_booked'] != null) {
      selectedHours = widget.tripDetail['hours_booked'];
    }
    // init();
    getCurrantLocation();
  }

  // void init() async {
  //   await getServices().then((value) {
  //     list.addAll(value.data ?? []);
  //     setState(() {});
  //   });
  // }

  void getCurrantLocation() {
    if (widget.trip_type == tripTypeRegular || widget.trip_type == tripTypeAirport || widget.trip_type == tripTypeAirportDropoff) {
      polylineSource = LatLng(sharedPref.getDouble(LATITUDE) ?? 0.0, sharedPref.getDouble(LONGITUDE) ?? 0.0);
      sourceLocation.text = widget.addressTitle ?? "";
      setState(() {});
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
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
                  SizedBox(height: 16),
                  Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.only(bottom: 16),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(defaultRadius)),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.near_me,
                                    color: Colors.green,
                                    shadows: [
                                      BoxShadow(color: Colors.black, blurRadius: 1, offset: Offset(1.5, 1.5), spreadRadius: 5),
                                      BoxShadow(color: Colors.white70, blurRadius: 1, offset: Offset(-1, -1), spreadRadius: 5),
                                    ],
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            widget.trip_type == tripTypeAirport || widget.trip_type == tripTypeAirportPickup || widget.trip_type == tripTypeAirportToZone
                                                ? '${language.lblWhereAreYou}'
                                                : widget.trip_type == tripTypeZoneWise || widget.trip_type == tripTypeZoneToAirport
                                                    ? '${language.selectZone}'
                                                    : '${language.lblWhereAreYou}',
                                            style: secondaryTextStyle()),
                                        130.width,
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: sourceLocation,
                                                focusNode: sourceFocus,
                                                readOnly: widget.trip_type == tripTypeAirport || widget.trip_type == tripTypeAirportDropoff || widget.trip_type == tripTypeRegular ? false : true,
                                                decoration: searchInputDecoration(hint: language.sourceLocation,),
                                                onTap: () async {
                                                  var pickUpDetails;
                                                  if (widget.trip_type == tripTypeAirportPickup || widget.trip_type == tripTypeAirportToZone) {
                                                    pickUpDetails = await launchScreen(context, ChooseAirportOrZoneScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                                                    if (pickUpDetails != null) {
                                                      setState(() {
                                                        sourceId = pickUpDetails['id'];
                                                        sourceLocation.text = pickUpDetails['name'];
                                                        polylineSource = LatLng(double.parse(pickUpDetails['latitude_deg'].toString()), double.parse(pickUpDetails['longitude_deg'].toString()));
                                                      });
                                                    }
                                                  } else if (widget.trip_type == tripTypeZoneWise || widget.trip_type == tripTypeZoneToAirport) {
                                                    pickUpDetails = await launchScreen(
                                                        context,
                                                        ChooseAirportOrZoneScreen(
                                                          zone_selection: true,
                                                        ),
                                                        pageRouteAnimation: PageRouteAnimation.Slide);
                                                    if (pickUpDetails != null) {
                                                      setState(() {
                                                        sourceId = pickUpDetails['id'];
                                                        sourceLocation.text = pickUpDetails['name'];
                                                        polylineSource = LatLng(double.parse(pickUpDetails['latitude'].toString()), double.parse(pickUpDetails['longitude'].toString()));
                                                      });
                                                    }
                                                  }else{
                                                    sourceLocation.clear();
                                                    sourceId=null;
                                                    // polylineSource=null;
                                                  }
                                                },
                                                onChanged: (val) {
                                                  if (val.isNotEmpty) {
                                                    if (val.length < 3) {
                                                      isDone = false;
                                                      listAddress.clear();
                                                      setState(() {});
                                                    } else {
                                                      searchAddressRequest(search: val).then((value) {
                                                        isDone = true;
                                                        value.suggestions?.map((e) {
                                                          print("----------214>>>${e.placePrediction?.toJson()}");
                                                        });
                                                        listAddress = value.suggestions!;
                                                        setState(() {});
                                                      }).catchError((error) {
                                                        log(error);
                                                      });
                                                    }
                                                  } else {
                                                    setState(() {});
                                                  }
                                                },
                                              ),
                                            ),
                                            if(widget.trip_type == tripTypeRegular || widget.trip_type == tripTypeAirport || widget.trip_type == tripTypeAirportDropoff)
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4),
                                              child: IconButton.outlined(
                                                iconSize: 18,
                                                color:primaryColor,
                                                  onPressed: () async{
                                                    var selectedPlace = await launchScreen(context, GoogleMapScreen(isDestination: true), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                                    sourceLocation.text = selectedPlace['formatted_address'];
                                                    polylineSource = selectedPlace['position'];
                                                  },
                                                  icon: Icon(Icons.map_outlined),),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(width: 8),
                                  SizedBox(
                                    height: 46,
                                    child: DottedLine(
                                      direction: Axis.vertical,
                                      lineLength: double.infinity,
                                      lineThickness: 1,
                                      dashLength: 3,
                                      dashColor: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (multipleDropPoints.isEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      shadows: [
                                        BoxShadow(color: Colors.black, blurRadius: 1, offset: Offset(1.5, 1.5), spreadRadius: 5),
                                        BoxShadow(color: Colors.white70, blurRadius: 1, offset: Offset(-1, -1), spreadRadius: 5),
                                      ],
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              widget.trip_type == tripTypeAirport
                                                  ? '${language.selectAirport}'
                                                  : widget.trip_type == tripTypeAirportPickup
                                                      ? '${language.lblDropOff}'
                                                      : widget.trip_type == tripTypeZoneWise
                                                          ? '${language.selectZone}'
                                                          : widget.trip_type == tripTypeAirportToZone
                                                              ? '${language.selectZone}'
                                                              : widget.trip_type == tripTypeAirportDropoff || widget.trip_type == tripTypeZoneToAirport
                                                                  ? '${language.selectAirport}'
                                                                  : '${language.lblDropOff}',
                                              style: secondaryTextStyle()),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: destinationLocation,
                                                  focusNode: desFocus,
                                                  autofocus: false,
                                                  readOnly: widget.trip_type == tripTypeAirport || widget.trip_type == tripTypeAirportPickup || widget.trip_type == tripTypeRegular ? false : true,
                                                  decoration: searchInputDecoration(hint: language.destinationLocation),
                                                  onTap: () async {
                                                    var dropDetails;
                                                    // For simplified Airport option, show airport selection for destination
                                                    if (widget.trip_type == tripTypeAirport) {
                                                      dropDetails = await launchScreen(context, ChooseAirportOrZoneScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                                                      if (dropDetails != null) {
                                                        destinationLocation.text = dropDetails['name'];
                                                        destinationId = dropDetails['id'];
                                                        polylineDestination = LatLng(double.parse(dropDetails['latitude_deg'].toString()), double.parse(dropDetails['longitude_deg'].toString()));
                                                      }
                                                    } else if (widget.trip_type == tripTypeAirportDropoff || widget.trip_type == tripTypeZoneToAirport) {
                                                      dropDetails = await launchScreen(context, ChooseAirportOrZoneScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                                                      if (dropDetails != null) {
                                                        destinationLocation.text = dropDetails['name'];
                                                        destinationId = dropDetails['id'];
                                                        polylineDestination = LatLng(double.parse(dropDetails['latitude_deg'].toString()), double.parse(dropDetails['longitude_deg'].toString()));
                                                      }
                                                    } else if (widget.trip_type == tripTypeZoneWise || widget.trip_type == tripTypeAirportToZone) {
                                                      dropDetails = await launchScreen(
                                                          context,
                                                          ChooseAirportOrZoneScreen(
                                                            zone_selection: true,
                                                          ),
                                                          pageRouteAnimation: PageRouteAnimation.Slide);
                                                      if (dropDetails != null) {
                                                        destinationId = dropDetails['id'];
                                                        destinationLocation.text = dropDetails['name'];
                                                        polylineDestination = LatLng(double.parse(dropDetails['latitude'].toString()), double.parse(dropDetails['longitude'].toString()));
                                                      }
                                                    }
                                                    setState(() {});
                                                  },
                                                  onChanged: (val) {
                                                    if (val.isNotEmpty) {
                                                      if (val.length < 3) {
                                                        listAddress.clear();
                                                        setState(() {});
                                                      } else {
                                                        searchAddressRequest(search: val).then((value) {
                                                          listAddress = value.suggestions!;
                                                          setState(() {});
                                                        }).catchError((error) {
                                                          log(error);
                                                        });
                                                      }
                                                    } else {
                                                      setState(() {});
                                                    }
                                                  },
                                                ),
                                              ),
                                              if(widget.trip_type == tripTypeRegular || widget.trip_type == tripTypeAirportPickup)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                                  child: IconButton.outlined(
                                                    iconSize: 18,
                                                    color:primaryColor,
                                                    onPressed: () async{
                                                      var selectedPlace = await launchScreen(context, GoogleMapScreen(isDestination: true), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                                      destinationLocation.text = selectedPlace['formatted_address'];
                                                      polylineDestination = selectedPlace['position'];
                                                    },
                                                    icon: Icon(Icons.map_outlined),),
                                                )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                  ],
                                ),
                              if (multipleDropPoints.isNotEmpty) reorderedView(),
                            ],
                          ),
                        ),
                      ),
                      Visibility(visible: isLocationLoading, child: Positioned(top: 80, left: 0, right: 0, child: loaderWidget())),
                    ],
                  ),
                  if (appStore.isMultiDrop != null && appStore.isMultiDrop == "1")
                    TextButton(
                        onPressed: () {
                          if (multipleDropPoints.isEmpty) {
                            hideKeyboard(context);
                            multipleDropPoints = [TextEditingController(), TextEditingController()];
                            multipleDropPointsFocus = [FocusNode(), FocusNode()];
                          } else {
                            multipleDropPoints.add(TextEditingController());
                            multipleDropPointsFocus.add(FocusNode());
                          }
                          setState(() {});
                        },
                        child: Text(
                          language.addDropPoint,
                          style: primaryTextStyle(),
                        )),

                  /// Booking Type Selector: Standard vs Hourly
                  if (widget.trip_type == tripTypeRegular)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),

                  /// Flight Number, Terminal, and Pickup Time for Airport trips
                  if (widget.trip_type == tripTypeAirport ||
                      widget.trip_type == tripTypeAirportDropoff ||
                      widget.trip_type == tripTypeAirportPickup ||
                      widget.trip_type == tripTypeAirportToZone ||
                      widget.trip_type == tripTypeZoneToAirport)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        AppTextField(
                          controller: flightNumberController,
                          autoFocus: false,
                          textFieldType: TextFieldType.NAME,
                          errorThisFieldRequired: language.thisFieldRequired,
                          decoration: inputDecoration(context, label: '${language.flightNumber}', prefixIcon: Icon(Icons.flight)),
                        ),
                        SizedBox(height: 8),
                        AppTextField(
                          controller: terminalAddressController,
                          autoFocus: false,
                          textFieldType: TextFieldType.NAME,
                          errorThisFieldRequired: language.thisFieldRequired,
                          decoration: inputDecoration(context, label: '${language.terminalAddress}', prefixIcon: Icon(Icons.airport_shuttle)),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 4.0, right: 2),
                              child: Icon(Icons.info_outline_rounded, size: 12),
                            ),
                            Expanded(
                              child: Text('${language.terminalHelperText}', style: secondaryTextStyle()),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
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
                              lastDate: DateTime.now().add(Duration(days: 45)),
                            );

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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Please select a future time.')),
                                  );
                                }
                              }
                            }
                          },
                          errorThisFieldRequired: language.thisFieldRequired,
                          decoration: inputDecoration(context, label: '${language.preferredPickupTime}', prefixIcon: Icon(Icons.access_time_rounded)),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),

                  if (listAddress.isNotEmpty) SizedBox(height: 16),
                  ListView.builder(
                    controller: ScrollController(),
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: listAddress.length,
                    itemBuilder: (context, index) {
                      Suggestion mData = listAddress[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: primaryColor,
                        ),
                        minLeadingWidth: 16,
                        title: Text(mData.placePrediction?.text?.text ?? "", style: primaryTextStyle()),
                        onTap: () async {
                          await searchAddressRequestPlaceId(placeId: mData.placePrediction!.placeId).then((value) async {
                            if (sourceFocus.hasFocus) {
                              isDone = true;
                              mLocation = mData.placePrediction?.text?.text ?? '';
                              sourceLocation.text = mData.placePrediction?.text?.text ?? '';
                              polylineSource = LatLng(value.location!.latitude!, value.location!.longitude!);
                            } else if (desFocus.hasFocus) {
                              polylineDestination = LatLng(value.location!.latitude!, value.location!.longitude!);
                              destinationLocation.text = mData.placePrediction!.text!.text!;
                            } else if (multipleDropPoints.isNotEmpty) {
                              multiDropLatLng[multiDropFieldPosition] = LatLng(value.location!.latitude!, value.location!.longitude!);
                              multipleDropPoints[multiDropFieldPosition].text = mData.placePrediction!.text!.text!;
                              try {
                                multipleDropPointsFocus[multiDropFieldPosition + 1].requestFocus();
                              } catch (e) {}
                            }
                            listAddress.clear();
                            setState(() {});
                          }).catchError((error) {
                            log(error);
                          });
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  if (multipleDropPoints.isEmpty || (multipleDropPoints.isNotEmpty && multiDropLatLng.length != multipleDropPoints.length))
                    AppButtonWidget(
                      width: MediaQuery.of(context).size.width,
                      onTap: () async {
                        print("--------------378");
                        // Validate text fields
                        if (sourceLocation.text.isEmptyOrNull) {
                          toast("Please enter pickup location");
                          return;
                        }
                        if (destinationLocation.text.isEmptyOrNull) {
                          toast("Please enter drop off location");
                          return;
                        }
                        // Validate coordinates - must select from dropdown
                        if (polylineSource == null) {
                          toast("Please select pickup location from suggestions");
                          return;
                        }
                        if (polylineDestination == null) {
                          toast("Please select drop off location from suggestions");
                          return;
                        }

                        // Handle simplified Airport trip type (pickup to airport)
                        if (widget.trip_type == tripTypeAirport) {
                          widget.tripDetail['airport_name'] = destinationLocation.text;
                          widget.tripDetail['drop_airport_id'] = destinationId;
                        } else if (widget.trip_type == tripTypeAirportPickup || widget.trip_type == tripTypeAirportToZone) {
                          widget.tripDetail['airport_name'] = sourceLocation.text;
                          widget.tripDetail['pickup_airport_id'] = sourceId;
                          if (widget.trip_type == tripTypeAirportToZone) {
                            widget.tripDetail['drop_zone_id'] = destinationId;
                            widget.tripDetail['zone_name'] = destinationLocation.text;
                          }
                        } else if (widget.trip_type == tripTypeAirportDropoff || widget.trip_type == tripTypeZoneToAirport) {
                          widget.tripDetail['airport_name'] = destinationLocation.text;
                          widget.tripDetail['drop_airport_id'] = destinationId;
                          if (widget.trip_type == tripTypeZoneToAirport) {
                            widget.tripDetail['pickup_zone_id'] = sourceId;
                            widget.tripDetail['zone_name'] = sourceLocation.text;
                          }
                        } else if (widget.trip_type == tripTypeZoneWise) {
                          widget.tripDetail['pickup_zone_id'] = sourceId;
                          widget.tripDetail['drop_zone_id'] = destinationId;
                        }

                        // Add booking type and hours for hourly booking
                        widget.tripDetail['booking_type'] = selectedBookingType;
                        if (selectedBookingType == 'HOURLY') {
                          widget.tripDetail['hours_booked'] = selectedHours;
                          widget.tripDetail['included_miles'] = selectedHours * 15;
                        }

                        // Add flight number, terminal, and pickup time for airport trips
                        bool isAirportTrip = widget.trip_type == tripTypeAirport ||
                            widget.trip_type == tripTypeAirportDropoff ||
                            widget.trip_type == tripTypeAirportPickup ||
                            widget.trip_type == tripTypeAirportToZone ||
                            widget.trip_type == tripTypeZoneToAirport;

                        if (isAirportTrip) {
                          // Validate pickup time for airport trips
                          if (pickupTimeController.text.isEmpty) {
                            toast("Please select pickup time");
                            return;
                          }
                          widget.tripDetail['flight_number'] = flightNumberController.text;
                          widget.tripDetail['pickup_point'] = terminalAddressController.text;
                          widget.tripDetail['preferred_pickup_time'] = pickupTimeValue;
                        }

                        // Add trip type
                        widget.tripDetail['trip_type'] = getTripTypeValue(widget.trip_type);

                        launchScreen(
                            context,
                            NewEstimateRideListWidget(
                                is_taxi_service: true,
                                tripDetail: widget.tripDetail,
                                pickupTimeValue: isAirportTrip ? pickupTimeValue : widget.pickupTimeValue,
                                sourceLatLog: polylineSource,
                                destinationLatLog: polylineDestination,
                                sourceTitle: sourceLocation.text,
                                destinationTitle: destinationLocation.text),
                            pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                        sourceLocation.clear();
                        destinationLocation.clear();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(language.continueD, style: boldTextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget reorderedView() {
    return ReorderableListView(
      shrinkWrap: true,
      children: [
        for (int i = 0; i < multipleDropPoints.length; i++)
          Row(
            key: ValueKey("$i"),
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.red,
                      shadows: [
                        BoxShadow(color: Colors.black, blurRadius: 1, offset: Offset(1.5, 1.5), spreadRadius: 5),
                        BoxShadow(color: Colors.white70, blurRadius: 1, offset: Offset(-1, -1), spreadRadius: 5),
                      ],
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: multipleDropPoints[i],
                            focusNode: multipleDropPointsFocus[i],
                            autofocus: false,
                            decoration: searchInputDecoration(hint: "${language.dropPoint} ${i + 1}"),
                            onTap: () {
                              multiDropFieldPosition = i;
                              setState(() {});
                            },
                            onChanged: (val) {
                              if (val.isNotEmpty) {
                                multiDropFieldPosition = i;
                                try {
                                  multiDropLatLng.remove(multiDropFieldPosition);
                                } catch (e) {}
                                if (val.length < 3) {
                                  listAddress.clear();
                                  setState(() {});
                                } else {
                                  searchAddressRequest(search: val).then((value) {
                                    listAddress = value.suggestions!;
                                    setState(() {});
                                  }).catchError((error) {
                                    log(error);
                                  });
                                }
                              } else {
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4),
                  ],
                ),
              ),
              if (i > 0)
                IconButton(
                  onPressed: () {
                    if (multipleDropPoints.length == 2) {
                      multipleDropPoints.clear();
                      multipleDropPointsFocus.clear();
                      multiDropLatLng.clear();
                    } else {
                      multipleDropPoints.removeAt(i);
                      multipleDropPointsFocus.removeAt(i);
                      multiDropLatLng.remove(i);
                    }
                    setState(() {});
                  },
                  icon: Icon(Icons.remove_circle_outline),
                ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.menu),
              )
            ],
          ),
      ],
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = multipleDropPoints.removeAt(oldIndex);
          multipleDropPoints.insert(newIndex, item);
        });
      },
    );
  }
}
