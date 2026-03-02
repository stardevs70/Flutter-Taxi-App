<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Coupon extends BaseModel
{
    use HasFactory;

    protected $fillable = [
        'code',
        'title',
        'service_type',
        'coupon_type',
        'usage_limit_per_rider',
        'discount_type',
        'discount',
        'start_date',
        'end_date',
        'minimum_amount',
        'maximum_discount',
        'status',
        'description',
        'service_ids',
        'region_ids'
    ];

    protected $casts = [
        'discount'  => 'double',
        'status'    => 'integer',
        'minimum_amount' => 'double',
        'maximum_discount' => 'double',
        'usage_limit_per_rider' => 'integer',
        'service_ids' => 'array',
    ];

    // public function getStartDateAttribute($value)
    // {
    //     return $this->attributes['start_date'] = Carbon::parse($value)->format('Y-m-d');
    // }

    // public function getEndDateAttribute($value)
    // {
    //     return $this->attributes['end_date'] = Carbon::parse($value)->format('Y-m-d');
    // }

    public function getStartDateAttribute($value)
    {
        return $value ? Carbon::parse($value)->format('Y-m-d') : null;
    }

    public function getEndDateAttribute($value)
    {
        return $value ? Carbon::parse($value)->format('Y-m-d') : null;
    }


    public function getRegionIdsAttribute($value)
    {
        $val = isset($value) ? json_decode($value, true) : null;

        return $val;
    }

    public function setRegionIdsAttribute($value)
    {
        $this->attributes['region_ids'] = isset($value) ? json_encode($value) : null;
    }

    public function getServiceIdsAttribute($value)
    {
        $val = isset($value) ? json_decode($value, true) : null;
        return $val;
    }

    public function setServiceIdsAttribute($value)
    {
        $this->attributes['service_ids'] = isset($value) ? json_encode($value) : null;
    }

    public static function isValidCoupon($coupon_data, $service_id = null, $rider_id = null)
    {
        $today = Carbon::today();
        $start_date = Carbon::parse($coupon_data->start_date);
        $end_date = Carbon::parse($coupon_data->end_date);

        if ($today->gt($end_date)) {
            return 400;
        } elseif ($today->lt($start_date) || $today->gt($end_date)) {
            return 405;
        }

        switch ($coupon_data->coupon_type) {
            case 'first_ride':
                $total = RideRequest::where('rider_id', $rider_id)->count();
                return $total < $coupon_data->usage_limit_per_rider ? 200 : 406;
                break;
            case 'region_wise':
                if (isset($coupon_data->region_ids)) {
                    $data = Service::whereIn('region_id', $coupon_data->region_ids)->where('id', $service_id)->first();
                    if (!$data) {
                        return 404;
                    }
                }
                break;
            case 'service_wise':
                if (!empty($coupon_data->service_ids) && $service_id != null) {
                    $service_ids = is_array($coupon_data->service_ids)
                        ? $coupon_data->service_ids
                        : json_decode($coupon_data->service_ids, true);


                    if (!is_array($service_ids)) {
                        try {
                            $service_ids = json_decode($coupon_data->service_ids, true);
                        } catch (\Exception $e) {
                            return 500;
                        }
                    }
                    return !in_array($service_id, $service_ids) ? 400 : 200;
                }
                break;
            default:
                # code...
                break;
        }

        $total = RideRequest::where('rider_id', request('rider_id'))->where('coupon_code', $coupon_data->code)->count();
        if ($total < $coupon_data->usage_limit_per_rider) {
            return 200;
        } else {
            return 407; // Limited  
        }

        return 200; // not found
    }
}
