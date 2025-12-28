/// Hourly Booking Service according to Eagle Rides Development Plan
/// Section 8: Rider app changes - Hourly booking UI, extensions, distance tracking

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/TripModel.dart';
import '../model/HourlyPricingModel.dart';
import '../model/TripTrackModel.dart';
import '../utils/DispatchConstants.dart';

class HourlyBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final HourlyBookingService _instance = HourlyBookingService._internal();
  factory HourlyBookingService() => _instance;
  HourlyBookingService._internal();

  // Track point recording state
  DateTime? _lastTrackPointTime;
  double? _lastTrackLat;
  double? _lastTrackLng;

  /// Get hourly pricing for a vehicle type
  Future<HourlyPricingModel?> getHourlyPricing(String vehicleType) async {
    try {
      final doc = await _firestore
          .collection('pricing')
          .doc('hourly')
          .collection('vehicle_types')
          .doc(vehicleType)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['vehicle_type'] = vehicleType;
        return HourlyPricingModel.fromJson(data);
      }

      // Return default pricing if not found
      return HourlyPricingModel(
        vehicleType: vehicleType,
        baseHourPrice: 75.0, // Default $75/hour
        includedMilesPerHour: 20,
        extraMileFee: 5.50,
        currency: 'USD',
      );
    } catch (e) {
      print('Error getting hourly pricing: $e');
      return null;
    }
  }

  /// Calculate hourly booking estimate
  Future<HourlyEstimate?> calculateEstimate(
    String vehicleType,
    int hours,
  ) async {
    if (hours < HourlyBookingConstants.minimumHours) {
      hours = HourlyBookingConstants.minimumHours;
    }

    final pricing = await getHourlyPricing(vehicleType);
    if (pricing == null) return null;

    return pricing.calculateEstimate(hours);
  }

  /// Request hourly extension (called by rider or driver)
  /// Per Section 8.3: Extension rounded to 10-minute blocks
  Future<ExtensionResult> requestExtension(
    String tripId,
    int extraMinutes,
    String requestedBy, // "RIDER" | "DRIVER"
  ) async {
    try {
      // Get trip details
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) {
        return ExtensionResult(
          success: false,
          error: 'Trip not found',
          errorCode: 'TRIP_NOT_FOUND',
        );
      }

      final tripData = tripDoc.data()!;
      tripData['id'] = tripId;
      final trip = TripModel.fromJson(tripData);

      // Verify it's an hourly booking
      if (!trip.isHourlyBooking) {
        return ExtensionResult(
          success: false,
          error: 'Not an hourly booking',
          errorCode: 'NOT_HOURLY',
        );
      }

      // Verify trip is in progress
      if (trip.status != TripStatus.STARTED) {
        return ExtensionResult(
          success: false,
          error: 'Trip must be started to request extension',
          errorCode: 'INVALID_STATUS',
        );
      }

      // Calculate rounded minutes and fee
      final roundedMinutes = HourlyBookingConstants.calculateRoundedMinutes(extraMinutes);
      final pricing = trip.pricingSnapshot;
      num extensionFee = 0;

      if (pricing != null && pricing.baseHourPrice != null) {
        final perMinuteRate = pricing.baseHourPrice! / 60;
        extensionFee = roundedMinutes * perMinuteRate;
      }

      // Create extension request
      final extensionRequest = ExtensionRequest(
        tripId: tripId,
        extraMinutes: extraMinutes,
        roundedMinutes: roundedMinutes,
        extensionFee: extensionFee,
        requestedBy: requestedBy,
        status: ExtensionStatus.PENDING,
        requestedAt: DateTime.now(),
      );

      // Store extension request
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('extensions')
          .add(extensionRequest.toJson());

      // Log event
      await _logTripEvent(tripId, 'EXTENSION_REQUESTED', {
        'requested_by': requestedBy,
        'extra_minutes': extraMinutes,
        'rounded_minutes': roundedMinutes,
        'extension_fee': extensionFee,
      });

      return ExtensionResult(
        success: true,
        tripId: tripId,
        roundedMinutes: roundedMinutes,
        extensionFee: extensionFee,
      );
    } catch (e) {
      return ExtensionResult(
        success: false,
        error: e.toString(),
        errorCode: 'REQUEST_FAILED',
      );
    }
  }

  /// Confirm hourly extension (driver confirms rider's request or vice versa)
  Future<ExtensionResult> confirmExtension(
    String tripId,
    String extensionId,
  ) async {
    try {
      // Store data for logging after transaction
      int? roundedMinutes;
      num? extensionFee;
      int? newExtension;

      final result = await _firestore.runTransaction<ExtensionResult>((transaction) async {
        // Get extension request
        final extensionRef = _firestore
            .collection('trips')
            .doc(tripId)
            .collection('extensions')
            .doc(extensionId);
        final extensionDoc = await transaction.get(extensionRef);

        if (!extensionDoc.exists) {
          return ExtensionResult(
            success: false,
            error: 'Extension request not found',
            errorCode: 'NOT_FOUND',
          );
        }

        final extensionData = extensionDoc.data()!;
        if (extensionData['status'] != ExtensionStatus.PENDING) {
          return ExtensionResult(
            success: false,
            error: 'Extension already processed',
            errorCode: 'ALREADY_PROCESSED',
          );
        }

        // Get trip
        final tripRef = _firestore.collection('trips').doc(tripId);
        final tripDoc = await transaction.get(tripRef);
        final tripData = tripDoc.data()!;

        // Calculate new total extension minutes
        final currentExtension = tripData['extension_minutes_total'] ?? 0;
        newExtension = currentExtension + (extensionData['rounded_minutes'] ?? 0);
        roundedMinutes = extensionData['rounded_minutes'];
        extensionFee = extensionData['extension_fee'];

        // Update trip with new extension total
        transaction.update(tripRef, {
          'extension_minutes_total': newExtension,
        });

        // Update extension status
        transaction.update(extensionRef, {
          'status': ExtensionStatus.CONFIRMED,
          'responded_at': DateTime.now().toIso8601String(),
        });

        return ExtensionResult(
          success: true,
          tripId: tripId,
          roundedMinutes: roundedMinutes,
          extensionFee: extensionFee,
          totalExtensionMinutes: newExtension,
        );
      });

      // Log event after transaction completes
      if (result.success) {
        await _logTripEvent(tripId, 'EXTENSION_CONFIRMED', {
          'extension_id': extensionId,
          'rounded_minutes': roundedMinutes,
          'total_extension_minutes': newExtension,
        });
      }

      return result;
    } catch (e) {
      return ExtensionResult(
        success: false,
        error: e.toString(),
        errorCode: 'CONFIRM_FAILED',
      );
    }
  }

  /// Reject hourly extension
  Future<ExtensionResult> rejectExtension(
    String tripId,
    String extensionId,
  ) async {
    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('extensions')
          .doc(extensionId)
          .update({
        'status': ExtensionStatus.REJECTED,
        'responded_at': DateTime.now().toIso8601String(),
      });

      await _logTripEvent(tripId, 'EXTENSION_REJECTED', {
        'extension_id': extensionId,
      });

      return ExtensionResult(
        success: true,
        tripId: tripId,
      );
    } catch (e) {
      return ExtensionResult(
        success: false,
        error: e.toString(),
        errorCode: 'REJECT_FAILED',
      );
    }
  }

  /// Get pending extension requests for a trip
  Future<List<ExtensionRequest>> getPendingExtensions(String tripId) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('extensions')
          .where('status', isEqualTo: ExtensionStatus.PENDING)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ExtensionRequest.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting pending extensions: $e');
      return [];
    }
  }

  /// Record track point for distance calculation
  /// Per Section 8.4: GPS breadcrumb tracking during STARTED → COMPLETED
  Future<void> recordTrackPoint(
    String tripId,
    double lat,
    double lng,
  ) async {
    // Check if we should record based on time/distance thresholds
    if (!TrackPointConfig.shouldRecord(
      _lastTrackPointTime,
      _lastTrackLat,
      _lastTrackLng,
      lat,
      lng,
    )) {
      return;
    }

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

      // Update last recorded point
      _lastTrackPointTime = DateTime.now();
      _lastTrackLat = lat;
      _lastTrackLng = lng;
    } catch (e) {
      print('Error recording track point: $e');
    }
  }

  /// Reset track point recording state (call when starting new trip)
  void resetTrackingState() {
    _lastTrackPointTime = null;
    _lastTrackLat = null;
    _lastTrackLng = null;
  }

  /// Get trip distance summary
  Future<TripTrackSummary> getTripDistance(String tripId) async {
    try {
      final snapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('track')
          .orderBy('ts')
          .get();

      final points = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TripTrackPoint.fromJson(data);
      }).toList();

      return TripTrackSummary.calculateFromPoints(tripId, points);
    } catch (e) {
      print('Error getting trip distance: $e');
      return TripTrackSummary(tripId: tripId, totalDistanceMiles: 0, totalDistanceKm: 0);
    }
  }

  /// Calculate remaining time for hourly booking
  HourlyTimeRemaining? calculateRemainingTime(TripModel trip) {
    if (!trip.isHourlyBooking || trip.startedAt == null || trip.hoursBooked == null) {
      return null;
    }

    final totalMinutes = (trip.hoursBooked! * 60) + (trip.extensionMinutesTotal ?? 0);
    final elapsedMinutes = DateTime.now().difference(trip.startedAt!).inMinutes;
    final remainingMinutes = totalMinutes - elapsedMinutes;

    return HourlyTimeRemaining(
      totalMinutes: totalMinutes,
      elapsedMinutes: elapsedMinutes,
      remainingMinutes: remainingMinutes > 0 ? remainingMinutes : 0,
      isOvertime: remainingMinutes < 0,
      overtimeMinutes: remainingMinutes < 0 ? -remainingMinutes : 0,
    );
  }

  /// Log trip event
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
}

/// Result of extension request/confirm
class ExtensionResult {
  final bool success;
  final String? tripId;
  final int? roundedMinutes;
  final num? extensionFee;
  final int? totalExtensionMinutes;
  final String? error;
  final String? errorCode;

  ExtensionResult({
    required this.success,
    this.tripId,
    this.roundedMinutes,
    this.extensionFee,
    this.totalExtensionMinutes,
    this.error,
    this.errorCode,
  });
}

/// Hourly booking time remaining calculation
class HourlyTimeRemaining {
  final int totalMinutes;
  final int elapsedMinutes;
  final int remainingMinutes;
  final bool isOvertime;
  final int overtimeMinutes;

  HourlyTimeRemaining({
    required this.totalMinutes,
    required this.elapsedMinutes,
    required this.remainingMinutes,
    required this.isOvertime,
    required this.overtimeMinutes,
  });

  String get formattedRemaining {
    if (isOvertime) {
      return '-${overtimeMinutes}m overtime';
    }
    final hours = remainingMinutes ~/ 60;
    final mins = remainingMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m remaining';
    }
    return '${mins}m remaining';
  }

  double get percentageRemaining {
    if (totalMinutes == 0) return 0;
    return (remainingMinutes / totalMinutes).clamp(0.0, 1.0);
  }
}
