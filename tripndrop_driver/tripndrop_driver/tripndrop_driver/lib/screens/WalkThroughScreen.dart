import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../languageConfiguration/LanguageDataConstant.dart';
import '../languageConfiguration/ServerLanguageResponse.dart';
import '../main.dart';
import '../model/WalkThroughModel.dart';
import '../network/RestApis.dart';
import '../screens/DashboardScreen.dart';
import '../screens/DocumentsScreen.dart';
import '../screens/EditProfileScreen.dart';
import '../screens/SignInScreen.dart';
import '../utils/Extensions/extension.dart';
import '../utils/utils.dart';

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
      name: language.driver_walkthrough_title_1,
      text: language.driver_walkthrough_subtitle_1,
      img: ic_walk1,
    ),
    WalkThroughModel(
      name: language.driver_walkthrough_title_2,
      text: language.driver_walkthrough_subtitle_2,
      img: ic_walk2,
    ),
    WalkThroughModel(
      name: language.driver_walkthrough_title_3,
      text: language.driver_walkthrough_subtitle_3,
      img: ic_walk3,
    )
  ];

  @override
  void initState() {
    super.initState();
    pageController.addListener(() => setState(() {}));
    _initializeApp();
    getAppSettingsData();
  }

  // ================== Main Initialization ==================
  void _initializeApp() async {
    await _checkNotifyPermission();

    // Check if user is logged in
    if (appStore.isLoggedIn) {
      // Agar user logged in hai to directly init() call karo
      await init();
    } else {
      // Agar user logged in nahi hai to walkthrough show karo
      setState(() {
        isCheckingAuth = false;
      });
    }
  }

  // ================== Background Logic (merged from SplashScreen) ==================
  Future<void> _checkNotifyPermission() async {
    String versionNo = sharedPref.getString(CURRENT_LAN_VERSION) ?? LanguageVersion;

    await getLanguageList(versionNo).then((value) async {
      await sharedPref.setString(OTP_STATUS, value.isOtpEnabled?.isOtpEnabled ?? '');
      appStore.setLoading(false);
      app_update_check = value.driver_version;

      if (value.status == true) {
        setValue(CURRENT_LAN_VERSION, value.currentVersionNo.toString());
        if (value.data!.isNotEmpty) {
          defaultServerLanguageData = value.data;
          performLanguageOperation(defaultServerLanguageData);
          setValue(LanguageJsonDataRes, value.toJson());

          bool isSetLanguage = sharedPref.getBool(IS_SELECTED_LANGUAGE_CHANGE) ?? false;
          if (!isSetLanguage) {
            for (var lang in value.data!) {
              if (lang.isDefaultLanguage == 1) {
                setValue(SELECTED_LANGUAGE_CODE, lang.languageCode);
                setValue(SELECTED_LANGUAGE_COUNTRY_CODE, lang.countryCode);
                appStore.setLanguage(lang.languageCode!, context: context);
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
          ServerLanguageResponse languageSettings = ServerLanguageResponse.fromJson(json.decode(getJsonData.trim()));
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

    // Permission check
    if (await Permission.notification.isGranted) {
      // Permission already granted
    } else {
      await Permission.notification.request();
    }
  }

  // ================== Main Initialization Logic ==================
  Future<void> init() async {
    List<ConnectivityResult> connection = await Connectivity().checkConnectivity();
    if (connection.contains(ConnectivityResult.none)) {
      toast(language.yourInternetIsNotWorking);
      setState(() {
        isCheckingAuth = false;
      });
      return;
    }

    await driverDetail();

    // Location permission + navigation logic
    await Future.delayed(Duration(seconds: 1));

    if (sharedPref.getBool(IS_FIRST_TIME) ?? true) {
      await Geolocator.requestPermission().then((value) async {
        Geolocator.getCurrentPosition().then((pos) {
          sharedPref.setDouble(LATITUDE, pos.latitude);
          sharedPref.setDouble(LONGITUDE, pos.longitude);
        });
      }).catchError((e) {});

      // First time hai but user logged in hai, to walkthrough skip karo
      setState(() {
        isCheckingAuth = false;
      });
    } else {
      // User logged in hai aur first time nahi hai
      if (sharedPref.getString(CONTACT_NUMBER).validate().isEmptyOrNull && appStore.isLoggedIn) {
        launchScreen(context, EditProfileScreen(isGoogle: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
      } else if (sharedPref.getString(UID).validate().isEmptyOrNull && appStore.isLoggedIn) {
        updateProfileUid().then((value) {
          if (sharedPref.getInt(IS_Verified_Driver) == 1) {
            launchScreen(context, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          } else {
            launchScreen(context, DocumentsScreen(isShow: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          }
        });
      } else if (sharedPref.getInt(IS_Verified_Driver) == 0 && appStore.isLoggedIn) {
        launchScreen(context, DocumentsScreen(isShow: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
      } else if (sharedPref.getInt(IS_Verified_Driver) == 1 && appStore.isLoggedIn) {
        launchScreen(context, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
      } else {
        launchScreen(context, SignInScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
      }
    }
  }

  Future<void> driverDetail() async {
    if (appStore.isLoggedIn) {
      await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) async {
        await sharedPref.setInt(IS_ONLINE, value.data!.isOnline!);
        if (value.data!.status == REJECT || value.data!.status == BANNED) {
          toast('${language.yourAccountIs} ${value.data!.status}. ${language.pleaseContactSystemAdministrator}');
          logout();
        }
        appStore.setUserEmail(value.data!.email.validate());
        appStore.setUserName(value.data!.username.validate());
        appStore.setFirstName(value.data!.firstName.validate());
        appStore.setUserProfile(value.data!.profileImage.validate());
        appStore.setReferralCode(value.data!.referralCode.validate());
        sharedPref.setString(USER_EMAIL, value.data!.email.validate());
        sharedPref.setString(FIRST_NAME, value.data!.firstName.validate());
        sharedPref.setString(LAST_NAME, value.data!.lastName.validate());
      }).catchError((error) {});
    }
  }

  // ================== UI ==================
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
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark),
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: walkThroughClass.length,
            controller: pageController,
            onPageChanged: (int i) {
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
                                color: Colors.grey.withValues(alpha: 0.9),
                                offset: Offset(1.5, 1.5),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
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
                SizedBox(height: 5),
                GestureDetector(
                  onTap: () {
                    if (currentPage >= walkThroughClass.length - 1) {
                      sharedPref.setBool(IS_FIRST_TIME, false);
                      launchScreen(context, SignInScreen(), isNewTask: true);
                    } else {
                      pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor),
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.arrow_forward, color: Colors.white),
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
                launchScreen(context, SignInScreen(), isNewTask: true);
              },
              child: Text(language.skip, style: boldTextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}