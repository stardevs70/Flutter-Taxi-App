import 'package:flutter/material.dart';
import 'package:taxi_booking/utils/Extensions/WidgetExtension.dart';

import '../main.dart';
import '../model/EstimatePriceModel.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

class CarDetailWidget extends StatefulWidget {
  final ServicesListData service;

  CarDetailWidget({required this.service});

  @override
  CarDetailWidgetState createState() => CarDetailWidgetState();
}

class CarDetailWidgetState extends State<CarDetailWidget> {
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              alignment: Alignment.center,
              height: 5,
              width: 70,
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(widget.service.serviceImage.validate(), fit: BoxFit.contain, width: 200, height: 100),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(widget.service.name.validate(), style: boldTextStyle()),
          SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${language.tripDistance}", style: primaryTextStyle()),
                      Text('${widget.service.dropoffDistanceInKm?.toInt() == 0 ? widget.service.distance : widget.service.dropoffDistanceInKm} ${widget.service.distanceUnit}',
                          style: primaryTextStyle()),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.capacity, style: primaryTextStyle()),
                      Text('${widget.service.capacity} ${language.people}', style: primaryTextStyle()),
                    ],
                  ).visible(widget.service.capacity != null),
                  SizedBox(height: 8).visible(widget.service.capacity != null),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.baseFare, style: primaryTextStyle()),
                      printAmountWidget(amount: '${widget.service.baseFare!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal)
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.minimumFare, style: primaryTextStyle()),
                      printAmountWidget(amount: '${widget.service.minimumFare?.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal)
                    ],
                  ).visible(widget.service.minimumFare != null),
                  SizedBox(height: 8).visible(widget.service.minimumFare != null),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.perDistance, style: primaryTextStyle()),
                      printAmountWidget(amount: '${widget.service.perDistance?.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal)
                    ],
                  ).visible(widget.service.perDistance != null),
                  SizedBox(height: 8).visible(widget.service.perDistance != null),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.perMinDrive, style: primaryTextStyle()),
                      printAmountWidget(amount: '${widget.service.perMinuteDrive?.toStringAsFixed(digitAfterDecimal)}/${language.min}', weight: FontWeight.normal)
                    ],
                  ).visible(widget.service.perMinuteDrive != null),
                  SizedBox(height: 8).visible(widget.service.perMinuteDrive != null),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(language.perMinWait, style: primaryTextStyle()),
                  //     printAmountWidget(amount: '${widget.service.perMinuteWait?.toStringAsFixed(digitAfterDecimal)}/${language.min}', weight: FontWeight.normal)
                  //   ],
                  // ).visible(widget.service.perMinuteWait != null),
                  // SizedBox(height: 8).visible(widget.service.perMinuteWait != null),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${language.lblPerWeightCharge}", style: primaryTextStyle()),
                      printAmountWidget(amount: '${widget.service.perWeightCharge?.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal)
                    ],
                  ).visible(widget.service.perWeightCharge != null),
                  SizedBox(height: 8).visible(widget.service.perWeightCharge != null),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${language.lblCancellationFee}", style: primaryTextStyle()),
                      printAmountWidget(amount: '${widget.service.cancellationFee?.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal)
                    ],
                  ).visible(widget.service.cancellationFee != null),
                  if (widget.service.fixed_charge != null && widget.service.fixed_charge! > 0) SizedBox(height: 8),
                  if (widget.service.fixed_charge != null && widget.service.fixed_charge! > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(language.fixedPrice, style: primaryTextStyle()),
                        printAmountWidget(amount: '${widget.service.fixed_charge!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal)
                      ],
                    ),
                  SizedBox(height: 8),
                  Text(widget.service.description.validate(), style: secondaryTextStyle(), textAlign: TextAlign.justify),
                  SizedBox(height: 8),
                  AppButtonWidget(
                    text: language.close,
                    width: MediaQuery.of(context).size.width,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
