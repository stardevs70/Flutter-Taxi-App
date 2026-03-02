<?php
namespace App\Http\Resources;

use App\Models\Coupon;
use App\Models\Region;
use App\Models\Service;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Models\Sos;
use Grimzy\LaravelMysqlSpatial\Types\Point;
use Illuminate\Database\Eloquent\Builder;
class DriverDashboardResource extends JsonResource
{
    public function toArray($request)
    {
        $schedule_ride_request = $this->driverRideRequestDetail()
            ->where('is_schedule', 1)
            ->where('type', 'book_ride')
            ->where('status', '!=', 'cancelled')
            ->where(function ($q) {
                $q->where('status', '!=', 'completed') // 1. Not completed
                ->orWhere(function ($q2) {           // 2. Completed but unpaid
                    $q2->where('status', 'completed')
                        ->whereHas('payment', function ($q3) {
                            $q3->where('payment_status', 'pending');
                        });
                });
            })
            ->orderBy('schedule_datetime', 'asc')
            ->get();


        $schedule_orders = $this->driverRideRequestDetail()
            ->where('is_schedule', 1)
            ->where('type', 'transport')
            ->where('status', '!=', 'cancelled')
            ->where(function ($q) {
                $q->where('status', '!=', 'completed')
                ->orWhere(function ($q2) {
                    $q2->where('status', 'completed')
                        ->whereHas('payment', function ($q3) {
                            $q3->where('payment_status', 'pending');
                        });
                });
            })
            ->orderBy('schedule_datetime', 'asc')
            ->get();

        $on_ride_request = $this->driverRideRequestDetail()->whereNotIn('status', ['cancelled'])->where('is_driver_rated', false)->latest()->first();
        $pending_payment_ride_request = $this->driverRideRequestDetail()->where('status', 'completed')->where('is_schedule', '!=', 1)
            ->whereHas('payment', function ($q) {
                $q->where('payment_status', 'pending');
            })->latest()->first();
        $rider = isset($on_ride_request) && optional($on_ride_request->rider) ? $on_ride_request->rider :  null;
        $payment = isset($pending_payment_ride_request) && optional($pending_payment_ride_request->payment) ? $pending_payment_ride_request->payment : null;
        
        if (!empty($on_ride_request)) {
            $service = Service::where('id', $on_ride_request->service_id)->first();
            if ($service) {
                if ($service->region_id) {
                    $service = Service::where('region_id', $service->region_id)->where('id', $service->id)->first();
                }

                if( $on_ride_request->start_latitude && isset($on_ride_request->start_latitude) && $on_ride_request->start_longitude && isset($on_ride_request->start_longitude) )
                {
                    $latitude = (float) $on_ride_request->start_latitude;
                    $longitude = (float) $on_ride_request->start_longitude;

                    $point = Region::where('status', 1)
                        ->get()
                        ->filter(function ($region) use ($latitude, $longitude) {
                            $coordinates = $region->coordinates;

                            if (is_string($coordinates)) {
                                $coordinates = json_decode($coordinates, true);
                            }

                            if (is_array($coordinates) && count($coordinates) >= 3) {
                                pointInPolygon([$latitude, $longitude], $coordinates);
                            }
                        });
                    
                    $service->whereHas('region',function ($q) use($point) {
                        $q->where('status', 1)->whereJsonContains('coordinates', $point);
                    });
                }

                if ($on_ride_request->coupon_code) {
                    $coupon = Coupon::find($on_ride_request->coupon_code);
                    $response = verify_coupon_code($coupon->code,$on_ride_request->service_id,$on_ride_request->rider_id);

                    if ($response['status'] != 200) {
                        return json_custom_response($response, $response['status']);
                    }
                }

                $place_details = mighty_get_distance_matrix($on_ride_request->start_latitude, $on_ride_request->start_longitude, $on_ride_request->end_latitude, $on_ride_request->end_longitude);
                $dropoff_distance_in_meters = distance_value_from_distance_matrix($place_details);
                $dropoff_time_in_seconds = duration_value_from_distance_matrix($place_details);

                $distance_in_unit = 0;
                if ($dropoff_distance_in_meters) {
                    // Region->distance_unit == km ( convert meter to km )
                    $distance_in_unit = $dropoff_distance_in_meters / 1000;
                    // echo $dropoff_distance_in_meters;
                }

                $service->start_latitude = $on_ride_request->start_latitude;
                $service->start_longitude = $on_ride_request->start_longitude;
                $service->end_latitude = $on_ride_request->end_latitude;
                $service->end_longitude = $on_ride_request->end_longitude;
                $service->distance_in_unit = $distance_in_unit;
                $service->dropoff_distance_in_meters = $dropoff_distance_in_meters ;
                $service->dropoff_time_in_seconds = $dropoff_time_in_seconds;
                
                $services = collect([$service]);
                $items = EstimateServiceResource::collection($services);
            }
        }

        return [
            
            'id'                => $this->id,
            'display_name'      => $this->display_name,
            'email'             => $this->email,
            'username'          => $this->username,
            'user_type'         => $this->user_type,
            'profile_image'     => getSingleMedia($this, 'profile_image',null),
            'status'            => $this->status,
            'ride_has_bid'      => $this->driverRideRequestDetail()->latest()->first()?->ride_has_bid === 1 ? 1 : 0,
            'latitude'          => $this->latitude,
            'longitude'         => $this->longitude,
            'schedule_ride_request' => RideRequestResource::collection($schedule_ride_request),
            'schedule_orders' => RideRequestResource::collection($schedule_orders),
            // 'sos'               => Sos::mySOs()->get(),
            // 'on_ride_request'   => isset($on_ride_request) ? new RideRequestResource($on_ride_request) : null,
            'on_ride_request'   => isset($on_ride_request) && $on_ride_request->is_schedule == 1 ? null : new RideRequestResource($on_ride_request),
            'rider'             => isset($rider) ? new UserResource($rider) : null,
            'payment'           => isset($payment) ? new PaymentResource($payment) : null,
            'estimated_price'   => $items ?? [],
            'service_marker'     => getServiceSingleMedia($this->service, 'service_marker',null),
        ];
    }
}