import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_driver/Services/AuthService.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Extensions/extension.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../model/ServiceModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import 'TermsConditionScreen.dart';

class SignUpScreen extends StatefulWidget {
  final bool isOtp;
  final bool socialLogin;

  final String? countryCode;
  final String? privacyPolicyUrl;
  final String? termsConditionUrl;
  final String? userName;

  SignUpScreen({this.socialLogin = false, this.userName, this.isOtp = false, this.countryCode, this.privacyPolicyUrl, this.termsConditionUrl});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  AuthServices authService = AuthServices();

  List<GlobalKey<FormState>> formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController firstController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController carModelController = TextEditingController();
  TextEditingController carProductionController = TextEditingController();
  TextEditingController carPlateController = TextEditingController();
  TextEditingController carColorController = TextEditingController();
  TextEditingController referralController = TextEditingController();

  FocusNode firstNameFocus = FocusNode();
  FocusNode lastNameFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode passFocus = FocusNode();

  String selectedValue = BOOK_RIDE;
  final List<String> options = [TRANSPORT, BOOK_RIDE, BOTH];
  List<ServiceList> filteredServices=[];

  bool mIsCheck = false;
  bool isAcceptedTc = false;
  String countryCode = defaultCountryCode;

  int currentIndex = 0;

  List<ServiceList> listServices = [];

  int selectedService = 0;

  XFile? imageProfile;
  int radioValue = -1;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (sharedPref.getString(PLAYER_ID).validate().isEmpty) {
      await saveOneSignalPlayerId().then((value) {

      });
    }
    await getServices().then((value) {
      listServices.addAll(value.data??[]);
      filteredServices  = selectedValue == BOTH
          ? listServices
          : listServices.where((e) => e.service_type == selectedValue).toList();
      setState(() {});
    }).catchError((error) {
      log(error.toString());
    });
  }

  Future<void> register() async {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (isAcceptedTc) {
        appStore.setLoading(true);
        Map req = {
          'first_name': firstController.text.trim(),
          'partner_referral_code': referralController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'username': widget.socialLogin ? widget.userName : userNameController.text.trim(),
          'email': emailController.text.trim(),
          "user_type": "driver",
          "contact_number": widget.socialLogin ? '${widget.userName}' : '${phoneController.text.trim()}',
          "country_code": widget.socialLogin ? '${widget.countryCode}' : '$countryCode',
          'password': widget.socialLogin ? widget.userName : passController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
          if (widget.socialLogin) 'login_type': LoginTypeOTP,
          "user_detail": {
            'car_model': carModelController.text.trim(),
            'car_color': carColorController.text.trim(),
            'car_plate_number': carPlateController.text.trim(),
            'car_production_year': carProductionController.text.trim(),
          },
          'service_id': listServices[selectedService].id,
          'service_type': selectedValue,
        };

        await signUpApi(req).then((value) {
          authService
              .signUpWithEmailPassword(context,
                  mobileNumber: widget.socialLogin ? '${widget.countryCode}${widget.userName}' : '$countryCode${phoneController.text.trim()}',
                  email: emailController.text.trim(),
                  fName: firstController.text.trim(),
                  lName: lastNameController.text.trim(),
                  userName: widget.socialLogin ? widget.userName : userNameController.text.trim(),
                  password: widget.socialLogin ? widget.userName : passController.text.trim(),
                  userType: DRIVER,
                  isOtpLogin: widget.socialLogin)
              .then((res) async {

          }).catchError((e,stack) {
            print("ERR:::00::$e ====>$stack");
            appStore.setLoading(false);
            toast('$e');
          });
        }).catchError((error, stack) {
          print("ERR:$error ====>$stack");
          appStore.setLoading(false);
          // currentIndex=0;
          // setState(() {});
          // FirebaseCrashlytics.instance.recordError("sign_up_stuck_issue::" + error.toString(), stack, fatal: true);
          // toast('${error}');
        });
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark),
      ),
      body: Stack(
        children: [
          Form(
            key: formKey,
            child: Theme(
              data: ThemeData(colorScheme: ColorScheme.light(primary: primaryColor)),
              child: Stepper(
                currentStep: currentIndex,
                onStepCancel: () {
                  if (currentIndex > 0) {
                    currentIndex--;
                    setState(() {});
                  }
                },
                onStepContinue: () {

                  if (formKeys[currentIndex].currentState!.validate()) {
                    if (currentIndex == 1 && selectedValue.isEmptyOrNull) {
                      return toast(language.pleaseSelectService);
                    }
                    if(currentIndex == 2 && listServices.isEmpty){
                      return toast('Please select Vehicle');
                    } else if (currentIndex <= 1) {
                      currentIndex++;
                      setState(() {});
                    } else {
                      register();
                    }
                  }
                },
                onStepTapped: (int index) {
                  currentIndex = index;
                  setState(() {});
                },
                steps: [
                  Step(
                    isActive: currentIndex <= 0,
                    state: currentIndex <= 0 ? StepState.disabled : StepState.complete,
                    title: Text(language.userDetail, style: boldTextStyle()),
                    content: Form(
                      key: formKeys[0],
                      child: Column(
                        children: [
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  textFieldType: TextFieldType.NAME,
                                  controller: firstController,
                                  focus: firstNameFocus,
                                  nextFocus: lastNameFocus,
                                  errorThisFieldRequired: language.thisFieldRequired,
                                  decoration: inputDecoration(context, label: language.firstName),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: AppTextField(
                                  textFieldType: TextFieldType.NAME,
                                  controller: lastNameController,
                                  focus: lastNameFocus,
                                  nextFocus: emailFocus,
                                  errorThisFieldRequired: language.thisFieldRequired,
                                  decoration: inputDecoration(context, label: language.lastName),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  textFieldType: TextFieldType.EMAIL,
                                  focus: emailFocus,
                                  controller: emailController,
                                  nextFocus: userNameFocus,
                                  errorThisFieldRequired: language.thisFieldRequired,
                                  decoration: inputDecoration(context, label: language.email),
                                ),
                              ),
                              SizedBox(width: 16),
                              if (widget.socialLogin != true)
                                Expanded(
                                  child: AppTextField(
                                    textFieldType: TextFieldType.USERNAME,
                                    focus: userNameFocus,
                                    controller: userNameController,
                                    nextFocus: phoneFocus,
                                    errorThisFieldRequired: language.thisFieldRequired,
                                    decoration: inputDecoration(context, label: language.userName),
                                  ),
                                ),
                            ],
                          ),
                          if (widget.socialLogin != true) SizedBox(height: 8),
                          if (widget.socialLogin != true)
                            AppTextField(
                              controller: phoneController,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textFieldType: TextFieldType.PHONE,
                              focus: phoneFocus,
                              nextFocus: passFocus,
                              decoration: inputDecoration(
                                context,
                                label: language.phoneNumber,
                                prefixIcon: IntrinsicHeight(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CountryCodePicker(
                                        padding: EdgeInsets.zero,
                                        initialSelection: countryCode,
                                        showCountryOnly: false,
                                        dialogSize: Size(MediaQuery.of(context).size.width - 60, MediaQuery.of(context).size.height * 0.6),
                                        showFlag: true,
                                        showFlagDialog: true,
                                        showOnlyCountryWhenClosed: false,
                                        alignLeft: false,
                                        textStyle: primaryTextStyle(),
                                        dialogBackgroundColor: Theme.of(context).cardColor,
                                        barrierColor: Colors.black12,
                                        dialogTextStyle: primaryTextStyle(),
                                        searchDecoration: InputDecoration(
                                          focusColor: primaryColor,
                                          iconColor: Theme.of(context).dividerColor,
                                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                                        ),
                                        searchStyle: primaryTextStyle(),
                                        onInit: (c) {
                                          countryCode = c!.dialCode!;
                                        },
                                        onChanged: (c) {
                                          countryCode = c.dialCode!;
                                        },
                                      ),
                                      VerticalDivider(color: Colors.grey.withValues(alpha: 0.5)),
                                    ],
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value!.trim().isEmpty) return language.thisFieldRequired;
                                return null;
                              },
                            ),
                          if (widget.socialLogin != true) SizedBox(height: 8),
                          if (widget.socialLogin != true)
                            AppTextField(
                              controller: passController,
                              focus: passFocus,
                              autoFocus: false,
                              textFieldType: TextFieldType.PASSWORD,
                              errorThisFieldRequired: language.thisFieldRequired,
                              decoration: inputDecoration(context, label: language.password),
                            ),
                          SizedBox(height: 8),
                          AppTextField(
                            controller:referralController,
                            autoFocus:false,
                            textFieldType: TextFieldType.OTHER,
                            errorThisFieldRequired: errorThisFieldRequired,
                            decoration: inputDecoration(context, label: "Referral Code"),
                            validator: (String? value) {
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Step(
                    isActive: currentIndex <= 1,
                    state: currentIndex <= 1 ? StepState.disabled : StepState.complete,
                    title: Text(language.selectService, style: boldTextStyle()),
                    content: Form(
                      key: formKeys[1],
                      child: Column(
                             mainAxisAlignment: MainAxisAlignment.start,
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Container(
                                 width: double.infinity,
                                 padding: const EdgeInsets.symmetric(horizontal: 12),
                                 decoration: BoxDecoration(
                                   color: Colors.grey[200],
                                   borderRadius: BorderRadius.circular(5),
                                   border: Border.all(color: Colors.grey),
                                 ),
                                 child: DropdownButtonHideUnderline(
                                   child: DropdownButton<String>(
                                     value: selectedValue.isEmpty ? null : selectedValue,
                                     isExpanded: true,
                                     hint: const Text('Select an option'),
                                     icon: const Icon(Icons.arrow_drop_down),
                                     onChanged: (String? newValue) {
                                       setState(() {
                                         selectedValue = newValue ?? '';

                                         // Filter the services based on selected service_type
                                         if (selectedValue.isEmpty) {
                                           filteredServices = listServices; // Show all if nothing selected
                                         } else {
                                           filteredServices = listServices
                                               .where((e) => e.service_type == selectedValue)
                                               .toList();
                                         }
                                       });
                                     },
                                     items: options.map((String option) {
                                       return DropdownMenuItem<String>(
                                         value: option,
                                         child: Text(option),
                                       );
                                     }).toList(),
                                   ),
                                 ),
                               ),                                SizedBox(height: 10),
                               listServices.isNotEmpty
                                   ? Column(
                                 children: filteredServices.map((e) {
                                   return inkWellWidget(
                                     onTap: () {
                                       selectedService = filteredServices.indexOf(e);
                                       setState(() {});
                                     },
                                     child: Container(
                                       margin: EdgeInsets.only(bottom: 8),
                                       padding: EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                                       decoration: BoxDecoration(
                                         border: Border.all(color: selectedService == filteredServices.indexOf(e) ? Colors.green : primaryColor.withValues(alpha: 0.5)),
                                         borderRadius: BorderRadius.circular(defaultRadius),
                                       ),
                                       child: Row(
                                         children: [
                                           commonCachedNetworkImage(e.serviceImage, fit: BoxFit.contain, height: 50, width: 50),
                                           SizedBox(width: 16),
                                           Expanded(
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Text(e.name.validate(), style: boldTextStyle()),
                                                 Text(language.serviceInfo+": "+e.service_type.validate().replaceAll("_", " ").toUpperCase(), style: secondaryTextStyle(size: 10,weight: FontWeight.bold)),
                                               ],
                                             ),
                                           ),
                                           Visibility(
                                             visible: selectedService == filteredServices.indexOf(e),
                                             child: Icon(Icons.check_circle_outline, color: Colors.green),
                                           )
                                         ],
                                       ),
                                     ),
                                   );
                                 }).toList(),
                               )
                                   : emptyWidget(),
                              ],
                            )

                    ),
                  ),
                  // update car info
                  Step(
                    isActive: currentIndex <= 2,
                    state: currentIndex <= 2 ? StepState.disabled : StepState.complete,
                    title: Text(language.updateVehicleInfo/*language.carModel*/, style: boldTextStyle()),
                    content: Form(
                      key: formKeys[2],
                      child: Column(
                        children: [
                          SizedBox(height: 8),
                          Row(
                            children: [
                              AppTextField(textFieldType: TextFieldType.NAME, controller: carPlateController, decoration: inputDecoration(context, label:language.carPlateNumber)).expand(),
                              SizedBox(width: 16,),
                              AppTextField(textFieldType: TextFieldType.PHONE, controller: carProductionController, decoration: inputDecoration(context, label: language.carProductionYear), inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],).expand(),
                            ],
                          ),
                          SizedBox(height: 8),
                          AppTextField(textFieldType: TextFieldType.NAME, controller: carModelController, decoration: inputDecoration(context, label:language.carModel)),
                          SizedBox(height: 8),
                          AppTextField(textFieldType: TextFieldType.NAME, controller: carColorController, decoration: inputDecoration(context, label:language.carColor)),
                          SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: primaryColor,
                            title: RichText(
                              text: TextSpan(children: [
                                TextSpan(text: '${language.agreeToThe} ', style: secondaryTextStyle()),
                                TextSpan(
                                  text: language.termsConditions,
                                  style: boldTextStyle(color: primaryColor, size: 14),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      if (widget.termsConditionUrl != null && widget.termsConditionUrl!.isNotEmpty) {
                                        launchScreen(context, TermsConditionScreen(title: language.termsConditions, subtitle: widget.termsConditionUrl), pageRouteAnimation: PageRouteAnimation.Slide);
                                      } else {
                                        toast(language.txtURLEmpty);
                                      }
                                    },
                                ),
                                TextSpan(text: ' & ', style: secondaryTextStyle()),
                                TextSpan(
                                  text: language.privacyPolicy,
                                  style: boldTextStyle(color: primaryColor, size: 14),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      if (widget.privacyPolicyUrl != null && widget.privacyPolicyUrl!.isNotEmpty) {
                                        launchScreen(context, TermsConditionScreen(title: language.privacyPolicy, subtitle: widget.privacyPolicyUrl), pageRouteAnimation: PageRouteAnimation.Slide);
                                      } else {
                                        toast(language.txtURLEmpty);
                                      }
                                    },
                                ),
                              ]),
                              textAlign: TextAlign.left,
                            ),
                            value: isAcceptedTc,
                            onChanged: (val) async {
                              isAcceptedTc = val!;
                              setState(() {});
                            },
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
    );
  }
}
