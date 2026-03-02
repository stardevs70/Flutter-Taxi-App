<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use App\Models\Coupon;
use App\Models\User;
use App\Models\SpecialServices;

// class EstimateServiceResource extends JsonResource
// {
//     public static $dropoffTimeInSeconds = null;
//     public static $dropoff_distance_in_meters = null;

//     public function toArray($request)
//     {
//         $distance_unit = optional($this->region)->distance_unit ?? 'km';
//         $distance_in_unit = request('distance_in_unit');
//         $dropoff_distance_in_meters = $this['dropoff_distance_in_meters'] ?? self::$dropoff_distance_in_meters ?? request('dropoff_distance_in_meters');
//         $dropoff_time_in_seconds = $this['dropoff_time_in_seconds'] ?? self::$dropoffTimeInSeconds ?? request('dropoff_time_in_seconds');
//         $coupon = request('coupon');
//         $pick_lat = $this['start_latitude'] ?? request('pick_lat');
//         $pick_lng = $this['start_longitude'] ?? request('pick_lng');
//         $drop_lat = $this['end_latitude'] ?? request('drop_lat');
//         $drop_lng = $this['end_longitude'] ?? request('drop_lng');
//         $date_time = now()->format('Y-m-d h:i');
        
//         $datetime = now();
//         $special_service = SpecialServices::where('start_date_time', '<=', $datetime)
//             ->where('end_date_time', '>=', $datetime)
//             ->where('service_id', $this->id)
//             ->latest()
//             ->first();

//         if ($special_service) {
//             $this->base_fare           = $special_service->base_fare;
//             $this->minimum_fare        = $special_service->minimum_fare;
//             $this->minimum_distance    = $special_service->minimum_distance;
//             $this->per_distance        = $special_service->per_distance;
//             $this->per_minute_drive    = $special_service->per_minute_drive;
//             $this->per_minute_wait     = $special_service->per_minute_wait;
//             $this->waiting_time_limit  = $special_service->waiting_time_limit;
//             $this->cancellation_fee    = $special_service->cancellation_fee;
//         }
        
//         $service_data = [   
//             'id'                => $this->id,
//             'service_id'        => $this->id,
//             'name'              => $this->name,
//             'region_id'         => $this->region_id,
//             'distance_unit'     => $distance_unit,
//             'dropoff_distance_in_km' => $dropoff_distance_in_meters/1000,
//             'duration'          => $dropoff_time_in_seconds/60,
//             'capacity'          => $this->capacity,
//             'base_fare'         => $this->base_fare,
//             'minimum_fare'      => $this->minimum_fare,
//             'minimum_distance'  => $this->minimum_distance,
//             'per_distance'      => $this->per_distance,
//             'per_minute_drive'  => $this->per_minute_drive,
//             'per_minute_wait'   => $this->per_minute_wait ?? 0,
//             'waiting_time_limit'=> $this->waiting_time_limit ?? 0,
//             'cancellation_fee'  => $this->cancellation_fee,
//             'payment_method'    => $this->payment_method,            
//             'service_image'     => getSingleMedia($this, 'service_image',null),
//             'service_marker'     => getServiceSingleMedia($this, 'service_marker',null),
//             'status'            => $this->status,
//             'created_at'        => $this->created_at,
//             'updated_at'        => $this->updated_at,
//             'description'       => $this->description,
//             'commission_type'   => $this->commission_type,
//             'admin_commission'  => $this->admin_commission,
//             'fleet_commission'  => $this->fleet_commission,
//             'minimum_weight'  => $this->minimum_weight,
//             'per_weight_charge'  => $this->per_weight_charge,
//             'per_distance_charge'  => $this->per_distance_charge,
//             'coupon_discount'  => optional($this->driverRideRequestDetail),
//         ];


//         $ridefee = calculateRideFares(
//             $distance_in_unit,
//             $pick_lat,
//             $pick_lng,
//             $drop_lat,
//             $drop_lng,
//             $dropoff_time_in_seconds,
//             $service_data,
//             null,
//             $date_time
//         );
        
//         $discount_amount = 0;
//         $subtotal = $ridefee['total_amount'];

//         if ($coupon) {
//             $apply_coupon = false;

//             switch ($coupon->coupon_type) {
//                 case 'all':
//                     $apply_coupon = true;
//                     break;

//                 case 'first_ride':
//                     $user = auth()->user();
//                     if ($user && $user->rides()->count() === 0) {
//                         $apply_coupon = true;
//                     }
//                     break;

//                 case 'region_wise':
//                     $coupon_region_ids = is_array($coupon->region_ids)
//                         ? $coupon->region_ids
//                         : json_decode($coupon->region_ids, true);

//                     if (is_array($coupon_region_ids)) {
//                         $coupon_region_ids = array_map('intval', $coupon_region_ids);
//                         if (in_array((int)$this->region_id, $coupon_region_ids)) {
//                             $apply_coupon = true;
//                         }
//                     }
//                     break;

//                 case 'service_wise':
//                     $coupon_service_ids = is_array($coupon->service_ids)
//                         ? $coupon->service_ids
//                         : json_decode($coupon->service_ids, true);

//                     if (is_array($coupon_service_ids)) {
//                         $coupon_service_ids = array_map('intval', $coupon_service_ids);
//                         if (in_array((int)$this->id, $coupon_service_ids)) {
//                             $apply_coupon = true;
//                         }
//                     }
//                     break;
//             }

//             if ($apply_coupon && $coupon->minimum_amount <= $subtotal) {
//                 if ($coupon->discount_type == 'percentage') {
//                     $discount_amount = $subtotal * ($coupon->discount / 100);
//                     if ($coupon->minimum_amount > 0 && $discount_amount < $coupon->minimum_amount) {
//                         $discount_amount = $coupon->minimum_amount;
//                     }
//                     if ($coupon->maximum_discount > 0 && $discount_amount > $coupon->maximum_discount) {
//                         $discount_amount = $coupon->maximum_discount;
//                     }
//                 } else {
//                     $discount_amount = $coupon->discount;
//                     if($coupon->discount >= $ridefee['total_amount']){
//                         $discount_amount = 0;
//                     }
//                 }        

//                 $subtotal -= $discount_amount;

//                 $ridefee['discount_amount'] = $discount_amount;
//                 $ridefee['subtotal'] = $subtotal;
//                 $ridefee['special_rate_applied'] = isset($special_service); // flag
//             }
//         }

//         return array_merge($service_data, $ridefee);
//     }
// }


class EstimateServiceResource extends JsonResource
{
    public static $dropoffTimeInSeconds = null;
    public static $dropoff_distance_in_meters = null;

    public function toArray($request)
    {
        $distance_unit = optional($this->region)->distance_unit ?? 'km';
        $distance_in_unit = $request->get('distance_in_unit');
        $dropoff_distance_in_meters = $this['dropoff_distance_in_meters'] ?? self::$dropoff_distance_in_meters;
        $dropoff_time_in_seconds = $this['dropoff_time_in_seconds'] ?? self::$dropoffTimeInSeconds;

        $coupon = $request->get('coupon');
        $pick_lat = $request->get('pick_lat');
        $pick_lng = $request->get('pick_lng');
        $drop_lat = $request->get('drop_lat');
        $drop_lng = $request->get('drop_lng');

        $datetime = now();

        $special_service = SpecialServices::where('start_date_time', '<=', $datetime)
            ->where('end_date_time', '>=', $datetime)
            ->where('service_id', $this->id)
            ->latest()
            ->first();

        if ($special_service) {
            foreach ([
                'base_fare', 'minimum_fare', 'minimum_distance',
                'per_distance', 'per_minute_drive', 'per_minute_wait',
                'waiting_time_limit', 'cancellation_fee'
            ] as $attr) {
                $this->$attr = $special_service->$attr;
            }
        }

        $service_data = [
            'id' => $this->id,
            'service_id' => $this->id,
            'name' => $this->name,
            'region_id' => $this->region_id,
            'distance_unit' => $distance_unit,
            'dropoff_distance_in_km' => $dropoff_distance_in_meters / 1000,
            'duration' => $dropoff_time_in_seconds / 60,
            'capacity' => $this->capacity,
            'base_fare' => $this->base_fare,
            'minimum_fare' => $this->minimum_fare,
            'minimum_distance' => $this->minimum_distance,
            'per_distance' => $this->per_distance,
            'per_minute_drive' => $this->per_minute_drive,
            'per_minute_wait' => $this->per_minute_wait ?? 0,
            'waiting_time_limit' => $this->waiting_time_limit ?? 0,
            'cancellation_fee' => $this->cancellation_fee,
            'payment_method' => $this->payment_method,
            'service_image' => getSingleMedia($this, 'service_image', null),
            'service_marker' => getServiceSingleMedia($this, 'service_marker', null),
            'status' => $this->status,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'description' => $this->description,
            'commission_type' => $this->commission_type,
            'admin_commission' => $this->admin_commission,
            'fleet_commission' => $this->fleet_commission,
            'minimum_weight' => $this->minimum_weight,
            'per_weight_charge' => $this->per_weight_charge,
            'per_distance_charge' => $this->per_distance_charge,
            'coupon_discount' => optional($this->driverRideRequestDetail),
        ];

        $ridefee = calculateRideFares($service_data, $distance_in_unit, $dropoff_time_in_seconds, [
            'ride_datetime' => $datetime->format('Y-m-d H:i:s'),  // Adjusted format if needed
            'pickup_zone_id' => request('pickup_zone_id'),
            'drop_zone_id' => request('drop_zone_id'),
            'pickup_airport_id' => request('pickup_airport_id'),
            'drop_airport_id' => request('drop_airport_id'),
            'trip_type' => request('trip_type'),
            'service_type' => request('service_type'),
            'is_estimation' => true,
            'weight' => request('weight') ?? 0,
        ]);

        $discount_amount = 0;
        $subtotal = $ridefee['total_amount'];

        if ($coupon) {
            $apply_coupon = false;

            switch ($coupon->coupon_type) {
                case 'all':
                    $apply_coupon = true;
                    break;
                case 'first_ride':
                    $user = auth()->user();
                    $apply_coupon = $user && $user->rides()->count() === 0;
                    break;
                case 'region_wise':
                    $region_ids = (array) json_decode($coupon->region_ids, true);
                    $apply_coupon = in_array((int) $this->region_id, array_map('intval', $region_ids));
                    break;
                case 'service_wise':
                    $service_ids = (array) json_decode($coupon->service_ids, true);
                    $apply_coupon = in_array((int) $this->id, array_map('intval', $service_ids));
                    break;
            }

            if ($apply_coupon && $coupon->minimum_amount <= $subtotal) {
                if ($coupon->discount_type === 'percentage') {
                    $discount_amount = $subtotal * ($coupon->discount / 100);
                    $discount_amount = min(max($discount_amount, $coupon->minimum_amount), $coupon->maximum_discount);
                } else {
                    $discount_amount = min($coupon->discount, $subtotal);
                }

                $subtotal -= $discount_amount;

                $ridefee['discount_amount'] = $discount_amount;
                $ridefee['subtotal'] = $subtotal;
                $ridefee['special_service_applied'] = isset($special_service);
            }
        }

        return array_merge($service_data, $ridefee);
    }
}
