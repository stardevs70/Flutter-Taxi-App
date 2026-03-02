import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taxi_booking/utils/Extensions/app_button.dart';

import '../main.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/DashBoardScreen.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class AuthServices {
/*  Future<User?> createAuthUser(String? email, String? password, bool isOtpLogin) async {
    User? userCredential;
    try {
      if (!isOtpLogin) {
        await _auth.createUserWithEmailAndPassword(email: email!, password: password!).then((value) {
          userCredential = value.user!;
        });
      } else {
        userCredential = _auth.currentUser;
      }
    } on FirebaseException catch (error) {
      if (error.code == "ERROR_EMAIL_ALREADY_IN_USE" || error.code == "account-exists-with-different-credential" || error.code == "email-already-in-use") {
        await _auth.signInWithEmailAndPassword(email: email!, password: password!).then((value) {
          userCredential = value.user!;
        });
      } else {
        toast(getMessageFromErrorCode(error));
      }
    }
    return userCredential;
  }*/
/*
  Future<User?> createAuthUser(
      String? email,
      String? password,
      bool isOtpLogin,
      ) async {
    User? user;

    try {
      if (!isOtpLogin) {
        UserCredential res =
        await _auth.createUserWithEmailAndPassword(
          email: email!,
          password: password!,
        );

        user = res.user;

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
        }
      } else {
        user = _auth.currentUser;
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        UserCredential res =
        await _auth.signInWithEmailAndPassword(
          email: email!,
          password: password!,
        );

        user = res.user;

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
        }
      } else {
        toast(getMessageFromErrorCode(error));
      }
    }

    return user;
  }
*/
  Future<User?> createAuthUser(
      String? email,
      String? password,
      bool isOtpLogin,
      ) async {
    User? user;

    try {
      if (!isOtpLogin) {
        UserCredential res =
        await _auth.createUserWithEmailAndPassword(
          email: email!,
          password: password!,
        );

        user = res.user;

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
        }
      } else {
        user = _auth.currentUser;
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        UserCredential res =
        await _auth.signInWithEmailAndPassword(
          email: email!,
          password: password!,
        );

        user = res.user;

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
        }
      } else {
        toast(getMessageFromErrorCode(error));
      }
    }

    return user;
  }

  Future<void> signUpWithEmailPassword(
    context, {
    String? email,
    String? password,
    String? mobileNumber,
    String? fName,
    String? lName,
    String? userName,
    String? userType,
    bool isOtpLogin = false,
  }) async {
    try {
      createAuthUser(email, password, isOtpLogin).then((user) async {
        if (user != null) {
          await user.reload();
          if (!user.emailVerified && !isOtpLogin) {
            appStore.setLoading(false);

            toast('Please verify your email before continuing');

          //  await FirebaseAuth.instance.signOut();
            launchScreen(context, VerifyEmailScreen(email: email??'', password:password??"", mobileNumber:  mobileNumber.validate(), fName: fName.validate() + " " + lName.validate(), lName:lName.validate(), userName:userName.validate(), userType: '',));
            return;
          }
          User currentUser = user;

          UserModel userModel = UserModel();

          /// Create user
          userModel.uid = currentUser.uid.validate();
          userModel.email = email;
          userModel.contactNumber = mobileNumber.validate();
          userModel.username = userName.validate();
          userModel.userType = userType.validate();
          userModel.displayName = fName.validate() + " " + lName.validate();
          userModel.firstName = fName.validate();
          userModel.lastName = lName.validate();
          userModel.createdAt = Timestamp.now().toDate().toString();
          userModel.updatedAt = Timestamp.now().toDate().toString();
          userModel.playerId = sharedPref.getString(PLAYER_ID).validate();
          sharedPref.setString(UID, user.uid.validate());

          await userService.addDocumentWithCustomId(currentUser.uid, userModel.toJson()).then((value) async {
            Map request = {
              "email": userModel.email,
              "password": password,
              "player_id": sharedPref.getString(PLAYER_ID).validate(),
              'user_type': RIDER,
            };
            if (isOtpLogin) {
              appStore.setLoading(false);
              updateProfileUid();
              launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
            } else {
              await logInApi(request).then((res) async {
                appStore.setLoading(false);
                updateProfileUid();
                launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
              }).catchError((e) {
                appStore.setLoading(false);
                log(e.toString());
                toast(e.toString());
              });
            }
          });
        } else {
          appStore.setLoading(false);
          throw 'Something went wrong';
        }
      });
    } on FirebaseException catch (error) {
      appStore.setLoading(false);
      toast(getMessageFromErrorCode(error));
    }
  }

  Future<void> loginFromFirebaseUser(User currentUser, {LoginResponse? loginDetail, String? fullName}) async {
    UserModel userModel = UserModel();
    if (await userService.isUserExist(loginDetail!.data!.email)) {
      ///Return user data
      await userService.userByEmail(loginDetail.data!.email).then((user) async {
        userModel = user;
        appStore.setUserEmail(userModel.email.validate());
        appStore.setUId(userModel.uid.validate());
      }).catchError((e) {
        log(e);
        throw e;
      });
    } else {
      /// Create user
      userModel.uid = currentUser.uid.validate();
      userModel.id = loginDetail.data!.id;
      userModel.email = loginDetail.data!.email.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.email = loginDetail.data!.email.validate();

      if (Platform.isIOS) {
        userModel.username = fullName;
      } else {
        userModel.username = loginDetail.data!.username.validate();
      }

      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.profileImage = loginDetail.data!.profileImage.validate();
      userModel.playerId = sharedPref.getString(PLAYER_ID);

      sharedPref.setString(UID, currentUser.uid.validate());
      log(sharedPref.getString(UID));
      sharedPref.setString(USER_EMAIL, userModel.email.validate());
      sharedPref.setBool(IS_LOGGED_IN, true);

      log(userModel.toJson());

      await userService.addDocumentWithCustomId(currentUser.uid, userModel.toJson()).then((value) {}).catchError((e) {
        throw e;
      });
    }
  }

  Future deleteUserFirebase() async {
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.currentUser!.delete();
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<bool> updateUserPassword(String newPassword) async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        await currentUser.updatePassword(newPassword);
        return true;
      } else {
        return false;
      }
    } on FirebaseException catch (error) {
      if (error.code == 'requires-recent-login') {
        toast("Please re-authenticate to update your password");
      } else {
        toast(getMessageFromErrorCode(error));
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
class VerifyEmailScreen extends StatefulWidget {
  final String? email;
  final String? password;
  final String? mobileNumber;
  final String? fName;
  final String? lName;
  final String? userName;
  final String? userType;
  final String? from;

  const VerifyEmailScreen({
    super.key,
     this.email,
     this.password,
     this.mobileNumber,
     this.fName,
     this.lName,
     this.userName,
     this.userType,
     this.from,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}




class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerification();
    });
  }

  Future<void> _checkVerification() async {
    if (_completed) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user!.emailVerified) {
      _completed = true;
      _timer?.cancel();
      await _onVerified(user);
    }
  }

  Future<void> _onVerified(User user) async {
    appStore.setLoading(true);
    User currentUser = user;
if(widget.from!="login") {
  UserModel userModel = UserModel();

  /// Create user
  userModel.uid = currentUser.uid.validate();
  userModel.email = widget.email;
  userModel.contactNumber = widget.mobileNumber.validate();
  userModel.username = widget.userName.validate();
  userModel.userType = widget.userType.validate();
  userModel.displayName =
      widget.fName.validate() + " " + widget.lName.validate();
  userModel.firstName = widget.fName.validate();
  userModel.lastName = widget.lName.validate();
  userModel.createdAt = Timestamp.now().toDate().toString();
  userModel.updatedAt = Timestamp.now().toDate().toString();
  userModel.playerId = sharedPref.getString(PLAYER_ID).validate();
  sharedPref.setString(UID, user.uid.validate());

  await userService.addDocumentWithCustomId(currentUser.uid, userModel.toJson())
      .then((value) async {
    Map request = {
      "email": userModel.email,
      "password": widget.password,
      "player_id": sharedPref.getString(PLAYER_ID).validate(),
      'user_type': RIDER,
    };
    appStore.setLoading(false);
    updateProfileUid();
    launchScreen(context, DashBoardScreen(), isNewTask: true,
        pageRouteAnimation: PageRouteAnimation.Slide);
  });
}else{
  launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);

}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please verify your email\nCheck your inbox',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            AppButton(
              onTap: _checkVerification,
              child: const Text('I have verified',style: TextStyle(color: Colors.white),),
            ),
            TextButton(

              onPressed: () async {
                await FirebaseAuth.instance.currentUser
                    ?.sendEmailVerification();
                toast('Verification email sent again');
              },
              child:  Text('Resend Email',style: TextStyle(color: primaryColor),),
            ),
          ],
        ),
      ),
    );
  }
}

