<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddExtraBookingOptionsToRideRequestsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('ride_requests', function (Blueprint $table) {
            // Extra booking options
            $table->boolean('trip_protection')->default(0)->nullable();
            $table->double('trip_protection_price')->nullable()->default(0);
            $table->boolean('meet_and_greet')->default(0)->nullable();
            $table->double('meet_and_greet_price')->nullable()->default(0);
            $table->string('meet_greet_name')->nullable();
            $table->text('meet_greet_comments')->nullable();
            $table->boolean('traveling_with_pet')->default(0)->nullable();
            $table->double('traveling_with_pet_price')->nullable()->default(0);
            $table->boolean('child_seat')->default(0)->nullable();
            $table->double('child_seat_price')->nullable()->default(0);
            $table->integer('booster_seat_count')->default(0)->nullable();
            $table->integer('rear_facing_infant_seat_count')->default(0)->nullable();
            $table->integer('forward_facing_toddler_seat_count')->default(0)->nullable();
            $table->double('extras_amount')->nullable()->default(0);

            // Payment status field
            $table->string('payment_status')->nullable()->default('pending');

            // Hourly booking fields
            $table->string('booking_type')->nullable()->default('STANDARD');
            $table->integer('hours_booked')->nullable();
            $table->double('included_miles')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('ride_requests', function (Blueprint $table) {
            $table->dropColumn([
                'trip_protection',
                'trip_protection_price',
                'meet_and_greet',
                'meet_and_greet_price',
                'meet_greet_name',
                'meet_greet_comments',
                'traveling_with_pet',
                'traveling_with_pet_price',
                'child_seat',
                'child_seat_price',
                'booster_seat_count',
                'rear_facing_infant_seat_count',
                'forward_facing_toddler_seat_count',
                'extras_amount',
                'payment_status',
                'booking_type',
                'hours_booked',
                'included_miles',
            ]);
        });
    }
}
