<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Carbon;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $reasons = [
            'Driver' => [
                'Rider not at pickup location',
                'Rider is unresponsive to calls/messages',
                'Trip is too far from my current location',
                'Vehicle issue',
                'Rider asked to cancel',
                'Emergency or personal reason',
                'Destination not suitable (e.g., long-distance, no return ride)',
                'Duplicate or fake booking',
            ],
            'Customer' => [
                'Driver is taking too long to arrive',
                'Driver is not moving on the map',
                'Changed my mind',
                'Found an alternative transport',
                'Entered wrong pickup or drop location',
                'Fare seems too high',
                'Driver asked to cancel',
                'Personal emergency',
                'Driver behavior was inappropriate',
                'Booking was made by mistake',
            ],
            'Customer Order' => [
                'Delivery is delayed',
                'Changed my mind',
                'Item not ready for pickup',
                'Entered wrong pickup or delivery address',
                'Found another delivery method',
                'Delivery charges are too high',
                'Delivery person asked to cancel',
                'Personal emergency',
                'Package size/weight is incorrect',
            ],
            'Driver Order' => [
                'Sender not available at pickup location',
                'Item is not allowed for delivery',
                'Package is too large/heavy',
                'Incorrect address provided',
                'Sender asked to cancel',
                'Emergency or personal reason',
                'Vehicle issue',
                'Order too far or low payout',
            ],
        ];

        foreach ($reasons as $type => $typeReasons) {
            foreach ($typeReasons as $reason) {
                DB::table('manage_cancelled_reasons')->updateOrInsert(
                    [
                        'type'   => $type,
                        'reason' => $reason,
                        'created_at' => Carbon::now(),
                    ],
                    [
                        'updated_at' => Carbon::now(),
                    ]
                );
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
