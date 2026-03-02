<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Region extends BaseModel
{
    use HasFactory;

    protected $fillable = [
        'name','distance_unit','status','timezone','coordinates'
    ];

    protected $casts = [
        'status' => 'integer',
        'coordinates' => 'array',
    ];
}
