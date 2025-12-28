import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/model/MyOrderResponse.dart';
import 'package:taxi_driver/screens/OrderDetailScreen.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/ResponsiveWidget.dart';
import 'package:taxi_driver/utils/Extensions/context_extension.dart';
import 'package:taxi_driver/utils/Extensions/decorations.dart';
import 'package:taxi_driver/utils/Extensions/int_extensions.dart';
import 'package:taxi_driver/utils/Images.dart';

import '../screens/PDF_Screen.dart';
import '../utils/Extensions/app_common.dart';

class OrderCardComponent extends StatefulWidget {
  final MyOrderData? item;

  OrderCardComponent({this.item});

  @override
  _OrderCardComponentState createState() => _OrderCardComponentState();
}

class _OrderCardComponentState extends State<OrderCardComponent> {
  @override
  Widget build(BuildContext context) {
    final utcDateTime = DateTime.parse("${widget.item?.datetime}");

    final istDateTime = utcDateTime.toLocal().add(Duration(hours: 5, minutes: 30));
    final formattedDate = DateFormat('dd MMM yyyy').format(istDateTime);
    final formattedTime = DateFormat('hh:mm a').format(istDateTime);

    return GestureDetector(
      onTap: () {
        launchScreen(context, OrderDetailScreen(orderData: widget.item), pageRouteAnimation: PageRouteAnimation.Slide);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: boxDecorationWithRoundedCorners(borderRadius: BorderRadius.circular(defaultRadius), border: Border.all(color: primaryColor.withValues(alpha: 0.3)), backgroundColor: Colors.transparent),
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.item?.datetime != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#${widget.item?.id}', style: boldTextStyle(size: 14)),
                          Text("$formattedDate at $formattedTime", style: primaryTextStyle(size: 14)),
                        ],
                      ).expand()
                    : SizedBox(),
                Visibility(
                  visible: widget.item?.status != ORDER_DELIVERED,
                  child: GestureDetector(
                    onTap: () {
                      openMap(double.parse(widget.item?.startLatitude.toString() ?? ''), double.parse(widget.item?.startLongitude.toString() ?? ''),
                          double.parse(widget.item?.endLatitude.toString() ?? ''), double.parse(widget.item?.endLongitude.toString() ?? ''));
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: statusColor(widget.item?.status ?? '').withValues(alpha: 0.08))),
                        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                        child: Icon(Icons.navigation_outlined, color: primaryColor).center(),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: statusColor(widget.item?.status ?? '').withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Text(rideStatusDisplay(status: widget.item?.status ?? ''), style: primaryTextStyle(size: 14, color: statusColor(widget.item?.status ?? ''))),
                    ],
                  ),
                ),
              ],
            ),
            Divider(
              height: 16,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: boxDecorationWithRoundedCorners(
                      borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(0xFFEAEAEA), width: appStore.isDarkMode ? 0.2 : 1), backgroundColor: context.cardColor),
                  padding: EdgeInsets.all(8),
                  child: Image.asset(parcelImg, height: 24, width: 24, color: primaryColor),
                ),
                8.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.parcel_type, style: boldTextStyle(size: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(widget.item?.parcelDescription ?? '', style: secondaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ).expand(),
                8.width,
                if (widget.item?.status == ORDER_DELIVERED)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: boxDecorationWithRoundedCorners(backgroundColor: primaryColor),
                    child: Row(
                      children: [
                        Text(language.invoice, style: secondaryTextStyle(color: Colors.white)),
                        4.width,
                        Icon(Ionicons.md_download_outline, color: Colors.white, size: 18).paddingBottom(4),
                      ],
                    ).onTap(() {
                      launchScreen(context, PDFViewer(invoice: "${widget.item?.invoiceUrl ?? ''}", filename: widget.item?.id.toString()), pageRouteAnimation: PageRouteAnimation.Slide);
                    }),
                  ),
              ],
            ),
            8.height,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        ImageIcon(AssetImage(ic_from), size: 24, color: primaryColor),
                        12.width,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${widget.item?.pickupPersonName ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: primaryTextStyle(weight: FontWeight.bold, size: 14)),
                            Text('${widget.item?.startAddress ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: secondaryTextStyle()),
                          ],
                        ).expand(),
                      ],
                    ).expand(),
                  ],
                ),
              ],
            ),
            16.height,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ImageIcon(AssetImage(ic_to), size: 24, color: primaryColor),
                            12.width,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${widget.item?.deliveryPersonName ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: primaryTextStyle(weight: FontWeight.bold, size: 14)),
                                Text('${widget.item?.endAddress ?? ""}', style: secondaryTextStyle(), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start),
                              ],
                            ).expand(),
                          ],
                        ),
                      ],
                    ).expand(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
