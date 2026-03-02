/// Trip Service according to Eagle Rides Development Plan
/// Handles trip lifecycle: ACCEPTED → ARRIVED → STARTED → COMPLETED
/// Also handles cancellation with 4-hour lock enforcement

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/TripModel.dart';
import '../model/TripTrackModel.dart';
import '../utils/DispatchConstants.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  /// Mark driver as arrived at pickup location
  /// Transition: ACCEPTED → ARRIVED
  Future<TripActionResult> markArrived(String tripId, String driverId) async {
    try {
      final result = await _firestore.runTransaction<TripActionResult>((transaction) async {
        final tripRef = _firestore.collection('trips').doc(tripId);
        final tripDoc = await transaction.get(tripRef);

        if (!tripDoc.exists) {
          return TripActionResult(
            success: false,
            error: 'Trip not found',
            errorCode: 'TRIP_NOT_FOUND',
          );
        }

        final tripData = tripDoc.data()!;
        final currentStatus = tripData['status'];
        final acceptedBy = tripData['accepted_by'];

        // Verify driver is assigned to this trip
        if (acceptedBy != driverId) {
          return TripActionResult(
            success: false,
            error: 'Not authorized',
            errorCode: 'NOT_AUTHORIZED',
          );
        }

        // Verify current status is ACCEPTED
        if (currentStatus != TripStatus.ACCEPTED) {
          return TripActionResult(
            success: false,
            error: 'Invalid status transition',
            errorCode: 'INVALID_TRANSITION',
          );
        }

        // Transition to ARRIVED
        final now = DateTime.now();
        transaction.update(tripRef, {
          'status': TripStatus.ARRIVED,
          'arrived_at': now.toIso8601String(),
        });

        return TripActionResult(
          success: true,
          tripId: tripId,
          newStatus: TripStatus.ARRIVED,
        );
      });

      // Log event after transaction completes
      if (result.success) {
        await _logTripEvent(tripId, TripEventTypes.ARRIVED, {
          'driver_id': driverId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return result;
    } catch (e) {
      return TripActionResult(
        success: false,
        error: e.toString(),
        errorCode: 'TRANSACTION_FAILED',
      );
    }
  }

  /// Start the trip
  /// Transition: ARRIVED → STARTED
  Future<TripActionResult> startTrip(String tripId, String driverId) async {
    try {
      final result = await _firestore.runTransaction<TripActionResult>((transaction) async {
        final tripRef = _firestore.collection('trips').doc(tripId);
        final tripDoc = await transaction.get(tripRef);

        if (!tripDoc.exists) {
          return TripActionResult(
            success: false,
            error: 'Trip not found',
            errorCode: 'TRIP_NOT_FOUND',
          );
        }

        final tripData = tripDoc.data()!;
        final currentStatus = tripData['status'];
        final acceptedBy = tripData['accepted_by'];

        // Verify driver is assigned to this trip
        if (acceptedBy != driverId) {
          return TripActionResult(
            success: false,
            error: 'Not authorized',
            errorCode: 'NOT_AUTHORIZED',
          );
        }

        // Verify current status is ARRIVED
        if (currentStatus != TripStatus.ARRIVED) {
          return TripActionResult(
            success: false,
            error: 'Invalid status transition',
            errorCode: 'INVALID_TRANSITION',
          );
        }

        // Transition to STARTED
        final now = DateTime.now();
        transaction.update(tripRef, {
          'status': TripStatus.STARTED,
          'started_at': now.toIso8601String(),
        });

        return TripActionResult(
          success: true,
          tripId: tripId,
          newStatus: TripStatus.STARTED,
        );
      });

      // Log event after transaction completes
      if (result.success) {
        await _logTripEvent(tripId, TripEventTypes.STARTED, {
          'driver_id': driverId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return result;
    } catch (e) {
      return TripActionResult(
        success: false,
        error: e.toString(),
        errorCode: 'TRANSACTION_FAILED',
      );
    }
  }

  /// Complete the trip with final billing calculation
  /// Transition: STARTED → COMPLETED
  Future<TripActionResult> completeTrip(
    String tripId,
    String driverId, {
    num? actualMiles,
  }) async {
    try {
      FinalBilling? finalBilling;

      final result = await _firestore.runTransaction<TripActionResult>((transaction) async {
        final tripRef = _firestore.collection('trips').doc(tripId);
        final tripDoc = await transaction.get(tripRef);

        if (!tripDoc.exists) {
          return TripActionResult(
            success: false,
            error: 'Trip not found',
            errorCode: 'TRIP_NOT_FOUND',
          );
        }

        final tripData = tripDoc.data()!;
        tripData['id'] = tripId;
        final trip = TripModel.fromJson(tripData);

        final currentStatus = trip.status;
        final acceptedBy = trip.acceptedBy;

        // Verify driver is assigned to this trip
        if (acceptedBy != driverId) {
          return TripActionResult(
            success: false,
            error: 'Not authorized',
            errorCode: 'NOT_AUTHORIZED',
          );
        }

        // Verify current status is STARTED
        if (currentStatus != TripStatus.STARTED) {
          return TripActionResult(
            success: false,
            error: 'Invalid status transition',
            errorCode: 'INVALID_TRANSITION',
          );
        }

        final now = DateTime.now();
        Map<String, dynamic> updates = {
          'status': TripStatus.COMPLETED,
          'completed_at': now.toIso8601String(),
        };

        // Calculate final billing for hourly trips
        if (trip.isHourlyBooking && trip.pricingSnapshot != null) {
          finalBilling = _calculateFinalBilling(trip, actualMiles ?? 0);
          updates['final'] = finalBilling!.toJson();
        }

        transaction.update(tripRef, updates);

        return TripActionResult(
          success: true,
          tripId: tripId,
          newStatus: TripStatus.COMPLETED,
        );
      });

      // Log event after transaction completes
      if (result.success) {
        await _logTripEvent(tripId, TripEventTypes.COMPLETED, {
          'driver_id': driverId,
          'timestamp': DateTime.now().toIso8601String(),
          'actual_miles': actualMiles,
          'final_billing': finalBilling?.toJson(),
        });
      }

      return result;
    } catch (e) {
      return TripActionResult(
        success: false,
        error: e.toString(),
        errorCode: 'TRANSACTION_FAILED',
      );
    }
  }

  /// Cancel trip with 4-hour lock enforcement
  /// Per Section 9: Driver cannot cancel within 4 hours unless adminOverride
  Future<TripActionResult> cancelTrip(
    String tripId,
    String cancelerId,
    String cancelerType, // "DRIVER" | "RIDER"
    String reason,
  ) async {
    try {
      final result = await _firestore.runTransaction<TripActionResult>((transaction) async {
        final tripRef = _firestore.collection('trips').doc(tripId);
        final tripDoc = await transaction.get(tripRef);

        if (!tripDoc.exists) {
          return TripActionResult(
            success: false,
            error: 'Trip not found',
            errorCode: 'TRIP_NOT_FOUND',
          );
        }

        final tripData = tripDoc.data()!;
        tripData['id'] = tripId;
        final trip = TripModel.fromJson(tripData);

        // If caller is driver, check cancellation lock
        if (cancelerType == CanceledBy.DRIVER) {
          if (!trip.canDriverCancel()) {
            return TripActionResult(
              success: false,
              error: trip.getCancellationLockMessage(),
              errorCode: 'CANCEL_LOCKED',
            );
          }
        }

        // Verify trip is in cancellable state
        final cancellableStatuses = [
          TripStatus.REQUESTED,
          TripStatus.ACCEPTED,
          TripStatus.ARRIVED,
        ];

        if (!cancellableStatuses.contains(trip.status)) {
          return TripActionResult(
            success: false,
            error: 'Trip cannot be cancelled in current state',
            errorCode: 'INVALID_TRANSITION',
          );
        }

        // Transition to CANCELED
        final now = DateTime.now();
        transaction.update(tripRef, {
          'status': TripStatus.CANCELED,
          'canceled_by': cancelerType,
          'cancel_reason': reason,
          'canceled_at': now.toIso8601String(),
        });

        return TripActionResult(
          success: true,
          tripId: tripId,
          newStatus: TripStatus.CANCELED,
        );
      });

      // Log event after transaction completes
      if (result.success) {
        await _logTripEvent(tripId, TripEventTypes.CANCELED, {
          'canceled_by': cancelerType,
          'canceler_id': cancelerId,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return result;
    } catch (e) {
      return TripActionResult(
        success: false,
        error: e.toString(),
        errorCode: 'TRANSACTION_FAILED',
      );
    }
  }

  /// Calculate final billing for hourly trips
  FinalBilling _calculateFinalBilling(TripModel trip, num actualMiles) {
    final pricing = trip.pricingSnapshot!;
    final hoursBooked = trip.hoursBooked ?? HourlyBookingConstants.minimumHours;
    final extensionMinutes = trip.extensionMinutesTotal ?? 0;
    final includedMiles = trip.includedMilesTotal ??
        (hoursBooked * (pricing.includedMilesPerHour ?? HourlyBookingConstants.defaultIncludedMilesPerHour));

    // Calculate base amount
    num baseAmount = (pricing.baseHourPrice ?? 0) * hoursBooked;

    // Calculate extension fee
    num extensionFee = 0;
    if (extensionMinutes > 0) {
      final roundedMinutes = HourlyBookingConstants.calculateRoundedMinutes(extensionMinutes);
      final perMinuteRate = (pricing.baseHourPrice ?? 0) / 60;
      extensionFee = roundedMinutes * perMinuteRate;
    }

    // Calculate extra miles fee
    num extraMiles = 0;
    num extraMilesFee = 0;
    if (actualMiles > includedMiles) {
      extraMiles = actualMiles - includedMiles;
      extraMilesFee = extraMiles * (pricing.extraMileFee ?? HourlyBookingConstants.defaultExtraMileFee);
    }

    // Calculate total
    num total = baseAmount + extensionFee + extraMilesFee;

    return FinalBilling(
      actualMiles: actualMiles,
      extraMiles: extraMiles,
      extraMilesFee: extraMilesFee,
      extensionFee: extensionFee,
      total: total,
    );
  }

  /// Add track point during trip for distance tracking
  Future<void> addTrackPoint(
    String tripId,
    double lat,
    double lng,
  ) async {
    try {
      final point = TripTrackPoint(
        lat: lat,
        lng: lng,
        ts: DateTime.now().millisecondsSinceEpoch,
      );

      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('track')
          .add(point.toJson());
    } catch (e) {
      print('Error adding track point: $e');
    }
  }

  /// Get all track points for a trip
  Future<List<TripTrackPoint>> getTrackPoints(String tripId) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('track')
          .orderBy('ts')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TripTrackPoint.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting track points: $e');
      return [];
    }
  }

  /// Calculate total distance from track points
  Future<TripTrackSummary> calculateTripDistance(String tripId) async {
    final points = await getTrackPoints(tripId);
    return TripTrackSummary.calculateFromPoints(tripId, points);
  }

  /// Log trip event for audit trail
  Future<void> _logTripEvent(
    String tripId,
    String eventType,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection('trip_events')
          .doc(tripId)
          .collection('events')
          .add({
        'type': eventType,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging trip event: $e');
    }
  }

  /// Get trip by ID
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

  /// Listen to trip changes
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

  /// Get active trips for a driver
  Future<List<TripModel>> getActiveTrips(String driverId) async {
    try {
      final activeStatuses = [
        TripStatus.ACCEPTED,
        TripStatus.ARRIVED,
        TripStatus.STARTED,
      ];

      final snapshot = await _firestore
          .collection('trips')
          .where('accepted_by', isEqualTo: driverId)
          .where('status', whereIn: activeStatuses)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TripModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting active trips: $e');
      return [];
    }
  }
}

/// Result of trip action
class TripActionResult {
  final bool success;
  final String? tripId;
  final String? newStatus;
  final String? error;
  final String? errorCode;

  TripActionResult({
    required this.success,
    this.tripId,
    this.newStatus,
    this.error,
    this.errorCode,
  });

  bool get isCancelLocked => errorCode == 'CANCEL_LOCKED';
  bool get isInvalidTransition => errorCode == 'INVALID_TRANSITION';
}
