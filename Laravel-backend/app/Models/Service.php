<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Spatie\MediaLibrary\MediaCollections\Models\Media;
use Spatie\Image\Manipulations;

class Service extends BaseModel implements HasMedia
{
    use HasFactory, InteractsWithMedia;

    protected $fillable = [ 'name', 'service_type', 'region_id','per_weight_charge','minimum_weight','capacity', 'base_fare', 'minimum_fare', 'minimum_distance', 'per_distance', 'per_minute_drive', 'per_minute_wait', 'waiting_time_limit', 'payment_method', 'commission_type', 'admin_commission', 'fleet_commission', 'status', 'cancellation_fee', 'description','per_distance_charge' ];

    protected $casts = [
        'region_id'         => 'integer',
        'capacity'          => 'integer',
        'status'            => 'integer',
        'base_fare'         => 'double',
        'minimum_fare'      => 'double',
        'minimum_distance'  => 'double',
        'per_distance'      => 'double',
        'per_minute_drive'  => 'double',
        'per_minute_wait'   => 'double',
        'waiting_time_limit'=> 'double',
        'cancellation_fee'  => 'double',
        'admin_commission'  => 'double',
        'fleet_commission'  => 'double',
        'payment_method' => 'array',
    ];
    public function region() {
        return $this->belongsTo( Region::class, 'region_id', 'id');
    }
    
    public function driverRideRequestDetail() {
        return $this->hasMany(RideRequest::class, 'service_id', 'id');
    }
    
    // public function registerMediaConversions(?Media $media = null): void
    // {
    //     $this->addMediaConversion('compressed')
    //         ->format(Manipulations::FORMAT_JPG) // Convert to JPG
    //         ->quality(75) // Reduce quality for compression
    //         ->width(800) // Resize width to 800px while keeping aspect ratio
    //         ->nonQueued(); // Ensure immediate processing
    // }
}
