import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/LoginResponse.dart';
import '../utils/Constants.dart';
import 'BaseServices.dart';

class UserService extends BaseService {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;

  UserService() {
    ref = fireStore.collection(USER_COLLECTION);
  }

  Future<UserModel> userByEmail(String? email) async {
    return await ref!.where('email', isEqualTo: email).limit(1).get().then((value) {
      if (value.docs.isNotEmpty) {
        return UserModel.fromJson(value.docs.first.data() as Map<String, dynamic>);
      } else {
        throw 'No User Found';
      }
    });
  }
}
