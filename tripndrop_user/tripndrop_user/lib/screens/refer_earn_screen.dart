import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taxi_booking/utils/Colors.dart';
import 'package:taxi_booking/utils/Constants.dart';
import 'package:taxi_booking/utils/Extensions/ResponsiveWidget.dart';
import 'package:taxi_booking/utils/Extensions/context_extension.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_booking/utils/Extensions/int_extensions.dart';

import '../main.dart';
import '../utils/Extensions/app_button.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/images.dart';
import 'RefferalHistoryScreen.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  String? maximumEarningPoint =
      sharedPref.getString("maxEarningPerMonth").isEmptyOrNull ? "0"  : sharedPref.getString("maxEarningPerMonth");
  String? referenceAmount = sharedPref.getString("reference_amount").isEmptyOrNull ? "0" : sharedPref.getString("reference_amount");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          language.lblReferAndEarn,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
              onPressed: () {
                launchScreen(context, ReferralHistoryScreen(),
                    pageRouteAnimation: PageRouteAnimation.Slide);
              },
              icon: Icon(Icons.history))
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(ic_refer_earn, width: 200),
              10.height,
              Text(
                  "${language.lblReferTitle}: "
                  "${sharedPref.getString("reference_type") == "fixed" ? "${appStore.currencyCode} ${referenceAmount}" : "${referenceAmount}%"}",
                  style: boldTextStyle(),
                  textAlign: TextAlign.center),
              10.height,
              Text("${language.lblReferSubtitle}:${appStore.currencyCode} ${maximumEarningPoint} Monthly",
                      style: secondaryTextStyle(), textAlign: TextAlign.center)
                  .center(),
              30.height,
              DottedBorder(
                  dashPattern: [6, 3, 2, 3],
                  color: primaryColor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(appStore.referralCode.toString(),
                              style: boldTextStyle(size: 20))
                          .paddingAll(8),
                      Icon(Icons.copy, size: 18).paddingAll(8)
                    ],
                  )).onTap(() {
                if (appStore.referralCode.toString().isNotEmpty) {
                  Clipboard.setData(
                          ClipboardData(text: appStore.referralCode.toString()))
                      .then((_) {
                    toast(
                        "${appStore.referralCode.toString()} Copied to clipboard");
                  });
                } else {
                  return;
                }
              }) /*.visible(!appStore.referralCode!.isEmpty)*/,
              30.height,
              Divider(thickness: 1, color: Colors.grey.withValues(alpha: 0.3)),
            ],
          ).paddingAll(20),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: AppButton(
              width: context.width(),
              color: primaryColor,
              text: language.lblReferAndEarn,
              textStyle: primaryTextStyle(color: Colors.white),
              onTap: () {
                SharePlus.instance.share(ShareParams(
                    text:
                        'Hey! Use my referral code ${appStore.referralCode} and join $mAppName to support me!'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
