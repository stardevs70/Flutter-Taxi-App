import 'package:flutter/material.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/screens/DashboardScreen.dart';
import 'package:taxi_driver/screens/ScheduleRideListScreen.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Constants.dart';

import '../utils/Extensions/app_common.dart';

class UpcomingMainScreen extends StatefulWidget {
  const UpcomingMainScreen({super.key});

  @override
  State<UpcomingMainScreen> createState() => _UpcomingMainScreenState();
}

class _UpcomingMainScreenState extends State<UpcomingMainScreen> {
  int currentPage = 1;
  int totalPage = 1;
  List<String> riderStatus = [language.rides, language.lblDelivery];


  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          return true;
        } else {
          launchScreen(getContext, DashboardScreen(), isNewTask: true);
          return false;
        }
      },
      child: DefaultTabController(
        length: riderStatus.length,
        child: Scaffold(
          appBar: AppBar(
            title: Text(language.schedule_list_title, style: boldTextStyle(color: appTextPrimaryColorWhite)),
          ),
          body: Column(
            children: [
              Container(
                height: 40,
                margin: EdgeInsets.only(right: 16, left: 16, top: 16),
                decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: dividerColor), borderRadius: radius(defaultRadius + 2)),
                child: TabBar(
                  dividerHeight: 0,
                  padding: EdgeInsets.all(2),
                  indicator: BoxDecoration(borderRadius: radius(), color: primaryColor),
                  labelColor: Colors.white,
                  unselectedLabelColor: primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: boldTextStyle(color: Colors.white, size: 14),
                  tabs: riderStatus.map((e) {
                    return Tab(
                      child: Text(e),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: riderStatus.map((e) {
                    return ScheduleRideListScreen(status: e);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
