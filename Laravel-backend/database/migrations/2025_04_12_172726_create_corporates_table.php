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
        Schema::create('corporates', function (Blueprint $table) {
            $table->id();
            $table->string('first_name')->nullable();
            $table->string('last_name')->nullable();
            $table->string('email')->unique();
            $table->string('username')->unique();
            $table->string('password');
            $table->string('contact_number')->nullable();
            $table->string('company_name')->nullable();
            $table->unsignedBigInteger('company_type_id')->nullable();
            $table->unsignedBigInteger('user_id')->nullable();
            $table->string('companyid')->nullable();
            $table->text('company_address')->nullable();
            $table->string('invoice_email')->unique();
            $table->string('url')->unique();
            $table->string('commission_type')->nullable()->comment('fixed, percentage');
            $table->double('commission')->nullable()->default('0');
            $table->string('VAT_number')->nullable();
            $table->string('status')->default('pending')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('corporates');
    }
};
