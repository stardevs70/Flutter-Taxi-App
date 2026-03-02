<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ZonePrice extends BaseModel
{
    protected $fillable = ['ride_request_id','zone_pickup','zone_dropoff','price','airport_pickup','airport_dropoff'];


    public function zonepickup() {
        return $this->belongsTo( ManageZone::class, 'zone_pickup', 'id');
    }

    public function zonedropoff() {
        return $this->belongsTo( ManageZone::class, 'zone_dropoff', 'id');
    }
    public function airportpickup() {
        return $this->belongsTo( Airport::class, 'airport_pickup', 'id');
    }

    public function airportdropoff() {
        return $this->belongsTo( Airport::class, 'airport_dropoff', 'id');
    }
}
