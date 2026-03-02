<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\DB;

class CreateLanguageDefaultListsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('language_default_lists', function (Blueprint $table) {
            $table->id();
            $table->string('languageName')->nullable();
            $table->string('languageCode')->nullable();
            $table->string('countryCode')->nullable();
            $table->timestamps();
        });

        $default_language = json_decode(File::get(public_path('json/languagedefaultlist.json')),true);    
        foreach ($default_language as $item) {
            DB::table('language_default_lists')->insert([
                'languageName' => $item['language_name'],
                'countryCode' => $item['language_code'],
                'languageCode' => $item['country_code'],
            ]);
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('language_default_lists');
    }
}
