import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/ChatScreen.dart';
import '../screens/RideDetailScreen.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'Extensions/Loader.dart';
import 'Extensions/app_common.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

Widget dotIndicator(list, i) {
  return SizedBox(
    height: 16,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        list.length,
        (ind) {
          return Container(
            height: 8,
            width: 8,
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(color: i == ind ? Colors.black : Colors.grey.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(defaultRadius)),
          );
        },
      ),
    ),
  );
}


Future<BitmapDescriptor> getResizedMarker(String assetPath,) async {
  final ByteData data = await rootBundle.load(assetPath);
  final Uint8List bytes = data.buffer.asUint8List();

  final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      // targetWidth: marker_size_width, // Resize image width
      targetHeight: marker_size_height
  );
  final ui.FrameInfo fi = await codec.getNextFrame();

  final ByteData? resizedBytes = await fi.image.toByteData(format: ui.ImageByteFormat.png);
  // ignore: deprecated_member_use
  return BitmapDescriptor.fromBytes(resizedBytes!.buffer.asUint8List());
}

Future<BitmapDescriptor> getNetworkImageMarker(String imageUrl) async {
  final http.Response response = await http.get(Uri.parse(imageUrl));
  final Uint8List bytes = response.bodyBytes;
  final ui.Codec codec = await ui.instantiateImageCodec(bytes,targetHeight: marker_size_height);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List resizedBytes = byteData!.buffer.asUint8List();
  // ignore: deprecated_member_use
  return BitmapDescriptor.fromBytes(resizedBytes);
}

InputDecoration inputDecoration(BuildContext context, {String? label, Widget? prefixIcon, Widget? suffixIcon, bool? alignWithHint = true, String? counterText,bool isFilled=false}) {
  return InputDecoration(
    fillColor: isFilled?Colors.grey.shade100:null,
    focusColor: primaryColor,
    prefixIcon: prefixIcon,
    counterText: counterText,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: isFilled?Colors.transparent:dividerColor)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color:isFilled?Colors.transparent: dividerColor)),
    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: isFilled?Colors.transparent:dividerColor)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color:isFilled?Colors.transparent: Colors.black)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color:isFilled?Colors.transparent: dividerColor)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: Colors.red)),
    alignLabelWithHint: alignWithHint,
    filled: isFilled,
    isDense: true,
    labelText: label ?? "Sample Text",
    labelStyle: primaryTextStyle(),
    suffixIcon: suffixIcon,
  );
}

InputDecoration searchInputDecoration({String? hint}) {
  return InputDecoration(
      contentPadding: EdgeInsets.symmetric(vertical: 8),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
      border: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
      focusColor: primaryColor,
      isDense: true,
      hintStyle: primaryTextStyle(),
      labelStyle: primaryTextStyle(),
      hintText: hint);
}

extension BooleanExtensions on bool? {
  /// Validate given bool is not null and returns given value if null.
  bool validate({bool value = false}) => this ?? value;
}

EdgeInsets dynamicAppButtonPadding(BuildContext context) {
  return EdgeInsets.symmetric(vertical: 14, horizontal: 16);
}

Widget inkWellWidget({Function()? onTap, required Widget child}) {
  return InkWell(onTap: onTap, child: child, highlightColor: Colors.transparent, hoverColor: Colors.transparent, splashColor: Colors.transparent);
}

bool get isRTL => rtlLanguage.contains(appStore.selectedLanguage);

Widget commonCachedNetworkImage(String? url, {double? height, double? width, BoxFit? fit, AlignmentGeometry? alignment, bool usePlaceholderIfUrlEmpty = true, double? radius}) {
  if (url != null && url.isEmpty) {
    return placeHolderWidget(height: height, width: width, fit: fit, alignment: alignment, radius: radius);
  } else if (url.validate().startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment as Alignment? ?? Alignment.center,
      errorWidget: (_, s, d) {
        return placeHolderWidget(height: height, width: width, fit: fit, alignment: alignment, radius: radius);
      },
      placeholder: (_, s) {
        if (!usePlaceholderIfUrlEmpty) return SizedBox();
        return placeHolderWidget(height: height, width: width, fit: fit, alignment: alignment, radius: radius);
      },
    );
  } else {
    return Image.network(url!, height: height, width: width, fit: fit, alignment: alignment ?? Alignment.center);
  }
}

Widget placeHolderWidget({double? height, double? width, BoxFit? fit, AlignmentGeometry? alignment, double? radius}) {
  return Image.asset(placeholder, height: height, width: width, fit: fit ?? BoxFit.cover, alignment: alignment ?? Alignment.center);
}

List<BoxShadow> defaultBoxShadow({
  Color? shadowColor,
  double? blurRadius,
  double? spreadRadius,
  Offset offset = const Offset(0.0, 0.0),
}) {
  return [
    BoxShadow(
      color: shadowColor ?? Colors.grey.withValues(alpha: 0.2),
      blurRadius: blurRadius ?? 4.0,
      spreadRadius: spreadRadius ?? 1.0,
      offset: offset,
    )
  ];
}

/// Hide soft keyboard
void hideKeyboard(context) => FocusScope.of(context).requestFocus(FocusNode());

const double degrees2Radians = pi / 180.0;

double radians(double degrees) => degrees * degrees2Radians;

Future<bool> isNetworkAvailable() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}

Widget loaderWidget() {
  return Center(
    child: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 0, offset: Offset(0.0, 0.0)),
        ],
      ),
      width: 50,
      height: 50,
      child: CircularProgressIndicator(strokeWidth: 3, color: primaryColor),
    ),
  );
}

void afterBuildCreated(Function()? onCreated) {
  makeNullable(SchedulerBinding.instance)!.addPostFrameCallback((_) => onCreated?.call());
}

T? makeNullable<T>(T? value) => value;

String printDate(String date) {
  return DateFormat('dd MMM yyyy').format(DateTime.parse(date).toLocal()) + " at " + DateFormat('hh:mm a').format(DateTime.parse(date).toLocal());
}

Widget emptyWidget() {
  return Center(child: Image.asset(noDataImg, width: 150, height: 250));
}

String statusTypeIcon({String? type}) {
  String icon = ic_history_img1;
  if (type == NEW_RIDE_REQUESTED) {
    icon = ic_history_img1;
  } else if (type == ACCEPTED || type == BID_ACCEPTED) {
    icon = ic_history_img2;
  } else if (type == ARRIVING) {
    icon = ic_history_img3;
  } else if (type == ARRIVED) {
    icon = ic_history_img4;
  } else if (type == IN_PROGRESS) {
    icon = ic_history_img5;
  } else if (type == CANCELED) {
    icon = ic_history_img6;
  } else if (type == COMPLETED) {
    icon = ic_history_img7;
  }
  return icon;
}

Widget scheduleOptionWidget(BuildContext context, bool isSelected, String imagePath, String title) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(
          color: isSelected
              ? primaryColor
              : appStore.isDarkMode
                  ? Colors.transparent
                  : borderColor),
    ),
    child: Row(
      children: [
        ImageIcon(AssetImage(imagePath), size: 20, color: isSelected ? primaryColor : Colors.grey),
        SizedBox(width: 16),
        Text(title, style: boldTextStyle()),
      ],
    ),
  );
}

Widget totalCount({String? title, num? amount, bool? isTotal = false, double? space}) {
  if (amount != null && amount > 0) {
    return Padding(
      padding: EdgeInsets.only(bottom: space ?? 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(title!, style: isTotal == true ? boldTextStyle(color: Colors.green, size: 18) : secondaryTextStyle())),
          printAmountWidget(amount: '${amount.toStringAsFixed(digitAfterDecimal)}', size: isTotal == true ? 18 : 14, color: isTotal == true ? Colors.green : textPrimaryColorGlobal)
        ],
      ),
    );
  } else {
    return SizedBox();
  }
}

Widget printAmountWidget({required String amount, double? size, Color? color, FontWeight? weight, TextDecoration? textDecoration}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: appStore.currencyPosition.toString().toLowerCase().trim() == LEFT.toLowerCase().trim()
        ? [
            Text(
              "${appStore.currencyCode} ",
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily,
                  decoration: textDecoration ?? TextDecoration.none,
                decorationColor: Colors.redAccent,
                decorationThickness: 2.0,
              ),
            ),
            Text(
              "$amount",
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily,
                  decoration: textDecoration ?? TextDecoration.none,
                decorationColor: Colors.redAccent,
                decorationThickness: 2.0,
              ),
            ),
          ]
        : [
            Text(
              "$amount ",
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily,
                  decoration: textDecoration ?? TextDecoration.none),
            ),
            Text(
              "${appStore.currencyCode}",
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily,
                  decoration: textDecoration ?? TextDecoration.none),
            ),
          ],
  );
}

Future<bool> checkPermission() async {
  // Request app level location permission
  LocationPermission locationPermission = await Geolocator.requestPermission();

  if (locationPermission == LocationPermission.whileInUse || locationPermission == LocationPermission.always) {
    await Geolocator.getCurrentPosition().then((value) {
      sharedPref.setDouble(LATITUDE, value.latitude);
      sharedPref.setDouble(LONGITUDE, value.longitude);
    });
    // Check system level location permission
    if (!await Geolocator.isLocationServiceEnabled()) {
      return await Geolocator.openLocationSettings().then((value) => false).catchError((e) => false);
    } else {
      return true;
    }
  } else {
    toast(language.pleaseEnableLocationPermission);

    // Open system level location permission
    await Geolocator.openAppSettings();

    return false;
  }
}

/// Handle error and loading widget when using FutureBuilder or StreamBuilder
Widget snapWidgetHelper<T>(
  AsyncSnapshot<T> snap, {
  Widget? errorWidget,
  Widget? loadingWidget,
  String? defaultErrorMessage,
  @Deprecated('Do not use this') bool checkHasData = false,
  Widget Function(String)? errorBuilder,
}) {
  if (snap.hasError) {
    log(snap.error);
    if (errorBuilder != null) {
      return errorBuilder.call(defaultErrorMessage ?? snap.error.toString());
    }
    return Center(
      child: errorWidget ??
          Text(
            defaultErrorMessage ?? snap.error.toString(),
            style: primaryTextStyle(),
          ),
    );
  } else if (!snap.hasData) {
    return loadingWidget ?? Loader();
  } else {
    return SizedBox();
  }
}

Future<bool> setValue(String key, dynamic value, {bool print1 = true}) async {
  if (print1) print('${value.runtimeType} - $key - $value');

  if (value is String) {
    return await sharedPref.setString(key, value.validate());
  } else if (value is int) {
    return await sharedPref.setInt(key, value.validate());
  } else if (value is bool) {
    return await sharedPref.setBool(key, value.validate());
  } else if (value is double) {
    return await sharedPref.setDouble(key, value);
  } else if (value is Map<String, dynamic>) {
    return await sharedPref.setString(key, jsonEncode(value));
  } else if (value is List<String>) {
    return await sharedPref.setStringList(key, value);
  } else {
    throw ArgumentError('Invalid value ${value.runtimeType} - Must be a String, int, bool, double, Map<String, dynamic> or StringList');
  }
}

Color statusColor(String status) {
  Color color = primaryColor;
  switch (status) {
    case ORDER_ACCEPTED:
      return acceptColor;
    case ORDER_CREATED:
      return CreatedColorColor;
    case ORDER_DEPARTED:
      return acceptColor;
    case ORDER_ASSIGNED:
      return pendingApprovalColorColor;
    case ORDER_PICKED_UP:
      return in_progressColor;
    case ORDER_ARRIVED:
      return in_progressColor;
    case ORDER_CANCELLED:
      return cancelledColor;
    case ORDER_DELIVERED:
      return completedColor;
    case ORDER_DRAFT:
      return holdColor;
    case ORDER_DELAYED:
      return WaitingStatusColor;
  }
  return color;
}

String statusName({String? status}) {
  print("--------407>>>${status}");
  if (status == NEW_RIDE_REQUESTED) {
    status = language.newRideRequested;
  } else if (status == ACCEPTED || status == BID_ACCEPTED || status == ASSIGN_DRIVER) {
    status = language.accepted;
  } else if (status == ARRIVING) {
    status = language.arriving;
  } else if (status == ARRIVED) {
    status = language.arrived;
  } else if (status == IN_PROGRESS) {
    status = language.inProgress;
  } else if (status == CANCELED) {
    status = language.cancelled;
  } else if (status == COMPLETED) {
    status = language.completed;
  }
  return status!;
}

Widget chatCallWidget(IconData icon, {String? uid}) {
  if (uid != null) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: dividerColor), color: appStore.isDarkMode ? scaffoldColorDark : scaffoldColorLight, borderRadius: BorderRadius.circular(defaultRadius)),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        StreamBuilder<int>(
            stream: chatMessageService.getUnReadCount(receiverId: "${uid}", senderId: "${sharedPref.getString(UID)}"),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null && snapshot.data! > 0) {
                return Positioned(top: -2, right: 0, child: Lottie.asset(messageDetect, width: 18, height: 18, fit: BoxFit.cover));
              }
              return SizedBox();
            })
      ],
    );
  } else {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: dividerColor), color: appStore.isDarkMode ? scaffoldColorDark : scaffoldColorLight, borderRadius: BorderRadius.circular(defaultRadius)),
      child: Icon(icon, size: 18, color: primaryColor),
    );
  }
}

void showOnlyDropLocationsRiderDialog(BuildContext context, List<String> dropLocations) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          language.viewDropLocations,
          style: primaryTextStyle(size: 18, weight: FontWeight.w500),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: dropLocations.map((location) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(location, style: primaryTextStyle(size: 14), overflow: TextOverflow.ellipsis, maxLines: 2)),
                    ],
                  ),
                  Divider(
                    height: 10,
                  )
                ],
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              language.close,
              style: primaryTextStyle(),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}

String transPortStatusName({String? status}) {
  if (status == NEW_RIDE_REQUESTED) {
    status = language.newRideRequested;
  } else if (status == ACCEPTED || status == BID_ACCEPTED || status == ASSIGN_DRIVER) {
    status = language.accepted;
  } else if (status == ARRIVING) {
    status = language.arriving;
  } else if (status == ARRIVED) {
    status = language.arrived;
  } else if (status == IN_PROGRESS) {
    status = language.inProgress;
  } else if (status == CANCELED) {
    status = language.cancelled;
  } else if (status == COMPLETED) {
    status = language.completed;
  }
  return status!;
}

String orderStatus(String orderStatus) {
  if (orderStatus == ORDER_ASSIGNED) {
    return 'Assigned';
  } else if (orderStatus == ORDER_DRAFT) {
    return 'Draft';
  } else if (orderStatus == ORDER_CREATED) {
    return 'Created';
  } else if (orderStatus == ORDER_ACCEPTED) {
    return language.accepted;
  } else if (orderStatus == ORDER_PICKED_UP) {
    return 'Picked up';
  } else if (orderStatus == ORDER_ARRIVED) {
    return language.arrived;
  } else if (orderStatus == ORDER_DEPARTED) {
    return 'Departed';
  } else if (orderStatus == ORDER_DELIVERED) {
    return 'Delivered to:';
  } else if (orderStatus == ORDER_CANCELLED) {
    return language.cancelled;
  } else if (orderStatus == ORDER_SHIPPED) {
    return 'Shipped via';
  }
  return 'Assigned';
}

String buttonText(String status) {
  print("--------450>>>${status}");
  if (status == NEW_RIDE_REQUESTED) {
    return language.pending;
  } else if (status == ACCEPTED || status == BID_ACCEPTED || status == ASSIGN_DRIVER) {
    return language.accepted;
  } else if (status == IN_PROGRESS) {
    return language.endRide;
  } else if (status == CANCELED) {
    return language.cancelled;
  } else if (status == ARRIVING) {
    return language.arrived;
  } else if (status == ARRIVED) {
    return language.startRide;
  } else {
    return status;
  }
}

rideStatusDisplay({String? status}){
  if (status == NEW_RIDE_REQUESTED) {
    return language.pending;
  } else if (status == ACCEPTED || status == BID_ACCEPTED || status == ASSIGN_DRIVER) {
    return language.accepted;
  } else if (status == IN_PROGRESS) {
    return language.inProgress;
  } else if (status == CANCELED) {
    return language.cancelled;
  } else if (status == COMPLETED) {
    return language.completed;
  } else {
    return status;
  }
}

Future<void> commonLaunchUrl(String url, {bool forceWebView = false}) async {
  log(url);
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).then((value) {}).catchError((e) {
    toast('${"Invalid phone number"}: $url');
  });
}

Future<void> openMap(double originLatitude, double originLongitude, double destinationLatitude, double destinationLongitude) async {
  String googleUrl = 'https://www.google.com/maps/dir/?api=1&origin=$originLatitude,$originLongitude&destination=$destinationLatitude,$destinationLongitude';

  if (await canLaunchUrl(Uri.parse(googleUrl))) {
    await launchUrl(Uri.parse(googleUrl));
  } else {
    throw language.mapLoadingError;
  }
}

String getTripTypeValue(String val) {
  // 'regular','airport_pickup','airport_drop','zone_wise','zone_to_airport','airport_to_zone'
  if (val == tripTypeRegular) {
    return 'regular';
  } else if (val == tripTypeAirport) {
    // New simplified "Airport" option maps to airport_pickup for backend
    return 'airport_pickup';
  } else if (val == tripTypeAirportPickup) {
    return 'airport_pickup';
  } else if (val == tripTypeAirportDropoff) {
    return 'airport_drop';
  } else if (val == tripTypeZoneWise) {
    return 'zone_wise';
  } else if (val == tripTypeZoneToAirport) {
    return 'zone_to_airport';
  } else if (val == tripTypeAirportToZone) {
    return 'airport_to_zone';
  }
  return 'regular';
}

String getMultiLanguageTripType(String val) {
  // 'regular','airport_pickup','airport_drop','zone_wise','zone_to_airport','airport_to_zone'
  if (val == tripTypeRegular) {
    return language.regular;
  } else if (val == tripTypeAirport) {
    // New simplified "Airport" option
    return 'Airport';
  } else if (val == tripTypeAirportPickup) {
    return language.airPickup;
  } else if (val == tripTypeAirportDropoff) {
    return language.airDropOff;
  } else if (val == tripTypeZoneWise) {
    return language.zoneWise;
  } else if (val == tripTypeZoneToAirport) {
    return language.zoneToAir;
  } else if (val == tripTypeAirportToZone) {
    return language.airToZone;
  }
  return language.regular;
}

String paymentStatus(String paymentStatus) {
  if (paymentStatus.toLowerCase() == PAYMENT_PENDING.toLowerCase()) {
    return language.pending;
  } else if (paymentStatus.toLowerCase() == PAYMENT_FAILED.toLowerCase()) {
    return language.failed;
  } else if (paymentStatus == PAYMENT_PAID) {
    return language.paid;
  } else if (paymentStatus == CASH) {
    return language.cash;
  } else if (paymentStatus == WALLET) {
    return language.wallet;
  } else if (paymentStatus == ONLINE) {
    return language.lblOnline;
  }
  return language.pending;
}

String paymentType(String paymentType) {
  if (paymentType.toLowerCase() == "online".toLowerCase()) {
    return 'online';
  } else if (paymentType.toLowerCase() == "cash".toLowerCase()) {
    return language.cash;
  } else if (paymentType.toLowerCase() == "wallet".toLowerCase()) {
    return language.wallet;
  }
  return language.cash;
}

String changeStatusText(String? status) {
  if (status == COMPLETED) {
    return language.completed;
  } else if (status == CANCELED) {
    return language.cancelled;
  }
  return '';
}

String getMessageFromErrorCode(FirebaseException error) {
  switch (error.code) {
    case "ERROR_EMAIL_ALREADY_IN_USE":
    case "account-exists-with-different-credential":
    case "email-already-in-use":
      return "The email address is already in use by another account.";
    case "ERROR_WRONG_PASSWORD":
    case "wrong-password":
      return "Wrong email/password combination.";
    case "ERROR_USER_NOT_FOUND":
    case "user-not-found":
      return "No user found with this email.";
    case "ERROR_USER_DISABLED":
    case "user-disabled":
      return "User disabled.";
    case "ERROR_TOO_MANY_REQUESTS":
    case "operation-not-allowed":
      return "Too many requests to log into this account.";
    case "ERROR_OPERATION_NOT_ALLOWED":
    case "ERROR_INVALID_EMAIL":
    case "invalid-email":
      return "Email address is invalid.";
    default:
      return error.message.toString();
  }
}

String printAmount(var amount) {
  return appStore.currencyPosition == CURRENCY_POSITION_LEFT
      ? '${appStore.currencyCode} ${amount.toStringAsFixed(digitAfterDecimal)}'
      : '${amount.toStringAsFixed(digitAfterDecimal)} ${appStore.currencyCode}';
}

Widget socialWidget({String? image, String? text}) {
  return Image.asset(image.validate(), fit: BoxFit.cover, height: 30, width: 30);
}

void scheduleFunction({required DateTime scheduledTime, required Function function}) {
  var d1 = DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", ""));
  Duration delay = scheduledTime.difference(d1);
  print("CheckDelay:::${delay.inSeconds}");
  if (delay.isNegative) {
    print("Scheduled time is in the past.");
    return;
  }
  Timer(delay, () {
    function();
  });
  print("Function scheduled to run at $scheduledTime");
}

oneSignalSettings() async {
  if (Platform.isAndroid) {
    await Permission.notification.request();
  } else {
    await OneSignal.Notifications.requestPermission(true);
  }
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Debug.setAlertLevel(OSLogLevel.none);
  OneSignal.consentRequired(false);

  OneSignal.initialize(mOneSignalAppIdRider);

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    event.preventDefault();
    event.notification.display();
  });

  saveOneSignalPlayerId();
  if (appStore.isLoggedIn) {
    updatePlayerId();
  }
  OneSignal.Notifications.addClickListener((notification) async {
    var notId = notification.notification.additionalData!["id"];
    log("$notId---" + notification.notification.additionalData!['type'].toString());
    var notType = notification.notification.additionalData!['type'];
    if (notId != null) {
      if (notId.toString().contains('CHAT')) {
        LoginResponse user = await getUserDetail(userId: int.parse(notId.toString().replaceAll("CHAT_", "")));
        launchScreen(
            getContext,
            ChatScreen(
              userData: user.data,
              ride_id: -1,
            ),
            isNewTask: true);
      } else if (notType == SUCCESS) {
        launchScreen(getContext, RideDetailScreen(orderId: notId), isNewTask: true);
      }
    }
  });
}

Future<void> saveOneSignalPlayerId() async {
  // Get the player ID immediately if already available
  String? playerId = OneSignal.User.pushSubscription.id;
  if (playerId != null && playerId.isNotEmpty) {
    await sharedPref.setString(PLAYER_ID, playerId);
    print("OneSignal Player ID saved immediately: $playerId");
    if (appStore.isLoggedIn) {
      updatePlayerId();
    }
  }

  // Also add observer for future changes
  OneSignal.User.pushSubscription.addObserver((state) async {
    String? newPlayerId = OneSignal.User.pushSubscription.id;
    if (newPlayerId != null && newPlayerId.isNotEmpty) {
      await sharedPref.setString(PLAYER_ID, newPlayerId);
      print("OneSignal Player ID updated via observer: $newPlayerId");
      if (appStore.isLoggedIn) {
        updatePlayerId();
      }
    }
  });
}

Color paymentStatusColor(String paymentStatus) {
  Color color = textPrimaryColor;

  switch (paymentStatus) {
    case PAYMENT_PAID:
      color = Colors.green;
    case PAYMENT_FAILED:
      color = Colors.red;
    case PAYMENT_PENDING:
      color = Colors.grey;
  }
  return color;
}

Future<void> getAppSettingsData() async {
  await getAppSetting().then((value) {
    sharedPref.setString("reference_amount", value.reference_amount ?? "0");
    sharedPref.setString("reference_type", value.reference_type ?? "fixed");
    sharedPref.setString("maxEarningPerMonth", value.maxEarningPerMonth ?? "0");
    if (value.walletSetting != null) {
      value.walletSetting!.forEach((element) {
        if (element.key == PRESENT_TOPUP_AMOUNT) {
          appStore.setWalletPresetTopUpAmount(element.value ?? PRESENT_TOP_UP_AMOUNT_CONST);
        }
        if (element.key == MIN_AMOUNT_TO_ADD) {
          if (element.value != null) appStore.setMinAmountToAdd(num.parse(element.value!).round());
        }
        if (element.key == MAX_AMOUNT_TO_ADD) {
          if (element.value != null) appStore.setMaxAmountToAdd(num.parse(element.value!).round());
        }
      });
    }

    if (value.rideSetting != null) {
      value.rideSetting!.forEach((element) {
        if (element.key == PRESENT_TIP_AMOUNT) {
          appStore.setWalletTipAmount(element.value ?? PRESENT_TIP_AMOUNT_CONST);
        }
        if (element.key == RIDE_FOR_OTHER) {
          appStore.setIsRiderForAnother(element.value ?? "0");
        }
        if (element.key == IS_MULTI_DROP) {
          appStore.setisMultiDrop(element.value ?? "0");
        }
        if (element.key == RIDE_IS_SCHEDULE_RIDE) {
          appStore.setisScheduleRide(element.value ?? "0");
        }
        if (element.key == ACTIVE_SERVICES) {
          // book_ride ,transport or both
          appStore.setActiveServices(element.value ?? BOTH);
        }
        if (element.key == IS_BID_ENABLE) {
          appStore.setisBidEnable(element.value ?? "0");
        }
        // isBidEnable
        if (element.key == MAX_TIME_FOR_RIDER_MINUTE) {
          appStore.setRiderMinutes(element.value ?? '4');
        }
      });
    }
    if (value.currencySetting != null) {
      appStore.setCurrencyCode(value.currencySetting!.symbol ?? currencySymbol);
      appStore.setCurrencyName(value.currencySetting!.code ?? currencyNameConst);
      appStore.setCurrencyPosition(value.currencySetting!.position ?? LEFT);
    }
    if (value.settingModel != null) {
      appStore.settingModel = value.settingModel!;
      if (value.settingModel!.helpSupportUrl != null) appStore.mHelpAndSupport = value.settingModel!.helpSupportUrl!;
    }
    if (value.privacyPolicyModel != null && value.privacyPolicyModel!.value != null) appStore.privacyPolicy = value.privacyPolicyModel!.value!;
    if (value.termsCondition != null && value.termsCondition!.value != null) appStore.termsCondition = value.termsCondition!.value!;
  }).catchError((error, stack) {
    log('${error.toString()} STack:::${stack}');
  });
}
