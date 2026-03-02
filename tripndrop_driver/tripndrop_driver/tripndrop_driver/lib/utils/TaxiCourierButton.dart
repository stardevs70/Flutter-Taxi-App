import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Colors.dart';

import 'Constants.dart';
import 'Extensions/app_common.dart';

class TaxiCourierButton extends StatelessWidget {
  final String? ScheduleTime;

  TaxiCourierButton({
    Key? key,
    this.ScheduleTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final utcDateTime = DateTime.parse("${ScheduleTime}");

    final istDateTime = utcDateTime.toLocal().add(Duration(hours: 5, minutes: 30));
    final formattedDate = DateFormat('dd MMM yyyy').format(istDateTime);
    final formattedTime = DateFormat('hh:mm a').format(istDateTime);
    return Container(
      decoration: BoxDecoration(
          color: secondaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(2, 2),
              blurRadius: 1,
            ),
          ],
          borderRadius: BorderRadius.circular(defaultRadius)
      ),
      padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule,size: 14,color: Colors.white,),
          SizedBox(width: 2,),
          Text(
              "${language.schedule_at}: ${formattedDate} ${formattedTime}",
            // "${language.schedule_at}: ${DateFormat('dd MMM yyyy hh:mm a').format(DateTime.parse(schedule_ride_request[i].schedule_datetime.toString() + "Z").toLocal())}",
            style: boldTextStyle(size: 14,color: Colors.white),
          ),
        ],
      ),
    );
  }
}
