import 'package:flutter/material.dart';

import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';

class DeliveryInfoScreen extends StatefulWidget {
  const DeliveryInfoScreen({super.key});

  @override
  State<DeliveryInfoScreen> createState() => _DeliveryInfoScreenState();
}

class _DeliveryInfoScreenState extends State<DeliveryInfoScreen> {
  TextEditingController weightController = TextEditingController(text: '1');
  TextEditingController parcelTypeController = TextEditingController();

// sender details
  TextEditingController SNameController = TextEditingController();
  TextEditingController SContactController = TextEditingController();
  TextEditingController SDescController = TextEditingController();

// receiver details
  TextEditingController RNameController = TextEditingController();
  TextEditingController RContactController = TextEditingController();
  TextEditingController RDescController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          language.provide_delivery_details,
          style: primaryTextStyle(size: 18, weight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(language.weight, style: primaryTextStyle(size: 18)),
                        SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                              ),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              IconButton(
                                  onPressed: () {
                                    int x = int.tryParse(weightController.text) ?? 0;
                                    if (x > 0) {
                                      weightController.text = (x - 1).toString();
                                      setState(
                                        () {},
                                      );
                                    }
                                  },
                                  icon: Icon(Icons.remove)),
                              Expanded(
                                child: AppTextField(
                                  controller: weightController,
                                  autoFocus: false,
                                  textFieldType: TextFieldType.PHONE,
                                  keyboardType: TextInputType.number,
                                  errorThisFieldRequired: language.thisFieldRequired,
                                  textAlign: TextAlign.center,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '0',
                                  ),
                                ),
                              ),
                              IconButton(
                                  onPressed: () {
                                    int x = int.tryParse(weightController.text) ?? 0;
                                    weightController.text = (x + 1).toString();
                                    setState(
                                      () {},
                                    );
                                  },
                                  icon: Icon(Icons.add)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(language.parcel_type, style: primaryTextStyle(size: 18)),
                        SizedBox(height: 4),
                        AppTextField(
                          controller: parcelTypeController,
                          autoFocus: false,
                          textFieldType: TextFieldType.OTHER,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          errorThisFieldRequired: language.thisFieldRequired,
                          decoration: inputDecoration(context, label: language.parcel_type),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: 12),
              Text(language.sender_details, style: primaryTextStyle(size: 18)),
              Divider(
                height: 24,
                color: Colors.grey.shade400,
                thickness: 1,
              ),
              AppTextField(
                controller: SNameController,
                autoFocus: false,
                textFieldType: TextFieldType.NAME,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                errorThisFieldRequired: language.thisFieldRequired,
                decoration: inputDecoration(context, label: language.name),
              ),
              SizedBox(height: 4),
              AppTextField(
                controller: SContactController,
                autoFocus: false,
                textFieldType: TextFieldType.PHONE,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                errorThisFieldRequired: language.thisFieldRequired,
                decoration: inputDecoration(context, label: language.phoneNumber),
              ),
              SizedBox(height: 4),
              AppTextField(
                controller: SDescController,
                autoFocus: false,
                textFieldType: TextFieldType.ADDRESS,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                errorThisFieldRequired: language.thisFieldRequired,
                decoration: inputDecoration(context, label: language.instruction),
              ),
              SizedBox(height: 12),
              Text(language.receiver_details, style: primaryTextStyle(size: 18)),
              Divider(
                height: 24,
                color: Colors.grey.shade400,
                thickness: 1,
              ),
              AppTextField(
                controller: RNameController,
                autoFocus: false,
                textFieldType: TextFieldType.NAME,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                errorThisFieldRequired: language.thisFieldRequired,
                decoration: inputDecoration(context, label: language.name),
              ),
              SizedBox(height: 4),
              AppTextField(
                controller: RContactController,
                autoFocus: false,
                textFieldType: TextFieldType.PHONE,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                errorThisFieldRequired: language.thisFieldRequired,
                decoration: inputDecoration(context, label: language.phoneNumber),
              ),
              SizedBox(height: 4),
              AppTextField(
                controller: RDescController,
                autoFocus: false,
                textFieldType: TextFieldType.ADDRESS,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                errorThisFieldRequired: language.thisFieldRequired,
                decoration: inputDecoration(context, label: language.instruction),
              ),
              SizedBox(height: 12),
              AppButtonWidget(
                color: primaryColor,
                onTap: () async {
                  if (weightController.text.trim().isEmpty) {
                    return toast(language.enterWight);
                  }
                  if (parcelTypeController.text.trim().isEmpty) {
                    return toast(language.enterParcel);
                  }
                  if (SNameController.text.trim().isEmpty) {
                    return toast(language.enterSenderName);
                  }
                  if (SContactController.text.trim().isEmpty) {
                    return toast(language.enterSenderContact);
                  }
                  if (RNameController.text.trim().isEmpty) {
                    return toast(language.enterReceiverName);
                  }
                  if (RContactController.text.trim().isEmpty) {
                    return toast(language.enterReceiverContact);
                  }
                  var req = {};
                  req['weight'] = weightController.text;
                  req['parcel_type'] = parcelTypeController.text;
                  req['sender_name'] = SNameController.text;
                  req['sender_contact'] = SContactController.text;
                  req['sender_desc'] = SDescController.text;
                  req['receiver_name'] = RNameController.text;
                  req['receiver_contact'] = RContactController.text;
                  req['receiver_desc'] = RDescController.text;
                  Navigator.pop(context, req);
                },
                text: language.continueD,
                textStyle: boldTextStyle(color: Colors.white),
                width: MediaQuery.of(context).size.width,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
