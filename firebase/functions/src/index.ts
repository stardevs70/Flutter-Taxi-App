/**
 * Eagle Rides Cloud Functions
 * Implementation according to Development Plan Section 10
 *
 * Core functions:
 * - createTripRequest
 * - dispatchCycle
 * - acceptTrip (transaction)
 * - markArrived
 * - startTrip
 * - completeTrip (final billing)
 * - cancelTrip (lock enforcement)
 * - requestHourlyExtension
 * - confirmHourlyExtension
 * - expireOffers (scheduled)
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getDatabase } from "firebase-admin/database";

initializeApp();

// Get Firestore instance
const db = getFirestore();

// Lazy RTDB getter - only initialize when needed
function getRtdb() {
  return getDatabase();
}

// ============================================
// Constants (from Appendix A)
// ============================================
const PRIORITY_RATING_THRESHOLD = 4.8;
const PRIORITY_WINDOW_SEC = 3;
const OFFER_COUNTDOWN_SEC = 20;
const CYCLE_LENGTH_SEC = 30;
const MAX_DISPATCH_CYCLES = 3;
const RADIUS_PER_CYCLE = [3.0, 5.0, 8.0]; // km
const LOCATION_FRESHNESS_SEC = 15;
const CANCELLATION_LOCK_HOURS = 4;
const EXTRA_MILE_FEE = 5.50;
const EXTENSION_ROUNDING_MINUTES = 10;

// ============================================
// Types
// ============================================
interface LocationData {
  lat: number;
  lng: number;
  address?: string;
}

interface TripData {
  id?: string;
  type: "STANDARD" | "HOURLY";
  status: string;
  city_id: string;
  vehicle_type: string;
  pickup: LocationData;
  dropoff?: LocationData;
  scheduled_at?: string;
  created_at: string;
  rider_id: string;
  accepted_by?: string;
  accepted_at?: string;
  arrived_at?: string;
  started_at?: string;
  completed_at?: string;
  canceled_by?: string;
  cancel_reason?: string;
  admin_override?: boolean;
  dispatch?: {
    cycle: number;
    radius_km: number;
    priority_window_sec: number;
  };
  hours_booked?: number;
  pricing_snapshot?: {
    base_hour_price: number;
    included_miles_per_hour: number;
    extra_mile_fee: number;
    currency: string;
  } | null;
  included_miles_total?: number;
  extension_minutes_total?: number;
  final?: {
    actual_miles: number;
    extra_miles: number;
    extra_miles_fee: number;
    extension_fee: number;
    total: number;
  };
}

// ============================================
// Helper Functions
// ============================================

/**
 * Calculate Haversine distance between two points
 */
function calculateDistance(
  lat1: number, lon1: number,
  lat2: number, lon2: number
): number {
  const R = 6371; // Earth radius in km
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRadians(degrees: number): number {
  return degrees * Math.PI / 180;
}

/**
 * Get radius for dispatch cycle
 */
function getRadiusForCycle(cycle: number): number {
  const index = Math.min(cycle - 1, RADIUS_PER_CYCLE.length - 1);
  return RADIUS_PER_CYCLE[index];
}

/**
 * Log trip event for audit
 */
async function logTripEvent(
  tripId: string,
  eventType: string,
  data: Record<string, unknown>
): Promise<void> {
  await db.collection("trip_events").doc(tripId).collection("events").add({
    type: eventType,
    data: data,
    created_at: new Date().toISOString(),
  });
}

// ============================================
// 1. Create Trip Request (Section 5.1)
// ============================================
export const createTripRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const riderId = request.auth.uid;
  const data = request.data;
  const {
    type = "STANDARD",
    cityId,
    vehicleType,
    pickup,
    dropoff,
    scheduledAt,
    hoursBooked,
  } = data;

  // Validate required fields
  if (!cityId || !vehicleType || !pickup) {
    throw new HttpsError("invalid-argument", "Missing required fields");
  }

  // For hourly bookings, validate hours
  if (type === "HOURLY" && (!hoursBooked || hoursBooked < 2)) {
    throw new HttpsError("invalid-argument", "Hourly bookings require minimum 2 hours");
  }

  // Get hourly pricing if applicable
  let pricingSnapshot = null;
  let includedMilesTotal = 0;
  if (type === "HOURLY") {
    const pricingDoc = await db.collection("pricing")
      .doc("hourly")
      .collection("vehicle_types")
      .doc(vehicleType)
      .get();

    if (pricingDoc.exists) {
      const pricing = pricingDoc.data();
      pricingSnapshot = {
        base_hour_price: pricing?.base_hour_price || 75,
        included_miles_per_hour: pricing?.included_miles_per_hour || 20,
        extra_mile_fee: pricing?.extra_mile_fee || EXTRA_MILE_FEE,
        currency: pricing?.currency || "USD",
      };
      includedMilesTotal = hoursBooked * pricingSnapshot.included_miles_per_hour;
    }
  }

  // Create trip document
  const tripRef = db.collection("trips").doc();
  const tripData: TripData = {
    type,
    status: "REQUESTED",
    city_id: cityId,
    vehicle_type: vehicleType,
    pickup,
    dropoff: dropoff || null,
    scheduled_at: scheduledAt || null,
    created_at: new Date().toISOString(),
    rider_id: riderId,
    admin_override: false,
    dispatch: {
      cycle: 1,
      radius_km: RADIUS_PER_CYCLE[0],
      priority_window_sec: PRIORITY_WINDOW_SEC,
    },
    ...(type === "HOURLY" && {
      hours_booked: hoursBooked,
      pricing_snapshot: pricingSnapshot,
      included_miles_total: includedMilesTotal,
      extension_minutes_total: 0,
    }),
  };

  await tripRef.set(tripData);

  // Log event
  await logTripEvent(tripRef.id, "CREATED", {
    rider_id: riderId,
    type,
    vehicle_type: vehicleType,
  });

  // Start dispatch cycle
  await dispatchCycleInternal(tripRef.id, 1, RADIUS_PER_CYCLE[0]);

  return {
    success: true,
    tripId: tripRef.id,
  };
});

// ============================================
// 2. Dispatch Cycle (Section 5.2 - 5.4)
// ============================================
async function dispatchCycleInternal(
  tripId: string,
  cycle: number,
  radiusKm: number
): Promise<void> {
  const tripDoc = await db.collection("trips").doc(tripId).get();
  if (!tripDoc.exists) return;

  const trip = tripDoc.data() as TripData;

  // Only dispatch if still REQUESTED
  if (trip.status !== "REQUESTED") return;

  // Get eligible drivers
  const driversSnapshot = await db.collection("drivers")
    .where("online", "==", true)
    .where("status", "==", "AVAILABLE")
    .where("vehicle_type", "==", trip.vehicle_type)
    .where("city_id", "==", trip.city_id)
    .where("documents_verified", "==", true)
    .where("active", "==", true)
    .get();

  const eligibleDrivers: Array<{
    id: string;
    rating: number;
    distanceKm: number;
    isPriority: boolean;
  }> = [];

  const now = Date.now();

  for (const driverDoc of driversSnapshot.docs) {
    const driver = driverDoc.data();

    // Get driver location from RTDB
    const locationSnapshot = await getRtdb().ref(`drivers_locations/${driverDoc.id}`).get();
    if (!locationSnapshot.exists()) continue;

    const location = locationSnapshot.val();

    // Check location freshness (15 seconds)
    if (now - location.updated_at > LOCATION_FRESHNESS_SEC * 1000) continue;

    // Calculate distance to pickup
    const distanceKm = calculateDistance(
      location.lat, location.lng,
      trip.pickup.lat, trip.pickup.lng
    );

    // Check if within radius
    if (distanceKm > radiusKm) continue;

    eligibleDrivers.push({
      id: driverDoc.id,
      rating: driver.rating || 0,
      distanceKm,
      isPriority: (driver.rating || 0) >= PRIORITY_RATING_THRESHOLD,
    });
  }

  if (eligibleDrivers.length === 0) {
    // No eligible drivers in this cycle
    if (cycle >= MAX_DISPATCH_CYCLES) {
      // Max cycles reached - NO_DRIVER_FOUND
      await db.collection("trips").doc(tripId).update({
        status: "NO_DRIVER_FOUND",
      });
      await logTripEvent(tripId, "NO_DRIVER_FOUND", { cycle, radiusKm });
      return;
    }

    // Schedule next cycle after CYCLE_LENGTH_SEC seconds
    // In production, use Cloud Tasks or PubSub for delayed execution
    setTimeout(async () => {
      await dispatchCycleInternal(
        tripId,
        cycle + 1,
        getRadiusForCycle(cycle + 1)
      );
    }, CYCLE_LENGTH_SEC * 1000);

    return;
  }

  // Split into priority and general drivers
  const priorityDrivers = eligibleDrivers.filter((d) => d.isPriority);
  const generalDrivers = eligibleDrivers.filter((d) => !d.isPriority);

  // Create offer documents
  const batch = db.batch();
  const expiresAt = new Date(Date.now() + OFFER_COUNTDOWN_SEC * 1000).toISOString();

  // Priority drivers first
  for (const driver of priorityDrivers) {
    const offerRef = db.collection("trip_requests")
      .doc(tripId)
      .collection("offers")
      .doc(driver.id);

    batch.set(offerRef, {
      trip_id: tripId,
      driver_id: driver.id,
      status: "OFFERED",
      created_at: new Date().toISOString(),
      expires_at: expiresAt,
      priority_tier: "PRIORITY",
      distance_km: driver.distanceKm,
      cycle,
    });
  }

  await batch.commit();

  // Send push notifications to priority drivers
  // (Implement FCM/OneSignal notification here)

  await logTripEvent(tripId, "DISPATCH_CYCLE", {
    cycle,
    radiusKm,
    priorityDriversCount: priorityDrivers.length,
    generalDriversCount: generalDrivers.length,
  });

  // After priority window, create offers for general drivers
  setTimeout(async () => {
    const tripCheck = await db.collection("trips").doc(tripId).get();
    if (tripCheck.data()?.status !== "REQUESTED") return;

    const generalBatch = db.batch();
    for (const driver of generalDrivers) {
      const offerRef = db.collection("trip_requests")
        .doc(tripId)
        .collection("offers")
        .doc(driver.id);

      generalBatch.set(offerRef, {
        trip_id: tripId,
        driver_id: driver.id,
        status: "OFFERED",
        created_at: new Date().toISOString(),
        expires_at: expiresAt,
        priority_tier: "GENERAL",
        distance_km: driver.distanceKm,
        cycle,
      });
    }
    await generalBatch.commit();

    // Send push notifications to general drivers
  }, PRIORITY_WINDOW_SEC * 1000);
}

// ============================================
// 3. Accept Trip (Section 5.5 - Race-condition safe)
// ============================================
export const acceptTrip = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const driverId = request.auth.uid;
  const { tripId } = request.data;

  if (!tripId) {
    throw new HttpsError("invalid-argument", "Trip ID required");
  }

  try {
    const result = await db.runTransaction(async (transaction) => {
      // 1. Read trip document
      const tripRef = db.collection("trips").doc(tripId);
      const tripDoc = await transaction.get(tripRef);

      if (!tripDoc.exists) {
        return { success: false, error: "Trip not found", errorCode: "TRIP_NOT_FOUND" };
      }

      const trip = tripDoc.data() as TripData;

      // 2. Ensure trip is still REQUESTED
      if (trip.status !== "REQUESTED") {
        return { success: false, error: "Trip already taken", errorCode: "ALREADY_ACCEPTED" };
      }

      // 3. Check offer exists and is valid
      const offerRef = db.collection("trip_requests")
        .doc(tripId)
        .collection("offers")
        .doc(driverId);
      const offerDoc = await transaction.get(offerRef);

      if (!offerDoc.exists) {
        return { success: false, error: "Offer not found", errorCode: "OFFER_NOT_FOUND" };
      }

      const offer = offerDoc.data();
      if (offer?.status !== "OFFERED") {
        return { success: false, error: "Offer no longer valid", errorCode: "OFFER_INVALID" };
      }

      // Check expiration
      if (offer?.expires_at && new Date(offer.expires_at) < new Date()) {
        return { success: false, error: "Offer expired", errorCode: "OFFER_EXPIRED" };
      }

      // 4. Accept the trip
      const now = new Date().toISOString();
      transaction.update(tripRef, {
        status: "ACCEPTED",
        accepted_by: driverId,
        accepted_at: now,
      });

      // 5. Mark offer as ACCEPTED
      transaction.update(offerRef, {
        status: "ACCEPTED",
      });

      // 6. Update driver status
      const driverRef = db.collection("drivers").doc(driverId);
      transaction.update(driverRef, {
        status: "ON_TRIP",
      });

      return {
        success: true,
        tripId,
        driverId,
        acceptedAt: now,
      };
    });

    if (result.success) {
      await logTripEvent(tripId, "ACCEPTED", { driver_id: driverId });
    }

    return result;
  } catch (error) {
    console.error("Accept trip error:", error);
    throw new HttpsError("internal", "Failed to accept trip");
  }
});

// ============================================
// 4. Mark Arrived
// ============================================
export const markArrived = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const driverId = request.auth.uid;
  const { tripId } = request.data;

  const result = await db.runTransaction(async (transaction) => {
    const tripRef = db.collection("trips").doc(tripId);
    const tripDoc = await transaction.get(tripRef);

    if (!tripDoc.exists) {
      return { success: false, error: "Trip not found" };
    }

    const trip = tripDoc.data() as TripData;

    if (trip.accepted_by !== driverId) {
      return { success: false, error: "Not authorized" };
    }

    if (trip.status !== "ACCEPTED") {
      return { success: false, error: "Invalid status transition" };
    }

    const now = new Date().toISOString();
    transaction.update(tripRef, {
      status: "ARRIVED",
      arrived_at: now,
    });

    return { success: true, tripId, newStatus: "ARRIVED" };
  });

  if (result.success) {
    await logTripEvent(tripId, "ARRIVED", { driver_id: driverId });
  }

  return result;
});

// ============================================
// 5. Start Trip
// ============================================
export const startTrip = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const driverId = request.auth.uid;
  const { tripId } = request.data;

  const result = await db.runTransaction(async (transaction) => {
    const tripRef = db.collection("trips").doc(tripId);
    const tripDoc = await transaction.get(tripRef);

    if (!tripDoc.exists) {
      return { success: false, error: "Trip not found" };
    }

    const trip = tripDoc.data() as TripData;

    if (trip.accepted_by !== driverId) {
      return { success: false, error: "Not authorized" };
    }

    if (trip.status !== "ARRIVED") {
      return { success: false, error: "Invalid status transition" };
    }

    const now = new Date().toISOString();
    transaction.update(tripRef, {
      status: "STARTED",
      started_at: now,
    });

    return { success: true, tripId, newStatus: "STARTED" };
  });

  if (result.success) {
    await logTripEvent(tripId, "STARTED", { driver_id: driverId });
  }

  return result;
});

// ============================================
// 6. Complete Trip (with final billing for hourly)
// ============================================
export const completeTrip = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const driverId = request.auth.uid;
  const { tripId, actualMiles } = request.data;

  const result = await db.runTransaction(async (transaction) => {
    const tripRef = db.collection("trips").doc(tripId);
    const tripDoc = await transaction.get(tripRef);

    if (!tripDoc.exists) {
      return { success: false, error: "Trip not found" };
    }

    const trip = tripDoc.data() as TripData;

    if (trip.accepted_by !== driverId) {
      return { success: false, error: "Not authorized" };
    }

    if (trip.status !== "STARTED") {
      return { success: false, error: "Invalid status transition" };
    }

    const now = new Date().toISOString();
    const updates: Record<string, unknown> = {
      status: "COMPLETED",
      completed_at: now,
    };

    // Calculate final billing for hourly trips
    if (trip.type === "HOURLY" && trip.pricing_snapshot) {
      const pricing = trip.pricing_snapshot;
      const hoursBooked = trip.hours_booked || 2;
      const extensionMinutes = trip.extension_minutes_total || 0;
      const includedMiles = trip.included_miles_total ||
        (hoursBooked * pricing.included_miles_per_hour);

      // Base amount
      const baseAmount = pricing.base_hour_price * hoursBooked;

      // Extension fee
      let extensionFee = 0;
      if (extensionMinutes > 0) {
        const roundedMinutes = Math.ceil(extensionMinutes / EXTENSION_ROUNDING_MINUTES) *
          EXTENSION_ROUNDING_MINUTES;
        const perMinuteRate = pricing.base_hour_price / 60;
        extensionFee = roundedMinutes * perMinuteRate;
      }

      // Extra miles fee
      let extraMiles = 0;
      let extraMilesFee = 0;
      const miles = actualMiles || 0;
      if (miles > includedMiles) {
        extraMiles = miles - includedMiles;
        extraMilesFee = extraMiles * pricing.extra_mile_fee;
      }

      updates.final = {
        actual_miles: miles,
        extra_miles: extraMiles,
        extra_miles_fee: extraMilesFee,
        extension_fee: extensionFee,
        total: baseAmount + extensionFee + extraMilesFee,
      };
    }

    transaction.update(tripRef, updates);

    // Update driver status back to AVAILABLE
    const driverRef = db.collection("drivers").doc(driverId);
    transaction.update(driverRef, {
      status: "AVAILABLE",
    });

    return { success: true, tripId, newStatus: "COMPLETED", final: updates.final };
  });

  if (result.success) {
    await logTripEvent(tripId, "COMPLETED", {
      driver_id: driverId,
      actual_miles: actualMiles,
      final: result.final,
    });
  }

  return result;
});

// ============================================
// 7. Cancel Trip (with 4-hour lock enforcement)
// ============================================
export const cancelTrip = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = request.auth.uid;
  const { tripId, cancelerType, reason } = request.data;

  const result = await db.runTransaction(async (transaction) => {
    const tripRef = db.collection("trips").doc(tripId);
    const tripDoc = await transaction.get(tripRef);

    if (!tripDoc.exists) {
      return { success: false, error: "Trip not found", errorCode: "TRIP_NOT_FOUND" };
    }

    const trip = tripDoc.data() as TripData;

    // If caller is driver, check cancellation lock
    if (cancelerType === "DRIVER") {
      if (trip.accepted_by !== userId) {
        return { success: false, error: "Not authorized", errorCode: "NOT_AUTHORIZED" };
      }

      // Check 4-hour lock
      if (trip.scheduled_at && !trip.admin_override) {
        const scheduledTime = new Date(trip.scheduled_at);
        const now = new Date();
        const hoursUntilPickup = (scheduledTime.getTime() - now.getTime()) / (1000 * 60 * 60);

        if (hoursUntilPickup <= CANCELLATION_LOCK_HOURS) {
          return {
            success: false,
            error: `Cannot cancel within ${CANCELLATION_LOCK_HOURS} hours of pickup. Contact admin for override.`,
            errorCode: "CANCEL_LOCKED",
          };
        }
      }
    }

    // Verify cancellable state
    const cancellableStatuses = ["REQUESTED", "ACCEPTED", "ARRIVED"];
    if (!cancellableStatuses.includes(trip.status)) {
      return { success: false, error: "Trip cannot be cancelled", errorCode: "INVALID_TRANSITION" };
    }

    const now = new Date().toISOString();
    transaction.update(tripRef, {
      status: "CANCELED",
      canceled_by: cancelerType,
      cancel_reason: reason || "",
      canceled_at: now,
    });

    // If driver was assigned, update their status
    if (trip.accepted_by) {
      const driverRef = db.collection("drivers").doc(trip.accepted_by);
      transaction.update(driverRef, {
        status: "AVAILABLE",
      });
    }

    return { success: true, tripId, newStatus: "CANCELED" };
  });

  if (result.success) {
    await logTripEvent(tripId, "CANCELED", {
      canceled_by: cancelerType,
      canceler_id: userId,
      reason,
    });
  }

  return result;
});

// ============================================
// 8. Request Hourly Extension
// ============================================
export const requestHourlyExtension = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // request.auth.uid can be used to verify caller if needed
  const { tripId, extraMinutes, requestedBy } = request.data;

  const tripDoc = await db.collection("trips").doc(tripId).get();
  if (!tripDoc.exists) {
    throw new HttpsError("not-found", "Trip not found");
  }

  const trip = tripDoc.data() as TripData;

  if (trip.type !== "HOURLY") {
    throw new HttpsError("failed-precondition", "Not an hourly booking");
  }

  if (trip.status !== "STARTED") {
    throw new HttpsError("failed-precondition", "Trip must be started");
  }

  // Calculate rounded minutes and fee
  const roundedMinutes = Math.ceil(extraMinutes / EXTENSION_ROUNDING_MINUTES) *
    EXTENSION_ROUNDING_MINUTES;

  let extensionFee = 0;
  if (trip.pricing_snapshot) {
    const perMinuteRate = trip.pricing_snapshot.base_hour_price / 60;
    extensionFee = roundedMinutes * perMinuteRate;
  }

  const extensionRef = await db.collection("trips")
    .doc(tripId)
    .collection("extensions")
    .add({
      trip_id: tripId,
      extra_minutes: extraMinutes,
      rounded_minutes: roundedMinutes,
      extension_fee: extensionFee,
      requested_by: requestedBy,
      status: "PENDING",
      requested_at: new Date().toISOString(),
    });

  await logTripEvent(tripId, "EXTENSION_REQUESTED", {
    requested_by: requestedBy,
    extra_minutes: extraMinutes,
    rounded_minutes: roundedMinutes,
    extension_fee: extensionFee,
  });

  return {
    success: true,
    extensionId: extensionRef.id,
    roundedMinutes,
    extensionFee,
  };
});

// ============================================
// 9. Confirm Hourly Extension
// ============================================
export const confirmHourlyExtension = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { tripId, extensionId } = request.data;

  const result = await db.runTransaction(async (transaction) => {
    const extensionRef = db.collection("trips")
      .doc(tripId)
      .collection("extensions")
      .doc(extensionId);
    const extensionDoc = await transaction.get(extensionRef);

    if (!extensionDoc.exists) {
      return { success: false, error: "Extension not found" };
    }

    const extension = extensionDoc.data();
    if (extension?.status !== "PENDING") {
      return { success: false, error: "Extension already processed" };
    }

    const tripRef = db.collection("trips").doc(tripId);
    const tripDoc = await transaction.get(tripRef);
    const trip = tripDoc.data() as TripData;

    const currentExtension = trip.extension_minutes_total || 0;
    const newExtension = currentExtension + (extension?.rounded_minutes || 0);

    transaction.update(tripRef, {
      extension_minutes_total: newExtension,
    });

    transaction.update(extensionRef, {
      status: "CONFIRMED",
      responded_at: new Date().toISOString(),
    });

    return {
      success: true,
      tripId,
      totalExtensionMinutes: newExtension,
    };
  });

  if (result.success) {
    await logTripEvent(tripId, "EXTENSION_CONFIRMED", {
      extension_id: extensionId,
      total_extension_minutes: result.totalExtensionMinutes,
    });
  }

  return result;
});

// ============================================
// 10. Expire Offers (Scheduled function)
// ============================================
export const expireOffers = onSchedule("every 1 minutes", async () => {
  const now = new Date().toISOString();

  // Find all expired offers
  const offersSnapshot = await db.collectionGroup("offers")
    .where("status", "==", "OFFERED")
    .where("expires_at", "<=", now)
    .get();

  const batch = db.batch();
  let count = 0;

  offersSnapshot.forEach((doc) => {
    batch.update(doc.ref, { status: "EXPIRED" });
    count++;
  });

  if (count > 0) {
    await batch.commit();
    console.log(`Expired ${count} offers`);
  }
});

// ============================================
// Admin Override
// ============================================
export const setAdminOverride = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // Verify admin role
  const adminDoc = await db.collection("admins").doc(request.auth.uid).get();
  if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin access required");
  }

  const { tripId, override } = request.data;

  await db.collection("trips").doc(tripId).update({
    admin_override: override === true,
  });

  await logTripEvent(tripId, "ADMIN_OVERRIDE", {
    admin_id: request.auth.uid,
    override,
  });

  return { success: true };
});
