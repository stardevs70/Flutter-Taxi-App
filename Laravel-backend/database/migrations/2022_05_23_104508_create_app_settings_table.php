<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class CreateAppSettingsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('app_settings', function (Blueprint $table) {
            $table->id();
            $table->string('site_name')->nullable();
            $table->string('site_email')->nullable();
            $table->string('site_logo')->nullable();
            $table->string('site_favicon')->nullable();
            $table->longText('site_description')->nullable();
            $table->string('site_copyright')->nullable();
            $table->string('facebook_url')->nullable();
            $table->string('instagram_url')->nullable();
            $table->string('support_number')->nullable();
            $table->string('twitter_url')->nullable();
            $table->string('linkedin_url')->nullable();
            $table->string('color')->nullable()->default('#4788ff');
            $table->json('language_option')->nullable();
            $table->string('contact_email')->nullable();
            $table->string('contact_number')->nullable();
            $table->string('help_support_url')->nullable();
            $table->json('notification_settings')->nullable();
            $table->string('backup_type')->nullable();
            $table->string('backup_email')->nullable();
            $table->timestamps();
        });

        DB::table('app_settings')->insert(array (
            0 => 
            array (
                'id' => 1,
                'site_name' => 'TripNDrop',
                'site_email' => NULL,
                'site_logo' => NULL,
                'site_favicon' => NULL,
                'site_description' => NULL,
                'site_copyright' => NULL,
                'facebook_url' => NULL,
                'instagram_url' => NULL,
                'twitter_url' => NULL,
                'linkedin_url' => NULL,
                'language_option' => '["en"]',
                'contact_email' => NULL,
                'contact_number' => NULL,
                'help_support_url' => NULL,
                'color' => '#003D5F', 
            ),
        ));
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('app_settings');
    }
}
