/// Dispatch Service according to Eagle Rides Development Plan Section 5
/// Handles dispatch algorithm with priority window and broadcast logic

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/TripModel.dart';
import '../model/OfferModel.dart';
import '../model/DriverLocationModel.dart';
import 'dart:math' as math;

class DispatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  // Singleton pattern
  static final DispatchService _instance = DispatchService._internal();
  factory DispatchService() => _instance;
  DispatchService._internal();

  /// Stream subscription for incoming offers
  StreamSubscription<QuerySnapshot>? _offerSubscription;

  /// Listen for incoming ride offers for a driver
  Stream<List<OfferModel>> listenForOffers(String driverId) {
    return _firestore
        .collectionGroup('offers')
        .where('driver_id', isEqualTo: driverId)
        .where('status', isEqualTo: OfferStatus.OFFERED)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OfferModel.fromJson(data);
      }).where((offer) => !offer.isExpired).toList();
    });
  }

  /// Get a specific offer by trip ID and driver ID
  Future<OfferModel?> getOffer(String tripId, String driverId) async {
    try {
      final doc = await _firestore
          .collection('trip_requests')
          .doc(tripId)
          .collection('offers')
          .doc(driverId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return OfferModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting offer: $e');
      return null;
    }
  }

  /// Accept a trip offer (transactional to prevent double-acceptance)
  /// This is the race-condition safe implementation per Section 5.5
  Future<AcceptResult> acceptTrip(String tripId, String driverId) async {
    try {
      return await _firestore.runTransaction<AcceptResult>((transaction) async {
        // 1. Read trip document
        final tripRef = _firestore.collection('trips').doc(tripId);
        final tripDoc = await transaction.get(tripRef);

        if (!tripDoc.exists) {
          return AcceptResult(
            success: false,
            error: 'Trip not found',
            errorCode: 'TRIP_NOT_FOUND',
          );
        }

        final tripData = tripDoc.data()!;
        final currentStatus = tripData['status'];

        // 2. Ensure trip is still REQUESTED
        if (currentStatus != TripStatus.REQUESTED) {
          return AcceptResult(
            success: false,
            error: 'Trip already taken',
            errorCode: 'ALREADY_ACCEPTED',
          );
        }

        // 3. Get offer document
        final offerRef = _firestore
            .collection('trip_requests')
            .doc(tripId)
            .collection('offers')
            .doc(driverId);
        final offerDoc = await transaction.get(offerRef);

        if (!offerDoc.exists) {
          return AcceptResult(
            success: false,
            error: 'Offer not found',
            errorCode: 'OFFER_NOT_FOUND',
          );
        }

        final offerData = offerDoc.data()!;
        if (offerData['status'] != OfferStatus.OFFERED) {
          return AcceptResult(
            success: false,
            error: 'Offer no longer valid',
            errorCode: 'OFFER_INVALID',
          );
        }

        // Check if offer expired
        final expiresAt = DateTime.tryParse(offerData['expires_at'] ?? '');
        if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
          return AcceptResult(
            success: false,
            error: 'Offer has expired',
            errorCode: 'OFFER_EXPIRED',
          );
        }

        // 4. Transition: Accept the trip
        final now = DateTime.now();
        transaction.update(tripRef, {
          'status': TripStatus.ACCEPTED,
          'accepted_by': driverId,
          'accepted_at': now.toIso8601String(),
        });

        // 5. Mark offer as ACCEPTED
        transaction.update(offerRef, {
          'status': OfferStatus.ACCEPTED,
        });

        return AcceptResult(
          success: true,
          tripId: tripId,
          driverId: driverId,
          acceptedAt: now,
        );
      });
    } catch (e) {
      print('Error accepting trip: $e');
      return AcceptResult(
        success: false,
        error: e.toString(),
        errorCode: 'TRANSACTION_FAILED',
      );
    }
  }

  /// Reject a trip offer
  Future<bool> rejectTrip(String tripId, String driverId) async {
    try {
      await _firestore
          .collection('trip_requests')
          .doc(tripId)
          .collection('offers')
          .doc(driverId)
          .update({
        'status': OfferStatus.REJECTED,
      });
      return true;
    } catch (e) {
      print('Error rejecting trip: $e');
      return false;
    }
  }

  /// Get trip details by ID
  Future<TripModel?> getTrip(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return TripModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting trip: $e');
      return null;
    }
  }

  /// Listen for trip updates
  Stream<TripModel?> listenToTrip(String tripId) {
    return _firestore.collection('trips').doc(tripId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return TripModel.fromJson(data);
      }
      return null;
    });
  }

  /// Update driver location in RTDB
  /// Per Section 4.2: Update every 3-5 seconds OR every 20-30 meters
  Future<void> updateDriverLocation(
    String driverId,
    double lat,
    double lng, {
    double? heading,
  }) async {
    try {
      final ref = _rtdb.ref('drivers_locations/$driverId');
      await ref.set({
        'lat': lat,
        'lng': lng,
        if (heading != null) 'heading': heading,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating driver location: $e');
    }
  }

  /// Get driver location from RTDB
  Future<DriverLocationModel?> getDriverLocation(String driverId) async {
    try {
      final ref = _rtdb.ref('drivers_locations/$driverId');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data['driver_id'] = driverId;
        return DriverLocationModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting driver location: $e');
      return null;
    }
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Clean up subscriptions
  void dispose() {
    _offerSubscription?.cancel();
  }
}

/// Result of accept trip operation
class AcceptResult {
  final bool success;
  final String? tripId;
  final String? driverId;
  final DateTime? acceptedAt;
  final String? error;
  final String? errorCode;

  AcceptResult({
    required this.success,
    this.tripId,
    this.driverId,
    this.acceptedAt,
    this.error,
    this.errorCode,
  });

  bool get isAlreadyAccepted => errorCode == 'ALREADY_ACCEPTED';
  bool get isExpired => errorCode == 'OFFER_EXPIRED';
}
