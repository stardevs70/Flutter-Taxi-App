import 'package:flutter/material.dart';
import 'package:taxi_booking/main.dart';
import 'package:taxi_booking/utils/Colors.dart';

class TaxiCourierButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(2, 2),
            blurRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.all(4),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 100, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color:primaryColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${language.bookService}",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
