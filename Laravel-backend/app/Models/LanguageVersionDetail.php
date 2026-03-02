<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LanguageVersionDetail extends BaseModel
{
    use HasFactory;

    protected $fillable = [ 'default_language_id', 'version_no' ];
}
