import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/AppButtonWidget.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/context_extensions.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Services/RideService.dart';
import '../model/CurrentRequestModel.dart';
import '../model/FRideBookingModel.dart';
import '../model/RideHistory.dart';
import '../model/RiderModel.dart';
import '../network/RestApis.dart';
import '../utils/Common.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Images.dart';
import 'DashboardScreen.dart';
import 'RideHistoryScreen.dart';

// ignore: must_be_immutable
class DetailScreen extends StatefulWidget {
  int? rideId;
  DetailScreen({this.rideId,});
  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> {
  RideService rideService = RideService();

  // CurrentRequestModel? currentData;
  RiderModel? riderModel;
  Payment? payment;
  List<RideHistory> rideHistory = [];
  bool isPaymentDone = false;
  bool paymentSuccessShown = false;
  bool currentScreen = true;
  bool paymentPressed = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if(widget.rideId!=null){
      orderDetailApi();
    }else{
      currentRideRequest();
    }
  }

  Future<void> currentRideRequest() async {
    appStore.setLoading(true);
    await getCurrentRideRequest().then((value) async {
      appStore.setLoading(false);
      widget.rideId=value.payment?.rideRequestId;
      payment=value.payment;
      await orderDetailApi();
    }).catchError((error, s) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> savePaymentApi() async {
    if (paymentPressed == true) return;
    paymentPressed = true;
    appStore.setLoading(true);
    Map req = {
      "id": payment!.id,
      "rider_id": payment!.riderId,
      "ride_request_id": payment!.rideRequestId,
      "datetime": DateTime.now().toString(),
      "total_amount": riderModel!.totalAmount,
      "payment_type": payment!.paymentType,
      "txn_id": "",
      "payment_status": PAYMENT_PAID,
      "transaction_detail": ""
    };
    log('Payment req---' + req.toString());
    await savePayment(req).then((value) async {
      appStore.setLoading(false);
      orderDetailApi();
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> orderDetailApi() async {
    appStore.setLoading(true);
    var rideIDVal= payment != null ? payment!.rideRequestId : widget.rideId;
    if(rideIDVal==null)return;
   try{
     rideDetail(rideId: rideIDVal).then((value) {
       appStore.setLoading(false);
       riderModel = value.data;
       if (value.ride_has_bids != null) {
         riderModel!.ride_has_bids = value.ride_has_bids;
       }
       if (value.payment != null) {
         payment = value.payment!;
       }
       // if (currentData!.payment == null) {
       //   currentData!.payment = value.payment;
       // }
       rideHistory = value.rideHistory??[];
       setState(() {});
       if (paymentSuccessShown == false && payment != null && payment!.paymentStatus == "paid") {
         if (isPaymentDone != true) {
           isPaymentDone = true;
           paymentSuccessShown = true;
           Future.delayed(
             Duration(seconds: 3),
                 () {
               launchScreen(context, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
               isPaymentDone = false;
             },
           );
         }
       }
     }).catchError((error, s) {
       print("Exception:$error===>$s");
       appStore.setLoading(false);
       log('${error.toString()}::::$s');
     });
   }catch(e,s){
     print("SpecialCase6.1::::${e}=++>$s");
   }

  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.detailScreen, style: boldTextStyle(color: Colors.white)),
      ),
      body: StreamBuilder(
          stream: rideService.fetchRide(userId: sharedPref.getInt(USER_ID)),
          builder: (context, snap) {
            if (snap.hasData) {
              if (snap.data != null && snap.data!.size == 0) {
                Future.delayed(
                  Duration(seconds: 2),
                  () {
                    if (currentScreen == false) return;
                    currentScreen = false;
                    orderDetailApi();
                  },
                );
              }

              List<FRideBookingModel> data = snap.data!.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
              data = data.where((e) => e.status == COMPLETED).toList().where((element) => element.rideId==widget.rideId,).toList();
              if(!data.map((e) => e.rideId,).toList().contains(widget.rideId)){
                orderDetailApi();
              }
              if (data.isEmpty) {
                Future.delayed(
                  Duration(seconds: 2),
                  () {
                    if (currentScreen == false) return;
                    currentScreen = false;
                    orderDetailApi();
                  },
                );
              }
              if (data.length != 0) {
                if (data[0].paymentType == CASH && /*currentData != null &&*/ payment != null && payment!.paymentType != CASH) {
                  payment!.paymentType = CASH;
                  currentRideRequest();
                }
                if (data[0].tips == 1 && data[0].onStreamApiCall == 0) {
                  rideService.updateStatusOfRide(rideID: data[0].rideId, req: {"on_stream_api_call": 1});
                  currentRideRequest();
                }
                if (data[0].paymentStatus == PAYMENT_PAID && data[0].status == COMPLETED) {
                  if (isPaymentDone != true) {
                    isPaymentDone = true;
                    paymentSuccessShown = true;
                    Future.delayed(
                      Duration(seconds: 3),
                      () {
                        isPaymentDone = false;
                        launchScreen(context, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                      },
                    );
                  }
                }
              }
              return /*currentData != null &&*/ riderModel != null
                  ? Stack(
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              addressComponent(),
                              if (riderModel!.otherRiderData != null) SizedBox(height: 12),
                              if (riderModel!.otherRiderData != null) riderDataComponent(),
                              SizedBox(height: 12),
                              paymentDetail(),
                              SizedBox(height: 12),
                              priceWidget(),
                            ],
                          ),
                        ),
                        Visibility(
                            visible: isPaymentDone,
                            child: Center(
                              child: Container(
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
                            )),
                      ],
                    )
                  : Observer(builder: (context) {
                      return Visibility(
                        visible: appStore.isLoading,
                        child: loaderWidget(),
                      );
                    });
            } else {
              return SizedBox();
            }
          }),
      bottomNavigationBar:/* currentData != null &&*/ payment != null
          ? Padding(
              padding: EdgeInsets.all(16),
              child: payment!.paymentType == CASH
                  ? AppButtonWidget(
                      text: language.cashCollected,
                      onTap: () {
                        showConfirmDialogCustom(
                            primaryColor: primaryColor,
                            positiveText: language.yes,
                            negativeText: language.no,
                            dialogType: DialogType.CONFIRMATION,
                            title: language.areYouSureCollectThisPayment,
                            context, onAccept: (v) {
                          savePaymentApi();
                        });
                      },
                    )
                  : AppButtonWidget(
                      text: language.waitingForDriverConformation,
                      textStyle: boldTextStyle(color: Colors.white, size: 12),
                      onTap: () {
                        if (payment!.paymentStatus == COMPLETED) {
                          orderDetailApi();
                        } else {
                          toast(language.waitingForDriverConformation);
                        }
                      },
                    ),
            )
          : SizedBox(),
    );
  }

  Widget addressComponent() {
    return Container(
      decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: dividerColor.withValues(alpha: 0.5)), borderRadius: radius()),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Ionicons.calendar, color: textSecondaryColorGlobal, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          '${printDate(riderModel!.createdAt.validate())}',
                          style: primaryTextStyle(size: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Row(
                children: [
                  Text(language.rideId, style: boldTextStyle(size: 16)),
                  SizedBox(width: 8),
                  Text('#${riderModel!.id}', style: boldTextStyle(size: 16)),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          riderModel!.distance != null
              ? Text('${language.distance}: ${riderModel!.distance!.toStringAsFixed(2)} ${riderModel!.distanceUnit.toString()}', style: boldTextStyle(size: 14))
              : Text('${language.distance}: -- ${riderModel!.distanceUnit.toString()}', style: boldTextStyle(size: 14)),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.near_me, color: Colors.green, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.startTime != null) Text(riderModel!.startTime != null ? printDate(riderModel!.startTime!) : '', style: secondaryTextStyle(size: 12)),
                        if (riderModel!.startTime != null) SizedBox(height: 4),
                        Text(riderModel!.startAddress.validate(), style: primaryTextStyle(size: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 10),
                  SizedBox(
                    height: 30,
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
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.endTime != null) Text(riderModel!.endTime != null ? printDate(riderModel!.endTime!) : '', style: secondaryTextStyle(size: 12)),
                        if (riderModel!.endTime != null) SizedBox(height: 4),
                        Text(riderModel!.endAddress.validate(), style: primaryTextStyle(size: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              if (riderModel != null && riderModel!.multiDropLocation != null && riderModel!.multiDropLocation!.isNotEmpty)
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
              if (riderModel != null && riderModel!.multiDropLocation != null && riderModel!.multiDropLocation!.isNotEmpty)
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
                    showOnlyDropLocationsDialog(context: context, multiDropData: riderModel!.multiDropLocation!);
                  },
                )
            ],
          ),
          SizedBox(height: 16),
          inkWellWidget(
            onTap: () {
              launchScreen(context, RideHistoryScreen(rideHistory: rideHistory), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.viewHistory, style: secondaryTextStyle()),
                Icon(Entypo.chevron_right, color: dividerColor, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget chargesWidget({String? name, String? amount}) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name!, style: primaryTextStyle()),
          Text(amount!, style: primaryTextStyle()),
        ],
      ),
    );
  }

  Widget paymentDetail() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: dividerColor.withValues(alpha: 0.5).withValues(alpha: 0.5)),
        borderRadius: radius(),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.paymentDetails, style: boldTextStyle(size: 16)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.via, style: secondaryTextStyle()),
              Text(riderModel!.paymentType.validate(), style: boldTextStyle()),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.status, style: secondaryTextStyle()),
              Text(paymentStatus(riderModel!.paymentStatus.validate()), style: boldTextStyle(color: paymentStatusColor(riderModel!.paymentStatus.validate()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget priceWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: dividerColor.withValues(alpha: 0.5).withValues(alpha: 0.5)),
        borderRadius: radius(),
      ),
      padding: EdgeInsets.all(12),
      child: riderModel!.ride_has_bids == 1
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.priceDetail, style: boldTextStyle(size: 16)),
                SizedBox(height: 12),
                totalCount(
                  title: language.amount,
                  amount: riderModel!.subtotal!,
                ),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.couponDiscount, style: secondaryTextStyle()),
                      Row(
                        children: [
                          Text("-", style: boldTextStyle(color: Colors.green, size: 14)),
                          printAmountWidget(amount: '${riderModel!.couponDiscount!.toStringAsFixed(digitAfterDecimal)}', color: Colors.green, size: 14, weight: FontWeight.normal)
                        ],
                      ),
                    ],
                  ),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0) SizedBox(height: 8),
                if (riderModel!.tips != null) totalCount(title: language.tips, amount: riderModel!.tips),
                if (riderModel!.extraCharges!.isNotEmpty)
                  SizedBox(
                    height: 8,
                  ),
                if (riderModel!.extraCharges!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.additionalFees, style: boldTextStyle()),
                      ...riderModel!.extraCharges!.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text(e.key.validate().capitalizeFirstLetter(), style: secondaryTextStyle()), printAmountWidget(amount: e.value!.toStringAsFixed(digitAfterDecimal), size: 14)],
                          ),
                        );
                      }).toList()
                    ],
                  ),
                Divider(height: 16, thickness: 1),
                riderModel!.tips != null
                    ? totalCount(title: language.total, amount: riderModel!.totalAmount! + riderModel!.tips!, isTotal: true)
                    : totalCount(title: language.total, amount: riderModel!.totalAmount, isTotal: true),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.priceDetail, style: boldTextStyle(size: 16)),
                SizedBox(height: 12),
                riderModel!.subtotal! <= riderModel!.minimumFare!
                    ? totalCount(title: language.minimumFees, amount: riderModel!.minimumFare)
                    : Column(
                        children: [
                          totalCount(title: language.basePrice, amount: riderModel!.baseFare, space: 8),
                          totalCount(title: language.distancePrice, amount: riderModel!.perDistanceCharge, space: 8),
                          totalCount(
                              title: language.minutePrice,
                              amount: riderModel!.perMinuteDriveCharge,
                              space: riderModel!.perMinuteWaitingCharge != 0
                                  ? 8
                                  : riderModel!.surgeCharge != 0
                                      ? 8
                                      : 0),
                          totalCount(title: language.waitingTimePrice, amount: riderModel!.perMinuteWaitingCharge, space: riderModel!.surgeCharge != 0 ? 8 : 0),
                        ],
                      ),
                if (riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0) totalCount(title: language.fixedPrice, amount: riderModel!.surgeCharge, space: 0),
                SizedBox(height: 8),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.couponDiscount, style: secondaryTextStyle()),
                      Row(
                        children: [
                          Text("-", style: boldTextStyle(color: Colors.green, size: 14)),
                          printAmountWidget(amount: '${riderModel!.couponDiscount!.toStringAsFixed(digitAfterDecimal)}', color: Colors.green, size: 14, weight: FontWeight.normal)
                        ],
                      ),
                    ],
                  ),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0) SizedBox(height: 8),
                if (riderModel!.tips != null) totalCount(title: language.tips, amount: riderModel!.tips),
                if (riderModel!.tips != null) SizedBox(height: 8),
                if (riderModel!.extraCharges!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.additionalFees, style: boldTextStyle()),
                      ...riderModel!.extraCharges!.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text(e.key.validate().capitalizeFirstLetter(), style: secondaryTextStyle()), printAmountWidget(amount: e.value!.toStringAsFixed(digitAfterDecimal), size: 14)],
                          ),
                        );
                      }).toList()
                    ],
                  ),
                Divider(height: 16, thickness: 1),
                riderModel!.tips != null
                    ? totalCount(title: language.total, amount: riderModel!.totalAmount! + riderModel!.tips!, isTotal: true)
                    : totalCount(title: language.total, amount: riderModel!.totalAmount, isTotal: true),
              ],
            ),
    );
  }

  Widget riderDataComponent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: dividerColor.withValues(alpha: 0.5).withValues(alpha: 0.5)),
            borderRadius: radius(),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(language.riderInformation.capitalizeFirstLetter(), style: boldTextStyle()),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Ionicons.person_outline, size: 18),
                  SizedBox(width: 8),
                  Text(riderModel!.otherRiderData!.name.validate(), style: primaryTextStyle()),
                ],
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: () {
                  launchUrl(Uri.parse('tel:${riderModel!.otherRiderData!.conatctNumber.validate()}'), mode: LaunchMode.externalApplication);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Icon(Icons.call_sharp, size: 18, color: Colors.green), SizedBox(width: 8), Text(riderModel!.otherRiderData!.conatctNumber.validate(), style: primaryTextStyle())],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
