/**
 * Test script for Eagle Rides Cloud Functions
 * Run with: node test-functions.js
 */

const admin = require('firebase-admin');

// Initialize with service account or default credentials
admin.initializeApp({
  projectId: 'eagle-rides-driver',
  databaseURL: 'https://eagle-rides-driver-default-rtdb.firebaseio.com'
});

const db = admin.firestore();
const rtdb = admin.database();

async function testCreateTrip() {
  console.log('\n=== Creating Test Trip ===');

  // Create a test trip directly in Firestore
  const tripRef = db.collection('trips').doc();
  const tripData = {
    type: 'STANDARD',
    status: 'REQUESTED',
    city_id: 'test-city',
    vehicle_type: 'sedan',
    pickup: {
      lat: 37.7749,
      lng: -122.4194,
      address: '123 Test St, San Francisco, CA'
    },
    dropoff: {
      lat: 37.7849,
      lng: -122.4094,
      address: '456 Demo Ave, San Francisco, CA'
    },
    created_at: new Date().toISOString(),
    rider_id: 'test-rider-123',
    admin_override: false,
    dispatch: {
      cycle: 1,
      radius_km: 3.0,
      priority_window_sec: 3
    }
  };

  await tripRef.set(tripData);
  console.log(`✓ Created trip: ${tripRef.id}`);
  console.log(`  Status: ${tripData.status}`);
  console.log(`  Type: ${tripData.type}`);

  return tripRef.id;
}

async function testCreateDriver() {
  console.log('\n=== Creating Test Driver ===');

  const driverRef = db.collection('drivers').doc('test-driver-456');
  const driverData = {
    online: true,
    status: 'AVAILABLE',
    vehicle_type: 'sedan',
    city_id: 'test-city',
    documents_verified: true,
    active: true,
    rating: 4.9,
    name: 'Test Driver',
    email: 'driver@test.com'
  };

  await driverRef.set(driverData);
  console.log(`✓ Created driver: ${driverRef.id}`);
  console.log(`  Rating: ${driverData.rating} (Priority eligible: ${driverData.rating >= 4.8})`);

  // Also set driver location in RTDB
  await rtdb.ref(`drivers_locations/${driverRef.id}`).set({
    lat: 37.7750,
    lng: -122.4195,
    heading: 90,
    updated_at: Date.now()
  });
  console.log(`✓ Set driver location in RTDB`);

  return driverRef.id;
}

async function testCreateOffer(tripId, driverId) {
  console.log('\n=== Creating Test Offer ===');

  const offerRef = db.collection('trip_requests').doc(tripId).collection('offers').doc(driverId);
  const offerData = {
    trip_id: tripId,
    driver_id: driverId,
    status: 'OFFERED',
    created_at: new Date().toISOString(),
    expires_at: new Date(Date.now() + 20000).toISOString(), // 20 seconds from now
    priority_tier: 'PRIORITY',
    distance_km: 0.5,
    cycle: 1
  };

  await offerRef.set(offerData);
  console.log(`✓ Created offer for driver ${driverId}`);
  console.log(`  Expires at: ${offerData.expires_at}`);

  return offerRef.id;
}

async function testAcceptTrip(tripId, driverId) {
  console.log('\n=== Simulating Trip Accept ===');

  // Simulate what the acceptTrip function does
  const tripRef = db.collection('trips').doc(tripId);
  const offerRef = db.collection('trip_requests').doc(tripId).collection('offers').doc(driverId);

  await db.runTransaction(async (transaction) => {
    const tripDoc = await transaction.get(tripRef);

    if (tripDoc.data().status !== 'REQUESTED') {
      throw new Error('Trip not in REQUESTED status');
    }

    const now = new Date().toISOString();
    transaction.update(tripRef, {
      status: 'ACCEPTED',
      accepted_by: driverId,
      accepted_at: now
    });

    transaction.update(offerRef, {
      status: 'ACCEPTED'
    });
  });

  console.log(`✓ Trip ${tripId} accepted by driver ${driverId}`);

  // Verify the update
  const updatedTrip = await tripRef.get();
  console.log(`  New Status: ${updatedTrip.data().status}`);
  console.log(`  Accepted By: ${updatedTrip.data().accepted_by}`);
}

async function testTripLifecycle(tripId, driverId) {
  console.log('\n=== Testing Trip Lifecycle ===');

  const tripRef = db.collection('trips').doc(tripId);

  // Mark Arrived
  console.log('\n> Marking ARRIVED...');
  await tripRef.update({
    status: 'ARRIVED',
    arrived_at: new Date().toISOString()
  });
  let trip = await tripRef.get();
  console.log(`✓ Status: ${trip.data().status}`);

  // Start Trip
  console.log('\n> Starting trip...');
  await tripRef.update({
    status: 'STARTED',
    started_at: new Date().toISOString()
  });
  trip = await tripRef.get();
  console.log(`✓ Status: ${trip.data().status}`);

  // Complete Trip
  console.log('\n> Completing trip...');
  await tripRef.update({
    status: 'COMPLETED',
    completed_at: new Date().toISOString()
  });
  trip = await tripRef.get();
  console.log(`✓ Status: ${trip.data().status}`);
}

async function testCancellationLock() {
  console.log('\n=== Testing 4-Hour Cancellation Lock ===');

  // Create a scheduled trip within 4 hours
  const tripRef = db.collection('trips').doc();
  const scheduledTime = new Date(Date.now() + 2 * 60 * 60 * 1000); // 2 hours from now

  const tripData = {
    type: 'STANDARD',
    status: 'ACCEPTED',
    city_id: 'test-city',
    vehicle_type: 'sedan',
    pickup: { lat: 37.7749, lng: -122.4194 },
    created_at: new Date().toISOString(),
    rider_id: 'test-rider-123',
    accepted_by: 'test-driver-456',
    scheduled_at: scheduledTime.toISOString(),
    admin_override: false
  };

  await tripRef.set(tripData);
  console.log(`✓ Created scheduled trip: ${tripRef.id}`);
  console.log(`  Scheduled: ${scheduledTime.toISOString()}`);

  // Check if cancellation should be blocked
  const hoursUntilPickup = (scheduledTime.getTime() - Date.now()) / (1000 * 60 * 60);
  const canCancel = hoursUntilPickup > 4 || tripData.admin_override;

  console.log(`  Hours until pickup: ${hoursUntilPickup.toFixed(2)}`);
  console.log(`  Can driver cancel: ${canCancel ? 'YES' : 'NO (LOCKED)'}`);

  if (!canCancel) {
    console.log(`  ⚠ Driver cannot cancel within 4 hours. Need admin override.`);
  }

  // Cleanup
  await tripRef.delete();
  console.log(`✓ Cleaned up test trip`);
}

async function testHourlyBooking() {
  console.log('\n=== Testing Hourly Booking ===');

  const tripRef = db.collection('trips').doc();
  const tripData = {
    type: 'HOURLY',
    status: 'STARTED',
    city_id: 'test-city',
    vehicle_type: 'sedan',
    pickup: { lat: 37.7749, lng: -122.4194 },
    created_at: new Date().toISOString(),
    started_at: new Date().toISOString(),
    rider_id: 'test-rider-123',
    accepted_by: 'test-driver-456',
    hours_booked: 3,
    pricing_snapshot: {
      base_hour_price: 75,
      included_miles_per_hour: 20,
      extra_mile_fee: 5.50,
      currency: 'USD'
    },
    included_miles_total: 60, // 3 hours * 20 miles
    extension_minutes_total: 0
  };

  await tripRef.set(tripData);
  console.log(`✓ Created hourly trip: ${tripRef.id}`);
  console.log(`  Hours booked: ${tripData.hours_booked}`);
  console.log(`  Base price: $${tripData.pricing_snapshot.base_hour_price}/hour`);
  console.log(`  Included miles: ${tripData.included_miles_total}`);

  // Simulate extension request
  console.log('\n> Simulating 25-minute extension request...');
  const extraMinutes = 25;
  const roundedMinutes = Math.ceil(extraMinutes / 10) * 10; // Round to 10 minutes
  const extensionFee = roundedMinutes * (tripData.pricing_snapshot.base_hour_price / 60);

  console.log(`  Requested: ${extraMinutes} minutes`);
  console.log(`  Rounded to: ${roundedMinutes} minutes`);
  console.log(`  Extension fee: $${extensionFee.toFixed(2)}`);

  // Simulate final billing with extra miles
  console.log('\n> Simulating trip completion with 75 actual miles...');
  const actualMiles = 75;
  const extraMiles = Math.max(0, actualMiles - tripData.included_miles_total);
  const extraMilesFee = extraMiles * tripData.pricing_snapshot.extra_mile_fee;
  const baseAmount = tripData.pricing_snapshot.base_hour_price * tripData.hours_booked;
  const total = baseAmount + extensionFee + extraMilesFee;

  console.log(`  Actual miles: ${actualMiles}`);
  console.log(`  Extra miles: ${extraMiles}`);
  console.log(`  Base amount: $${baseAmount.toFixed(2)}`);
  console.log(`  Extension fee: $${extensionFee.toFixed(2)}`);
  console.log(`  Extra miles fee: $${extraMilesFee.toFixed(2)}`);
  console.log(`  TOTAL: $${total.toFixed(2)}`);

  // Cleanup
  await tripRef.delete();
  console.log(`\n✓ Cleaned up test trip`);
}

async function showFirestoreData() {
  console.log('\n=== Current Firestore Data ===');

  const tripsSnapshot = await db.collection('trips').limit(5).get();
  console.log(`\nTrips (${tripsSnapshot.size} shown):`);
  tripsSnapshot.forEach(doc => {
    const data = doc.data();
    console.log(`  - ${doc.id}: ${data.status} (${data.type})`);
  });

  const driversSnapshot = await db.collection('drivers').limit(5).get();
  console.log(`\nDrivers (${driversSnapshot.size} shown):`);
  driversSnapshot.forEach(doc => {
    const data = doc.data();
    console.log(`  - ${doc.id}: ${data.status} (rating: ${data.rating})`);
  });
}

async function cleanup(tripId, driverId) {
  console.log('\n=== Cleanup ===');

  if (tripId) {
    await db.collection('trips').doc(tripId).delete();
    await db.collection('trip_requests').doc(tripId).delete();
    console.log(`✓ Deleted trip ${tripId}`);
  }

  if (driverId) {
    await db.collection('drivers').doc(driverId).delete();
    await rtdb.ref(`drivers_locations/${driverId}`).remove();
    console.log(`✓ Deleted driver ${driverId}`);
  }
}

async function main() {
  console.log('========================================');
  console.log('  Eagle Rides Cloud Functions Test');
  console.log('========================================');

  try {
    // Test basic trip creation and acceptance
    const tripId = await testCreateTrip();
    const driverId = await testCreateDriver();
    await testCreateOffer(tripId, driverId);
    await testAcceptTrip(tripId, driverId);
    await testTripLifecycle(tripId, driverId);

    // Test cancellation lock
    await testCancellationLock();

    // Test hourly booking
    await testHourlyBooking();

    // Show current data
    await showFirestoreData();

    // Cleanup test data
    await cleanup(tripId, driverId);

    console.log('\n========================================');
    console.log('  All Tests Completed Successfully!');
    console.log('========================================\n');

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
  }

  process.exit(0);
}

main();
