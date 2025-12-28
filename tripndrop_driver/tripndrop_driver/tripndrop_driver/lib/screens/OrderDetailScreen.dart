import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/model/ExtraChargeRequestModel.dart';
import 'package:taxi_driver/model/MyOrderResponse.dart';
import 'package:taxi_driver/screens/RideHistoryScreen.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/ResponsiveWidget.dart';
import 'package:taxi_driver/utils/Extensions/animatedList/animated_scroll_view.dart';
import 'package:taxi_driver/utils/Extensions/app_button.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_driver/utils/Extensions/decorations.dart';
import 'package:taxi_driver/utils/Extensions/int_extensions.dart';
import 'package:taxi_driver/utils/Images.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/RideHistory.dart';

class OrderDetailScreen extends StatefulWidget {
  final MyOrderData? orderData;

  OrderDetailScreen({required this.orderData});

  @override
  OrderDetailScreenState createState() => OrderDetailScreenState();
}

class OrderDetailScreenState extends State<OrderDetailScreen> {
  TextEditingController proofTitleTextEditingController = TextEditingController();
  TextEditingController proofDetailsTextEditingController = TextEditingController();
  List<RideHistory>? orderHistory;
  List<ExtraChargeRequestModel> list = [];
  String? formattedDate;
  String? formattedTime;

  @override
  void initState() {
    super.initState();
    final utcDateTime = DateTime.parse("${widget.orderData?.datetime}");

    final istDateTime = utcDateTime.toLocal().add(Duration(hours: 5, minutes: 30));
    formattedDate = DateFormat('dd MMM yyyy').format(istDateTime);
    formattedTime = DateFormat('hh:mm a').format(istDateTime);
  }

  orderDetailApiCall() async {
    appStore.setLoading(true);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${language.order} #${widget.orderData?.id}', style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Stack(
        children: [
          widget.orderData != null
              ? Stack(
                  children: [
                    AnimatedScrollView(
                      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: boxDecorationWithRoundedCorners(
                                  borderRadius: BorderRadius.circular(defaultRadius), border: Border.all(color: primaryColor.withValues(alpha: 0.3)), backgroundColor: Colors.transparent),
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('#${widget.orderData?.id}', style: boldTextStyle(size: 14)),
                                  widget.orderData!.datetime != null ? Text("$formattedDate at $formattedTime", style: primaryTextStyle(size: 14, weight: FontWeight.w500)) : SizedBox(),
                                  Divider(
                                    height: 16,
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text('${language.lblDistance}', style: secondaryTextStyle(size: 14), overflow: TextOverflow.ellipsis, maxLines: 1),
                                                  4.width,
                                                  Text('${widget.orderData?.distance?.toString() ?? ''}km', style: boldTextStyle(), overflow: TextOverflow.ellipsis, maxLines: 1),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(language.duration, style: secondaryTextStyle(size: 14), overflow: TextOverflow.ellipsis, maxLines: 1),
                                                  4.width,
                                                  Text('${widget.orderData?.duration?.toStringAsFixed(2) ?? ''} mins', style: boldTextStyle(), overflow: TextOverflow.ellipsis, maxLines: 1),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ).expand(),
                                    ],
                                  ),
                                  15.height,
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ImageIcon(AssetImage(ic_from), size: 24, color: primaryColor),
                                      12.width,
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${widget.orderData?.pickupPersonName ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: primaryTextStyle(weight: FontWeight.bold, size: 14)),
                                          Text('${widget.orderData?.startAddress ?? ''}', style: secondaryTextStyle(size: 12)),
                                          if (widget.orderData != null && !widget.orderData!.pickupDescription.isEmptyOrNull)
                                            Text('${language.note} ${widget.orderData?.pickupDescription ?? ''}', style: secondaryTextStyle(size: 12, weight: FontWeight.bold))
                                        ],
                                      ).expand(),
                                      if (widget.orderData != null && !widget.orderData!.pickupContactNumber.isEmptyOrNull)
                                        inkWellWidget(
                                          onTap: () {
                                            launchUrl(Uri.parse('tel:${widget.orderData?.pickupContactNumber}'), mode: LaunchMode.externalApplication);
                                          },
                                          child: chatCallWidget(Icons.call),
                                        )
                                    ],
                                  ),
                                  16.height,
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ImageIcon(AssetImage(ic_to), size: 24, color: primaryColor),
                                      12.width,
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${widget.orderData?.deliveryPersonName ?? ''}',
                                              maxLines: 1, overflow: TextOverflow.ellipsis, style: primaryTextStyle(weight: FontWeight.bold, size: 14)),
                                          Text('${widget.orderData?.endAddress ?? ''}', style: secondaryTextStyle(size: 12)),
                                          if (widget.orderData != null && !widget.orderData!.deliveryDescription.isEmptyOrNull)
                                            Text('${language.note} ${widget.orderData?.deliveryDescription ?? ''}', style: secondaryTextStyle(size: 12, weight: FontWeight.bold))
                                        ],
                                      ).expand(),
                                      if (widget.orderData != null && !widget.orderData!.deliveryContactNumber.isEmptyOrNull)
                                        inkWellWidget(
                                          onTap: () {
                                            launchUrl(Uri.parse('tel:${widget.orderData?.deliveryContactNumber}'), mode: LaunchMode.externalApplication);
                                          },
                                          child: chatCallWidget(Icons.call),
                                        )
                                    ],
                                  ),
                                  if (widget.orderData!.status != ORDER_CANCELLED || (widget.orderData!.status == ORDER_DEPARTED || widget.orderData!.status == ORDER_ACCEPTED)) 16.height,
                                  AppButton(
                                    elevation: 0,
                                    height: 35,
                                    color: Colors.transparent,
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(defaultRadius),
                                      side: BorderSide(color: primaryColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(language.viewHistory, style: primaryTextStyle(color: primaryColor)),
                                        Icon(Icons.arrow_right, color: primaryColor),
                                      ],
                                    ),
                                    onTap: () {
                                      launchScreen(
                                          context,
                                          RideHistoryScreen(
                                            rideHistory: widget.orderData!.rideHistory ?? [],
                                          ),
                                          pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            16.height,
                            Text('${language.parcelDetail}', style: boldTextStyle(size: 16)),
                            8.height,
                            Container(
                              decoration: boxDecorationWithRoundedCorners(
                                  borderRadius: BorderRadius.circular(defaultRadius), border: Border.all(color: primaryColor.withValues(alpha: 0.3)), backgroundColor: Colors.transparent),
                              padding: EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: boxDecorationWithRoundedCorners(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Color(0xFFEAEAEA), width: appStore.isDarkMode ? 0.2 : 1),
                                        backgroundColor: Colors.transparent),
                                    padding: EdgeInsets.all(8),
                                    child: Image.asset(parcelImg, height: 24, width: 24, color: Colors.grey),
                                  ),
                                  8.width,
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.orderData?.parcelDescription ?? '', style: boldTextStyle()),
                                      Text('${widget.orderData?.weight} Kg', style: secondaryTextStyle()),
                                    ],
                                  ).expand(),
                                ],
                              ),
                            ),
                            16.height,
                            Text(language.paymentDetails, style: boldTextStyle(size: 16)),
                            8.height,
                            Container(
                              decoration: boxDecorationWithRoundedCorners(
                                  borderRadius: BorderRadius.circular(defaultRadius), border: Border.all(color: primaryColor.withValues(alpha: 0.3)), backgroundColor: Colors.transparent),
                              padding: EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(language.paymentType, style: secondaryTextStyle()),
                                      Text('${paymentType(widget.orderData?.paymentType ?? 'cash')}', style: boldTextStyle(size: 14)),
                                    ],
                                  ),
                                  8.height,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(language.paymentStatus, style: secondaryTextStyle()),
                                      Text('${paymentStatus(widget.orderData?.paymentStatus ?? PAYMENT_PENDING)}', style: boldTextStyle(size: 14)),
                                    ],
                                  ),
                                  Divider(
                                    height: 16,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(language.total, style: boldTextStyle(size: 20)),
                                      Text('${printAmount(widget.orderData?.totalAmount ?? 0)}', style: boldTextStyle(size: 20)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            12.height,
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              : SizedBox(),
          Observer(builder: (context) => Visibility(visible: appStore.isLoading, child: Center(child: loaderWidget()))),
        ],
      ),
    );
  }

  chatCallWidget(IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: dividerColor), color: appStore.isDarkMode ? scaffoldColorDark : scaffoldColorLight, borderRadius: BorderRadius.circular(defaultRadius)),
      child: Icon(icon, size: 18, color: primaryColor),
    );
  }
}
