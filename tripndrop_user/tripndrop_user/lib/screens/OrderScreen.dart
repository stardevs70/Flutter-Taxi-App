import 'package:flutter/material.dart';
import 'package:taxi_booking/components/OrderCardComponent.dart';
import 'package:taxi_booking/main.dart';
import 'package:taxi_booking/model/MyOrderResponse.dart';
import 'package:taxi_booking/network/RestApis.dart';
import 'package:taxi_booking/utils/Colors.dart';
import 'package:taxi_booking/utils/Common.dart';
import 'package:taxi_booking/utils/Constants.dart';
import 'package:taxi_booking/utils/Extensions/WidgetExtension.dart';
import 'package:taxi_booking/utils/Extensions/animatedList/animated_configurations.dart';
import 'package:taxi_booking/utils/Extensions/animatedList/animated_list_view.dart';
import 'package:taxi_booking/utils/Extensions/app_common.dart';

class Orderscreen extends StatefulWidget {
  const Orderscreen({super.key});

  @override
  State<Orderscreen> createState() => _OrderscreenState();
}

class _OrderscreenState extends State<Orderscreen> {
  List<MyOrderData> orderList = [];
  ScrollController scrollController = ScrollController();

  int page = 1;
  int totalPage = 1;
  int currentPage = 1;
  List storeList = [];

  @override
  void initState() {
    super.initState();
    getOrderListApiCall();
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        if (currentPage < totalPage) {
          appStore.setLoading(true);
          currentPage++;
          setState(() {});

          getOrderListApiCall();
        }
      }
    });
  }

  getOrderListApiCall() async {
    appStore.setLoading(true);
    await getMyOrder(page: currentPage).then((value) {
      appStore.setLoading(false);

      currentPage = value.pagination!.currentPage!;
      totalPage = value.pagination!.totalPages!;
      if (currentPage == 1) {
        orderList.clear();
      }
      orderList.addAll(value.data ?? []);
      setState(() {});
    }).catchError((error, s) {
      appStore.setLoading(false);
      log(error.toString());
      print("-----------63>>>>${s}");
    });
    appStore.setLoading(false);
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
        title: Text(language.myorder, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: AnimatedListView(
        controller: scrollController,
        itemCount: orderList.length,
        shrinkWrap: true,
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        listAnimationType: ListAnimationType.Slide,
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 60),
        flipConfiguration: FlipConfiguration(duration: Duration(seconds: 1), curve: Curves.fastOutSlowIn),
        fadeInConfiguration: FadeInConfiguration(duration: Duration(seconds: 1), curve: Curves.fastOutSlowIn),
        onNextPage: () {
          if (page < totalPage) {
            page++;
            setState(() {});
            getOrderListApiCall();
          }
        },
        emptyWidget: Stack(
          children: [
            loaderWidget().visible(appStore.isLoading),
            emptyWidget().visible(!appStore.isLoading),
          ],
        ),
        onSwipeRefresh: () async {
          page = 1;
          getOrderListApiCall();
          return Future.value(true);
        },
        itemBuilder: (context, i) {
          MyOrderData item = orderList[i];
          print("-----------110>>>${item.id}");
          return item.status != ORDER_DRAFT ? OrderCardComponent(item: item) : SizedBox();
        },
      ),
    );
  }
}
