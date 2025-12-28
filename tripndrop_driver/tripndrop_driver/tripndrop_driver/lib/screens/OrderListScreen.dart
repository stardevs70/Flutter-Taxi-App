import 'package:flutter/material.dart';
import 'package:taxi_driver/components/OrderCardComponent.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/model/MyOrderResponse.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:taxi_driver/utils/Extensions/WidgetExtension.dart';
import 'package:taxi_driver/utils/Extensions/animatedList/animated_configurations.dart';
import 'package:taxi_driver/utils/Extensions/animatedList/animated_list_view.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
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
      print("Exception:::$error::::$s");
      appStore.setLoading(false);
      log(error.toString());
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
        title: Text("My Orders", style: boldTextStyle(color: appTextPrimaryColorWhite)),
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
          return OrderCardComponent(item: item);
        },
      ),
    );
  }
}
