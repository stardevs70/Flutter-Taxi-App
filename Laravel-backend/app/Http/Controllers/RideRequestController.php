<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\RideRequest;
use App\DataTables\RideRequestDataTable;
use App\Http\Requests\RideRequestRequest;
use App\Models\Coupon;
use App\Models\Payment;
use App\Models\Service;
use Illuminate\Support\Facades\DB;
use App\Traits\PaymentTrait;
use App\Traits\RideRequestTrait;
use App\Http\Resources\RideRequestResource;
use App\Models\AppSetting;
use App\Models\Corporate;
use App\Models\ManageCancelledReason;
use App\Models\Notification;
use App\Models\RideRequestBid;
use App\Models\Setting;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletHistory;
use App\Traits\WalletHistoryTrait;
use App\Notifications\CommonNotification;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class RideRequestController extends Controller
{
    use PaymentTrait, RideRequestTrait, WalletHistoryTrait;

    public function index(RideRequestDataTable $dataTable)
    {
        $pageTitle = __('message.list_form_title', ['form' => __('message.riderequest')]);
        $auth_user = authSession();
        $assets = ['datatable'];
        $button = '';
        $rideRequestfilterButton = true;

        return $dataTable->render('global.datatable', compact('pageTitle', 'auth_user', 'button', 'rideRequestfilterButton'));
    }

    public function create()
    {
        $pageTitle = __('message.add_form_title', ['form' => __('message.riderequest')]);

        return view('riderequest.form', compact('pageTitle'));
    }

    public function store(Request $request)
    {
        $request['datetime'] = $request->datetime ?? now();

        if ($request->is_schedule == null || !isset($request->is_schedule)) {
            $request['is_schedule'] = 0;
        }

        $data = $request->all();

        $rider_exists_riderequest = RideRequest::whereNotIn('status', ['cancelled', 'completed'])->where('rider_id', Auth::user()->id)->where('is_schedule', 0)->first();
        if ($request->type == 'book_ride') {
            if ($rider_exists_riderequest) {
                if (is_null($rider_exists_riderequest->driver_id)) {
                    $rider_exists_riderequest->delete();
                } else {
                    return json_message_response(__('message.rider_already_in_riderequest'), 400);
                }
            }
        }

        // Get service details for fare calculation
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

        $coupon_code = $request->coupon_code;
        if ($coupon_code != null) {
            $coupon = Coupon::where('code', $coupon_code)->first();
            $status = isset($coupon_code) ? 200 : 400;

            if ($coupon != null) {
                $status = Coupon::isValidCoupon($coupon, $request->service_id, Auth::user()->id);
            }
            if ($status != 200) {
                $response = couponVerifyResponse($status);
                return json_custom_response($response, $status);
            } else {
                $data['coupon_code'] = $coupon->id;
                $data['coupon_data'] = $coupon;
            }
        }

        $data['total_amount']   = $request->total_amount;
        $data['subtotal']       = $request->subtotal;
        $data['base_fare']      = $request->base_fare;
        $data['distance']       = $request->distance;
        $data['base_distance']  = $request->dropoff_distance_in_km;
        $data['duration']       = $request->duration;
        if ($coupon_code) {
            // Calculate coupon discount
            $coupon_discount = $this->calculateCouponDiscount($coupon, $data['subtotal']);
            $data['coupon_discount'] = $coupon_discount;
        }

        $data['is_schedule'] = $request->is_schedule;
        if ($request->is_schedule && $request->schedule_datetime) {
            $data['schedule_datetime'] = $request->schedule_datetime;
        }
        $data['trip_type'] = $request->trip_type;
        $corporate_data = Corporate::where('id', $request->corporate_id)->first();
        $data['corporate_commission'] = isset($corporate_data) ? $corporate_data->commission : 0;

        $result = RideRequest::create($data);

        if ($corporate_data && $result->traveler_info == 'corporate') {
            $user_wallet_data['amount'] = $corporate_data->commission;
            $user_wallet_data['type'] = 'credit';
            $user_wallet_data['transaction_type'] = 'ride_fee';
            $this->saveUserWalletHistory($user_wallet_data, $corporate_data->user_id);
        }

        $this->updateRideRequestAddresses($result->id, $request);

        $message = __('message.save_form', ['form' => __('message.riderequest')]);

        if ($request->type == 'transport' && ($result->payment_type == 'wallet' || $result->payment_type == 'online')) {
            $commission = calculateCommission($service, $result->total_amount);

            $payment = Payment::create([
                'rider_id' => $result->rider_id,
                'ride_request_id' => $result->id,
                'payment_status' => 'paid',
                'datetime' => $request->datetime,
                'total_amount' => $result->total_amount,
                'admin_commission' => $commission['admin_commission'],
                'driver_commission' => $commission['driver_commission'],
                'payment_type' => $result->payment_type,
            ]);

            if ($payment->payment_type == 'wallet') {
                $wallet = Wallet::where('user_id', $result->rider_id)->first();
                if (isset($wallet)) {
                    if ($wallet->total_amount < $result->total_amount) {
                        $result->delete();
                        return json_custom_response(['status' => false, 'message' => 'Insufficient wallet balance. Required: ' . $result->total_amount . ', Available: ' . $wallet->total_amount]);
                    }

                    $wallet->currency = strtolower(SettingData('CURRENCY', 'CURRENCY_CODE') ?? 'USD');

                    try {
                        DB::beginTransaction();

                        // Deduct the calculated amount from wallet
                        $wallet->total_amount -= $payment->total_amount;
                        $wallet->save();

                        WalletHistory::create([
                            'user_id'           => $wallet->user_id,
                            'amount'            => $result->total_amount,
                            'balance'           => $wallet->total_amount,
                            'transaction_type'  => 'ride_fee',
                            'type'              => 'debit',
                            'datetime'          => $request->datetime,
                            'ride_request_id'   => $result->id,
                        ]);

                        DB::commit();
                    } catch (\Exception $e) {
                        DB::rollBack();
                        $result->delete();
                        return json_custom_response(['status' => false, 'message' => 'Payment processing failed'], 500);
                    }
                } else {
                    $result->delete();
                    return json_custom_response(['status' => false, 'message' => 'Wallet not found'], 404);
                }
            }
        }

        $history_data = [
            'ride_request_id' => $result->id,
            'history_type'    => $result->status,
            'ride_request'    => $result,
            'driver_ids'      => $result,
        ];

        if (!$data['is_schedule'] || $data['is_schedule'] == 0) {
            if ($request->ride_type === 'with_bidding') {
                if ($result->status === 'pending') {
                    $this->findDrivers($result);
                }
            } else {
                if ($result->status === 'pending') {
                    $this->acceptDeclinedRideRequest($result, $request->all());
                }
            }
        } else {
            $this->acceptDeclinedRideRequest($result, $request->all());
        }

        saveRideHistory($history_data);

        if ($request->is('api/*')) {
            return json_custom_response([
                'riderequest_id' => $result->id,
                'message' => $message,
            ]);
        }

        return redirect()->route('riderequest.index')->withSuccess($message);
    }

    public function applyBidRideRequest(Request $request)
    {
        $auth_user = Auth::user();
        $driverID = $auth_user->id;

        $rideRequest = RideRequest::find($request->ride_request_id);

        if (!$rideRequest) {
            return json_message_response(__('message.ride_request_not_found', ['id' => $request->ride_request_id]), 404);
        }

        $existingBid = RideRequestBid::where('ride_request_id', $request->ride_request_id)
            ->where('driver_id', $driverID)
            ->first();

        if ($existingBid) {
            return json_message_response(__('message.already_bid_applied', ['id' => $request->ride_request_id, 'driver_name' => $auth_user->username]), 400);
        }

        RideRequestBid::create([
            'ride_request_id' => $request->ride_request_id,
            'is_bid_accept' => 0,
            'driver_id' => $driverID,
            'bid_amount' => $request->bid_amount,
            'notes' => $request->notes,
        ]);

        $history_data = [
            'history_type' => 'bid_placed',
            'ride_request_id' => $rideRequest->id,
            'ride_request' => $rideRequest,
        ];
        saveRideHistory($history_data);

        return json_message_response(__('message.bid_applied', ['id' => $request->ride_request_id, 'driver_name' => $auth_user->username]));
    }

    public function getBiddingDrivers(Request $request)
    {
        // Find the ride request
        $ride_request_id = $request->ride_request_id;
        $ride_request = RideRequest::find($ride_request_id);
        if (!$ride_request) {
            return response()->json(['error' => 'Ride request not found.'], 404);
        }

        $unit = $ride_request->distance_unit ?? 'km';
        $unit_value = convertUnitvalue($unit);
        $radius = Setting::where('type', 'DISTANCE')->where('key', 'DISTANCE_RADIUS')->pluck('value')->first() ?? 50;

        $latitude = $ride_request->start_latitude;
        $longitude = $ride_request->start_longitude;

        // Get nearby drivers who have bid on the ride
        $bidding_drivers = DB::table('ride_request_bids')
            ->join('users', 'ride_request_bids.driver_id', '=', 'users.id')
            ->select(
                'users.id as driver_id',
                'users.display_name as driver_name',
                'ride_request_bids.bid_amount',
                'ride_request_bids.notes',
                DB::raw("($unit_value * acos(cos(radians($latitude)) * cos(radians(users.latitude)) * cos(radians(users.longitude) - radians($longitude)) + sin(radians($latitude)) * sin(radians(users.latitude)))) AS distance")
            )
            ->where('ride_request_bids.is_bid_accept', 0)
            ->where('ride_request_bids.ride_request_id', $ride_request_id)
            ->where('users.status', 'active')
            ->where('users.is_online', 1)
            ->where('users.is_available', 1)
            ->having('distance', '<=', $radius)
            ->orderBy('distance', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $bidding_drivers,
            'start_address' => $ride_request->start_address,
            'end_address' => $ride_request->end_address,
            'multi_drop_location' => $ride_request->multi_drop_location,
        ]);
    }

    public function acceptBidRequest(Request $request)
    {
        $riderequest = RideRequest::find($request->id);

        if ($riderequest == null) {
            $message = __('message.not_found_entry', ['name' => __('message.riderequest')]);
            return json_message_response($message);
        }

        if ($riderequest->status == 'accepted') {
            $message = __('message.not_found_entry', ['name' => __('message.riderequest')]);
            return json_message_response($message, 400);
        }

        $driverIds = is_array(request('driver_id')) ? request('driver_id') : [request('driver_id')];

        if (request()->has('is_bid_accept') && request('is_bid_accept') == 1) {
            $riderequest->driver_id = $driverIds[0];
            $riderequest->status = 'bid_accepted';
            $riderequest->max_time_for_find_driver_for_ride_request = 0;
            $riderequest->otp = rand(1000, 9999);
            $riderequest->riderequest_in_driver_id = null;
            $riderequest->riderequest_in_datetime = null;
            $riderequest->save();

            $bid = RideRequestBid::where('ride_request_id', $riderequest->id)
                ->where('driver_id', $driverIds[0])
                ->first();

            if ($bid) {
                $bid->is_bid_accept = 1;
                $bid->save();
            }

            saveRideHistory([
                'history_type' => 'bid_accepted',
                'ride_request_id' => $riderequest->id,
                'ride_request' => $riderequest,
            ]);

            $riderequest->driver->update(['is_available' => 0]);

            $message = __('message.updated');
        } elseif (request()->has('is_bid_accept') && request('is_bid_accept') == 2) {
            $currentRejectedIds = json_decode($riderequest->rejected_bid_driver_ids, true) ?? [];
            if (!is_array($currentRejectedIds)) {
                $currentRejectedIds = [];
            }

            foreach ($driverIds as $driverId) {
                if (!in_array($driverId, $currentRejectedIds)) {
                    $currentRejectedIds[] = $driverId;
                }

                $bid = RideRequestBid::where('ride_request_id', $riderequest->id)
                    ->where('driver_id', $driverId)
                    ->first();

                if (!$bid) {
                    RideRequestBid::create([
                        'ride_request_id' => $riderequest->id,
                        'driver_id' => $driverId,
                        'bid_amount' => 0,
                        'is_bid_accept' => 2,
                    ]);
                } else {
                    $bid->is_bid_accept = 2;
                    $bid->save();
                }
            }

            $riderequest->update(['rejected_bid_driver_ids' => json_encode($currentRejectedIds)]);

            saveRideHistory([
                'history_type' => 'bid_rejected',
                'ride_request_id' => $riderequest->id,
                'ride_request' => $riderequest,
            ]);
        }

        $response = [
            'ride_request_id' => $riderequest->id,
            'message' => $message ?? __('message.save_form', ['form' => __('message.riderequest')]),
        ];

        if ($request->is('api/*')) {
            return json_custom_response($response);
        }

        return response()->json($response);
    }

    public function acceptRideRequest(Request $request)
    {
        $riderequest = RideRequest::find($request->id);

        if ($riderequest == null) {
            $message = __('message.not_found_entry', ['name' => __('message.riderequest')]);
            return json_message_response($message);
        }

        if ($riderequest->status == 'accepted') {
            $message = __('message.not_found_entry', ['name' => __('message.riderequest')]);
            return json_message_response($message, 400);
        }
        if (request()->has('is_accept') && request('is_accept') == 1) {
            $riderequest->driver_id = request('driver_id');
            $riderequest->status = 'accepted';
            $riderequest->max_time_for_find_driver_for_ride_request = 0;
            $riderequest->otp = rand(1000, 9999);
            $riderequest->riderequest_in_driver_id = null;
            $riderequest->riderequest_in_datetime = null;
            $riderequest->save();
            $result = $riderequest;

            $history_data = [
                'history_type'      => 'accepted',
                'ride_request_id'   => $result->id,
                'ride_request'      => $result,
            ];

            saveRideHistory($history_data);
            if ($riderequest->is_schedule != 1) {
                $riderequest->driver->update(['is_available' => 0]);
            }

            // Notify rider that driver accepted the ride
            try {
                $rider = User::find($riderequest->rider_id);
                if ($rider) {
                    $notification_data = [
                        'id'        => $riderequest->id,
                        'type'      => 'accepted',
                        'subject'   => 'Ride Accepted',
                        'message'   => 'Your ride has been accepted by the driver.',
                    ];
                    $rider->notify(new CommonNotification($notification_data['type'], $notification_data));
                }
            } catch (\Exception $e) {
                Log::error('Failed to send ride accepted notification: ' . $e->getMessage());
            }
        } else {
            $result = $this->acceptDeclinedRideRequest($riderequest, $request->all());
        }

        $message = __('message.updated');
        if ($result->driver_id == null) {
            $message = __('message.save_form', ['form' => __('message.riderequest')]);
        }
        if ($request->is('api/*')) {
            $response = [
                'ride_request_id' => $result->id,
                'message' => $message
            ];
            return json_custom_response($response);
        }
    }

    public function show($id)
    {
        if (!Auth::user()->can('riderequest show')) {
            abort(403, __('message.action_is_unauthorized'));
        }
        $pageTitle = __('message.add_form_title', ['form' => __('message.riderequest')]);
        $data = RideRequest::findOrFail($id);

        if ($data != null) {
            $auth_user = Auth::user();
            if (count($auth_user->unreadNotifications) > 0) {
                $auth_user->unreadNotifications->where('data.type', '!=', 'complaintcomment')->where('data.id', $id)->markAsRead();
            }
        }
        return view('riderequest.show', compact('data'));
    }

    public function edit($id)
    {
        $pageTitle = __('message.update_form_title', ['form' => __('message.riderequest')]);
        $data = RideRequest::findOrFail($id);

        return view('riderequest.form', compact('data', 'pageTitle', 'id'));
    }

    public function update(RideRequestRequest $request, $id)
    {
        $riderequest = RideRequest::findOrFail($id);

        if ($request->has('otp')) {
            if ($riderequest->otp != $request->otp) {
                return json_message_response(__('message.otp_invalid'), 400);
            }
        }
        // RideRequest data...
        $riderequest->fill($request->all())->update();
        $message = __('message.update_form', ['form' => __('message.riderequest')]);
        if ($riderequest->status == 'pending') {
            if ($riderequest->riderequest_in_driver_id == null) {
                $this->acceptDeclinedRideRequest($riderequest, $request->all());
            }
            if ($request->is('api/*')) {
                return json_message_response($message);
            }
        }
        $payment = Payment::where('ride_request_id', $id)->first();

        if ($request->has('is_change_payment_type') && request('is_change_payment_type') == 1) {
            $payment->update(['payment_type' => request('payment_type')]);

            $message = __('message.change_payment_type');
            $notify_data = new \stdClass();
            $notify_data->success = true;
            $notify_data->success_type = 'change_payment_type';
            $notify_data->success_message = $message;
            $notify_data->result = new RideRequestResource($riderequest);

            try {
                $document_name = 'ride_' . $riderequest->id;
                $firebaseData = app('firebase.firestore')->database()->collection('rides')->document($document_name);

                $rideData = [
                    'driver_ids' => [$riderequest->driver_id],
                    'on_rider_stream_api_call' => 1,
                    'on_stream_api_call' => 1,
                    'payment_status' => $riderequest->payment->payment_status,
                    'payment_type' => $riderequest->payment->payment_type,
                    'ride_id' => $riderequest->id,
                    'rider_id' => $riderequest->rider_id,
                    'status' => $riderequest->status,
                    'tips' => $riderequest->tips ? 1 : 0,
                ];

                if ($riderequest->status == 'cancelled') {
                    sleep(3);
                    $firebaseData->delete();
                } else {
                    $firebaseData->set($rideData, ['merge' => true]);
                }
            } catch (\Exception $e) {
                Log::error('Error updating Firestore document for Ride:-405 ' . $e->getMessage());
            }
            // dispatch(new NotifyViaMqtt('ride_request_status_'.$riderequest->driver_id, json_encode($notify_data)));

            return json_message_response($message);
        }

        if ($request->status == 'cancelled') {
            $cancellation_fee = $riderequest->service->cancellation_fee ?? 0;
            $this->deductCancellationFee($riderequest->rider_id, $cancellation_fee, $riderequest->id);
        }

        if (request('status') == 'in_progress') {
            $riderequest->driver->update(['is_available' => 0]);
        }

        $history_data = [
            'history_type'      => request('status'),
            'ride_request_id'   => $id,
            'ride_request'      => $riderequest,
        ];

        saveRideHistory($history_data);

        // Send push notification for ride status changes
        try {
            $status = request('status');
            $notification_map = [
                'arrived'     => ['subject' => 'Driver Arrived', 'message' => 'Your driver has arrived at the pickup location.', 'to' => 'rider'],
                'in_progress' => ['subject' => 'Ride Started', 'message' => 'Your ride is now in progress.', 'to' => 'rider'],
                'completed'   => ['subject' => 'Ride Completed', 'message' => 'Your ride has been completed.', 'to' => 'rider'],
                'cancelled'   => ['subject' => 'Ride Cancelled', 'message' => 'Your ride has been cancelled.', 'to' => 'both'],
            ];

            if (isset($notification_map[$status])) {
                $info = $notification_map[$status];
                $notification_data = [
                    'id'      => $riderequest->id,
                    'type'    => $status,
                    'subject' => $info['subject'],
                    'message' => $info['message'],
                ];

                if (in_array($info['to'], ['rider', 'both']) && $riderequest->rider_id) {
                    $rider = User::find($riderequest->rider_id);
                    if ($rider) {
                        $rider->notify(new CommonNotification($notification_data['type'], $notification_data));
                    }
                }
                if (in_array($info['to'], ['driver', 'both']) && $riderequest->driver_id) {
                    $driver = User::find($riderequest->driver_id);
                    if ($driver) {
                        $driver->notify(new CommonNotification($notification_data['type'], $notification_data));
                    }
                }
            }
        } catch (\Exception $e) {
            Log::error('Failed to send ride status notification: ' . $e->getMessage());
        }

        if ($request->is('api/*')) {
            return json_message_response($message);
        }

        if (auth()->check()) {
            return redirect()->route('riderequest.index')->withSuccess(__('message.update_form', ['form' => __('message.riderequest')]));
        }
        return redirect()->back()->withSuccess(__('message.update_form', ['form' => __('message.riderequest')]));
    }

    public function destroy($id)
    {
        if (env('APP_DEMO')) {
            $message = __('message.demo_permission_denied');
            if (request()->ajax()) {
                return response()->json(['status' => true, 'message' => $message]);
            }
            return redirect()->route('riderequest.index')->withErrors($message);
        }
        $riderequest = RideRequest::find($id);
        $status = 'errors';
        $message = __('message.not_found_entry', ['name' => __('message.riderequest')]);

        if ($riderequest != '') {
            $search = "id" . '":' . $id;
            Notification::where('data', 'like', "%{$search}%")->delete();

            $document_name = 'ride_' . $riderequest->id;
            $firebaseData = app('firebase.firestore')->database()->collection('rides')->document($document_name);
            $firebaseData->delete();
            $riderequest->delete();

            $status = 'success';
            $message = __('message.delete_form', ['form' => __('message.riderequest')]);
        }

        if (request()->is('api/*')) {
            return json_message_response($message);
        }

        if (request()->ajax()) {
            return response()->json(['status' => true, 'message' => $message]);
        }

        return redirect()->back()->with($status, $message);
    }

    public function rideInvoicePdf($id)
    {
        $ride_detail = RideRequest::find($id);
        $today = now()->format('d/m/Y');
        $app_setting = AppSetting::first();

        $pdf = Pdf::loadView('riderequest.invoice', compact('ride_detail', 'today', 'app_setting'), []);
        if (request()->is('api/*')) {
            return $pdf->stream('ride_' . $ride_detail->id . '.pdf');
        }
        return $pdf->download('invoice_' . $ride_detail->id . '.pdf');
    }

    public function updateDropLocationTime($rideId, $dropIndex)
    {
        $ride = RideRequest::findOrFail($rideId);
        $updateField = !empty($ride->multi_drop_location) ? 'multi_drop_location' : 'drop_location';

        $locationData = $ride->$updateField;

        // Decode JSON if needed
        if (is_string($locationData)) {
            $decoded = json_decode($locationData, true);
            if (json_last_error() === JSON_ERROR_NONE) {
                $locationData = $decoded;
            }
        }

        // Ensure we have an array
        if (!is_array($locationData)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid location data format.'
            ], 400);
        }

        // Validate drop index
        if (!isset($locationData[$dropIndex])) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid drop index.'
            ], 400);
        }

        // Update dropped_at timestamp
        $locationData[$dropIndex]['dropped_at'] = now()->toDateTimeString();

        // Save as a JSON-encoded string
        $ride->$updateField = json_encode($locationData, JSON_UNESCAPED_SLASHES);
        $ride->save();

        return response()->json([
            'success' => true,
            'message' => 'Drop time updated successfully',
            'updated_data' => $locationData
        ]);
    }

    public function assigndriver($id)
    {
        $riderequest = RideRequest::find($id);

        // For admin manual assignment: show all active drivers for this service
        // Don't require is_online or is_available (admin assigns for scheduled rides)
        $drivers = User::where('status', 'active')
            ->where('user_type', 'driver')
            ->where('service_id', $riderequest->service_id)
            ->when(optional($riderequest->traveler_info)->type == 'corporate', function ($query) use ($riderequest) {
                $query->where('corporate_id', $riderequest->corporate_id);
            })
            ->orderBy('display_name', 'asc')
            ->get();

        $pageTitle = __('message.assign_driver');
        return view('riderequest.assgin', compact('pageTitle', 'drivers', 'id', 'riderequest'))->render();
    }

    public function assigndriversave(Request $request)
    {
        $id = $request->id;
        $rides = RideRequest::where('id', $id)->first();
        if ($request->type == 'assigned_driver') {
            $message = __('message.assign_driver');
            $data['datetime'] = now();

            $rides->update(['driver_id' => $request->driver_id, 'riderequest_in_driver_id' => null, 'status' => $request->status, 'otp' => rand(1000, 9999)]);
            $history_data = [
                'ride_request_id' => $rides->id,
                'history_type'    => 'assign_driver',
                'ride_request'    => $rides,
                'driver_ids'      => $request->driver_id,
            ];

            saveRideHistory($history_data);
        }
        $message = __('message.assign_driver');
        return redirect()->route('riderequest.index')->withSuccess($message);
    }

    public function ridecancel($id)
    {
        $pageTitle = __('message.cancel_ride');
        return view('riderequest.cancelmodel', compact('pageTitle', 'id'));
    }

    public function saveCancelRide(Request $request)
    {
        $request->validate([
            'reason' => 'required|exists:manage_cancelled_reasons,id',
        ], [
            'reason.required' => __('message.field_is_required', ['reason' => __('message.cancel_reason')]),
            'reason.exists' => __('message.invalid_selection', ['reason' => __('message.cancel_reason')]),
        ]);

        $riderequest = RideRequest::find($request->id);

        if (!$riderequest) {
            return redirect()->back()->with('error', __('message.not_found_entry', ['name' => __('message.ride')]));
        }
        $cancelReason = ManageCancelledReason::find($request->reason);
        $riderequest->status = 'cancelled';
        $riderequest->reason = $cancelReason->reason;
        $riderequest->save();
        $message = __('message.cancelled_ride');

        if ($riderequest->payment_id) {
            if ($riderequest->payment->payment_type !== 'cash' && $riderequest->payment->payment_type !== 'wallet') {
                $wallet = Wallet::where('user_id', $riderequest->rider_id)->first();

                if ($wallet) {
                    $wallet->total_amount += $riderequest->payment->total_amount;
                    $wallet->save();
                } else {
                    $wallet = Wallet::create([
                        'user_id'      => $riderequest->rider_id,
                        'total_amount' => $riderequest->payment->total_amount,
                    ]);
                }

                WalletHistory::create([
                    'user_id'               => $riderequest->rider_id,
                    'amount'                => $riderequest->payment->total_amount,
                    'type'                  => 'credit',
                    'transaction_type'      => 'ride_cancel_refund',
                    'ride_request_id'       => $riderequest->id,
                    'note'                  => 'Ride cancelled refund',
                ]);
            }
        }
        $history_data = [
            'history_type' => $riderequest->status,
            'ride_request_id' => $riderequest->id,
            'ride_request' => $riderequest,
        ];
        saveRideHistory($history_data);
        return redirect()->back()->withSuccess($message);
    }
}
