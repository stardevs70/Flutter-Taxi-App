import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_braintree_betc/flutter_braintree_betc.dart';
import 'package:flutter_braintree_payment/flutter_braintree_payment.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:flutter_paytabs_bridge/BaseBillingShippingInfo.dart' as payTab;
import 'package:flutter_paytabs_bridge/IOSThemeConfiguration.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkApms.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkConfigurationDetails.dart';
import 'package:flutter_paytabs_bridge/flutter_paytabs_bridge.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutterwave_standard_smart/flutterwave.dart';
import 'package:http/http.dart' as http;
import 'package:my_fatoorah/my_fatoorah.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:taxi_driver/screens/WebViewScreen.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../../main.dart';
import '../../network/NetworkUtils.dart';
import '../../network/RestApis.dart';
import '../../utils/Colors.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../model/PaymentListModel.dart';
import '../model/StripePayModel.dart';
import '../utils/Images.dart';

class PaymentScreen extends StatefulWidget {
  final num? amount;

  PaymentScreen({this.amount});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  List<PaymentModel> paymentList = [];

  String? selectedPaymentType,
      stripPaymentKey,
      stripPaymentPublishKey,
      payStackPublicKey,
      payPalTokenizationKey,
      flutterWavePublicKey,
      flutterWaveSecretKey,
      flutterWaveEncryptionKey,
      payTabsProfileId,
      payTabsServerKey,
      payTabsClientKey,
      mercadoPagoPublicKey,
      mercadoPagoAccessToken,
      myFatoorahToken,
      paytmMerchantId,
      paytmMerchantKey;

  String? razorKey;
  bool isTestType = true;
  bool loading = false;
  final plugin = PaystackPlugin();
  late Razorpay _razorpay;
  CheckoutMethod method = CheckoutMethod.card;
  Map<String, dynamic> paypalValue = {
    "is_test": true,
    "client_id": "1234",
    "client_secret": "1234",
  };

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await paymentListApiCall();
    if (paymentList.any((element) => element.type == PAYMENT_TYPE_STRIPE)) {
      Stripe.publishableKey = stripPaymentPublishKey.validate();
      Stripe.merchantIdentifier = mStripeIdentifier;
      await Stripe.instance.applySettings().catchError((e) {
        log("${e.toString()}");
      });
    }
    if (paymentList.any((element) => element.type == PAYMENT_TYPE_PAYSTACK)) {
      plugin.initialize(publicKey: payStackPublicKey.validate());
    }
    if (paymentList.any((element) => element.type == PAYMENT_TYPE_RAZORPAY)) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  /// Get Payment Gateway Api Call
  Future<void> paymentListApiCall() async {
    appStore.setLoading(true);
    await getPaymentList().then((value) {
      appStore.setLoading(false);
      paymentList.addAll(value.data!);
      if (paymentList.isNotEmpty) {
        paymentList.forEach((element) {
          if (element.type == PAYMENT_TYPE_STRIPE) {
            stripPaymentKey = element.isTest == 1 ? element.testValue!.secretKey : element.liveValue!.secretKey;
            stripPaymentPublishKey = element.isTest == 1 ? element.testValue!.publishableKey : element.liveValue!.publishableKey;
          } else if (element.type == PAYMENT_TYPE_PAYSTACK) {
            payStackPublicKey = element.isTest == 1 ? element.testValue!.publicKey : element.liveValue!.publicKey;
            plugin.initialize(publicKey: payStackPublicKey.validate());
          } else if (element.type == PAYMENT_TYPE_RAZORPAY) {
            razorKey = element.isTest == 1 ? element.testValue!.keyId.validate() : element.liveValue!.keyId.validate();
          } else if (element.type == PAYMENT_TYPE_PAYPAL) {
            payPalTokenizationKey = element.isTest == 1 ? element.testValue!.tokenizationKey : element.liveValue!.tokenizationKey;
            if (element.isTest == 1) {
              paypalValue = {
                "is_test": true,
                "client_id": "${element.testValue?.publicKey}",
                "client_secret": "${element.testValue?.secretKey}",
              };
              print("paypal keys ${element.testValue?.publicKey} ${element.testValue?.secretKey}");
            } else {
              paypalValue = {
                "is_test": false,
                "client_id": "${element.liveValue?.publicKey}",
                "client_secret": "${element.liveValue?.secretKey}",
              };
            }
            print("paypal ${payPalTokenizationKey}");
          } else if (element.type == PAYMENT_TYPE_FLUTTERWAVE) {
            flutterWavePublicKey = element.isTest == 1 ? element.testValue!.publicKey : element.liveValue!.publicKey;
            flutterWaveSecretKey = element.isTest == 1 ? element.testValue!.secretKey : element.liveValue!.secretKey;
            flutterWaveEncryptionKey = element.isTest == 1 ? element.testValue!.encryptionKey : element.liveValue!.encryptionKey;
          } else if (element.type == PAYMENT_TYPE_PAYTABS) {
            payTabsProfileId = element.isTest == 1 ? element.testValue!.profileId : element.liveValue!.profileId;
            payTabsClientKey = element.isTest == 1 ? element.testValue!.clientKey : element.liveValue!.clientKey;
            payTabsServerKey = element.isTest == 1 ? element.testValue!.serverKey : element.liveValue!.serverKey;
          } else if (element.type == PAYMENT_TYPE_MERCADOPAGO) {
            mercadoPagoPublicKey = element.isTest == 1 ? element.testValue!.publicKey : element.liveValue!.publicKey;
            mercadoPagoAccessToken = element.isTest == 1 ? element.testValue!.accessToken : element.liveValue!.accessToken;
          } else if (element.type == PAYMENT_TYPE_MYFATOORAH) {
            myFatoorahToken = element.isTest == 1 ? element.testValue!.accessToken : element.liveValue!.accessToken;
          } else if (element.type == PAYMENT_TYPE_PAYTM) {
            paytmMerchantId = element.isTest == 1 ? element.testValue!.merchantId : element.liveValue!.merchantId;
            paytmMerchantKey = element.isTest == 1 ? element.testValue!.merchantKey : element.liveValue!.merchantKey;
          }
        });
      }
      selectedPaymentType = paymentList.first.type;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log('${error.toString()}');
    });
  }

  /// Razor Pay
  void razorPayPayment() {
    var options = {
      'key': razorKey.validate(),
      'amount': (widget.amount! * 100).round(),
      'name': mAppName,
      'description': mRazorDescription,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': sharedPref.getString(CONTACT_NUMBER),
        'email': sharedPref.getString(USER_EMAIL),
      },
      'external': {
        'wallets': ['paytm']
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      log(e.toString());
      debugPrint('Error: e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    toast(language.transactionSuccessful);
    paymentConfirm();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    toast(language.transactionFailed);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "EXTERNAL_WALLET: " + response.walletName!, toastLength: Toast.LENGTH_SHORT);
  }

  /// StripPayment
  void stripePay() async {
    Map<String, String> headers = {
      HttpHeaders.authorizationHeader: 'Bearer ${stripPaymentKey.validate()}',
      HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
    };

    var request = http.Request('POST', Uri.parse(stripeURL));

    request.bodyFields = {
      'amount': '${(widget.amount! * 100)}',
      'currency': "${appStore.currencyName.toUpperCase()}",
    };

    log(request.bodyFields);
    request.headers.addAll(headers);

    log(request);

    appStore.setLoading(true);

    await request.send().then((value) {
      appStore.setLoading(false);
      http.Response.fromStream(value).then((response) async {
        if (response.statusCode == 200) {
          var res = StripePayModel.fromJson(await handleResponse(response));

          SetupPaymentSheetParameters setupPaymentSheetParameters = SetupPaymentSheetParameters(
            paymentIntentClientSecret: res.clientSecret.validate(),
            style: ThemeMode.light,
            appearance: PaymentSheetAppearance(colors: PaymentSheetAppearanceColors(primary: primaryColor)),
            applePay: PaymentSheetApplePay(merchantCountryCode: appStore.currencyName.toUpperCase()),
            googlePay: PaymentSheetGooglePay(merchantCountryCode: appStore.currencyName.toUpperCase(), testEnv: true),
            merchantDisplayName: mAppName,
            customerId: appStore.userId.toString(),
          );

          await Stripe.instance.initPaymentSheet(paymentSheetParameters: setupPaymentSheetParameters).then((value) async {
            await Stripe.instance.presentPaymentSheet().then((value) async {
              toast(language.transactionSuccessful);
              paymentConfirm();
            });
          }).catchError((e) {
            log("presentPaymentSheet ${e.toString()}");
          });
        }
      }).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString(), print: true);
      });
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  Future<void> paymentConfirm() async {
    Map req = {
      "user_id": sharedPref.getInt(USER_ID),
      "type": "credit",
      "amount": widget.amount,
      "transaction_type": "topup",
      "currency": appStore.currencyName.toUpperCase(),
    };
    appStore.setLoading(true);
    await saveWallet(req).then((value) {
      appStore.setLoading(false);

      Navigator.pop(context);
    }).catchError((error) {
      appStore.setLoading(true);

      log(error.toString());
    });
  }

  ///PayStack Payment
  void payStackPayment(BuildContext context) async {
    Charge charge = Charge()
      ..amount = (widget.amount! * 100).round() // In base currency
      ..email = sharedPref.getString(USER_EMAIL)
      ..currency = appStore.currencyName.toUpperCase()
      ..accessCode;

    charge.reference = _getReference();

    try {
      CheckoutResponse response = await plugin.checkout(context, method: method, charge: charge, fullscreen: false);
      payStackUpdateStatus(response.reference, response.message);
      if (response.message == 'Success') {
        toast(language.transactionSuccessful);
        paymentConfirm();
      } else {
        toast(language.transactionFailed);
      }
    } catch (e) {
      payStackShowMessage(language.checkConsoleForError);
      rethrow;
    }
  }

  payStackUpdateStatus(String? reference, String message) {
    payStackShowMessage(message, Duration(seconds: 7));
  }

  void payStackShowMessage(String message, [Duration duration = const Duration(seconds: 4)]) {
    toast(message);
    log(message);
  }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }
    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Paypal Payment
  // void payPalPayment() async {
  //   appStore.setLoading(true);
  //   var request = BraintreeDropInRequest(
  //     tokenizationKey: payPalTokenizationKey,
  //     collectDeviceData: true,
  //     vaultManagerEnabled: true,
  //     requestThreeDSecureVerification: true,
  //     email: sharedPref.getString(USER_EMAIL).validate(),
  //     googlePaymentRequest: BraintreeGooglePaymentRequest(
  //       totalPrice: widget.amount.toString(),
  //       currencyCode: appStore.currencyCode,
  //       billingAddressRequired: false,
  //     ),
  //     applePayRequest: BraintreeApplePayRequest(
  //         currencyCode: appStore.currencyCode,
  //         supportedNetworks: [
  //           ApplePaySupportedNetworks.visa,
  //           ApplePaySupportedNetworks.masterCard,
  //         ],
  //         countryCode: 'US',
  //         merchantIdentifier: '',
  //         displayName: sharedPref.getString(USER_NAME).validate(),
  //         paymentSummaryItems: []),
  //     paypalRequest: BraintreePayPalRequest(
  //       amount: widget.amount.toString(),
  //       displayName: sharedPref.getString(USER_NAME).validate(),
  //     ),
  //     cardEnabled: true,
  //   );
  //   final result = await BraintreeDropIn.start(request);
  //   if (result != null) {
  //     appStore.setLoading(false);
  //     paymentConfirm();
  //   } else {
  //     appStore.setLoading(false);
  //   }
  // }

  void payPalPayment() async {
    final braintreePayment = BraintreePayment();
    final String token = payPalTokenizationKey!;
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    print("PayPal result: $packageInfo");
    try {
      final result = await braintreePayment.paypalPayment(
        PayPalRequest(
          token: token,
          amount: widget.amount.toString(),
          currencyCode: "EUR",
          displayName: "My Store",
          billingAgreementDescription: "Payment Description",
          androidAppLinkReturnUrl: packageInfo.packageName,
          androidDeepLinkFallbackUrlScheme: packageInfo.packageName,
        ),
      );
      print("PayPal result: $result");
      if (result != null) {
        appStore.setLoading(false);
        paymentConfirm();
      } else {
        appStore.setLoading(false);
      }
    } catch (e) {
      print('PayPal error: $e');
    }
  }

  // void payPalPayment() async {
  //   appStore.setLoading(true);
  //   var accessToken = await getPaypalAccessToken();
  //   String url = paypalValue['is_test'] == true ? 'https://api-m.sandbox.paypal.com/v2/checkout/orders' : 'https://api-m.paypal.com/v2/checkout/orders';
  //   Map<String, String> headers = {
  //     'Authorization': 'Bearer $accessToken',
  //     'Content-Type': 'application/json',
  //     'Accept': 'application/json',
  //   };
  //   Map<String, dynamic> body = {
  //     'intent': 'CAPTURE',
  //     'purchase_units': [
  //       {
  //         'amount': {
  //           // 'currency_code': '${appStore.currencyName.toUpperCase()}',
  //           'currency_code': 'EUR',
  //           'value': '${widget.amount?.toInt()}',
  //         },
  //         'description': 'Wallet Top UP',
  //       }
  //     ],
  //     'application_context': {
  //       'return_url': 'https://www.google.com',
  //       'cancel_url': 'https://login.yahoo.com',
  //       'shipping_preference': 'NO_SHIPPING',
  //     }
  //   };
  //   try {
  //     final response = await http.post(
  //       Uri.parse(url),
  //       headers: headers,
  //       body: jsonEncode(body),
  //     );
  //     if (response.statusCode == 201) {
  //       final data = jsonDecode(response.body);
  //       String orderId = data['id'];
  //       var link = paypalValue['is_test'] == true ? "https://www.sandbox.paypal.com/checkoutnow?token=${orderId}" : "https://www.paypal.com/checkoutnow?token=${orderId}";
  //       appStore.setLoading(false);
  //       launchScreen(
  //           navigatorKey.currentState!.overlay!.context,
  //           WebViewScreen(
  //               onClick: (msg) {
  //                 if (msg == "Success") {
  //                   paymentConfirm();
  //                 }
  //               },
  //               mInitialUrl: link));
  //     } else {
  //       toast("Payment failed: Invalid token or unsupported currency.", length: Toast.LENGTH_LONG);
  //       appStore.setLoading(false);
  //       return null;
  //     }
  //   } catch (e) {
  //     appStore.setLoading(false);
  //     return null;
  //   }
  // }

  Future<String?> getPaypalAccessToken() async {
    String url = paypalValue['is_test'] == true ? 'https://api-m.sandbox.paypal.com/v1/oauth2/token' : 'https://api-m.paypal.com/v1/oauth2/token';
    String credentials = '${paypalValue['client_id']}:${paypalValue['client_secret']}';
    String encodedCredentials = base64Encode(utf8.encode(credentials));

    Map<String, String> headers = {
      'Authorization': 'Basic $encodedCredentials',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    Map<String, String> body = {
      'grant_type': 'client_credentials',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String accessToken = data['access_token'];
        return accessToken;
      } else {
        print('Failed to get token: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  /// FlutterWave Payment
  void flutterWaveCheckout() async {
    final customer = Customer(name: sharedPref.getString(USER_NAME).validate(), phoneNumber: sharedPref.getString(CONTACT_NUMBER).validate(), email: sharedPref.getString(USER_EMAIL).validate());

    final Flutterwave flutterwave = Flutterwave(
      context: context,
      publicKey: flutterWavePublicKey.validate(),
      currency: appStore.currencyName.toLowerCase(),
      redirectUrl: "https://www.google.com",
      txRef: DateTime.now().millisecond.toString(),
      amount: widget.amount.toString(),
      customer: customer,
      paymentOptions: "card, payattitude",
      customization: Customization(title: "Test Payment"),
      isTestMode: isTestType,
    );
    final ChargeResponse response = await flutterwave.charge();
    if (response.status == 'successful') {
      toast(language.transactionSuccessful);
      paymentConfirm();
    } else {
      toast(language.transactionFailed);
    }
  }

  /// PayTabs Payment
  void payTabsPayment() {
    FlutterPaytabsBridge.startCardPayment(generateConfig(), (event) {
      setState(() {
        if (event["status"] == "success") {
          var transactionDetails = event["data"];
          if (transactionDetails["isSuccess"]) {
            toast(language.transactionSuccessful);
            paymentConfirm();
          } else {
            toast(language.transactionFailed);
          }
          toast(language.transactionSuccessful);
        } else if (event["status"] == "error") {
          toast(event["message"]);
        } else if (event["status"] == "event") {
          toast(event["message"]);
          //
        }
      });
    });
  }

  PaymentSdkConfigurationDetails generateConfig() {
    List<PaymentSdkAPms> apms = [];
    apms.add(PaymentSdkAPms.STC_PAY);
    var configuration = PaymentSdkConfigurationDetails(
        profileId: payTabsProfileId,
        serverKey: payTabsServerKey,
        clientKey: payTabsClientKey,
        cartDescription: language.appName,
        screentTitle: language.payWithCard,
        amount: widget.amount!.toDouble(),
        showBillingInfo: true,
        forceShippingInfo: false,
        currencyCode: appStore.currencyName.toUpperCase(),
        merchantCountryCode: "IN",
        billingDetails: payTab.BillingDetails(
          sharedPref.getString(USER_NAME).validate(),
          sharedPref.getString(USER_EMAIL).validate(),
          sharedPref.getString(CONTACT_NUMBER).validate(),
          sharedPref.getString(ADDRESS).validate(),
          '',
          '',
          '',
          '',
        ),
        alternativePaymentMethods: apms,
        linkBillingNameWithCardHolderName: true);

    var theme = IOSThemeConfigurations();

    theme.logoImage = ic_taxi_logo;

    configuration.iOSThemeConfigurations = theme;

    return configuration;
  }

  /// My Fatoorah Payment
  Future<void> myFatoorahPayment() async {
    PaymentResponse response = await MyFatoorah.startPayment(
      context: context,
      successChild: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 50, color: Colors.green),
            SizedBox(height: 16),
            Text(language.success, style: boldTextStyle(color: Colors.green, size: 24)),
          ],
        ),
      ),
      errorChild: Center(child: Text(language.failed, style: boldTextStyle(color: Colors.red, size: 24))),
      request: isTestType
          ? MyfatoorahRequest.test(
              currencyIso: Country.SaudiArabia,
              successUrl: 'https://pub.dev/packages/get',
              errorUrl: 'https://www.google.com/',
              invoiceAmount: widget.amount!.toDouble(),
              language: defaultLanguageCode == 'ar' ? ApiLanguage.Arabic : ApiLanguage.English,
              token: myFatoorahToken!,
            )
          : MyfatoorahRequest.live(
              currencyIso: Country.SaudiArabia,
              successUrl: 'https://pub.dev/packages/get',
              errorUrl: 'https://www.google.com/',
              invoiceAmount: widget.amount!.toDouble(),
              language: defaultLanguageCode == 'ar' ? ApiLanguage.Arabic : ApiLanguage.English,
              token: myFatoorahToken!,
            ),
    );
    if (response.isSuccess) {
      toast(language.transactionSuccessful);
      paymentConfirm();
    } else if (response.isError) {
      toast(language.paymentFailed);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.payment, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: paymentList.map((e) {
                return inkWellWidget(
                  onTap: () {
                    selectedPaymentType = e.type;
                    setState(() {});
                  },
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(defaultRadius),
                      border: Border.all(width: selectedPaymentType == e.type ? 1.5 : 1, color: selectedPaymentType == e.type ? primaryColor : dividerColor),
                    ),
                    child: Row(
                      children: [
                        Image.network(e.gatewayLogo!, width: 40, height: 40),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(e.title.validate(), style: primaryTextStyle(), maxLines: 2),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Observer(builder: (context) {
            if (!appStore.isLoading && paymentList.isEmpty) {
              return emptyWidget();
            }
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          }),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Visibility(
          visible: paymentList.isNotEmpty,
          child: AppButtonWidget(
            text: language.pay,
            onTap: () {
              if (selectedPaymentType == PAYMENT_TYPE_RAZORPAY) {
                razorPayPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_STRIPE) {
                stripePay();
              } else if (selectedPaymentType == PAYMENT_TYPE_PAYSTACK) {
                payStackPayment(context);
              } else if (selectedPaymentType == PAYMENT_TYPE_PAYPAL) {
                payPalPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_FLUTTERWAVE) {
                flutterWaveCheckout();
              } else if (selectedPaymentType == PAYMENT_TYPE_PAYTABS) {
                payTabsPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_MYFATOORAH) {
                myFatoorahPayment();
              }
            },
          ),
        ),
      ),
    );
  }
}
