import 'package:flutter/material.dart';

import '../../main.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/Loader.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

class CancelOrderDialog extends StatefulWidget {
  static String tag = '/CancelOrderDialog';
  final String? service_type;
  final Function(String)? onCancel;

  CancelOrderDialog({this.onCancel, this.service_type});

  @override
  CancelOrderDialogState createState() => CancelOrderDialogState();
}

class CancelOrderDialogState extends State<CancelOrderDialog> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController reasonController = TextEditingController();
  String? reason;
  int selectedReason = 0;
  bool loadDone = false;
  List<String> cancelReasonList = [];
  late FocusNode myFocusNode;

  @override
  void initState() {
    myFocusNode = FocusNode();
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  void loadData() async {
    var value = await fetchCancelReasons(type: widget.service_type == TRANSPORT ? 'driver_order' : 'driver');
    try {
      value['data'].forEach(
        (element) {
          cancelReasonList.add(element['reason'].toString());
        },
      );
      cancelReasonList.add("Others");
      loadDone = true;
      setState(() {});
    } catch (e, s) {
      loadDone = true;
      setState(() {});
      print("CheckERROR:::$e ==>$s");
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            child: Padding(
              padding: const EdgeInsets.only(left: 0, right: 0, top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.service_type == TRANSPORT ? language.cancelOrder : language.cancelRide, style: boldTextStyle(size: 18)),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.clear),
                        ),
                      ],
                    ),
                  ),
                  loadDone == false
                      ? SizedBox(height: 150, child: Loader())
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < cancelReasonList.length; i++)
                                  RadioListTile(
                                    value: i,
                                    groupValue: selectedReason,
                                    onChanged: (value) {
                                      selectedReason = value ?? -1;
                                      if (selectedReason != -1 && cancelReasonList[selectedReason] == "Others") {
                                        myFocusNode.requestFocus();
                                      }
                                      setState(() {});
                                    },
                                    title: Text(cancelReasonList[i]),
                                    activeColor: primaryColor,
                                    contentPadding: EdgeInsets.zero,
                                    visualDensity: VisualDensity(vertical: VisualDensity.minimumDensity, horizontal: VisualDensity.minimumDensity),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (selectedReason != -1 && cancelReasonList[selectedReason] == "Others")
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: AppTextField(
                                      focus: myFocusNode,
                                      controller: reasonController,
                                      textFieldType: TextFieldType.OTHER,
                                      maxLength: 1000,
                                      decoration: inputDecoration(context, label: language.writeReasonHere),
                                      maxLines: 3,
                                      minLines: 3,
                                      validator: (value) {
                                        if (value!.isEmpty) return language.thisFieldRequired;
                                        return null;
                                      },
                                    ),
                                  ),
                                if (selectedReason != -1 && cancelReasonList[selectedReason] == "Others") SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AppButtonWidget(
                        onTap: () {
                          if (formKey.currentState!.validate()) {
                            widget.onCancel?.call(selectedReason != -1 && cancelReasonList[selectedReason] != "Others" ? cancelReasonList[selectedReason].validate() : reasonController.text);
                          }
                        },
                        text: language.submit,
                        color: primaryColor,
                        textStyle: boldTextStyle(color: Colors.white),
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                  ),
                  SizedBox(height: 16)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
