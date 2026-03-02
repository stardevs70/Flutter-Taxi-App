<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateServicesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('services', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('service_type')->nullable()->comment('transport,book_ride,both');
            $table->unsignedBigInteger('region_id')->nullable();
            $table->unsignedBigInteger('capacity')->nullable()->default('1');
            $table->double('base_fare')->nullable();
            $table->double('minimum_fare')->nullable();
            $table->double('minimum_distance')->nullable();
            $table->double('minimum_weight')->nullable();
            $table->double('per_weight_charge')->nullable();
            $table->double('per_distance')->nullable();
            $table->double('per_minute_drive')->nullable();
            $table->double('per_minute_wait')->nullable();
            $table->double('waiting_time_limit')->nullable();
            $table->double('cancellation_fee')->nullable();
            $table->json('payment_method')->nullable();
            $table->string('commission_type')->nullable()->comment('fixed, percentage');
            $table->double('admin_commission')->nullable()->default('0');
            $table->double('fleet_commission')->nullable()->default('0');
            $table->double('per_distance_charge')->nullable()->default('0');
            $table->tinyInteger('status')->nullable();
            $table->foreign('region_id')->references('id')->on('regions')->onDelete('cascade');
            $table->text('description')->nullable();
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
        Schema::dropIfExists('services');
    }
}
