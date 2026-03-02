import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_booking/utils/Extensions/context_extension.dart';

import '../../main.dart';
import '../../model/CurrentRequestModel.dart';
import '../../model/OrderHistory.dart';
import '../../model/RiderModel.dart';
import '../../network/RestApis.dart';
import '../../screens/RideHistoryScreen.dart';
import '../../utils/Colors.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../components/RideAcceptWidget.dart';
import '../model/FRideBookingModel.dart';
import '../service/RideService.dart';
import '../utils/Common.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'DashBoardScreen.dart';
import 'PaymentScreen.dart';
// ignore: must_be_immutable
class RidePaymentDetailScreen extends StatefulWidget {
  final int? rideId;
  bool? schedule_flow;
  RidePaymentDetailScreen({this.rideId,this.schedule_flow});

  @override
  RidePaymentDetailScreenState createState() => RidePaymentDetailScreenState();
}

class RidePaymentDetailScreenState extends State<RidePaymentDetailScreen> {
  List<RideHistory> rideHistory = [];
  RideService rideService = RideService();
  // CurrentRequestModel? currentData;
  bool isCashPayment = true;
  bool isShow = false;
  bool currentScreen = true;
  bool navigateDone = false;
  RiderModel? riderModel;
  Payment? paymentData;
  bool isPaymentDone = false;
  bool paymentPressed = false;
  num? balance;
  num? requiredAmount;
  num? payableAmount;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if(widget.schedule_flow==true){
      await orderDetailApi();
    }else{
      getCurrentRide();
    }
  }

  getCurrentRide() async {
    Future.delayed(
      Duration.zero,
      () {
        appStore.setLoading(true);
        getCurrentRideRequest().then((value) async {
          appStore.setLoading(false);
          // currentData = value;
          await orderDetailApi();
          setState(() {});
        }).catchError((error, s) {
          appStore.setLoading(false);
          print("ERROR:::$error =>$s");
          log(error.toString());
        });
      },
    );
  }

  Future<void> savePaymentApi() async {
    if (paymentPressed == true) return;
    paymentPressed = true;
    appStore.setLoading(true);
    Map req = {
      "id": paymentData!.id,
      "rider_id": paymentData!.riderId,
      "ride_request_id": paymentData!.rideRequestId,
      "datetime": DateTime.now().toString(),
      "total_amount": riderModel!.totalAmount,
      "payment_type": WALLET,
      "txn_id": "",
      "payment_status": PAID,
      "transaction_detail": ""
    };
    await savePayment(req).then((value) async {
      appStore.setLoading(false);
      await rideService.updateStatusOfRide(rideID: paymentData!.rideRequestId, req: {
        "on_stream_api_call": 0, /*"payment_status": PAID*/
      });
      orderDetailApi();
      paymentPressed = false;
    }).catchError((error) {
      paymentPressed = false;
      isShow = true;
      setState(() {});
      appStore.setLoading(false);
      log(error.toString());
      toast(error.toString());
      getWalletList(page: 1).then((value) {
        appStore.setLoading(false);
        if (value.walletBalance != null) balance = value.walletBalance!.totalAmount!;
        payableAmount = paymentData!.totalAmount!;
        requiredAmount = payableAmount! - balance!;
        requiredAmount = requiredAmount! + 1;
        setState(() {});
      }).catchError((error) {
        appStore.setLoading(false);
        log(error.toString());
      });
    });
  }

  Future<void> saveOnlinePaymentApi() async {
    if (paymentPressed == true) return;
    paymentPressed = true;
    appStore.setLoading(true);
    Map req = {
      "id": paymentData!.id,
      "rider_id": paymentData!.riderId,
      "ride_request_id": paymentData!.rideRequestId,
      "datetime": DateTime.now().toString(),
      "total_amount": riderModel!.totalAmount,
      "payment_type": ONLINE,
      "txn_id": "",
      "payment_status": PAID,
      "transaction_detail": ""
    };
    await savePayment(req).then((value) async {
      appStore.setLoading(false);
      await rideService.updateStatusOfRide(rideID: paymentData!.rideRequestId, req: {
        "on_stream_api_call": 0, /*"payment_status": PAID*/
      });
      orderDetailApi();
      paymentPressed = false;
    }).catchError((error) {
      paymentPressed = false;
      isShow = true;
      setState(() {});
      appStore.setLoading(false);
      log(error.toString());
      toast(error.toString());
      getWalletList(page: 1).then((value) {
        appStore.setLoading(false);
        if (value.walletBalance != null) balance = value.walletBalance!.totalAmount!;
        payableAmount = paymentData!.totalAmount!;
        requiredAmount = payableAmount! - balance!;
        requiredAmount = requiredAmount! + 1;
        setState(() {});
      }).catchError((error) {
        appStore.setLoading(false);
        log(error.toString());
      });
    });
  }

  Future<void> rideRequest() async {
    appStore.setLoading(true);
    Map req = {
      "payment_type": isCashPayment ? CASH : WALLET,
      "is_change_payment_type": 1,
    };
    log(req);
    await rideRequestUpdate(request: req, rideId: paymentData!.rideRequestId).then((value) async {
      await rideService.updateStatusOfRide(rideID: paymentData!.rideRequestId, req: {
        /*"tips": 1,*/ "on_stream_api_call": 0,
        "payment_type": isCashPayment ? CASH : WALLET,
      });
      appStore.setLoading(false);
      init();
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> orderDetailApi() async {
    await rideDetail(orderId: widget.rideId).then((value) {
      riderModel = value.data;
      if (value.ride_has_bids != null) {
        riderModel!.ride_has_bids = value.ride_has_bids;
      }
      if (value.payment != null) {
        paymentData = value.payment;
      }
      rideHistory = value.rideHistory!;
      setState(() {});
      if (paymentData != null && paymentData!.paymentStatus == "paid") {
        isPaymentDone = true;
        if (navigateDone == true) return;
        navigateDone = true;
        Future.delayed(
          Duration(seconds: 3),
          () {
            launchScreen(getContext, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            isPaymentDone = false;
          },
        );
      }
    }).catchError((error, s) {
      print("CheckError:::$error ::::$s");
      toast(error.toString());
      appStore.setLoading(false);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(language.detailScreen, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: StreamBuilder(
          stream: rideService.fetchRide(rideId: widget.rideId),
          builder: (context, snap) {
            if (snap.hasData) {
              List<FRideBookingModel> data = [];
              try {
                data = snap.data!.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
              } catch (e) {
                data = [];
              }
              if (data.length == 0) {
                Future.delayed(
                  Duration(seconds: 2),
                  () {
                    if (currentScreen == false) return;
                    currentScreen = false;
                    orderDetailApi();
                  },
                );
              }
              if (data.isNotEmpty && data[0].paymentStatus.toString() == PAID && data[0].status.toString() == COMPLETED) {
                Future.delayed(
                  Duration(seconds: 1),
                  () {
                    isPaymentDone = false;
                    if (currentScreen == false) return;
                    currentScreen = false;
                    orderDetailApi();
                  },
                );
              }

              return Stack(
                children: [
                  // currentData != null
              paymentData!=null
                      ? SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              addressComponent(),
                              SizedBox(height: 12),
                              paymentDetailWidget(),
                              SizedBox(height: 12),
                              priceDetailWidget(),
                              SizedBox(height: 12),
                              if (paymentData != null && paymentData!.paymentStatus != COMPLETED && isShow)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(language.payment, style: boldTextStyle()),
                                    SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(14)),
                                      padding: EdgeInsets.all(6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: inkWellWidget(
                                                onTap: () {
                                                  isCashPayment = true;
                                                  setState(() {});
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: isCashPayment ? primaryColor : null,
                                                      boxShadow: isCashPayment ? [BoxShadow(color: Colors.grey.shade400, spreadRadius: 1, blurRadius: 1)] : [],
                                                      borderRadius: BorderRadius.circular(12)),
                                                  padding: EdgeInsets.all(12),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      ImageIcon(AssetImage(icCash), size: 20, color: isCashPayment ? Colors.white : Colors.grey),
                                                      SizedBox(
                                                        width: 8,
                                                      ),
                                                      Text(
                                                        language.cash,
                                                        style: boldTextStyle(color: isCashPayment ? Colors.white : Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: inkWellWidget(
                                                onTap: () {
                                                  isCashPayment = false;
                                                  setState(() {});
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: isCashPayment == false ? primaryColor : null,
                                                      boxShadow: isCashPayment == false ? [BoxShadow(color: Colors.grey.shade400, spreadRadius: 1, blurRadius: 1)] : [],
                                                      borderRadius: BorderRadius.circular(12)),
                                                  padding: EdgeInsets.all(12),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      ImageIcon(AssetImage(icCard), size: 20, color: isCashPayment == false ? Colors.white : Colors.grey),
                                                      SizedBox(
                                                        width: 8,
                                                      ),
                                                      Text(
                                                        language.addMoney,
                                                        style: boldTextStyle(color: isCashPayment == false ? Colors.white : Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text("${language.note} ", style: secondaryTextStyle(color: Colors.red, size: 14, weight: FontWeight.bold)),
                                        Expanded(
                                            child: Text(
                                          isCashPayment
                                              ? "${riderModel!.tips != null && payableAmount != null ? riderModel!.tips! + payableAmount! : payableAmount}${appStore.currencyCode} - ${language.fullCashPayment}"
                                              : "+$requiredAmount${appStore.currencyCode} ${language.moreMoneyForWalletPayment}",
                                          style: secondaryTextStyle(color: Colors.red, size: 12, weight: FontWeight.bold),
                                          maxLines: 1,
                                        )),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    AppButtonWidget(
                                      width: context.width(),
                                      text: isCashPayment == true ? language.updatePaymentStatus : language.continueD,
                                      textStyle: boldTextStyle(color: Colors.white),
                                      color: primaryColor,
                                      onTap: () async {
                                        if (isCashPayment == false) {
                                          appStore.setLoading(true);
                                          bool res = await launchScreen(context, PaymentScreen(amount: requiredAmount), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                          if (res == true) {
                                            await getWalletList(page: 1).then((value) {
                                              appStore.setLoading(false);
                                              if (value.walletBalance != null) balance = value.walletBalance!.totalAmount!;
                                              payableAmount = paymentData!.totalAmount!;
                                              requiredAmount = payableAmount! - balance!;
                                              requiredAmount = requiredAmount! + 1;
                                              setState(() {});
                                              isShow = false;
                                              rideRequest();
                                            }).catchError((error) {
                                              appStore.setLoading(false);
                                              log(error.toString());
                                            });
                                          } else {
                                            toast("Add MONEY");
                                          }
                                        } else {
                                          isShow = false;
                                          rideRequest();
                                        }
                                      },
                                    )
                                  ],
                                ),
                              SizedBox(height: 8),
                            ],
                          ),
                        )
                      : Observer(builder: (context) {
                          return Visibility(
                            visible: appStore.isLoading,
                            child: loaderWidget(),
                          );
                        }),
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
                  Observer(builder: (context) {
                    return Visibility(
                      visible: appStore.isLoading,
                      child: loaderWidget(),
                    );
                  })
                ],
              );
            } else {
              return SizedBox();
            }
          }),
      bottomNavigationBar: /*currentData != null && */paymentData != null && isShow == false
          ? Padding(
              padding: EdgeInsets.all(16),
              child: AppButtonWidget(
                text: getButtonText(),
                width: MediaQuery.of(context).size.width,
                onTap: () async {
                  if (paymentData!.paymentStatus == COMPLETED) {
                    orderDetailApi();
                  } else if (paymentData!.paymentStatus != COMPLETED && paymentData!.paymentType == CASH) {
                    toast(language.waitingForDriverConformation);
                  } else if (paymentData!.paymentStatus != COMPLETED && paymentData!.paymentType == WALLET) {
                    savePaymentApi();
                  } else if (paymentData!.paymentStatus != COMPLETED && paymentData!.paymentType == ONLINE) {
                    bool? res = await launchScreen(context, PaymentScreen(amount: num.parse(paymentData?.totalAmount.toString() ?? ''), flow: 'online'),
                        pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                    if (res != null && res == true) {
                      saveOnlinePaymentApi();
                    }
                  }
                },
              ),
            )
          : SizedBox(),
    );
  }

  String? getButtonText() {
    if (paymentData!.paymentStatus == COMPLETED) {
      return language.continueNewRide;
    } else if (paymentData!.paymentStatus != COMPLETED && paymentData!.paymentType == CASH) {
      return language.waitingForDriverConformation;
    } else if (paymentData!.paymentStatus != COMPLETED && paymentData!.paymentType == WALLET) {
      return language.payToPayment;
    } else if (paymentData!.paymentStatus != COMPLETED && paymentData!.paymentType == ONLINE) {
      return language.payToPayment;
    }
    return '';
  }

  Widget addressComponent() {
    if (riderModel == null) {
      return SizedBox();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: dividerColor.withValues(alpha: 0.5).withValues(alpha: 0.5)),
        borderRadius: radius(),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Ionicons.calendar, color: textSecondaryColorGlobal, size: 16),
                  SizedBox(width: 4),
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('${printDate(riderModel!.createdAt.validate())}', style: primaryTextStyle(size: 14)),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(language.rideId, style: boldTextStyle(size: 16)),
                  SizedBox(width: 8),
                  Text('#${riderModel!.id}', style: boldTextStyle(size: 16)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('${language.lblDistance} ${riderModel!.distance!.toStringAsFixed(2)} ${riderModel!.distanceUnit.toString()}', style: boldTextStyle(size: 14)),
          SizedBox(height: 12),
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
              if (riderModel!.multiDropLocation != null && riderModel!.multiDropLocation!.isNotEmpty)
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
              if (riderModel!.multiDropLocation != null && riderModel!.multiDropLocation!.isNotEmpty)
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
                    showOnlyDropLocationsDialog(
                        context,
                        riderModel!.multiDropLocation!
                            .map(
                              (e) => e.address,
                            )
                            .toList());
                  },
                )
            ],
          ),
          SizedBox(height: 12),
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

  Widget paymentDetailWidget() {
    if (riderModel == null) {
      return SizedBox();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: dividerColor.withValues(alpha: 0.5).withValues(alpha: 0.5)),
        borderRadius: radius(),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.paymentDetails, style: boldTextStyle(size: 16)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.via, style: primaryTextStyle()),
              Text(paymentStatus(riderModel!.paymentType.validate()), style: boldTextStyle()),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.status, style: primaryTextStyle()),
              Text(paymentStatus(riderModel!.paymentStatus.validate()), style: boldTextStyle(color: paymentStatusColor(riderModel!.paymentStatus.validate()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget priceDetailWidget() {
    if (riderModel == null) {
      return SizedBox();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: dividerColor.withValues(alpha: 0.5).withValues(alpha: 0.5)),
        borderRadius: radius(),
      ),
      padding: EdgeInsets.all(16),
      child: riderModel!.ride_has_bids == 1
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.priceDetail, style: boldTextStyle(size: 16)),
                SizedBox(height: 12),
                totalCount(title: language.amount, amount: riderModel!.totalAmount, space: 8),
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
                if (riderModel!.tips != null) totalCount(title: language.tip, amount: riderModel!.tips),
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
                    ? totalCount(title: language.minimumFare, amount: riderModel!.minimumFare)
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
                if (riderModel!.tips != null) totalCount(title: language.tip, amount: riderModel!.tips),
                if (riderModel!.tips != null) SizedBox(height: 8),
                if (riderModel!.extraCharges!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.additionalFees, style: boldTextStyle()),
                      SizedBox(height: 8),
                      ...riderModel!.extraCharges!.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 4),
                          child: totalCount(title: e.key.validate(), amount: e.value),
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
}
