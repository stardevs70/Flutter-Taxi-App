<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\RideRequest;
use App\Models\RideRequestRating;
use App\Models\Coupon;
use App\Models\Region;
use App\Http\Resources\RideRequestResource;
use App\Http\Resources\ComplaintResource;
use App\Http\Resources\EstimateServiceResource;
use Carbon\Carbon;
use App\Models\Payment;
use App\Models\RideRequestBid;
use App\Models\Service;
use App\Models\SpecialServices;
use App\Models\ZonePrice;
use Illuminate\Support\Facades\Http;
use App\Models\Wallet;
use App\Models\WalletHistory;
use App\Models\User;
use App\Notifications\CommonNotification;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class RideRequestController extends Controller
{
    public function getList(Request $request)
    {
        $riderequest = RideRequest::GetRide();

        $riderequest->when(request('service_id'), function ($q) {
            return $q->where('service_id', request('service_id'));
        });

        $riderequest->when(request('is_schedule'), function ($q) {
            return $q->where('is_schedule', request('is_schedule'));
        });

        $riderequest->when(request('rider_id'), function ($q) {
            return $q->where('rider_id',request('rider_id'));
        });

        $riderequest->when(request('status'), function ($q) {
            return $q->where('status',request('status'));
        });

        $riderequest->when(request('driver_id'), function ($query) {
            return $query->whereHas('driver',function ($q) {
                $q->where('driver_id',request('driver_id'));
            });
        });
        $order = 'desc';
       
        if( request('from_date') != null && request('to_date') != null ){
            $riderequest = $riderequest->whereBetween('datetime',[ request('from_date'), request('to_date')]);
        }

        $per_page = config('constant.PER_PAGE_LIMIT');
        if( $request->has('per_page') && !empty($request->per_page)){
            if(is_numeric($request->per_page))
            {
                $per_page = $request->per_page;
            }
            if($request->per_page == -1 ){
                $per_page = $riderequest->count();
            }
        }
        if( request('status') == 'upcoming' ) {
            $order = 'asc';
        }
        $riderequest = $riderequest->orderBy('datetime',$order)->paginate($per_page);
        $items = RideRequestResource::collection($riderequest);

        $response = [
            'pagination' => json_pagination_response($items),
            'data' => $items,
        ];
        
        return json_custom_response($response);
    }

    public function getDetail(Request $request)
    {
        $id = $request->id;
        $riderequest = RideRequest::where('id',$id)->first();

        if( $riderequest == null )
        {
            return json_message_response( __('message.not_found_entry',['name' => __('message.riderequest') ]) );
        }
        $ride_detail = new RideRequestResource($riderequest);

        $ride_history = optional($riderequest)->rideRequestHistory;
        $rider_rating = optional($riderequest)->rideRequestRiderRating();
        $driver_rating = optional($riderequest)->rideRequestDriverRating();

        $current_user = Auth::user();
        if(count($current_user->unreadNotifications) > 0 ) {
            $current_user->unreadNotifications->where('data.id',$id)->markAsRead();
        }

        $complaint = null;
        if($current_user->hasRole('driver')) {
            $complaint = optional($riderequest)->rideRequestDriverComplaint();
        }

        if($current_user->hasRole('rider')) {
            $complaint = optional($riderequest)->rideRequestRiderComplaint();
        }

        $service = Service::where('id', $riderequest->service_id)->first();

        if ($service) {
            if ($service->region_id) {
                $service = Service::where('region_id', $service->region_id)->where('id', $service->id)->first();
            }

            if( $riderequest->start_latitude && isset($riderequest->start_latitude) && $riderequest->start_longitude && isset($riderequest->start_longitude) )
            {
                $latitude = (float) $riderequest->start_latitude;
                $longitude = (float) $riderequest->start_longitude;

                $point = Region::where('status', 1)
                    ->get()
                    ->filter(function ($region) use ($latitude, $longitude) {
                        $coordinates = $region->coordinates;

                        if (is_string($coordinates)) {
                            $coordinates = json_decode($coordinates, true);
                        }

                        // Ensure coordinates are in proper format  
                        if (is_array($coordinates) && count($coordinates) >= 3) {
                            pointInPolygon([$latitude, $longitude], $coordinates);
                        }
                    });
                
                $service->whereHas('region',function ($q) use($point) {
                    $q->where('status', 1)->whereJsonContains('coordinates', $point);
                });
            }

            if ($riderequest->coupon_code) {
                $coupon = Coupon::find($riderequest->coupon_code);
                $response = verify_coupon_code($coupon->code);

                if ($response['status'] != 200) {
                    return json_custom_response($response, $response['status']);
                }
            }

            $place_details = mighty_get_distance_matrix( $riderequest->start_latitude,$riderequest->start_longitude,$riderequest->end_latitude, $riderequest->end_longitude );
            $dropoff_distance_in_meters = distance_value_from_distance_matrix($place_details);
            $dropoff_time_in_seconds = duration_value_from_distance_matrix($place_details);

            $distance_in_unit = $dropoff_distance_in_meters ? $dropoff_distance_in_meters / 1000 : 0;

            $request['distance_in_unit'] = $distance_in_unit;
            $request['dropoff_distance_in_meters'] = $dropoff_distance_in_meters;
            $request['dropoff_time_in_seconds'] = $dropoff_time_in_seconds;

            $service->start_latitude = $riderequest->start_latitude;
            $service->start_longitude = $riderequest->start_longitude;
            $service->end_latitude = $riderequest->end_latitude;
            $service->end_longitude = $riderequest->end_longitude;
            $service->multi_drop_location = $riderequest->multi_drop_location;
            
            $services = collect([$service]);
            $items = EstimateServiceResource::collection($services);
        
            $pdfUrl = null;
            if($ride_detail->status == 'completed' ){
                $pdfUrl = route('ride-invoice', ['id' => $ride_detail->id]);
            }

            $bid_data = RideRequestBid::where('ride_request_id',$id)->where('driver_id',$current_user->id)->first();
            if ($bid_data) {
                $bid_data->extra_charge_amount = $riderequest->extra_charges_amount ?? '';
            }
            $response = [
                'data' => $ride_detail,
                'coupon_discount' => $ride_detail->coupon_discount ?? '',
                'ride_history' => $ride_history,
                'rider_rating' => $rider_rating,
                'driver_rating' => $driver_rating,
                'complaint' => isset($complaint) ? new ComplaintResource($complaint) : null,
                'payment' => optional($ride_detail)->payment,
                'invoice_url' => $pdfUrl,
                'invoice_name' => 'Ride_' . $ride_detail->id,
                'estimated_price' => $items,
                'ride_has_bids' => $riderequest->ride_has_bid == 1 ? 1 : 0,
                'bid_data' => $bid_data ?? [],
                // 'region' => optional($ride_detail)->service_data['region'] 
            ];
            return json_custom_response($response);
        }
    }

    public function completeRideRequest(Request $request)
    {
        $ride_request = RideRequest::with(['service', 'approvedBids', 'driver'])->find($request->id);

        if (!$ride_request) {
            return json_message_response(__('message.not_found_entry', ['name' => __('message.riderequest')]));
        }

        if ($ride_request->status == 'completed') {
            return json_message_response(__('message.ride.completed'));
        }
        
        $total_amount = $ride_request->total_amount;
        $service = $ride_request->service;
        $commission = calculateCommission($service, $total_amount);

        if($ride_request->type == 'transport'){
            $ride_request->update([
                'status' => 'completed',
            ]);
            $driver_earning = $commission['driver_commission'];
            if($ride_request->payment_type == 'cash'){
                $admin_commission = $commission['admin_commission'];
                $wallet = Wallet::firstOrCreate(['user_id' => $ride_request->driver_id]);
                $wallet->currency = strtolower(SettingData('CURRENCY', 'CURRENCY_CODE') ?? 'USD');
                $wallet->total_amount -= $admin_commission;

                try {
                    DB::beginTransaction();
                    $wallet->save();
                    WalletHistory::create([
                        'user_id'          => $wallet->user_id,
                        'amount'           => $admin_commission,
                        'balance'          => $wallet->total_amount,
                        'transaction_type' => 'admin commission',
                        'type'             => 'debit',
                        'datetime'         => $request->datetime,
                        'ride_request_id'  => $ride_request->id
                    ]);
                    DB::commit();
                } catch (\Exception $e) {
                    DB::rollBack();
                    Log::error('Wallet transaction failed', ['error' => $e->getMessage()]);
                }
            }else{
                $wallet = Wallet::firstOrCreate(['user_id' => $ride_request->driver_id]);
                $wallet->currency = strtolower(SettingData('CURRENCY', 'CURRENCY_CODE') ?? 'USD');
                $wallet->total_amount += $driver_earning;

                try {
                    DB::beginTransaction();
                    $wallet->save();
                    WalletHistory::create([
                        'user_id'          => $wallet->user_id,
                        'amount'           => $driver_earning,
                        'balance'          => $wallet->total_amount,
                        'transaction_type' => 'ride_fee',
                        'type'             => 'credit',
                        'datetime'         => $request->datetime,
                        'ride_request_id'  => $ride_request->id
                    ]);
                    DB::commit();
                } catch (\Exception $e) {
                    DB::rollBack();
                    Log::error('Wallet transaction failed', ['error' => $e->getMessage()]);
                }
            }
        }
        else{
            // Book Ride Logic
            $ride_request->update([
                'end_latitude'         => $request->end_latitude,
                'end_longitude'        => $request->end_longitude,
                'end_address'          => $request->end_address,
                'extra_charges'        => $request->extra_charges,
                'extra_charges_amount' => $request->extra_charges_amount,
            ]);

            $service        = $ride_request->service;
            $distance_unit  = $ride_request->distance_unit ?? 'km';
            $extra_charges_amount  = $request->input('extra_charges_amount', 0);
            $tips           = $request->input('tips', 0);

            $start_datetime = $ride_request->rideRequestHistory()->where('history_type', 'in_progress')->pluck('datetime')->first();
            $end_datetime   = $ride_request->rideRequestHistory()->where('history_type', 'completed')->pluck('datetime')->first();
            $ride_datetime  = Carbon::parse($ride_request->created_at);

            $duration       = calculateRideDuration($start_datetime, $end_datetime);
            $distance       = haversineDistance($request->start_latitude,$request->start_longitude,$request->end_latitude,$request->end_longitude);
            $waiting_time   = 0;
            
            // Apply special service pricing if exists
            $special_service = SpecialServices::where('start_date_time', '<=', $ride_datetime)
                ->where('end_date_time', '>=', $ride_datetime)
                ->first();

            if ($special_service) {
                foreach ([
                    'base_fare', 'minimum_fare', 'minimum_distance', 'per_distance',
                    'per_minute_drive', 'per_minute_wait', 'waiting_time_limit', 'cancellation_fee'
                ] as $field) {
                    $service->$field = $special_service->$field;
                }
            }

            $coupon = Coupon::where('id', $ride_request->coupon_code)
                ->where('start_date', '<=', Carbon::today())
                ->where('end_date', '>=', Carbon::today())
                ->first();

            $total_amount = null;
            $extras_amount = $ride_request->extras_amount ?? 0;

            // Hourly booking: use the pre-agreed hourly price, don't recalculate
            if ($ride_request->booking_type == 'HOURLY' && $ride_request->hours_booked > 0) {
                $total_amount = $ride_request->total_amount;
                $ride_request->update([
                    'status'       => 'completed',
                    'distance'     => $distance,
                    'duration'     => $duration / 60,
                    'service_data' => $service,
                ]);
            }

            // Zone/airport based pricing
            if (!$total_amount) {
                $is_zone_based = in_array($ride_request->trip_type, [
                    'zone_wise', 'zone_to_airport', 'airport_to_zone', 'airport_pickup', 'airport_drop'
                ]) && ($ride_request->zone_pickup || $ride_request->airport_pickup || $ride_request->pickup_airport_id);

                if ($is_zone_based) {
                    $zoneData = null;

                    switch ($ride_request->trip_type) {
                        case 'zone_wise':
                            $zoneData = ZonePrice::where('zone_pickup', $ride_request->zone_pickup)
                                ->where('zone_dropoff', $ride_request->zone_dropoff)->first();
                            break;
                        case 'zone_to_airport':
                            $zoneData = ZonePrice::where('zone_pickup', $ride_request->zone_pickup)
                                ->where('airport_dropoff', $ride_request->drop_airport_id ?? $ride_request->airport_dropoff)->first();
                            break;
                        case 'airport_to_zone':
                            $zoneData = ZonePrice::where('airport_pickup', $ride_request->pickup_airport_id ?? $ride_request->airport_pickup)
                                ->where('zone_dropoff', $ride_request->zone_dropoff)->first();
                            break;
                        case 'airport_pickup':
                            $zoneData = ZonePrice::where('airport_pickup', $ride_request->pickup_airport_id ?? $ride_request->airport_pickup)
                                ->where('zone_dropoff', $ride_request->drop_zone_id ?? $ride_request->zone_dropoff)->first();
                            break;
                        case 'airport_drop':
                            $zoneData = ZonePrice::where('zone_pickup', $ride_request->pickup_zone_id ?? $ride_request->zone_pickup)
                                ->where('airport_dropoff', $ride_request->drop_airport_id ?? $ride_request->airport_dropoff)->first();
                            break;
                    }

                    if ($zoneData) {
                        $total_amount = $zoneData->price + $extras_amount;
                    }
                    $ride_request->update([
                        'status'        => 'completed',
                        'distance'      => $distance,
                        'duration'      => $duration / 60,
                        'total_amount'  => $total_amount ?? $ride_request->total_amount,
                        'service_data'  => $service,
                    ]);
                }
            }

            if (!$total_amount) {
                $ridefee = calculateRideFares($service->toArray(), $distance, $duration, [
                    'waiting_time' => $waiting_time,
                    'extra_charges_amount' => $extra_charges_amount,
                    'tips' => $tips,
                    'coupon' => $coupon,
                    'ride_datetime' => $ride_datetime,
                    'is_estimation' => false,
                ]);

                // Add extras_amount (trip protection, meet & greet, pet, child seat) to fare
                if ($extras_amount > 0) {
                    $ridefee['total_amount'] += $extras_amount;
                    $ridefee['subtotal'] += $extras_amount;
                }

                if ($ride_request->ride_has_bid && $ride_request->approvedBids) {
                    $ridefee['total_amount'] = $ride_request->approvedBids->bid_amount + $extras_amount;
                }

                $ridefee['special_service_applied'] = (bool) $special_service;
                if ($special_service) {
                    $ridefee['subtotal'] = $special_service->base_fare;
                }

                if ($ride_request->is_ride_for_other) {
                    $ridefee['is_rider_rated'] = true;
                }

                $ride_request->update(array_merge([
                    'status'       => 'completed',
                    'distance'     => $ridefee['distance'],
                    'duration'     => $duration / 60,
                    'per_minute_drive_charge' => $ridefee['time_price'],
                    'per_distance_charge' => $ridefee['distance_price'],
                    'service_data' => $service,
                ], $ridefee));

                $total_amount = $ride_request->ride_has_bid && $ride_request->approvedBids
                    ? $ride_request->approvedBids->bid_amount
                    : ($request->type == 'transport'
                        ? $ride_request->estimated_amount
                        : $ridefee['total_amount']);
            }

            Payment::create([
                'rider_id'        => $ride_request->rider_id,
                'ride_request_id' => $ride_request->id,
                'payment_type'    => $ride_request->payment_type ?? 'cash',
                'datetime'        => now(),
                'payment_status'  => 'pending',
                'total_amount'    => $total_amount,
                'admin_commission' => $commission['admin_commission'],
                'driver_commission' => $commission['driver_commission'],
            ]);
        }

        saveRideHistory([
            'history_type'    => 'completed',
            'ride_request_id' => $ride_request->id,
            'ride_request'    => $ride_request,
        ]);

        // Make driver available again
        $ride_request->driver->update(['is_available' => 1]);

        // Notify rider that ride is completed
        try {
            $rider = User::find($ride_request->rider_id);
            if ($rider) {
                $notification_data = [
                    'id'      => $ride_request->id,
                    'type'    => 'completed',
                    'subject' => 'Ride Completed',
                    'message' => 'Your ride has been completed. Thank you for riding with us!',
                ];
                $rider->notify(new CommonNotification($notification_data['type'], $notification_data));
            }
        } catch (\Exception $e) {
            Log::error('Failed to send ride completed notification: ' . $e->getMessage());
        }

        return json_message_response(__('message.ride.completed'));
    }

    public function calculateCommission($amount, $service)
    {
        $admin_commission = 0;
        $fleet_commission = 0;

        if ($service->commission_type === 'percentage') {
            $admin_commission = $amount * ($service->admin_commission / 100);
            $fleet_commission = $amount * ($service->fleet_commission / 100);
        } else {
            $admin_commission = $service->admin_commission;
            $fleet_commission = $service->fleet_commission;
        }

        $total_commission = $admin_commission + $fleet_commission;
        $driver_earning = $amount - $total_commission;

        return [
            'admin_commission' => $admin_commission,
            'fleet_commission' => $fleet_commission,
            'driver_earning' => $driver_earning,
            'total_commission' => $total_commission,
        ];
    }

    public function verifyCoupon(Request $request)
    {
        $coupon_code = $request->coupon_code;

        $coupon = Coupon::where('code', $coupon_code)->first();
        $status = isset($coupon_code) ? 400 : 200;
        
        if($coupon != null) {
            $status = Coupon::isValidCoupon($coupon,null,null);
        }
        
        $response = couponVerifyResponse($status);

        return json_custom_response($response,$status);
    }

    public function rideRating(Request $request)
    {
        $ride_request = RideRequest::where('id',request('ride_request_id'))->first();

        $message = __('message.not_found_entry', ['name' => __('message.riderequest')]);

        if($ride_request == '') {
            return json_message_response( $message );
        }
        $data = $request->all();

        $data['rider_id'] = Auth::user()->user_type == 'driver' ? $ride_request->rider_id : null;
        $data['driver_id'] = Auth::user()->user_type == 'rider' ? $ride_request->driver_id : null;

        $data['rating_by'] = Auth::user()->user_type;
        RideRequestRating::updateOrCreate([ 'id' => $request->id ], $data);
        
        if(Auth::user()->user_type =='rider') {
            $ride_request->update(['is_rider_rated' => true]);
            $msg = __('message.rated_successfully', ['form' => __('message.rider')]);
        }
        if(Auth::user()->user_type =='driver') {
            $ride_request->update(['is_driver_rated' => true]);
            $msg = __('message.rated_successfully', ['form' => __('message.driver')]);
        }
        if(($ride_request->payment && $ride_request->payment->payment_status == 'pending') && $request->has('tips') && request('tips') != null) {
            $ride_request->update(['tips' => request('tips')]);
        }

        if( Auth::user()->hasRole('driver') ) {
            $this->updateFirestoreRideDocument($ride_request, 'driver');
        }

        if( Auth::user()->hasRole('rider') ) {
            $this->updateFirestoreRideDocument($ride_request, 'rider');
        }

        $message = __('message.save_form',[ 'form' => __('message.rating') ] );
        
        return json_message_response($message);
    }

    public function placeAutoComplete(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'search_text' => 'required',
            'language' => 'required'
        ]);

        if ( $validator->fails() ) {
            $data = [
                'status' => 'false',
                'message' => $validator->errors()->first(),
                'all_message' =>  $validator->errors()
            ];

            return json_custom_response($data,400);
        }
        
        $google_map_api_key = env('GOOGLE_MAP_KEY');
        
        $payload = ['input' => $request->input('search_text')];

        if ($request->has('language')) {
            $payload['languageCode'] = $request->input('language');
        }

        $response = Http::withHeaders([
            'X-Goog-Api-Key' => $google_map_api_key,
            'Content-Type' => 'application/json'
        ])->post('https://places.googleapis.com/v1/places:autocomplete', $payload);
        return $response->json();
    }

    public function placeDetail(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'placeid' => 'required',
        ]);

        if ( $validator->fails() ) {
            $data = [
                'status' => 'false',
                'message' => $validator->errors()->first(),
                'all_message' =>  $validator->errors()
            ];

            return json_custom_response($data,400);
        }
        
        $google_map_api_key = env('GOOGLE_MAP_KEY');
        $placeId = $request->placeid;
        $apiUrl = "https://places.googleapis.com/v1/places/{$placeId}";

        $headers = [
            'Content-Type' => 'application/json',
            'X-Goog-Api-Key' => $google_map_api_key,
            'X-Goog-FieldMask' => 'id,displayName,formattedAddress,location'
        ];

        $response = Http::withHeaders($headers)->get($apiUrl);

        return $response->json();
    }

    public function updateFirestoreRideDocument($ride_request, $role)
    {
        try {
            $document_name = 'ride_' . $ride_request->id;
            $firebaseData = app('firebase.firestore')->database()->collection('rides')->document($document_name);
            
            if ($firebaseData) {
                $rideData = [
                    'driver_ids' => [$ride_request->driver_id],
                    'on_rider_stream_api_call' => 1,
                    'on_stream_api_call' => 1,
                    'ride_id' => $ride_request->id,
                    'rider_id' => $ride_request->rider_id,
                    'status' => $ride_request->status,
                    'payment_status' => $ride_request->payment->payment_status,
                    'payment_type' => $ride_request->payment_type,
                    'tips' => $ride_request->tips ? 1 : 0,
                ];
        
                $firebaseData->set($rideData, ['merge' => true]);

                if ($ride_request->payment->payment_status === 'paid') {
                    sleep(3);
                    $firebaseData->delete();
                }
            } else {
                Log::info('Document does not exist: ' . $document_name);
                return null;
            }
        } catch (\Exception $e) {
            Log::error('Error updating Firestore document for Ride: ' . $e->getMessage());
        }
    }
    public function snapToRoads(Request $request)
    {
        if (!$request->has('path') || !is_array($request->path)) {
            return response()->json(['error' => 'Invalid path data'], 400);
        }

        $apiKey = env('GOOGLE_MAP_KEY');
        $url = "https://routes.googleapis.com/directions/v2:computeRoutes";

        // Parse the latitude and longitude from the path
        $coordinates = explode(',', $request->path[0]);
        $origin_lat = $coordinates[0];
        $origin_lng = $coordinates[1];

        $coordinates = explode(',', $request->path[1]);
        $destination_lat = $coordinates[0];
        $destination_lng = $coordinates[1];

        // Construct request body for the Routes API
        $requestBody = [
            "origin" => [
                "location" => [
                    "latLng" => ["latitude" => (float)$origin_lat, "longitude" => (float)$origin_lng]
                ]
            ],
            "destination" => [
                "location" => [
                    "latLng" => ["latitude" => (float)$destination_lat, "longitude" => (float)$destination_lng]
                ]
            ],
            "travelMode" => "DRIVE"
        ];

        try {
            $client = new \GuzzleHttp\Client();
            $response = $client->post($url, [
                'headers' => [
                    'Content-Type' => 'application/json',
                    'X-Goog-Api-Key' => $apiKey,
                    'X-Goog-FieldMask' => 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
                ],
                'json' => $requestBody
            ]);

            return response()->json(json_decode($response->getBody(), true));
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

}