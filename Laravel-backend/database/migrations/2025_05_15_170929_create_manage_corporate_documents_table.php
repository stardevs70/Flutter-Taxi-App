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
        Schema::create('manage_corporate_documents', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->unsignedBigInteger('corporate_id')->nullable();
            $table->unsignedBigInteger('document_id')->nullable();
            $table->tinyInteger('is_verified')->nullable()->default('0')->comment('0-pending,1-approved,2-rejected');
            $table->date('expire_date')->nullable();
            $table->foreign('corporate_id')->references('id')->on('corporates')->onDelete('cascade');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('manage_corporate_documents');
    }
};
