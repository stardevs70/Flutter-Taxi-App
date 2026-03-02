<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('zone_prices', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('ride_request_id');
            $table->foreign('ride_request_id')->references('id')->on('ride_requests')->onDelete('cascade');
            $table->string('zone_pickup')->nullable();
            $table->string('zone_dropoff')->nullable();
            $table->string('price')->nullable();
            $table->string('airport_pickup')->nullable();
            $table->string('airport_dropoff')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('zone_prices');
    }
};
