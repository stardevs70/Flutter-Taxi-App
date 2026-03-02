<?php

namespace App\Http\Controllers;

use App\Http\Requests\DispatchRequest;
use App\Models\Airport;
use App\Models\Corporate;
use App\Models\Coupon;
use App\Models\ManageZone;
use App\Models\RideRequest;
use App\Models\RideRequestHistory;
use App\Models\Service;
use App\Models\SpecialServices;
use App\Models\User;
use App\Models\ZonePrice;
use App\Traits\RideRequestTrait;
use Carbon\Carbon;
use Illuminate\Http\Request;
use App\Traits\WalletHistoryTrait;
use Illuminate\Support\Facades\Validator;

class DispatchController extends Controller
{
    use RideRequestTrait, WalletHistoryTrait;

    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
        $pageTitle = __('message.dispatch');
        $assets = ['map_place', 'phone', 'mobile_number'];
        $auth_user = authSession();
        $button = $auth_user->can('riderequest list') ? '<a href="' . route('riderequest.index') . '" class="float-right btn btn-sm border-radius-10 btn-primary me-2">' . __('message.list_form_title', ['form' => __('message.riderequest')]) . '</a>' : '';

        // $airportList = Airport::get()->toArray();
        $zoneList = ManageZone::where('status', 'active')->get()->toArray();

        return view('dispatch.form', compact('pageTitle', 'assets', 'button', 'zoneList'));
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param Request $request
     *
     * @return \Illuminate\Http\Response
     */
    public function store(DispatchRequest $request)
    {
        if ($request->type != 'transport') { // type is book ride than ignore the transport fields
            $request['weight'] = 0;
            $request['parcel_description'] = null;
            $request['pickup_contact_number'] = null;
            $request['pickup_person_name'] = null;
            $request['pickup_description'] = null;
            $request['delivery_contact_number'] = null;
            $request['delivery_person_name'] = null;
            $request['delivery_description'] = null;
        }

        if ($request->type != 'book_ride') { // type is transport than ignore book ride fields
            $request['passenger'] = null;
            $request['luggage'] = null;
            $request['payment_method'] = null;
            $request['driver_note'] = null;
            $request['internal_note'] = null;
        }

        if ($request->traveler_info != 'corporate') {
            $request['corporate_id'] = null;
        }

        if ($request->schedule_datetime > now()) {
            $request['is_schedule'] = 1;
        }

        $data = $request->all();
       // dd($data);
        // Check if the rider has registred a riderequest already
        $rider_exists_riderequest = RideRequest::whereNotIn('status', ['cancelled', 'completed'])->where('rider_id', request('rider_id'))->where('is_schedule', 0)->exists();

        if ($rider_exists_riderequest) {
            if ($request->is('api/*')) {
                return json_custom_response([
                    'message' => __('message.rider_already_in_riderequest'),
                    'status' => false,
                    'event' => 'validation',
                ]);
            } else {
                return redirect()->back()->withErrors(__('message.rider_already_in_riderequest'));
            }
        }

        // Check if the driver in riderequest already
        if (request('driver_id') != null) {
            $driver_exists_riderequest = RideRequest::whereNotIn('status', ['cancelled', 'completed'])->where('driver_id', request('driver_id'))->where('is_schedule', 0)->exists();

            if ($driver_exists_riderequest) {
                if ($request->is('api/*')) {
                    return json_custom_response([
                        'message' => __('message.driver_already_in_riderequest'),
                        'status' => false,
                        'event' => 'validation',
                    ]);
                } else {
                    return redirect()->back()->withErrors(__('message.driver_already_in_riderequest'));
                }
            }
        }

        $coupon_code = $request->coupon_code;

        if ($coupon_code != null) {
            $coupon = Coupon::where('code', $coupon_code)->first();
            $status = isset($coupon_code) ? 200 : 400;

            if ($coupon != null) {
                $status = Coupon::isValidCoupon($coupon, $request->service_id, request('rider_id'));
            }
            if ($status != 200) {
                $response = couponVerifyResponse($status);

                return json_custom_response($response, $status);
            } else {
                $data['coupon_code'] = $coupon->id;
                $data['coupon_data'] = $coupon;
            }
        }

        $service = Service::with('region')->where('id', $request->service_id)->first();

        if (!$service) {
            return json_custom_response(['status' => false, 'message' => 'Service not found'], 404);
        }

        $data['distance_unit'] = $service->region->distance_unit ?? 'km';
        $data['ride_has_bid'] = $request->ride_type == 'with_bidding' ? 1 : 0;

        $calculated_amounts = $this->calculateFareAmount($request, $service);
        $data['minimum_fare'] = $calculated_amounts['minimum_fare'];
        $data['per_distance'] = $service->per_distance;
        $data['per_distance_charge'] = $calculated_amounts['per_distance_charge'];
        $data['per_minute_drive'] = $service->per_minute_drive;
        $data['per_minute_drive_charge'] = $calculated_amounts['per_minute_drive_charge'];
        if ($request->type == 'transport' && !is_null($request->weight)) {
                $data['weight'] = $request->weight;
                $data['total_weight'] = $calculated_amounts['weight_charge'];
            }

        $timezone = $service->region->timezone ?? 'UTC';
        $data['schedule_datetime'] = Carbon::parse($request->schedule_datetime)->setTimezone($timezone)->toDateTimeString();

        $rider = User::when(request('rider_id'), function ($query, $rider_id) {
            return $query->where('id', $rider_id);
        }, function ($query) {
            return $query->where('contact_number', request('contact_number'));
        })->first();

        if ($rider != null) {
            $rider->timezone = $timezone;
            $rider->save();
        }

        if ($rider == null && request('rider_id') == null) {
            $new_customer_data = User::create([
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'email' => $request->email,
                'contact_number' => $request->contact_number,
                'display_name' => $request->first_name . ' ' . $request->last_name,
                'username' => $request->first_name . ' ' . $request->last_name,
                'password' => bcrypt($request->email),
                'user_type' => 'rider',
            ]);
            $data['rider_id'] = $new_customer_data->id;
        }

        $data['datetime'] = Carbon::parse(date('Y-m-d H:i:s'))->setTimezone($timezone)->toDateTimeString();

        if (request()->has('driver_id') && request('driver_id') != null) {
            $data['riderequest_in_driver_id'] = $data['driver_id'];
            $data['riderequest_in_datetime'] = $data['datetime'];
            $data['driver_id'] = request('driver_id');
            // unset($data['driver_id']);
        }

        $data['distance_unit'] = $service->region->distance_unit ?? 'km';
        $data['status'] = 'pending';
        $data['payment_type'] = 'cash';

        // Fallback to a single destination distance calculation
        $place_details = mighty_get_distance_matrix(
            request('start_latitude'),
            request('start_longitude'),
            request('end_latitude'),
            request('end_longitude')
        );

        // Extract distance and duration
        $dropoff_distance_in_meters = $place_details['distance'] ?? 0;
        $dropoff_time_in_seconds = $place_details['duration'] ?? 0;

        $distance_in_unit = 0;

        if ($dropoff_distance_in_meters) {
            // Region->distance_unit == km ( convert meter to km )
            $distance_in_unit = $dropoff_distance_in_meters / 1000;
        }
        $service_data = $service;
        $service_data['distance_unit'] = $distance_in_unit;
        // caclulate ride
        $pick_lat = request('pick_lat');
        $pick_lng = request('pick_lng');
        $drop_lat = request('drop_lat');
        $drop_lng = request('drop_lng');
        $distance = haversineDistance($pick_lat, $pick_lng, $drop_lat, $drop_lng);
        // $ridefee = calculateRideFares($distance_in_unit, $pick_lat, $pick_lng, $drop_lat, $drop_lng, $dropoff_time_in_seconds, $service_data, $coupon = null);
        $ridefee = calculateRideFares($service_data->toArray(), $distance_in_unit, $dropoff_time_in_seconds, [
            'ride_datetime' => Carbon::parse(date('Y-m-d H:i:s'))->setTimezone($timezone)->toDateTimeString(),  // Adjusted format if needed
            'pickup_zone_id' => $request->pickup_zone_id,
            'drop_zone_id' => $request->drop_zone_id,
            'pickup_airport_id' => $request->pickup_airport_id,
            'drop_airport_id' => $request->drop_airport_id,
            'trip_type' => request('trip_type'),
            'service_type' => request('service_type'),
            'is_estimation' => true,
        ]);
        $data['distance'] = $distance_in_unit;
        $data['total_amount'] = $request->is('api/*') ? $ridefee['total_amount'] : $request->total_amount;
        $data['duration'] = $dropoff_time_in_seconds / 60;
        $data['trip_type'] = $request->trip_type;
        $corporate_data = Corporate::where('id', $request->corporate_id)->first();
        $data['corporate_commission'] = isset($corporate_data) ? $corporate_data->commission : 0;

        $result = RideRequest::create($data);

        if ($corporate_data && $result->traveler_info == 'corporate') {
            # code...
            $user_wallet_data['amount'] = $corporate_data->commission;
            $user_wallet_data['type'] = 'credit';
            $user_wallet_data['transaction_type'] = 'ride_fee';
            $this->saveUserWalletHistory($user_wallet_data, $corporate_data->user_id);
        }

        $pickupZonedata     = ManageZone::find($request->pickup_zone_id);
        $dropoffZonedata    = ManageZone::find($request->drop_zone_id);
        $pickupAirportdata  = Airport::find($request->pickup_airport_id);
        $dropoffAirportdata = Airport::find($request->drop_airport_id);

        if ($request->trip_type == "zone_wise") {
            $zone = ZonePrice::where(['zone_pickup' => $request->pickup_zone_id, 'zone_dropoff' => $request->drop_zone_id])->first();
            if (!$zone && $request->discount != null) {
                $zoneData = [
                    'ride_request_id' => $result->id,
                    'zone_pickup' => $request->pickup_zone_id,
                    'zone_dropoff' => $request->drop_zone_id,
                    'price' => $request->total_amount
                ];
                ZonePrice::create($zoneData);
            }
            $result->start_address = $pickupZonedata->name ?? null;
            $result->end_address = $dropoffZonedata->name ?? null;
            $result->update();
        } elseif ($request->trip_type == "zone_to_airport") {
            $zone = ZonePrice::where(['zone_pickup' => $request->pickup_zone_id, 'airport_dropoff' => $request->drop_airport_id])->first();
            if (!$zone && $request->discount != null) {
                $zoneData = [
                    'ride_request_id' => $result->id,
                    'zone_pickup' => $request->pickup_zone_id,
                    'airport_dropoff' => $request->drop_airport_id,
                    'price' => $request->total_amount
                ];
                ZonePrice::create($zoneData);
            }
            $result->start_address = $pickupZonedata->name ?? null;
            $result->end_address = $dropoffAirportdata->name ?? null;
            $result->zone_dropoff = $request->pickup_zone_id;
            $result->airport_dropoff = $request->drop_airport_id;

            $result->update();
        } elseif ($request->trip_type == "airport_to_zone") {
            $zone = ZonePrice::where(['airport_pickup' => $request->pickup_airport_id, 'zone_dropoff' => $request->drop_zone_id])->first();
            if (!$zone && $request->discount != null) {
                $zoneData = [
                    'ride_request_id' => $result->id,
                    'airport_pickup' => $request->pickup_airport_id,
                    'zone_dropoff' => $request->drop_zone_id,
                    'price' => $request->total_amount
                ];
                ZonePrice::create($zoneData);
            }
            $result->start_address = $pickupAirportdata->name ?? null;
            $result->end_address = $dropoffZonedata->name ?? null;
            $result->airport_pickup = $request->pickup_airport_id ?? null;
            $result->zone_dropoff = $request->drop_zone_id ?? null;
            $result->update();
        } elseif ($request->trip_type == "airport_pickup") {
            $result->start_address = $pickupAirportdata->name ?? null;
            $result->airport_pickup = $request->pickup_airport_id ?? null;
            $result->update();
        } elseif ($request->trip_type == "airport_drop") {
            $result->end_address = $dropoffAirportdata->name ?? null;
            $result->airport_dropoff = $request->drop_airport_id;
            $result->update();
        } else {
        }

        $message = __('message.save_form', ['form' => __('message.riderequest')]);

        if ($result->is_schedule) {
            $rider_data = [
                'rider_id' => $result->rider_id,
                'rider_name' => optional($result->rider)->display_name ?? '',
            ];

            $history_data = [
                'ride_request_id' => $result->id,
                'history_type' => $result->status,
                'history_message' => __('message.ride.pending'),
                'datetime' => date('Y-m-d H:i:s'),
                'history_data' => json_encode($rider_data),
            ];

            RideRequestHistory::create($history_data);
            // $this->acceptDeclinedRideRequest($result);
        } else {
            if ($result->status == 'pending') {
                $history_data = [
                    'ride_request_id' => $result->id,
                    'history_type' => $result->status,
                    'ride_request' => $result,
                ];
                saveRideHistory($history_data);
                // if ($result->driver_id != null) {
                //     $this->acceptDeclinedRideRequest($result);
                // }
            } else {
                $history_data = [
                    'history_type' => $result->status,
                    'ride_request_id' => $result->id,
                    'ride_request' => $result,
                ];

                saveRideHistory($history_data);
            }
        }

        if ($result->driver_id != null) {
            $this->acceptDeclinedRideRequest($result);
        }
        // return response()->json(['status' => true, 'event' => 'reset', 'message' => $message]);

        return redirect()->route('riderequest.index')->withSuccess($message);
    }

    public function supplierPayout(Request $request)
    {
        $title = __('message.adjust_price');
        $fleet_fare = $request->fleet_fare;
        $id = $request->id ?? null;

        return view('dispatch.supplier_payout', compact('title', 'fleet_fare', 'request', 'id'));
    }

    public function updateSupplierPayout(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'base_fare' => 'required|numeric',
            // 'surcharge' => 'required|numeric',
            // 'discount' => 'required|numeric',
        ]);

        if ($validate->fails()) {
            return response()->json(['status' => false, 'event' => 'validation', 'message' => $validate->errors()->first()]);
        }

        $id = $request->id;
        $result = RideRequest::find($id);

        if ($result != null && $result->status == 'pending') {
            $result->base_fare = $request->base_fare;
            $result->surcharge = $request->surcharge;
            $result->discount = $request->discount;
            $result->reason = $request->reason;
            $result->total_amount = $request->fleet_fare;
            $result->save();
            return response()->json(['status' => true, 'event' => 'submited', 'message' => __('message.update_form', ['form' => __('message.adjust_price')])]);
        } else {
            return response()->json(['status' => false, 'event' => 'validation', 'message' => __('message.not_found_entry', ['name' => __('message.adjust_price')])]);
        }
    }

    public function checkSpecialServices(Request $request)
    {
        $service_type = $request->service_type;
        $service = null;

        if ($service_type == 'transport') {
            // code...
            $service = Service::find($request->service_id);
            if (isset($service)) {
                // code...
                $per_weight_charge = $request->weight > $service->minimum_weight ? ($request->weight - $service->minimum_weight) * $service->per_weight_charge : 0;
                $distance = $request->distance > $service->minimum_distance ? ($request->distance - $service->minimum_distance) * $service->per_distance : 0;
                $total = $per_weight_charge + $distance;
                if ($total) {
                    return response()->json(['status' => true, 'total_amount' => $total]);
                }
            }
        }

        $datetime = $request->date_time;
        if ($datetime) {
            // code...
            $service = SpecialServices::where('service_id', $request->service_id)->where('start_date_time', '<=', $datetime)->where('end_date_time', '>=', $datetime)->first();

            return response()->json(['status' => isset($service) ? true : false, 'total_amount' => isset($service) ? $service->base_fare : null]);
        }
    }
}
