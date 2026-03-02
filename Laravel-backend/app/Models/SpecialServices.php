<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SpecialServices extends BaseModel
{
    use HasFactory;

    protected $fillable = [ 'name','service_id','start_date_time','end_date_time', 'base_fare', 'minimum_fare', 'minimum_distance', 'per_distance', 'per_minute_drive', 'per_minute_wait', 'waiting_time_limit','cancellation_fee','status'];

    public function service(){

     return $this->belongsTo(Service::class,'service_id');
    }

}
