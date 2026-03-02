import 'package:flutter/material.dart';
import 'package:flutter_arc_text/flutter_arc_text.dart';
import 'package:taxi_booking/main.dart';
import 'package:taxi_booking/utils/images.dart';
import 'package:tuple/tuple.dart';

import '../utils/Constants.dart';

class AnimatedBottomSheetContent extends StatefulWidget {
  @override
  AnimatedBottomSheetContentState createState() => AnimatedBottomSheetContentState();
}

class AnimatedBottomSheetContentState extends State<AnimatedBottomSheetContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  int serviceType = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        height: 150 ,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    navigator.pop();
                  },
                  child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close, size: 18, color: Colors.black)),
                )),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (appStore.activeServices == BOTH || appStore.activeServices == BOOK_RIDE)
                  InkWell(
                    onTap: () {
                      setState(() {
                        serviceType = 1;
                        navigator.pop<Tuple2<int, int>>(
                          Tuple2(serviceType, serviceType),
                        );
                      });
                    },
                    child: Stack(
                      children: [
                        Positioned(
                          top: 50,
                          right: 40,
                          child: ArcText(
                            radius: 50,
                            text: '${language.bookTaxi}',
                            textStyle: TextStyle(fontSize: 12, color: Colors.black),
                            startAngle: -2.14 / 25,
                            startAngleAlignment: StartAngleAlignment.center,
                            placement: Placement.outside,
                            direction: Direction.clockwise,
                          ),
                        ),
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: textSecondaryColorGlobal, width: 1)),
                          padding: EdgeInsets.all(12),
                          child: Image.asset(cab, fit: BoxFit.fitWidth),
                        ),
                      ],
                    ),
                  ),
                if (appStore.activeServices == BOTH || appStore.activeServices == TRANSPORT) SizedBox(width: 40),
                if (appStore.activeServices == BOTH || appStore.activeServices == TRANSPORT)
                  InkWell(
                    onTap: () {
                      setState(() {
                        serviceType = 2;
                        navigator.pop<Tuple2<int, int>>(
                          Tuple2(serviceType, serviceType),
                        );
                      });
                    },
                    child: Stack(
                      children: [
                        Positioned(
                          top: 50,
                          left: 40,
                          child: ArcText(
                            radius: 50,
                            text: '${language.bookParcel}',
                            textStyle: TextStyle(fontSize: 12, color: Colors.black),
                            startAngle: -2.14 / 25,
                            startAngleAlignment: StartAngleAlignment.center,
                            placement: Placement.outside,
                            direction: Direction.clockwise,
                          ),
                        ),
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: textSecondaryColorGlobal, width: 1)),
                          padding: EdgeInsets.all(12),
                          child: Image.asset(delivery, fit: BoxFit.fitWidth),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
