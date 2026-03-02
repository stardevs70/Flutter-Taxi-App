<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ManageZone extends BaseModel
{
    use HasFactory;

    protected $fillable =[ 'name', 'address','latitude', 'longitude', 'description', 'status' ];
}
