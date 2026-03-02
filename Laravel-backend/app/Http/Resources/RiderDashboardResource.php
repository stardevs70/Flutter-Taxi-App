<?php

namespace App\Http\Resources;

use App\Models\RideRequest;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Models\Sos;

class RiderDashboardResource extends JsonResource
{
    public function toArray($request)
    {
        $ride_request = $this->riderRideRequestDetail()->where('is_schedule', 0)->where('driver_id', null)->whereNotIn('status', ['cancelled','completed'])->where('is_rider_rated', false)->latest()->first();

        $schedule_ride_request = $this->riderRideRequestDetail()
                ->where('is_schedule', 1)
                ->where('type', 'book_ride')
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


            $schedule_orders = $this->riderRideRequestDetail()
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

        $on_ride_request = $this->riderRideRequestDetail()->where('driver_id', '!=', null)->where('is_schedule', 0)->whereNotIn('status', ['cancelled'])->where('is_rider_rated',false)
                        // ->whereHas('payment',function ($q) {
                        //     $q->where('payment_status', 'pending');
                        // })
                        ->latest()
                        ->first();
        $on_ride_request_data = $this->riderRideRequestDetail()->where('driver_id', '!=', null)->where('is_schedule', 1)->whereNotIn('status', ['cancelled'])->where('is_rider_rated',false)
                        // ->whereHas('payment',function ($q) {
                        //     $q->where('payment_status', 'pending');
                        // })
                        ->latest()
                        ->first();

        $pending_payment_ride_request = $this->riderRideRequestDetail()
                        // ->where('status', 'completed')
                        ->where('is_rider_rated',true)
                        ->where(function ($q) {
                                $q->where('status', 'completed')
                                ->whereHas('payment', function ($q3) {
                                    $q3->where('payment_status', '!=', 'paid');
                                });
                        })
                        ->where('is_schedule', '!=', 1)
                        ->latest()
                        ->first();
    
        // $driver = isset($on_ride_request) && optional($on_ride_request->driver) ? $on_ride_request->driver : null;
        $driver = null;

        if ($on_ride_request && $on_ride_request->driver) {
            $driver = $on_ride_request->driver;
        } elseif ($on_ride_request_data && $on_ride_request_data->driver) {
            $driver = $on_ride_request_data->driver;
        }

        $payment = isset($pending_payment_ride_request) && optional($pending_payment_ride_request->payment) ? $pending_payment_ride_request->payment : null;
        
        $is_rider_rated = isset($on_ride_request) ? $on_ride_request->rideRequestRating()->where('driver_id', $on_ride_request->driver_id)->first() : null;

        return [
            'id'                => $this->id,
            'display_name'      => $this->display_name,
            'email'             => $this->email,
            'username'          => $this->username,
            'user_type'         => $this->user_type,
            'profile_image'     => getSingleMedia($this, 'profile_image',null),
            'status'            => $this->status,
            'ride_has_bids' => ($ride_request && $ride_request->ride_has_bid == 1) ? 1 : 0,
            // 'sos'               => Sos::mySOs()->get(),
            'ride_request'      => isset($ride_request) ? new RideRequestResource($ride_request) : null,
            'schedule_ride_request' => RideRequestResource::collection($schedule_ride_request),
            'schedule_orders' => RideRequestResource::collection($schedule_orders),
            'on_ride_request'   => isset($on_ride_request) && $is_rider_rated == null  ? new RideRequestResource($on_ride_request) : null,
            'driver'            => isset($driver) ? new DriverResource($driver) : null,
            'payment'           => isset($payment) ? new PaymentResource($payment) : null,
            'service_marker'     => $ride_request ? getServiceSingleMedia($ride_request->service , 'service_marker',null) : null,
        ];
    }
}