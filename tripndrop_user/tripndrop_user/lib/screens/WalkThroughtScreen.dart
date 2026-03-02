import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';

import '../main.dart';
import '../model/WalkThroughModel.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/images.dart';
import '../screens/SignInScreen.dart';
import '../screens/EditProfileScreen.dart';
import '../screens/DashBoardScreen.dart';
import '../languageConfiguration/ServerLanguageResponse.dart';
import '../network/RestApis.dart';
import '../languageConfiguration/LanguageDataConstant.dart';

class WalkThroughScreen extends StatefulWidget {
  @override
  WalkThroughScreenState createState() => WalkThroughScreenState();
}

class WalkThroughScreenState extends State<WalkThroughScreen> {
  PageController pageController = PageController(viewportFraction: 1);
  int currentPage = 0;
  bool isCheckingAuth = true;

  List<WalkThroughModel> walkThroughClass = [
    WalkThroughModel(
      name: language.walkthrough_title_1,
      text: language.walkthrough_subtitle_1,
      img: ic_walk1,
    ),
    WalkThroughModel(
      name: language.walkthrough_title_2,
      text: language.walkthrough_subtitle_2,
      img: ic_walk2,
    ),
    WalkThroughModel(
      name: language.walkthrough_title_3,
      text: language.walkthrough_subtitle_3,
      img: ic_walk3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    pageController.addListener(() {
      setState(() {});
    });
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkNotifyPermission();

    // Agar user logged in hai, to directly navigate kar do
    if (appStore.isLoggedIn) {
      await _navigateLoggedInUser();
    } else {
      // Agar logged in nahi hai, to walkthrough show karo
      setState(() {
        isCheckingAuth = false;
      });
    }
  }

  Future<void> _checkNotifyPermission() async {
    String versionNo = sharedPref.getString(CURRENT_LAN_VERSION) ?? LanguageVersion;
    await getLanguageList(versionNo).then((value) async {
      await sharedPref.setString(OTP_STATUS, value.isOtpEnabled?.isOtpEnabled ?? '');
      appStore.setLoading(false);
      app_update_check = value.rider_version;
      if (value.status == true) {
        setValue(CURRENT_LAN_VERSION, value.currentVersionNo.toString());
        if (value.data!.isNotEmpty) {
          defaultServerLanguageData = value.data;
          performLanguageOperation(defaultServerLanguageData);
          setValue(LanguageJsonDataRes, value.toJson());
          bool isSetLanguage = sharedPref.getBool(IS_SELECTED_LANGUAGE_CHANGE) ?? false;
          if (!isSetLanguage) {
            for (var item in value.data!) {
              if (item.isDefaultLanguage == 1) {
                setValue(SELECTED_LANGUAGE_CODE, item.languageCode);
                setValue(SELECTED_LANGUAGE_COUNTRY_CODE, item.countryCode);
                appStore.setLanguage(item.languageCode!, context: context);
                break;
              }
            }
          }
        } else {
          defaultServerLanguageData = [];
          selectedServerLanguageData = null;
          setValue(LanguageJsonDataRes, "");
        }
      } else {
        String getJsonData = sharedPref.getString(LanguageJsonDataRes) ?? '';
        if (getJsonData.isNotEmpty) {
          ServerLanguageResponse languageSettings =
          ServerLanguageResponse.fromJson(json.decode(getJsonData.trim()));
          if (languageSettings.data!.isNotEmpty) {
            defaultServerLanguageData = languageSettings.data;
            performLanguageOperation(defaultServerLanguageData);
          }
        }
      }
    }).catchError((error) {
      appStore.setLoading(false);
      log(error);
    });
  }

  Future<void> _navigateLoggedInUser() async {
    if (sharedPref.getString(CONTACT_NUMBER).validate().isEmptyOrNull) {
      launchScreen(context, EditProfileScreen(isGoogle: true), isNewTask: true);
    } else {
      try {
        var user = await getUserDetail(userId: sharedPref.getInt(USER_ID));
        appStore.setUserEmail(user.data!.email.validate());
        appStore.setUserName(user.data!.username.validate());
        appStore.setFirstName(user.data!.firstName?.validate());
        appStore.setUserProfile(user.data!.profileImage.validate());
        appStore.setReferralCode(user.data!.referralCode?.validate());

        sharedPref.setString(USER_EMAIL, user.data!.email.validate());
        sharedPref.setString(FIRST_NAME, user.data!.firstName.validate());
        sharedPref.setString(LAST_NAME, user.data!.lastName.validate());
        sharedPref.setString(USER_PROFILE_PHOTO, user.data!.profileImage.validate());

        appStore.setLoading(false);

        if (await checkPermission()) {
          await Geolocator.requestPermission();
          Position pos = await Geolocator.getCurrentPosition();
          sharedPref.setDouble(LATITUDE, pos.latitude);
          sharedPref.setDouble(LONGITUDE, pos.longitude);
        }

        launchScreen(context, DashBoardScreen(), isNewTask: true);
      } catch (e) {
        log(e.toString());
        launchScreen(context, DashBoardScreen(), isNewTask: true);
      }
    }
  }

  Future<void> _handleNavigationLogic() async {
    List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      toast(language.yourInternetIsNotWorking);
      return;
    }

    if (sharedPref.getBool(IS_FIRST_TIME) ?? true) {
      await Geolocator.requestPermission().then((_) async {
        Position pos = await Geolocator.getCurrentPosition();
        sharedPref.setDouble(LATITUDE, pos.latitude);
        sharedPref.setDouble(LONGITUDE, pos.longitude);
      }).catchError((_) {});
    } else {
      if (!appStore.isLoggedIn) {
        launchScreen(context, SignInScreen(), isNewTask: true);
      } else {
        await _navigateLoggedInUser();
      }
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Agar auth check chal raha hai, to loading screen dikhao
    if (isCheckingAuth) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    // Agar user logged in nahi hai, to walkthrough dikhao
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: walkThroughClass.length,
            controller: pageController,
            onPageChanged: (i) {
              currentPage = i;
              setState(() {});
            },
            itemBuilder: (context, i) {
              double pageOffset = 0;
              try {
                pageOffset = pageController.page ?? 0;
              } catch (_) {}

              double scale = (1 - ((pageOffset - i).abs() * 0.2)).clamp(0.8, 1.0);
              double opacity = (1 - ((pageOffset - i).abs() * 0.5)).clamp(0.0, 1.0);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        walkThroughClass[i].img!,
                        fit: BoxFit.fill,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          walkThroughClass[i].name ?? "",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            shadows: [
                              Shadow(
                                blurRadius: 2.0,
                                color: Colors.grey.withAlpha(230),
                                offset: const Offset(1.5, 1.5),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            walkThroughClass[i].text ?? "",
                            style: secondaryTextStyle(size: 14, color: Colors.black),
                            maxLines: 4,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 20,
            right: 16,
            left: 16,
            child: Column(
              children: [
                dotIndicator(walkThroughClass, currentPage),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () {
                    if (currentPage >= walkThroughClass.length - 1) {
                      sharedPref.setBool(IS_FIRST_TIME, false);
                      _handleNavigationLogic();
                    } else {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: primaryColor),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 0,
            child: TextButton(
              onPressed: () {
                sharedPref.setBool(IS_FIRST_TIME, false);
                _handleNavigationLogic();
              },
              child: Text(language.skip, style: boldTextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}