<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('special_services', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->unsignedBigInteger('service_id')->nullable();
            $table->dateTime('start_date_time')->nullable();
            $table->dateTime('end_date_time')->nullable();
            $table->double('base_fare')->nullable();
            $table->double('minimum_fare')->nullable();
            $table->double('minimum_weight')->nullable();
            $table->double('per_weight_charge')->nullable();
            $table->double('minimum_distance')->nullable();
            $table->double('per_distance')->nullable();
            $table->double('per_minute_drive')->nullable();
            $table->double('per_minute_wait')->nullable();
            $table->double('waiting_time_limit')->nullable();
            $table->double('cancellation_fee')->nullable();
            $table->enum('payment_method',['cash_wallet', 'cash', 'wallet'])->default('cash');
            $table->tinyInteger('status')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('special_services');
    }
};
