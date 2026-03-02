<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateRideRequestsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('ride_requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('rider_id')->nullable();
            $table->unsignedBigInteger('service_id')->nullable();
            $table->dateTime('datetime')->nullable();
            $table->boolean('is_schedule')->default(0)->comment('0-regular, 1-schedule')->nullable();
            $table->integer('ride_attempt')->default(0)->nullable();
            $table->string('distance_unit')->nullable();
            $table->double('total_amount')->nullable()->default('0');
            $table->double('subtotal')->nullable()->default('0');
            $table->double('extra_charges_amount')->nullable()->default('0');
            $table->unsignedBigInteger('driver_id')->nullable();
            $table->unsignedBigInteger('riderequest_in_driver_id')->nullable();
            $table->dateTime('riderequest_in_datetime')->nullable();
            $table->string('start_latitude')->nullable();
            $table->string('start_longitude')->nullable();
            $table->text('start_address')->nullable();
            $table->string('end_latitude')->nullable();
            $table->string('end_longitude')->nullable();
            $table->text('end_address')->nullable();
            $table->double('distance')->nullable();
            $table->double('base_distance')->nullable();
            $table->double('duration')->nullable();
            $table->double('seat_count')->nullable();
            $table->text('reason')->nullable();
            $table->string('status', 20)->default('active');
            $table->double('base_fare')->nullable();
            $table->double('minimum_fare')->nullable();
            $table->double('per_distance')->nullable();
            $table->double('per_distance_charge')->nullable();
            $table->double('per_minute_drive')->nullable();
            $table->double('per_minute_drive_charge')->nullable();
            $table->json('extra_charges')->nullable();
            $table->double('coupon_discount')->nullable();
            $table->unsignedBigInteger('coupon_code')->nullable();
            $table->json('coupon_data')->nullable();
            $table->string('otp')->nullable();
            $table->enum('cancel_by', ['rider','driver','auto'])->nullable();
            $table->double('cancelation_charges')->nullable();
            $table->double('waiting_time')->nullable();
            $table->double('waiting_time_limit')->nullable();
            $table->double('tips')->nullable();
            $table->double('per_minute_waiting')->nullable();
            $table->double('per_minute_waiting_charge')->nullable();
            $table->string('payment_type')->nullable(); 
            $table->boolean('is_driver_rated')->default(0)->nullable();
            $table->boolean('is_rider_rated')->default(0)->nullable();
            $table->text('cancelled_driver_ids')->nullable();
            $table->json('service_data')->nullable();
            $table->double('max_time_for_find_driver_for_ride_request')->nullable();

            // new columns
            $table->string('type')->nullable();
            $table->string('traveler_info')->nullable();
            $table->string('contact_number')->nullable();
            $table->string('first_name')->nullable();
            $table->string('last_name')->nullable();
            $table->string('email')->nullable();
            $table->double('passenger')->nullable();
            $table->double('luggage')->nullable();
            $table->text('driver_note')->nullable();
            $table->text('internal_note')->nullable();
            $table->double('surcharge')->nullable();
            $table->unsignedBigInteger('corporate_id')->nullable();
            $table->double('weight')->nullable();
            $table->double('total_weight')->nullable();
            $table->text('parcel_description')->nullable();
            $table->string('pickup_contact_number')->nullable();
            $table->string('pickup_person_name')->nullable();
            $table->text('pickup_description')->nullable();
            $table->string('delivery_contact_number')->nullable();
            $table->string('delivery_person_name')->nullable();
            $table->text('delivery_description')->nullable();
            $table->double('discount')->nullable();
            $table->string('external_trip_id')->nullable();
            $table->text('customer_note')->nullable();
            $table->foreign('rider_id')->references('id')->on('users')->onDelete('cascade');
            $table->boolean('is_ride_for_other')->default(0)->nullable()->comment('0-self, 1-other');
            $table->json('other_rider_data')->nullable();
            $table->json('drop_location')->nullable();
            $table->dateTime('datetime_utc')->nullable();
            $table->boolean('ride_has_bid')->nullable();
            $table->text('nearby_driver_ids')->nullable();
            $table->text('rejected_bid_driver_ids')->nullable();
            $table->unsignedBigInteger('airport_id')->nullable();
            $table->string('trip_type')->comment('regular, airport_pickup, airport_drop, zone_wise, zone_to_airport, airport_to_zone')->default('regular')->nullable();
            $table->string('flight_number')->nullable();
            $table->string('pickup_point')->nullable();
            $table->timestamp('preferred_pickup_time')->nullable();
            $table->timestamp('preferred_dropoff_time')->nullable();
            $table->unsignedBigInteger('airport_pickup')->nullable();
            $table->unsignedBigInteger('airport_dropoff')->nullable();
            $table->unsignedBigInteger('zone_pickup')->nullable();
            $table->unsignedBigInteger('zone_dropoff')->nullable();
            $table->string('sms_type')->nullable();
            $table->dateTime('schedule_datetime')->nullable();
            $table->double('surge_amount')->nullable()->default('0');
            $table->double('corporate_commission')->nullable()->default('0');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('ride_requests');
    }
}
