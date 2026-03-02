import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi_driver/model/FRideBookingModel.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

import '../utils/Constants.dart';
import 'BaseServices.dart';

class RideService extends BaseService {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  late CollectionReference rideRef;

  RideService() {
    print(RIDE_COLLECTION);
    print("RIDE_COLLECTION");
    rideRef = fireStore.collection(RIDE_COLLECTION);
  }

  Stream<QuerySnapshot> fetchRide({int? userId}) {
    // Query for pending rides so drivers can see new ride requests
    // Changed from driver_ids query to status query so all online drivers see pending rides
    return rideRef.where('status', isEqualTo: 'pending').snapshots();
  }

  /// Fetch rides assigned to this driver (for accepted/in-progress rides)
  Stream<QuerySnapshot> fetchMyRides({int? userId}) {
    return rideRef.where('driver_id', isEqualTo: userId).snapshots();
  }

  /// Fetch rides where this driver is in the driver_ids array (legacy)
  Stream<QuerySnapshot> fetchRideByDriverIds({int? userId}) {
    return rideRef.where('driver_ids', arrayContains: userId).snapshots();
  }

  Future<bool> removeOldRideEntry({int? userId}) async {
    try {
      QuerySnapshot<Object?> b = await rideRef.where('driver_id', isEqualTo: userId).get();
      List<FRideBookingModel> x = b.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
      FRideBookingModel y = x
          .where(
            (element) => element.status == COMPLETED || element.status == CANCELED,
          )
          .first;
      await rideRef.doc("ride_${y.rideId}").delete();
      return true;
    } catch (e) {
      log(e);
      return false;
    }
  }

  Future<List<FRideBookingModel>> fetchRideData({int? userId}) {
    return rideRef.where('driver_id', isEqualTo: userId).get().then((value) {
      return value.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> updateStatusOfRide({int? rideID, req}) {
    return rideRef.doc("ride_$rideID").update(req).then((value) {}).catchError((e) {
      log('Error status update $e');
    });
  }
}
