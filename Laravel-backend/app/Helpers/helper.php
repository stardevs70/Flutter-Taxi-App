<?php

use App\Models\User;
use App\Models\AppSetting;
use App\Models\Setting;
use App\Models\RideRequest;
use App\Models\RideRequestHistory;
use App\Models\Coupon;
use App\Notifications\RideNotification;
use App\Notifications\CommonNotification;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Http;
use App\Http\Resources\RideRequestResource;
use App\Models\Document;
use App\Models\LanguageVersionDetail;
use App\Models\MailTemplate;
use App\Models\RideRequestBid;
use App\Models\SMSSetting;
use App\Models\SMSTemplate;
use App\Mail\sendmail;
use App\Models\SurgePrice;
use App\Models\ZonePrice;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use App\Models\Wallet;
use App\Models\WalletHistory;
use App\Models\SpecialServices;

function authSession($force = false) {
    $session = new User;
    if( $force ) {
        $user = auth()->user()->getRoleNames();
        Session::put('auth_user',$user);
        $session = Session::get('auth_user');
        return $session;
    }
    if ( Session::has('auth_user') ) {
        $session = Session::get('auth_user');
    } else {
        $user = auth()->user();
        Session::put('auth_user',$user);
        $session = Session::get('auth_user');
    }
    return $session;
}

function appSettingData($type = 'get')
{
    if(Session::get('setting_data') == ''){
        $type='set';
    }
    switch ($type){
        case 'set' :
            $settings = AppSetting::first();
            Session::put('setting_data',$settings);
            break;
        default :
            break;
    }
    return Session::get('setting_data');
}

function json_message_response( $message, $status_code = 200)
{	
	return response()->json( [ 'message' => $message ], $status_code );
}

function json_custom_response( $response, $status_code = 200 )
{
    return response()->json($response,$status_code);
}

function json_pagination_response($items)
{
    return [
        'total_items' => $items->total(),
        'per_page' => $items->perPage(),
        'currentPage' => $items->currentPage(),
        'totalPages' => $items->lastPage()
    ];
}

function imageExtention($media)
{
    $extention = null;
    if($media != null){
        $path_info = pathinfo($media);
        $extention = $path_info['extension'];
    }
    return $extention;
}

function saveRideHistory($data)
{
    $user_type = auth()->user()->user_type;
    $data['datetime'] = date('Y-m-d H:i:s');
    // $mqtt_event = 'test_connection';
    $history_data = [];
    $rideData = [];
    $sendTo = [];
    
    $ride_request_id = $data['ride_request']->id;
    $ride_request = RideRequest::find($ride_request_id);

    $sendEmail = function($ride_request, $status_key, $dynamicData) {
        $setting = SettingData('mail_template', $status_key);
        // \Log::info("Sending email for status: {$status_key}, Setting: {$setting}");
        if ($setting == 1) {
            $email = $ride_request->rider->email ?? null;
            if ($email) {
                $emailData = MailTemplate::where('type', $status_key)->first();
                if ($emailData) {
                    $mailDescription = str_replace(array_keys($dynamicData),array_values($dynamicData),$emailData->description ?? '');
                    $data = [
                        'ride_id' => $ride_request->id,
                        'status' => $status_key,
                        'company_name' => AppSetting::first()->company_name ?? 'Your Company',
                        'rider_name' => $ride_request->rider->name ?? 'Rider',
                        'driver_name' => $ride_request->driver->name ?? 'Driver',
                    ];
                    try {
                        Mail::to($email)->send(new SendMail($emailData->subject ?? __('message.ride.' . $status_key), $mailDescription, $data));
                    } catch (\Exception $e) {
                        \Log::error("Failed to send email for ride ID: {$ride_request->id}, Status: {$status_key}, Error: {$e->getMessage()}");
                    }
                    
                    // Mail::to($email)->send(new SendMail($emailData->subject ?? __('message.ride.' . $status_key),$mailDescription,$data));
                }
            }
        }
    };
    $dynamicData = [
        '[ride ID]' => $ride_request->id,
        '[status]' => ucfirst($ride_request->status),
        '[Company name]' => config('app.name'),
        '[user name]' => $ride_request->rider->display_name ?? __('message.rider.anonymous'),
        '[driver name]' => $ride_request->driver->display_name ?? __('message.driver.anonymous'),
        '[pickup location]' => $ride_request->start_address ?? __('message.ride.location_unknown'),
        '[dropoff location]' => $ride_request->end_address ?? __('message.ride.location_unknown'),
    ];
    switch ($data['history_type']) {
        case 'pending':
            $data['history_message'] = __('message.ride.pending');
            $history_data = [
                'rider_id' => $ride_request->rider_id,
                'rider_name' => optional($ride_request->rider)->display_name ?? '',
            ];
            $sendTo = [];
            break;
            
        case 'assign_driver':
            $data['history_message'] = __('message.assign_driver');
            $history_data = [
                'driver_id' => $data['driver_ids'],
                'driver_name' => optional($ride_request->driver)->display_name ?? '',
            ];
            $sendTo = removeValueFromArray(['admin', 'rider'], $user_type);
        
        case 'no_drivers_available':
            # code...
            break;

        case 'accepted':
            $data['history_message'] = __('message.ride.accepted');
            $history_data = [
                'driver_id' => $ride_request->driver_id,
                'driver_name' => optional($ride_request->driver)->display_name ?? '',
            ];
            // $mqtt_event = 'ride_request_status';
            $dynamicData = [
                '[ride ID]' => $ride_request->id,
                '[status]' => ucfirst($ride_request->status),
                '[Company name]' => config('app.name'),
                '[user name]' => $ride_request->rider->display_name ?? __('message.rider.anonymous'),
                '[driver name]' => $ride_request->driver->display_name ?? __('message.driver.anonymous'),
                '[pickup location]' => $ride_request->start_address ?? __('message.ride.location_unknown'),
                '[dropoff location]' => $ride_request->end_address ?? __('message.ride.location_unknown'),
            ];
            $sendTo = removeValueFromArray(['admin', 'rider'], $user_type);
            $sendEmail($ride_request, 'accepted', $dynamicData);
            break;
        case 'assgined':
            $data['history_message'] = __('message.ride.accepted');
            $history_data = [
                'driver_id' => $ride_request->driver_id,
                'driver_name' => optional($ride_request->driver)->display_name ?? '',
            ];
            // $mqtt_event = 'ride_request_status';
            $dynamicData = [
                '[ride ID]' => $ride_request->id,
                '[status]' => ucfirst($ride_request->status),
                '[Company name]' => config('app.name'),
                '[user name]' => $ride_request->rider->display_name ?? __('message.rider.anonymous'),
                '[driver name]' => $ride_request->driver->display_name ?? __('message.driver.anonymous'),
                '[pickup location]' => $ride_request->start_address ?? __('message.ride.location_unknown'),
                '[dropoff location]' => $ride_request->end_address ?? __('message.ride.location_unknown'),
            ];
            $sendTo = removeValueFromArray(['admin', 'rider'], $user_type);
            $sendEmail($ride_request, 'accepted', $dynamicData);
            break;

        case 'bid_placed':
            foreach ($ride_request->bids as $bid) {
                $data['history_message'] = __('message.ride.bid_placed', ['name' => optional($bid->driver)->display_name]);
                $history_data = [
                    'driver_id' => $bid->driver_id,
                    'rider_id' => $ride_request->rider_id,
                    'driver_name' => optional($bid->driver)->display_name ?? '',
                ];
                $sendTo = removeValueFromArray(['admin', 'rider'], $user_type);
                $sendEmail($ride_request, 'bid_placed', $dynamicData);
            }
            break;

        case 'bid_accepted':
            $accepted_bid = $ride_request->bids->where('is_bid_accept', 1)->first();
            if ($accepted_bid) {
                $data['history_message'] = __('message.ride.bid_accept', ['name' => optional($accepted_bid->driver)->display_name]);
                $ride_request->update(['driver_id' => $accepted_bid->driver_id]);
                $history_data = [
                    'driver_id' => $accepted_bid->driver_id,
                    'driver_name' => optional($accepted_bid->driver)->display_name ?? '',
                ];
            }
            $sendEmail($ride_request, 'bid_accepted', $dynamicData);
            $sendTo = removeValueFromArray(['admin', 'driver'], $user_type);
            break;

        case 'bid_rejected':
            $rejected_bid = $ride_request->bids->where('is_bid_accept', 2)->first();
            if ($rejected_bid) {
                $data['history_message'] = __('message.ride.bid_reject', ['name' => optional($rejected_bid->driver)->display_name]);
                
                $current_rejected_ids = $ride_request->rejected_bid_driver_ids;
                if (is_string($current_rejected_ids)) {
                    $current_rejected_ids = json_decode($current_rejected_ids, true) ?? [];
                } elseif (!is_array($current_rejected_ids)) {
                    $current_rejected_ids = [];
                }
                
                if (!in_array($rejected_bid->driver_id, $current_rejected_ids)) {
                    $current_rejected_ids[] = $rejected_bid->driver_id; // Avoid duplicates
                }
                
                $ride_request->update(['rejected_bid_driver_ids' => json_encode($current_rejected_ids)]);
                
                $ride_request->update(['status' => 'bid_rejected']);
                
                $history_data = [
                    'driver_id' => $rejected_bid->driver_id,
                    'driver_name' => optional($rejected_bid->driver)->display_name ?? '',
                ];
                
                // sleep(2);
                
                // $ride_request->refresh();
                
                // if ($ride_request->status === 'bid_rejected') {
                //     $ride_request->update(['status' => 'pending']);
                // }
            }
            $sendEmail($ride_request, 'bid_rejected', $dynamicData);
            $sendTo = removeValueFromArray(['admin', 'driver'], $user_type);
            break;
        // ride is in progress from the start to the end location
        case 'in_progress':
            $data['history_message'] = __('message.ride.in_progress');
            $history_data = [
                'driver_id' => $ride_request->driver_id,
                'driver_name' => optional($ride_request->driver)->display_name ?? '',
            ];
            $sendEmail($ride_request, 'in_progress', $dynamicData);
            // \Log::info("Email sent for ride ID: {$ride_request->id}, status: in_progress");
            // $mqtt_event = 'ride_request_status';
            $sendTo = removeValueFromArray(['admin', 'rider'], $user_type);
            break;
        
        case 'cancelled':
            $data['history_message'] = __('message.ride.cancelled');
            
            if( $ride_request->cancel_by == 'auto' ) {
                $history_data = [
                    'cancel_by' => $ride_request->cancel_by,
                    'rider_id' => $ride_request->rider_id,
                    'rider_name' => optional($ride_request->rider)->display_name ?? '',
                ];
            }

            if( $ride_request->cancel_by == 'rider' ) {
                $data['history_message'] = __('message.ride.rider_cancelled');
                $history_data = [
                    'cancel_by' => $ride_request->cancel_by,
                    'rider_id' => $ride_request->rider_id,
                    'rider_name' => optional($ride_request->rider)->display_name ?? '',
                ];
            }

            if( $ride_request->cancel_by == 'driver' ) {
                $data['history_message'] = __('message.ride.driver_cancelled');
                $history_data = [
                    'cancel_by' => $ride_request->cancel_by,
                    'driver_id' => $ride_request->driver_id,
                    'driver_name' => optional($ride_request->driver)->display_name ?? '',
                ];
            }
            
            if ($ride_request->driver_id) {
                $ride_request->driver->update(['is_available' => 1]);
            } elseif ($ride_request->riderequest_in_driver) {
                $ride_request->riderequest_in_driver->update(['is_available' => 1]);
            }

            $sendEmail($ride_request, 'cancelled', $dynamicData);
            
            // $mqtt_event = 'ride_request_status';
            $sendTo = removeValueFromArray(['admin', 'rider', 'driver'], $user_type);
            break;

        case 'completed':
            $data['history_message'] = __('message.ride.completed');
            $ride_request = RideRequest::find($ride_request_id);

            $processReferral = function($user, $ride_request_id) {
                if ($user && $user->partner_referral_code) {
                    Log::info("Referral process started for user_id={$user->id} with referral_code={$user->partner_referral_code}");

                    $partner = User::where('referral_code', $user->partner_referral_code)->first();

                    if ($partner) {
                        \Log::info("Partner found: partner_id={$partner->id}");

                        $ride_request = RideRequest::find($ride_request_id);

                        if ($ride_request && $ride_request->driver_id && $ride_request->rider_id) {
                            $wallet = Wallet::firstOrCreate(['user_id' => $partner->id]);

                            $reference_amount = SettingData('reference_amount', 'reference_amount');
                            $reference_type = SettingData('reference_type', 'reference_type');
                            $maxEarningPerMonth = SettingData('max_earning_per_month', 'max_earning_per_month');

                            $currentMonth = now()->format('Y-m');
                            $totalMonthlyReferrals = WalletHistory::where('user_id', $partner->id)
                                ->where('type', 'credit')
                                ->where('transaction_type', 'reference_reward')
                                ->whereDate('datetime', 'like', "$currentMonth%")
                                ->sum('amount');

                            \Log::info("Referral current month total={$totalMonthlyReferrals}, max limit={$maxEarningPerMonth}");

                            if ($reference_type == 'fixed') {
                                $amount_to_credit = $reference_amount;
                            } elseif ($reference_type == 'percentage') {
                                $amount_to_credit = ($reference_amount / 100) * $wallet->total_amount;
                            } else {
                                $amount_to_credit = 0;
                            }

                            \Log::info("Calculated referral amount_to_credit={$amount_to_credit}");

                            if (($totalMonthlyReferrals + $amount_to_credit) <= $maxEarningPerMonth && $amount_to_credit > 0) {
                                $wallet->total_amount = max($wallet->total_amount + $amount_to_credit, 0);
                                $wallet->save();

                                $currency_code = SettingData('CURRENCY', 'CURRENCY_CODE') ?? 'USD';

                                WalletHistory::create([
                                    'user_id'           => $partner->id,
                                    'type'              => 'credit',
                                    'transaction_type'  => 'Reference Reward',
                                    'currency'          => $currency_code,
                                    'amount'            => $amount_to_credit,
                                    'balance'           => $wallet->total_amount,
                                    'ride_request_id'   => $ride_request_id,
                                    'datetime'          => now(),
                                ]);

                                \Log::info("Referral reward credited successfully: partner_id={$partner->id}, amount={$amount_to_credit}");
                            } else {
                                \Log::info("Referral reward skipped (limit reached or 0 amount).");
                            }
                        }
                    } else {
                        Log::info("No partner found for referral_code={$user->partner_referral_code}");
                    }
                } else {
                    Log::info("No valid referral_code for user_id={$user->id} or user not found.");
                }
            };

            // History data for notification
            $history_data = [
                'rider_id'   => $ride_request->rider_id,
                'rider_name' => optional($ride_request->rider)->display_name ?? '',
            ];

            // Process Rider Referral
            if ($ride_request->rider_id) {
                $processReferral($ride_request->rider, $ride_request_id);
            }

            // Process Driver Referral
            if ($ride_request->driver_id) {
                $processReferral($ride_request->driver, $ride_request_id);
            }

            // Email sending
            $sendEmail($ride_request, 'completed', $dynamicData);

            // MQTT event (commented out):
            // $mqtt_event = 'ride_request_status';

            // Send notification to remaining users
            $sendTo = removeValueFromArray(['rider', 'driver'], $user_type);

            break;
        case 'payment_status_message':
            $data['history_message'] = __('message.ride.payment_status_message', ['id' => $ride_request->id, 'status' => __('message.'.optional($ride_request->payment)->payment_status) ]);
            $history_data = [
                'rider_id' => $ride_request->rider_id,
                'status' => optional($ride_request->payment)->payment_status,
                'rider_name' => optional($ride_request->rider)->display_name ?? '',
            ];
            $dynamicData = array_merge($dynamicData, [
                '[payment_status]' => __('message.' . optional($ride_request->payment)->payment_status)
            ]);
            $sendEmail($ride_request, 'payment_status_message', $dynamicData);
            $sendTo = removeValueFromArray(['admin', 'driver', 'rider'], $user_type);
            // $mqtt_event = 'ride_request_status';
            break;

        
            
        default:
            # code...
            break;
    }

    $data['history_data'] = json_encode($history_data);

    if( $data['history_type'] != null ) {
        RideRequestHistory::create($data);
    }

    if( count($sendTo) > 0 ) {
        $notification_data = [
            'id'   => $ride_request->id,
            'type' => $data['history_type'],
            'subject' => __('message.'.$data['history_type']),
            'message' => $data['history_message'],
            'rider_id' => $ride_request->rider_id,
            'driver_id' => $ride_request->driver_id,
        ];
    
        $notify_data = new \stdClass();
        $notify_data->success = true;
        $notify_data->success_type = $data['history_type'];
        $notify_data->success_message = $data['history_message'];
        $notify_data->result = new RideRequestResource($ride_request);
        foreach($sendTo as $send){
            switch ($send) {
                case 'admin':
                    $user = User::admin();
                    break;
                case 'rider':
                    $user = User::whereId( $ride_request->rider_id )->first();
                    break;
                case 'driver':
                    $user = User::whereId( $ride_request->driver_id )->first();
                    break;
            }

            if ($user != null) {
                if ($send != 'driver') {
                    if ($data['history_type'] != 'pending') {
                        try {
                            $document_name = 'ride_' . $ride_request->id;
                            $firebaseData = app('firebase.firestore')->database()->collection('rides')->document($document_name);
                        
                            $nearby_driver_ids = $ride_request->nearby_driver_ids;
                            if (is_string($nearby_driver_ids)) {
                                $nearby_driver_ids = json_decode($nearby_driver_ids, true);
                            } elseif (is_object($nearby_driver_ids)) {
                                $nearby_driver_ids = (array)$nearby_driver_ids;
                            }
                            $nearby_driver_ids = is_array($nearby_driver_ids) ? $nearby_driver_ids : [];
                        
                            $rejected_bid_driver_ids = is_string($ride_request->rejected_bid_driver_ids) 
                                ? json_decode($ride_request->rejected_bid_driver_ids, true) 
                                : [];
                            $rejected_bid_driver_ids = is_array($rejected_bid_driver_ids) ? array_filter($rejected_bid_driver_ids) : [];
                        
                            $updated_nearby_driver_ids = !empty($nearby_driver_ids) && !empty($rejected_bid_driver_ids) 
                                ? array_diff($nearby_driver_ids, $rejected_bid_driver_ids) 
                                : $nearby_driver_ids;
                        
                            $rideData = [
                                'on_rider_stream_api_call' => 1,
                                'on_stream_api_call' => 1,
                                'ride_id' => $ride_request->id,
                                'rider_id' => $ride_request->rider_id,
                                'status' => $ride_request->status,
                                'ride_has_bid' => $ride_request->ride_has_bid,
                                'driver_ids' => $updated_nearby_driver_ids ?? [$ride_request->driver_id]
                            ];
                        
                            $rideRequestStatuses = ['bid_accepted','in_progress', 'completed', 'accepted','assign_driver'];
                            if (in_array($data['history_type'], $rideRequestStatuses) || in_array($ride_request->status, $rideRequestStatuses)) {
                                $rideData['driver_ids'] = [$ride_request->driver_id];
                            }
                        
                            if ($data['history_type'] == 'bid_rejected') {
                                $rideData['status'] = 'bid_rejected';
                            }
                        
                            $firebaseData->set($rideData, ['merge' => true]);
                        
                            if ($ride_request->status == 'completed') {
                                $rideData['payment_status'] = $ride_request->payment->payment_status ?? '';
                                $rideData['payment_type'] = $ride_request->payment->payment_type ?? '';
                                $rideData['tips'] = $ride_request->tips ? 1 : 0;
                        
                                $firebaseData->set($rideData, ['merge' => true]);
                        
                                if ($ride_request->payment->payment_status === 'paid') {
                                    sleep(3);
                                    $firebaseData->delete();
                                }
                            } elseif ($data['history_type'] === 'cancelled' || $ride_request->status === 'cancelled') {
                                sleep(3);
                                $rideData['payment_status'] = 'cancelled';
                                $firebaseData->set($rideData, ['merge' => true]);
                                $firebaseData->delete();
                            } else {
                                $rideData['payment_status'] = '';
                                $rideData['payment_type'] = '';
                                $rideData['tips'] = 0;
                                $firebaseData->set($rideData);
                            }
                        } catch (\Exception $e) {
                            \Log::error('Error updating Firestore document for Ride: ' . $e->getMessage());
                            \Log::error('Error context: ride_id=' . $ride_request->id . ' | rideData=' . json_encode($rideData));
                        }
                        
                    }
                    $user->notify(new RideNotification($notification_data)); 
                }
                $user->notify(new CommonNotification($notification_data['type'], $notification_data));
            }

            if( $user == null && isset($ride_request->riderequest_in_driver_id) && $ride_request->riderequest_in_driver != null && $data['history_type'] == 'cancelled' ) {
                $ride_request->riderequest_in_driver->notify(new CommonNotification($notification_data['type'], $notification_data));
                $ride_request->update([
                    'riderequest_in_driver_id' => null,
                    'riderequest_in_datetime' => null
                ]);
            }
        }
    }
}

function checkMenuRoleAndPermission($menu)
{
    if (auth()->check()) {
        if ($menu->data('role') == null && auth()->user()->hasRole('admin')) {
            return true;
        }

        if($menu->data('permission') == null && $menu->data('role') == null) {
            return true;
        }

        if($menu->data('role') != null) {
            if(auth()->user()->hasAnyRole(explode(',', $menu->data('role')))) {
                return true;
            }
        }

        if($menu->data('permission') != null) {
            if(auth()->user()->can($menu->data('permission')) ) {
                return true;
            }
        }
    }
    return false;
}

function checkRolePermission($role,$permission){
    try{
        if($role->hasPermissionTo($permission)){
            return true;
        }
        return false;
    }catch (Exception $e){
        return false;
    }
}

function getSingleMedia($model, $collection = 'profile_image', $skip=true   )
{
    if (!auth()->check() && $skip) {
        return asset('images/user/1.jpg');
    }
    $media = null;
    if ($model !== null) {
        $media = $model->getFirstMedia($collection);
    }

    if (getFileExistsCheck($media))
    {
        return $media->getFullUrl();
    } else {
        switch ($collection) {
            case 'profile_image':
                $media = asset('images/user/1.jpg');
                break;
            case 'site_logo':
                $media = asset('images/logo.png');
                break;
            case 'site_dark_logo':
                $media = asset('images/dark_logo.png');
                break;
            case 'gateway_image':
                $gateway_name = $model->type ?? 'default';
                $media = asset('images/'.$gateway_name.'.png');
                break;
            case 'site_favicon':
                $media = asset('images/favicon.ico');
                break;
            case 'corporate_background':
                $media = asset('images/favicon.ico');
                break;
            default:
                $media = asset('images/default.png');
                break;
        }
        return $media;
    }
}

function getServiceSingleMedia($model, $collection = 'profile_image', $skip=true   )
{
    if (!auth()->check() && $skip) {
        return asset('images/user/1.jpg');
    }
    $media = null;
    if ($model !== null) {
        $media = $model->getFirstMedia($collection);
    }

    if (getFileExistsCheck($media))
    {
        return $media->getFullUrl();
    } else {
        switch ($collection) {
            case 'profile_image':
                $media = asset('images/user/1.jpg');
                break;
            case 'site_logo':
                $media = asset('images/logo.png');
                break;
            case 'site_dark_logo':
                $media = asset('images/dark_logo.png');
                break;
            case 'gateway_image':
                $gateway_name = $model->type ?? 'default';
                $media = asset('images/'.$gateway_name.'.png');
                break;
            case 'site_favicon':
                $media = asset('images/favicon.ico');
                break;
            default:
                $media = asset('images/service_default.png');
                break;
        }
        return $media;
    }
}

function getFileExistsCheck($media)
{
    $mediaCondition = false;

    if($media) {
        if($media->disk == 'public') {
            $mediaCondition = file_exists($media->getPath());
        } else {
            $mediaCondition = Storage::disk($media->disk)->exists($media->getPath());
        }
    }
    return $mediaCondition;
}

function uploadMediaFile($model,$file,$name)
{
    if($file) {
        $model->clearMediaCollection($name);
        if (is_array($file)){
            foreach ($file as $key => $value){
                $model->addMedia($value)->toMediaCollection($name);
            }
        }else{
            $model->addMedia($file)->toMediaCollection($name);
        }
    }

    return true;
}

function getAttachments($attchments)
{
    $files = [];
    if (count($attchments) > 0) {
        foreach ($attchments as $attchment) {
            if (getFileExistsCheck($attchment)) {
                array_push($files, $attchment->getFullUrl());
            }
        }
    }

    return $files;
}

function getMediaFileExit($model, $collection = 'profile_image')
{
    if($model==null){
        return asset('images/user/1.jpg');
    }

    $media = $model->getFirstMedia($collection);

    return getFileExistsCheck($media);
}

function couponVerifyResponse($status)
{
    $messages = [
        400 => __('message.coupons.code_invalid'),
        405 => __('message.coupons.expire'),
        406 => __('message.coupons.first_rider_only'),
        407 => __('message.coupons.applied_limit'),
        404 => __('message.coupons.code_not_found'),
    ];

    return [
        'message' => $messages[$status] ?? __('message.coupons.code_valid'),
    ];
}

function removeValueFromArray($array = [], $find = null)
{
    foreach (array_keys($array, $find) as $key) {
        unset($array[$key]);
    }

    return array_values($array);
}

function timeZoneList()
{
    $list = \DateTimeZone::listAbbreviations();
    $idents = \DateTimeZone::listIdentifiers();

    $data = $offset = $added = array();
    foreach ($list as $abbr => $info) {
        foreach ($info as $zone) {
            if (!empty($zone['timezone_id']) and !in_array($zone['timezone_id'], $added) and in_array($zone['timezone_id'], $idents)) {

                $z = new \DateTimeZone($zone['timezone_id']);
                $c = new \DateTime(null, $z);
                $zone['time'] = $c->format('H:i a');
                $offset[] = $zone['offset'] = $z->getOffset($c);
                $data[] = $zone;
                $added[] = $zone['timezone_id'];
            }
        }
    }

    array_multisort($offset, SORT_ASC, $data);
    $options = array();
    foreach ($data as $key => $row) {
        $options[$row['timezone_id']] = $row['time'] . ' - ' . formatOffset($row['offset'])  . ' ' . $row['timezone_id'];
    }
    return $options;
}

function formatOffset($offset)
{
    $hours = $offset / 3600;
    $remainder = $offset % 3600;
    $sign = $hours > 0 ? '+' : '-';
    $hour = (int) abs($hours);
    $minutes = (int) abs($remainder / 60);

    if ($hour == 0 and $minutes == 0) {
        $sign = ' ';
    }
    return 'GMT' . $sign . str_pad($hour, 2, '0', STR_PAD_LEFT) . ':' . str_pad($minutes, 2, '0');
}
function languagesArray($ids = [])
{
    $language = [
        [ 'title' => 'Abkhaz' , 'id' => 'ab'],
        [ 'title' => 'Afar' , 'id' => 'aa'],
        [ 'title' => 'Afrikaans' , 'id' => 'af'],
        [ 'title' => 'Akan' , 'id' => 'ak'],
        [ 'title' => 'Albanian' , 'id' => 'sq'],
        [ 'title' => 'Amharic' , 'id' => 'am'],
        [ 'title' => 'Arabic' , 'id' => 'ar'],
        [ 'title' => 'Aragonese' , 'id' => 'an'],
        [ 'title' => 'Armenian' , 'id' => 'hy'],
        [ 'title' => 'Assamese' , 'id' => 'as'],
        [ 'title' => 'Avaric' , 'id' => 'av'],
        [ 'title' => 'Avestan' , 'id' => 'ae'],
        [ 'title' => 'Aymara' , 'id' => 'ay'],
        [ 'title' => 'Azerbaijani' , 'id' => 'az'],
        [ 'title' => 'Bambara' , 'id' => 'bm'],
        [ 'title' => 'Bashkir' , 'id' => 'ba'],
        [ 'title' => 'Basque' , 'id' => 'eu'],
        [ 'title' => 'Belarusian' , 'id' => 'be'],
        [ 'title' => 'Bengali' , 'id' => 'bn'],
        [ 'title' => 'Bihari' , 'id' => 'bh'],
        [ 'title' => 'Bislama' , 'id' => 'bi'],
        [ 'title' => 'Bosnian' , 'id' => 'bs'],
        [ 'title' => 'Breton' , 'id' => 'br'],
        [ 'title' => 'Bulgarian' , 'id' => 'bg'],
        [ 'title' => 'Burmese' , 'id' => 'my'],
        [ 'title' => 'Catalan; Valencian' , 'id' => 'ca'],
        [ 'title' => 'Chamorro' , 'id' => 'ch'],
        [ 'title' => 'Chechen' , 'id' => 'ce'],
        [ 'title' => 'Chichewa; Chewa; Nyanja' , 'id' => 'ny'],
        [ 'title' => 'Chinese' , 'id' => 'zh'],
        [ 'title' => 'Chuvash' , 'id' => 'cv'],
        [ 'title' => 'Cornish' , 'id' => 'kw'],
        [ 'title' => 'Corsican' , 'id' => 'co'],
        [ 'title' => 'Cree' , 'id' => 'cr'],
        [ 'title' => 'Croatian' , 'id' => 'hr'],
        [ 'title' => 'Czech' , 'id' => 'cs'],
        [ 'title' => 'Danish' , 'id' => 'da'],
        [ 'title' => 'Divehi; Dhivehi; Maldivian;' , 'id' => 'dv'],
        [ 'title' => 'Dutch' , 'id' => 'nl'],
        [ 'title' => 'English' , 'id' => 'en'],
        [ 'title' => 'Esperanto' , 'id' => 'eo'],
        [ 'title' => 'Estonian' , 'id' => 'et'],
        [ 'title' => 'Ewe' , 'id' => 'ee'],
        [ 'title' => 'Faroese' , 'id' => 'fo'],
        [ 'title' => 'Fijian' , 'id' => 'fj'],
        [ 'title' => 'Finnish' , 'id' => 'fi'],
        [ 'title' => 'French' , 'id' => 'fr'],
        [ 'title' => 'Fula; Fulah; Pulaar; Pular' , 'id' => 'ff'],
        [ 'title' => 'Galician' , 'id' => 'gl'],
        [ 'title' => 'Georgian' , 'id' => 'ka'],
        [ 'title' => 'German' , 'id' => 'de'],
        [ 'title' => 'Greek, Modern' , 'id' => 'el'],
        [ 'title' => 'Guaraní' , 'id' => 'gn'],
        [ 'title' => 'Gujarati' , 'id' => 'gu'],
        [ 'title' => 'Haitian; Haitian Creole' , 'id' => 'ht'],
        [ 'title' => 'Hausa' , 'id' => 'ha'],
        [ 'title' => 'Hebrew (modern)' , 'id' => 'he'],
        [ 'title' => 'Herero' , 'id' => 'hz'],
        [ 'title' => 'Hindi' , 'id' => 'hi'],
        [ 'title' => 'Hiri Motu' , 'id' => 'ho'],
        [ 'title' => 'Hungarian' , 'id' => 'hu'],
        [ 'title' => 'Interlingua' , 'id' => 'ia'],
        [ 'title' => 'Indonesian' , 'id' => 'id'],
        [ 'title' => 'Interlingue' , 'id' => 'ie'],
        [ 'title' => 'Irish' , 'id' => 'ga'],
        [ 'title' => 'Igbo' , 'id' => 'ig'],
        [ 'title' => 'Inupiaq' , 'id' => 'ik'],
        [ 'title' => 'Ido' , 'id' => 'io'],
        [ 'title' => 'Icelandic' , 'id' => 'is'],
        [ 'title' => 'Italian' , 'id' => 'it'],
        [ 'title' => 'Inuktitut' , 'id' => 'iu'],
        [ 'title' => 'Japanese' , 'id' => 'ja'],
        [ 'title' => 'Javanese' , 'id' => 'jv'],
        [ 'title' => 'Kalaallisut, Greenlandic' , 'id' => 'kl'],
        [ 'title' => 'Kannada' , 'id' => 'kn'],
        [ 'title' => 'Kanuri' , 'id' => 'kr'],
        [ 'title' => 'Kashmiri' , 'id' => 'ks'],
        [ 'title' => 'Kazakh' , 'id' => 'kk'],
        [ 'title' => 'Khmer' , 'id' => 'km'],
        [ 'title' => 'Kikuyu, Gikuyu' , 'id' => 'ki'],
        [ 'title' => 'Kinyarwanda' , 'id' => 'rw'],
        [ 'title' => 'Kirghiz, Kyrgyz' , 'id' => 'ky'],
        [ 'title' => 'Komi' , 'id' => 'kv'],
        [ 'title' => 'Kongo' , 'id' => 'kg'],
        [ 'title' => 'Korean' , 'id' => 'ko'],
        [ 'title' => 'Kurdish' , 'id' => 'ku'],
        [ 'title' => 'Kwanyama, Kuanyama' , 'id' => 'kj'],
        [ 'title' => 'Latin' , 'id' => 'la'],
        [ 'title' => 'Luxembourgish, Letzeburgesch' , 'id' => 'lb'],
        [ 'title' => 'Luganda' , 'id' => 'lg'],
        [ 'title' => 'Limburgish, Limburgan, Limburger' , 'id' => 'li'],
        [ 'title' => 'Lingala' , 'id' => 'ln'],
        [ 'title' => 'Lao' , 'id' => 'lo'],
        [ 'title' => 'Lithuanian' , 'id' => 'lt'],
        [ 'title' => 'Luba-Katanga' , 'id' => 'lu'],
        [ 'title' => 'Latvian' , 'id' => 'lv'],
        [ 'title' => 'Manx' , 'id' => 'gv'],
        [ 'title' => 'Macedonian' , 'id' => 'mk'],
        [ 'title' => 'Malagasy' , 'id' => 'mg'],
        [ 'title' => 'Malay' , 'id' => 'ms'],
        [ 'title' => 'Malayalam' , 'id' => 'ml'],
        [ 'title' => 'Maltese' , 'id' => 'mt'],
        [ 'title' => 'Māori' , 'id' => 'mi'],
        [ 'title' => 'Marathi (Marāṭhī)' , 'id' => 'mr'],
        [ 'title' => 'Marshallese' , 'id' => 'mh'],
        [ 'title' => 'Mongolian' , 'id' => 'mn'],
        [ 'title' => 'Nauru' , 'id' => 'na'],
        [ 'title' => 'Navajo, Navaho' , 'id' => 'nv'],
        [ 'title' => 'Norwegian Bokmål' , 'id' => 'nb'],
        [ 'title' => 'North Ndebele' , 'id' => 'nd'],
        [ 'title' => 'Nepali' , 'id' => 'ne'],
        [ 'title' => 'Ndonga' , 'id' => 'ng'],
        [ 'title' => 'Norwegian Nynorsk' , 'id' => 'nn'],
        [ 'title' => 'Norwegian' , 'id' => 'no'],
        [ 'title' => 'Nuosu' , 'id' => 'ii'],
        [ 'title' => 'South Ndebele' , 'id' => 'nr'],
        [ 'title' => 'Occitan' , 'id' => 'oc'],
        [ 'title' => 'Ojibwe, Ojibwa' , 'id' => 'oj'],
        [ 'title' => 'Oromo' , 'id' => 'om'],
        [ 'title' => 'Oriya' , 'id' => 'or'],
        [ 'title' => 'Ossetian, Ossetic' , 'id' => 'os'],
        [ 'title' => 'Panjabi, Punjabi' , 'id' => 'pa'],
        [ 'title' => 'Pāli' , 'id' => 'pi'],
        [ 'title' => 'Persian' , 'id' => 'fa'],
        [ 'title' => 'Polish' , 'id' => 'pl'],
        [ 'title' => 'Pashto, Pushto' , 'id' => 'ps'],
        [ 'title' => 'Portuguese' , 'id' => 'pt'],
        [ 'title' => 'Quechua' , 'id' => 'qu'],
        [ 'title' => 'Romansh' , 'id' => 'rm'],
        [ 'title' => 'Kirundi' , 'id' => 'rn'],
        [ 'title' => 'Romanian, Moldavian, Moldovan' , 'id' => 'ro'],
        [ 'title' => 'Russian' , 'id' => 'ru'],
        [ 'title' => 'Sanskrit (Saṁskṛta)' , 'id' => 'sa'],
        [ 'title' => 'Sardinian' , 'id' => 'sc'],
        [ 'title' => 'Sindhi' , 'id' => 'sd'],
        [ 'title' => 'Northern Sami' , 'id' => 'se'],
        [ 'title' => 'Samoan' , 'id' => 'sm'],
        [ 'title' => 'Sango' , 'id' => 'sg'],
        [ 'title' => 'Serbian' , 'id' => 'sr'],
        [ 'title' => 'Scottish Gaelic; Gaelic' , 'id' => 'gd'],
        [ 'title' => 'Shona' , 'id' => 'sn'],
        [ 'title' => 'Sinhala, Sinhalese' , 'id' => 'si'],
        [ 'title' => 'Slovak' , 'id' => 'sk'],
        [ 'title' => 'Slovene' , 'id' => 'sl'],
        [ 'title' => 'Somali' , 'id' => 'so'],
        [ 'title' => 'Southern Sotho' , 'id' => 'st'],
        [ 'title' => 'Spanish; Castilian' , 'id' => 'es'],
        [ 'title' => 'Sundanese' , 'id' => 'su'],
        [ 'title' => 'Swahili' , 'id' => 'sw'],
        [ 'title' => 'Swati' , 'id' => 'ss'],
        [ 'title' => 'Swedish' , 'id' => 'sv'],
        [ 'title' => 'Tamil' , 'id' => 'ta'],
        [ 'title' => 'Telugu' , 'id' => 'te'],
        [ 'title' => 'Tajik' , 'id' => 'tg'],
        [ 'title' => 'Thai' , 'id' => 'th'],
        [ 'title' => 'Tigrinya' , 'id' => 'ti'],
        [ 'title' => 'Tibetan Standard, Tibetan, Central' , 'id' => 'bo'],
        [ 'title' => 'Turkmen' , 'id' => 'tk'],
        [ 'title' => 'Tagalog' , 'id' => 'tl'],
        [ 'title' => 'Tswana' , 'id' => 'tn'],
        [ 'title' => 'Tonga (Tonga Islands)' , 'id' => 'to'],
        [ 'title' => 'Turkish' , 'id' => 'tr'],
        [ 'title' => 'Tsonga' , 'id' => 'ts'],
        [ 'title' => 'Tatar' , 'id' => 'tt'],
        [ 'title' => 'Twi' , 'id' => 'tw'],
        [ 'title' => 'Tahitian' , 'id' => 'ty'],
        [ 'title' => 'Uighur, Uyghur' , 'id' => 'ug'],
        [ 'title' => 'Ukrainian' , 'id' => 'uk'],
        [ 'title' => 'Urdu' , 'id' => 'ur'],
        [ 'title' => 'Uzbek' , 'id' => 'uz'],
        [ 'title' => 'Venda' , 'id' => 've'],
        [ 'title' => 'Vietnamese' , 'id' => 'vi'],
        [ 'title' => 'Volapük' , 'id' => 'vo'],
        [ 'title' => 'Walloon' , 'id' => 'wa'],
        [ 'title' => 'Welsh' , 'id' => 'cy'],
        [ 'title' => 'Wolof' , 'id' => 'wo'],
        [ 'title' => 'Western Frisian' , 'id' => 'fy'],
        [ 'title' => 'Xhosa' , 'id' => 'xh'],
        [ 'title' => 'Yiddish' , 'id' => 'yi'],
        [ 'title' => 'Yoruba' , 'id' => 'yo'],
        [ 'title' => 'Zhuang, Chuang' , 'id' => 'za']
    ];

    if(!empty($ids))
    {
        $language = collect($language)->whereIn('id',$ids)->values();
    }

    return $language;
}

function flattenToMultiDimensional(array $array, $delimiter = '.')
{
    $result = [];
    foreach ($array as $notations => $value) {
        // extract keys
        $keys = explode($delimiter, $notations);
        // reverse keys for assignments
        $keys = array_reverse($keys);

        // set initial value
        $lastVal = $value;
        foreach ($keys as $key) {
            // wrap value with key over each iteration
            $lastVal = [
                $key => $lastVal
            ];
        }
        // merge result
        $result = array_merge_recursive($result, $lastVal);
    }
    return $result;
}

function createLangFile($lang=''){
    $langDir = resource_path().'/lang/';
    $enDir = $langDir.'en';
    $currentLang = $langDir . $lang;
    if(!File::exists($currentLang)){
       File::makeDirectory($currentLang);
       File::copyDirectory($enDir,$currentLang);
    }
}

function dateAgoFormate($date,$type2='')
{
    if($date == null || $date == '0000-00-00 00:00:00') {
        return '-';
    }

    $diff_time1 = \Carbon\Carbon::createFromTimeStamp(strtotime($date))->diffForHumans();
    $datetime = new \DateTime($date);
    $la_time = new \DateTimeZone(auth()->check() ? auth()->user()->timezone ?? 'UTC' : 'UTC');
    $datetime->setTimezone($la_time);
    $diff_date = $datetime->format('Y-m-d H:i:s');

    $diff_time = \Carbon\Carbon::parse($diff_date)->isoFormat('LLL');

    if($type2 != ''){
        return $diff_time;
    }

    return $diff_time1 .' on '.$diff_time;
}

function timeAgoFormate($date)
{
    if($date==null){
        return '-';
    }

    date_default_timezone_set('UTC');

    $diff_time= \Carbon\Carbon::createFromTimeStamp(strtotime($date))->diffForHumans();

    return $diff_time;
}

function envChanges($type,$value)
{
    $path = base_path('.env');

    $checkType = $type.'="';
    if(strpos($value,' ') || strpos(file_get_contents($path),$checkType) || preg_match('/[\'^£$%&*()}{@#~?><>,|=_+¬-]/', $value)){
        $value = '"'.$value.'"';
    }

    $value = str_replace('\\', '\\\\', $value);

    if (file_exists($path)) {
        $typeValue = env($type);

        if(strpos(env($type),' ') || strpos(file_get_contents($path),$checkType)){
            $typeValue = '"'.env($type).'"';
        }

        file_put_contents($path, str_replace(
            $type.'='.$typeValue, $type.'='.$value, file_get_contents($path)
        ));

        $onesignal = collect(config('constant.ONESIGNAL'))->keys();

        $checkArray = Arr::collapse([['DEFAULT_LANGUAGE']]);


        if( in_array( $type ,$checkArray) ){
            if(env($type) === null){
                file_put_contents($path,"\n".$type.'='.$value ,FILE_APPEND);
            }
        }
    }
}

function convertUnitvalue($unit)
{
    switch ($unit) {
        case 'mile':
            return 3956;
            break;
        default:
            return 6371;
            break;
    }
}

function mile_to_km($mile) {
    return $mile * 1.60934;
}

function km_to_mile($km) {
    return $km * 0.621371;
}

function mighty_get_distance_matrix($pick_lat, $pick_lng, $drop_lat, $drop_lng, $traffic = false)
{
    $google_map_api_key = env('GOOGLE_MAP_KEY');
    if (!$google_map_api_key) {
        return response()->json(['error' => 'Google Map API Key is missing'], 500);
    }

    // Get formatted addresses using Geocoding API
    function getFormattedAddress($lat, $lng, $google_map_api_key) {
        $response = Http::get("https://maps.googleapis.com/maps/api/geocode/json", [
            'latlng' => "$lat,$lng",
            'key' => $google_map_api_key
        ]);

        if ($response->json()['status'] !== 'OK') {
            return "$lat,$lng";
        }

        return $response->json()['results'][0]['formatted_address'] ?? "$lat,$lng";
    }

    $originAddress = getFormattedAddress($pick_lat, $pick_lng, $google_map_api_key);
    $destinationAddress = getFormattedAddress($drop_lat, $drop_lng, $google_map_api_key);

    // Request to Distance Matrix API v2
    $response = Http::withHeaders([
        'Content-Type' => 'application/json',
        'X-Goog-Api-Key' => $google_map_api_key,
        'X-Goog-FieldMask' => 'originIndex,destinationIndex,status,distanceMeters,duration'
    ])->post('https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix', [
        "origins" => [
            ["waypoint" => ["location" => ["latLng" => ["latitude" => (float) $pick_lat, "longitude" => (float) $pick_lng]]]]
        ],
        "destinations" => [
            ["waypoint" => ["location" => ["latLng" => ["latitude" => (float) $drop_lat, "longitude" => (float) $drop_lng]]]]
        ],
        "travelMode" => "DRIVE"
    ]);    

    if (!$response->successful()) {
        return response()->json(['error' => 'Failed to retrieve distance matrix', 'details' => $response->body()], 500);
    }

    $routeData = $response->json()[0] ?? null;

    if (!$routeData || !isset($routeData['distanceMeters']) || !isset($routeData['duration'])) {
        return response()->json([
            'error' => 'Invalid response from Distance Matrix API',
            'api_response' => $response->json()
        ], 400);
    }
    $distanceMeters = is_numeric($routeData['distanceMeters']) ? $routeData['distanceMeters'] : 0;    
    $rawDuration = $routeData['duration'] ?? '0s';
    $durationSeconds = (int) rtrim($rawDuration, 's'); // safely cast

    $convertedResponse = [
        "destination_addresses" => [$destinationAddress],
        "origin_addresses" => [$originAddress],
        "rows" => [
            [
                "elements" => [
                    [
                        "distance" => [
                            "text" => round($distanceMeters / 1000, 1) . " km",
                            "value" => $distanceMeters
                        ],
                        "duration" => [
                            "text" => round($durationSeconds / 60) . " mins",
                            "value" => $durationSeconds
                        ],
                        "status" => $routeData['status'] ?? 'UNKNOWN'
                    ]
                ]
            ]
        ],
        "status" => "OK"
    ];

    return $convertedResponse;
}

function distance_value_from_distance_matrix($distance_matrix) {
    $element = first_element_in_distance_matrix($distance_matrix);

    if (isset($element) && isset($element['distance'])) {
        return (float)$element['distance']['value'];
    }

    return null;
}

function duration_value_from_distance_matrix($distance_matrix)
{
    $element = first_element_in_distance_matrix($distance_matrix);

    if (isset($element)) {
        if (isset($element['duration_in_traffic'])) {
            return (int)$element['duration_in_traffic']['value'];
        } elseif (isset($element['duration'])) {
            return (int)$element['duration']['value'];
        }
    }
}

function first_element_in_distance_matrix($distance_matrix)
{
    try {
        $row = $distance_matrix['rows'][0];
        return $row['elements'][0];
    } catch (\Throwable $th) {
        return null;
    }

}

function calculateRideFares( $service, $distance,  $duration_in_seconds,  $options = [])
{
    // Extract options
    $waiting_time = $options['waiting_time'] ?? 0;
    $extra_charges_amount = $options['extra_charges_amount'] ?? 0;
    $tips = $options['tips'] ?? 0;
    $coupon = $options['coupon'] ?? null;
    $ride_datetime = $options['ride_datetime'] ?? null;
    $is_estimation = $options['is_estimation'] ?? false;
    $weight = $options['weight'] ?? 0;

    $trip_type = $options['trip_type'] ?? request('trip_type');
    $service_type = $options['service_type'] ?? request('service_type');
    $pickup_zone_id = $options['pickup_zone_id'] ?? request('pickup_zone_id');
    $drop_zone_id = $options['drop_zone_id'] ?? request('drop_zone_id');
    $pickup_airport_id = $options['pickup_airport_id'] ?? request('pickup_airport_id');
    $drop_airport_id = $options['drop_airport_id'] ?? request('drop_airport_id');

    // Distance unit
    $distance_unit = $service['distance_unit'] ?? 'km';
    $minimum_distance = $service['minimum_distance'] ?? 0;

    // Adjust distance
    if ($distance > $minimum_distance) {
        $distance -= $minimum_distance;
    }

    $base_fare = $service['base_fare'];
    $per_distance_charge = $distance * $service['per_distance'];
    $per_minute_drive_charge = ($duration_in_seconds / 60) * $service['per_minute_drive'];
    $per_minute_waiting_charge = $waiting_time * ($service['per_minute_waiting'] ?? 0);
    $weight_charge = 0;
    $total_amount = $base_fare;

    if ($service_type == 'transport' && $weight > 0){
        if($weight > $service['minimum_weight']){
            $weight -= $service['minimum_weight'];
        }
        $weight_charge = $weight * $service['per_weight_charge'];
    }
    $total_amount = $per_minute_drive_charge + $per_distance_charge + $weight_charge;

    // Minimum fare
    if ($total_amount < $service['minimum_fare']) {
        $total_amount = $service['minimum_fare'];
    }

    $total_amount += $extra_charges_amount + $tips;

    // Commission
    if ($service['commission_type'] === 'percentage') {
        $admin_commission = $total_amount * ($service['admin_commission'] / 100);
        $fleet_commission = $total_amount * ($service['fleet_commission'] / 100);
        $commission = $admin_commission + $fleet_commission;
    } else {
        $commission = $service['admin_commission'] + $service['fleet_commission'];
    }

    if ($total_amount <= $commission) {
        $total_amount += $commission;
    }

    $subtotal = $total_amount;
    $discount_amount = 0;

    // Coupon logic
    if ($coupon && $coupon->minimum_amount < $total_amount) {
        $discount_amount = $coupon->discount_type === 'percentage'
            ? $total_amount * ($coupon->discount / 100)
            : $coupon->discount;

        if ($coupon->maximum_discount > 0 && $discount_amount > $coupon->maximum_discount) {
            $discount_amount = $coupon->maximum_discount;
        }

        $subtotal -= $discount_amount;
    }

    // Special service override
    $special_service_applied = false;
    $special_service_base_fare = null;

    if ($ride_datetime) {
        $special_service = SpecialServices::where('start_date_time', '<=', $ride_datetime)
            ->where('end_date_time', '>=', $ride_datetime)
            ->first();

        if ($special_service) {
            $subtotal = $total_amount;
            $discount_amount = 0;
            $special_service_applied = true;
            $special_service_base_fare = $special_service->base_fare;
        }
    }

    // Zone-based override pricing (for estimates and zone/airport trip types)
    if ($is_estimation && $service_type == 'book_ride') {
        $zone_price = ZonePrice::query();

        switch ($trip_type) {
            case 'zone_wise':
                $zone_price->where('zone_pickup', $pickup_zone_id)->where('zone_dropoff', $drop_zone_id);
                break;
            case 'zone_to_airport':
                $zone_price->where('zone_pickup', $pickup_zone_id)->where('airport_dropoff', $drop_airport_id);
                break;
            case 'airport_to_zone':
                $zone_price->where('airport_pickup', $pickup_airport_id)->where('zone_dropoff', $drop_zone_id);
                break;
            case 'airport_pickup':
                $zone_price->where('airport_pickup', $pickup_airport_id)->where('zone_dropoff', $drop_zone_id);
                break;
            case 'airport_drop':
                $zone_price->where('zone_pickup', $pickup_zone_id)->where('airport_dropoff', $drop_airport_id);
                break;
        }

        if (in_array($trip_type, ['zone_wise', 'zone_to_airport', 'airport_to_zone', 'airport_pickup', 'airport_drop'])) {
            $zone_price = $zone_price->latest()->first();
            if ($zone_price) {
                $total_amount = $subtotal = (double)$zone_price->price;
                $discount_amount = 0;
            }
        }
    }

    return [
        'distance' => round($distance, 2),
        'minimum_distance_in_km' => $minimum_distance,
        'base_fare' => $special_service_applied ? $special_service_base_fare : $base_fare,
        'distance_price' => round($per_distance_charge, 2),
        'time_price' => round($per_minute_drive_charge, 2),
        'per_minute_waiting_charge' => round($per_minute_waiting_charge, 2),
        'extra_charges_amount' => $extra_charges_amount,
        'tips' => $tips,
        'subtotal' => round($subtotal, 2),
        'total_amount' => round($total_amount, 2),
        'discount_amount' => round($discount_amount, 2),
        'special_service_applied' => $special_service_applied,
        'commission_applied' => round($commission, 2),
    ];
}


function haversineDistance($lat1, $lng1, $lat2, $lng2) {
    $earthRadius = 6371;

    $dLat = deg2rad($lat2 - $lat1);
    $dLng = deg2rad($lng2 - $lng1);

    $a = sin($dLat / 2) * sin($dLat / 2) +
         cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * 
         sin($dLng / 2) * sin($dLng / 2);

    $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
    $distance = $earthRadius * $c;
    return $distance;
}

function calculateRideDuration($start_time, $end_time = null)
{
    $end_time = $end_time ?? date('Y-m-d H:i:s');
    $start_time = Carbon\Carbon::parse($start_time);
    $end_time = Carbon\Carbon::parse($end_time);
    return $start_time->diffInSeconds($end_time, false); // signed result
}

function calculate_distance($lat1, $lng1, $lat2, $lng2, $unit)
{
    if (($lat1 == $lat2) && ($lng1 == $lng2)) {
        return 0;
    } else {
        $theta = $lng1 - $lng2;
        $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) +  cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
        $dist = acos($dist);
        $dist = rad2deg($dist);
        $miles = $dist * 60 * 1.1515;

        if ($unit == "km") {
            return ($miles * 1.609344);
        } elseif ($unit == "mile") {
            return ($miles * 0.8684);
        } else {
            return $miles;
        }
    }
}

function SettingData($type, $key = null)
{
    $setting = Setting::where('type',$type);
   
    $setting->when($key != null, function ($q) use($key) {
        return $q->where('key', $key);
    });

    $setting_data = $setting->pluck('value')->first();
   return $setting_data;
}

function getPriceFormat($price)
{
    if (gettype($price) == 'string') {
        return $price;
    }
    if($price === null){
        $price = 0;
    }
    
    $currency_code = SettingData('CURRENCY', 'CURRENCY_CODE') ?? 'USD';
    $currecy = currencyArray($currency_code);

    $code = $currecy['symbol'] ?? '$';
    $position = SettingData('CURRENCY', 'CURRENCY_POSITION') ?? 'left';
    
    if ($position == 'left') {
        $price = $code."".number_format( (float) $price,2,'.','');
    } else {
        $price = number_format( (float) $price, 2,'.','')."".$code;
    }

    return $price;
}

function verify_coupon_code($coupon_code, $service = null, $rider_id = null)
{
    $coupon = Coupon::where('code', $coupon_code)->first();

    if (!$coupon) {
        return [
            'status' => 400,
            'message' => 'The coupon code is not valid.',
        ];
    }

    $status = Coupon::isValidCoupon($coupon, $service);

    if ($status !== 200) {
        $response = couponVerifyResponse($status);
        $response['status'] = $status;
        return $response;
    }

    return [
        'status' => 200,
        'message' => 'Valid coupon.',
    ];
}

function currencyArray($code = null)
{
    $currency = [
        [ 'code' => 'AED', 'name' => 'United Arab Emirates dirham', 'symbol' => 'د.إ'],
        [ 'code' => 'AFN', 'name' => 'Afghan afghani', 'symbol' => '؋'],
        [ 'code' => 'ALL', 'name' => 'Albanian lek', 'symbol' => 'L'],
        [ 'code' => 'AMD', 'name' => 'Armenian dram', 'symbol' => 'AMD'],
        [ 'code' => 'ANG', 'name' => 'Netherlands Antillean guilder', 'symbol' => 'ƒ'],
        [ 'code' => 'AOA', 'name' => 'Angolan kwanza', 'symbol' => 'Kz'],
        [ 'code' => 'ARS', 'name' => 'Argentine peso', 'symbol' => '$'],
        [ 'code' => 'AUD', 'name' => 'Australian dollar', 'symbol' => '$'],
        [ 'code' => 'AWG', 'name' => 'Aruban florin', 'symbol' => 'Afl.'],
        [ 'code' => 'AZN', 'name' => 'Azerbaijani manat', 'symbol' => 'AZN'],
        [ 'code' => 'BAM', 'name' => 'Bosnia and Herzegovina convertible mark', 'symbol' => 'KM'],
        [ 'code' => 'BBD', 'name' => 'Barbadian dollar', 'symbol' => '$'],
        [ 'code' => 'BDT', 'name' => 'Bangladeshi taka', 'symbol' => '৳ '],
        [ 'code' => 'BGN', 'name' => 'Bulgarian lev', 'symbol' => 'лв.'],
        [ 'code' => 'BHD', 'name' => 'Bahraini dinar', 'symbol' => '.د.ب'],
        [ 'code' => 'BIF', 'name' => 'Burundian franc', 'symbol' => 'Fr'],
        [ 'code' => 'BMD', 'name' => 'Bermudian dollar', 'symbol' => '$'],
        [ 'code' => 'BND', 'name' => 'Brunei dollar', 'symbol' => '$'],
        [ 'code' => 'BOB', 'name' => 'Bolivian boliviano', 'symbol' => 'Bs.'],
        [ 'code' => 'BRL', 'name' => 'Brazilian real', 'symbol' => 'R$'],
        [ 'code' => 'BSD', 'name' => 'Bahamian dollar', 'symbol' => '$'],
        [ 'code' => 'BTC', 'name' => 'Bitcoin', 'symbol' => '฿'],
        [ 'code' => 'BTN', 'name' => 'Bhutanese ngultrum', 'symbol' => 'Nu.'],
        [ 'code' => 'BWP', 'name' => 'Botswana pula', 'symbol' => 'P'],
        [ 'code' => 'BYR', 'name' => 'Belarusian ruble (old)', 'symbol' => 'Br'],
        [ 'code' => 'BYN', 'name' => 'Belarusian ruble', 'symbol' => 'Br'],
        [ 'code' => 'BZD', 'name' => 'Belize dollar', 'symbol' => '$'],
        [ 'code' => 'CAD', 'name' => 'Canadian dollar', 'symbol' => '$'],
        [ 'code' => 'CDF', 'name' => 'Congolese franc', 'symbol' => 'Fr'],
        [ 'code' => 'CHF', 'name' => 'Swiss franc', 'symbol' => 'CHF'],
        [ 'code' => 'CLP', 'name' => 'Chilean peso', 'symbol' => '$'],
        [ 'code' => 'CNY', 'name' => 'Chinese yuan', 'symbol' => '¥'],
        [ 'code' => 'COP', 'name' => 'Colombian peso', 'symbol' => '$'],
        [ 'code' => 'CRC', 'name' => 'Costa Rican colón', 'symbol' => '₡'],
        [ 'code' => 'CUC', 'name' => 'Cuban convertible peso', 'symbol' => '$'],
        [ 'code' => 'CUP', 'name' => 'Cuban peso', 'symbol' => '$'],
        [ 'code' => 'CVE', 'name' => 'Cape Verdean escudo', 'symbol' => '$'],
        [ 'code' => 'CZK', 'name' => 'Czech koruna', 'symbol' => 'Kč'],
        [ 'code' => 'DJF', 'name' => 'Djiboutian franc', 'symbol' => 'Fr'],
        [ 'code' => 'DKK', 'name' => 'Danish krone', 'symbol' => 'kr.'],
        [ 'code' => 'DOP', 'name' => 'Dominican peso', 'symbol' => 'RD$'],
        [ 'code' => 'DZD', 'name' => 'Algerian dinar', 'symbol' => 'د.ج'],
        [ 'code' => 'EGP', 'name' => 'Egyptian pound', 'symbol' => 'EGP'],
        [ 'code' => 'ERN', 'name' => 'Eritrean nakfa', 'symbol' => 'Nfk'],
        [ 'code' => 'ETB', 'name' => 'Ethiopian birr', 'symbol' => 'Br'],
        [ 'code' => 'EUR', 'name' => 'Euro', 'symbol' => '€'],
        [ 'code' => 'FJD', 'name' => 'Fijian dollar', 'symbol' => '$'],
        [ 'code' => 'FKP', 'name' => 'Falkland Islands pound', 'symbol' => '£'],
        [ 'code' => 'GBP', 'name' => 'Pound sterling', 'symbol' => '£'],
        [ 'code' => 'GEL', 'name' => 'Georgian lari', 'symbol' => 'ლ'],
        [ 'code' => 'GGP', 'name' => 'Guernsey pound', 'symbol' => '£'],
        [ 'code' => 'GHS', 'name' => 'Ghana cedi', 'symbol' => '₵'],
        [ 'code' => 'GIP', 'name' => 'Gibraltar pound', 'symbol' => '£'],
        [ 'code' => 'GMD', 'name' => 'Gambian dalasi', 'symbol' => 'D'],
        [ 'code' => 'GNF', 'name' => 'Guinean franc', 'symbol' => 'Fr'],
        [ 'code' => 'GTQ', 'name' => 'Guatemalan quetzal', 'symbol' => 'Q'],
        [ 'code' => 'GYD', 'name' => 'Guyanese dollar', 'symbol' => '$'],
        [ 'code' => 'HKD', 'name' => 'Hong Kong dollar', 'symbol' => '$'],
        [ 'code' => 'HNL', 'name' => 'Honduran lempira', 'symbol' => 'L'],
        [ 'code' => 'HRK', 'name' => 'Croatian kuna', 'symbol' => 'kn'],
        [ 'code' => 'HTG', 'name' => 'Haitian gourde', 'symbol' => 'G'],
        [ 'code' => 'HUF', 'name' => 'Hungarian forint', 'symbol' => 'Ft'],
        [ 'code' => 'IDR', 'name' => 'Indonesian rupiah', 'symbol' => 'Rp'],
        [ 'code' => 'ILS', 'name' => 'Israeli new shekel', 'symbol' => '₪'],
        [ 'code' => 'IMP', 'name' => 'Manx pound', 'symbol' => '£'],
        [ 'code' => 'INR', 'name' => 'Indian rupee', 'symbol' => '₹'],
        [ 'code' => 'IQD', 'name' => 'Iraqi dinar', 'symbol' => 'د.ع'],
        [ 'code' => 'IRR', 'name' => 'Iranian rial', 'symbol' => '﷼'],
        [ 'code' => 'IRT', 'name' => 'Iranian toman', 'symbol' => 'تومان'],
        [ 'code' => 'ISK', 'name' => 'Icelandic króna', 'symbol' => 'kr.'],
        [ 'code' => 'JEP', 'name' => 'Jersey pound', 'symbol' => '£'],
        [ 'code' => 'JMD', 'name' => 'Jamaican dollar', 'symbol' => '$'],
        [ 'code' => 'JOD', 'name' => 'Jordanian dinar', 'symbol' => 'د.ا'],
        [ 'code' => 'JPY', 'name' => 'Japanese yen', 'symbol' => '¥'],
        [ 'code' => 'KES', 'name' => 'Kenyan shilling', 'symbol' => 'KSh'],
        [ 'code' => 'KGS', 'name' => 'Kyrgyzstani som', 'symbol' => 'сом'],
        [ 'code' => 'KHR', 'name' => 'Cambodian riel', 'symbol' => '៛'],
        [ 'code' => 'KMF', 'name' => 'Comorian franc', 'symbol' => 'Fr'],
        [ 'code' => 'KPW', 'name' => 'North Korean won', 'symbol' => '₩'],
        [ 'code' => 'KRW', 'name' => 'South Korean won', 'symbol' => '₩'],
        [ 'code' => 'KWD', 'name' => 'Kuwaiti dinar', 'symbol' => 'د.ك'],
        [ 'code' => 'KYD', 'name' => 'Cayman Islands dollar', 'symbol' => '$'],
        [ 'code' => 'KZT', 'name' => 'Kazakhstani tenge', 'symbol' => '₸'],
        [ 'code' => 'LAK', 'name' => 'Lao kip', 'symbol' => '₭'],
        [ 'code' => 'LBP', 'name' => 'Lebanese pound', 'symbol' => 'ل.ل'],
        [ 'code' => 'LKR', 'name' => 'Sri Lankan rupee', 'symbol' => 'රු'],
        [ 'code' => 'LRD', 'name' => 'Liberian dollar', 'symbol' => '$'],
        [ 'code' => 'LSL', 'name' => 'Lesotho loti', 'symbol' => 'L'],
        [ 'code' => 'LYD', 'name' => 'Libyan dinar', 'symbol' => 'ل.د'],
        [ 'code' => 'MAD', 'name' => 'Moroccan dirham', 'symbol' => 'د.م.'],
        [ 'code' => 'MDL', 'name' => 'Moldovan leu', 'symbol' => 'MDL'],
        [ 'code' => 'MGA', 'name' => 'Malagasy ariary', 'symbol' => 'Ar'],
        [ 'code' => 'MKD', 'name' => 'Macedonian denar', 'symbol' => 'ден'],
        [ 'code' => 'MMK', 'name' => 'Burmese kyat', 'symbol' => 'Ks'],
        [ 'code' => 'MNT', 'name' => 'Mongolian tögrög', 'symbol' => '₮'],
        [ 'code' => 'MOP', 'name' => 'Macanese pataca', 'symbol' => 'P'],
        [ 'code' => 'MRU', 'name' => 'Mauritanian ouguiya', 'symbol' => 'UM'],
        [ 'code' => 'MUR', 'name' => 'Mauritian rupee', 'symbol' => '₨'],
        [ 'code' => 'MVR', 'name' => 'Maldivian rufiyaa', 'symbol' => '.ރ'],
        [ 'code' => 'MWK', 'name' => 'Malawian kwacha', 'symbol' => 'MK'],
        [ 'code' => 'MXN', 'name' => 'Mexican peso', 'symbol' => '$'],
        [ 'code' => 'MYR', 'name' => 'Malaysian ringgit', 'symbol' => 'RM'],
        [ 'code' => 'MZN', 'name' => 'Mozambican metical', 'symbol' => 'MT'],
        [ 'code' => 'NAD', 'name' => 'Namibian dollar', 'symbol' => 'N$'],
        [ 'code' => 'NGN', 'name' => 'Nigerian naira', 'symbol' => '₦'],
        [ 'code' => 'NIO', 'name' => 'Nicaraguan córdoba', 'symbol' => 'C$'],
        [ 'code' => 'NOK', 'name' => 'Norwegian krone', 'symbol' => 'kr'],
        [ 'code' => 'NPR', 'name' => 'Nepalese rupee', 'symbol' => '₨'],
        [ 'code' => 'NZD', 'name' => 'New Zealand dollar', 'symbol' => '$'],
        [ 'code' => 'OMR', 'name' => 'Omani rial', 'symbol' => 'ر.ع.'],
        [ 'code' => 'PAB', 'name' => 'Panamanian balboa', 'symbol' => 'B/.'],
        [ 'code' => 'PEN', 'name' => 'Sol', 'symbol' => 'S/'],
        [ 'code' => 'PGK', 'name' => 'Papua New Guinean kina', 'symbol' => 'K'],
        [ 'code' => 'PHP', 'name' => 'Philippine peso', 'symbol' => '₱'],
        [ 'code' => 'PKR', 'name' => 'Pakistani rupee', 'symbol' => '₨'],
        [ 'code' => 'PLN', 'name' => 'Polish złoty', 'symbol' => 'zł'],
        [ 'code' => 'PRB', 'name' => 'Transnistrian ruble', 'symbol' => 'р.'],
        [ 'code' => 'PYG', 'name' => 'Paraguayan guaraní', 'symbol' => '₲'],
        [ 'code' => 'QAR', 'name' => 'Qatari riyal', 'symbol' => 'ر.ق'],
        [ 'code' => 'RON', 'name' => 'Romanian leu', 'symbol' => 'lei'],
        [ 'code' => 'RSD', 'name' => 'Serbian dinar', 'symbol' => 'рсд'],
        [ 'code' => 'RUB', 'name' => 'Russian ruble', 'symbol' => '₽'],
        [ 'code' => 'RWF', 'name' => 'Rwandan franc', 'symbol' => 'Fr'],
        [ 'code' => 'SAR', 'name' => 'Saudi riyal', 'symbol' => 'ر.س'],
        [ 'code' => 'SBD', 'name' => 'Solomon Islands dollar', 'symbol' => '$'],
        [ 'code' => 'SCR', 'name' => 'Seychellois rupee', 'symbol' => '₨'],
        [ 'code' => 'SDG', 'name' => 'Sudanese pound', 'symbol' => 'ج.س.'],
        [ 'code' => 'SEK', 'name' => 'Swedish krona', 'symbol' => 'kr'],
        [ 'code' => 'SGD', 'name' => 'Singapore dollar', 'symbol' => '$'],
        [ 'code' => 'SHP', 'name' => 'Saint Helena pound', 'symbol' => '£'],
        [ 'code' => 'SLL', 'name' => 'Sierra Leonean leone', 'symbol' => 'Le'],
        [ 'code' => 'SOS', 'name' => 'Somali shilling', 'symbol' => 'Sh'],
        [ 'code' => 'SRD', 'name' => 'Surinamese dollar', 'symbol' => '$'],
        [ 'code' => 'SSP', 'name' => 'South Sudanese pound', 'symbol' => '£'],
        [ 'code' => 'STN', 'name' => 'São Tomé and Príncipe dobra', 'symbol' => 'Db'],
        [ 'code' => 'SYP', 'name' => 'Syrian pound', 'symbol' => 'ل.س'],
        [ 'code' => 'SZL', 'name' => 'Swazi lilangeni', 'symbol' => 'E'],
        [ 'code' => 'THB', 'name' => 'Thai baht', 'symbol' => '฿'],
        [ 'code' => 'TJS', 'name' => 'Tajikistani somoni', 'symbol' => 'ЅМ'],
        [ 'code' => 'TMT', 'name' => 'Turkmenistan manat', 'symbol' => 'm'],
        [ 'code' => 'TND', 'name' => 'Tunisian dinar', 'symbol' => 'د.ت'],
        [ 'code' => 'TOP', 'name' => 'Tongan paʻanga', 'symbol' => 'T$'],
        [ 'code' => 'TRY', 'name' => 'Turkish lira', 'symbol' => '₺'],
        [ 'code' => 'TTD', 'name' => 'Trinidad and Tobago dollar', 'symbol' => '$'],
        [ 'code' => 'TWD', 'name' => 'New Taiwan dollar', 'symbol' => 'NT$'],
        [ 'code' => 'TZS', 'name' => 'Tanzanian shilling', 'symbol' => 'Sh'],
        [ 'code' => 'UAH', 'name' => 'Ukrainian hryvnia', 'symbol' => '₴'],
        [ 'code' => 'UGX', 'name' => 'Ugandan shilling', 'symbol' => 'UGX'],
        [ 'code' => 'USD', 'name' => 'United States (US) dollar', 'symbol' => '$'],
        [ 'code' => 'UYU', 'name' => 'Uruguayan peso', 'symbol' => '$'],
        [ 'code' => 'UZS', 'name' => 'Uzbekistani som', 'symbol' => 'UZS'],
        [ 'code' => 'VEF', 'name' => 'Venezuelan bolívar', 'symbol' => 'Bs F'],
        [ 'code' => 'VES', 'name' => 'Bolívar soberano', 'symbol' => 'Bs.S'],
        [ 'code' => 'VND', 'name' => 'Vietnamese đồng', 'symbol' => '₫'],
        [ 'code' => 'VUV', 'name' => 'Vanuatu vatu', 'symbol' => 'Vt'],
        [ 'code' => 'WST', 'name' => 'Samoan tālā', 'symbol' => 'T'],
        [ 'code' => 'XAF', 'name' => 'Central African CFA franc', 'symbol' => 'CFA'],
        [ 'code' => 'XCD', 'name' => 'East Caribbean dollar', 'symbol' => '$'],
        [ 'code' => 'XOF', 'name' => 'West African CFA franc', 'symbol' => 'CFA'],
        [ 'code' => 'XPF', 'name' => 'CFP franc', 'symbol' => 'Fr'],
        [ 'code' => 'YER', 'name' => 'Yemeni rial', 'symbol' => '﷼'],
        [ 'code' => 'ZAR', 'name' => 'South African rand', 'symbol' => 'R'],
        [ 'code' => 'ZMW', 'name' => 'Zambian kwacha', 'symbol' => 'ZK'],
    ];

    if($code != null)
    {
        $currency = collect($currency)->where('code', $code)->first();
    }
    return $currency;
}

function driver_common_document($driver) {
    $documents = Document::where('is_required',1)->where('status', 1)->pluck('id')->toArray();
    $is_common_document = $driver->driverDocument()->whereIn('document_id', $documents)->count();

    if(count($documents) == $is_common_document) {
        return true;
    } else {
        return false;
    }
}

function driver_required_document($driver) {
    $required_document = $driver->driverDocument()->pluck('document_id')->toArray();
    $documents = Document::where('is_required',1)->where('status', 1)->whereNotIn('id',$required_document)->get();

    return $documents;
}

function stringLong($str = '', $type = 'title', $length = 0)
{
    if (empty($str)) return $str;

    // Define default lengths by type
    if ($length == 0) {
        if ($type == 'desc') {
            $length = 150;
        } elseif ($type == 'title') {
            $length = 25;
        } else {
            $length = 50;
        }
    }

    if (mb_strlen($str) > $length) {
        return mb_substr($str, 0, $length) . '<br>' . mb_substr($str, $length);
    }

    return $str;
}

function maskSensitiveInfo($type, $info)
{
    if ($type === 'email' && empty($info) or $type === 'contact_number' && empty($info)) {
        return '-';
    }
    if(env('APP_DEMO')) {
        switch ($type) {
            case 'email':
                $parts = explode('@', $info);
                $username = $parts[0];
                $domain = $parts[1];
                $maskedUsername = substr($username, 0, 1) . str_repeat('*', strlen($username) - 1);
                return $maskedUsername . '@' . $domain;

            case 'contact_number':
                return substr($info, 0, 3) . str_repeat('*', strlen($info) - 4) . substr($info, -2);

            default:
                return $info;
        }
    } else {
        return $info;
    }
}

if (!function_exists('getDaysOfWeek')) {
    function getDaysOfWeek()
    {
        return [
            '1' => 'Monday',
            '2' => 'Tuesday',
            '3' => 'Wednesday',
            '4' => 'Thursday',
            '5' => 'Friday',
            '6' => 'Saturday',
            '7' => 'Sunday',
        ];
    }
}

function updateLanguageVersion()
{
    $language_version_data = LanguageVersionDetail::find(1);
    return $language_version_data->increment('version_no',1);
}

function mighty_language_direction($language = null)
{
    if (empty($language)) {
        $language = app()->getLocale();
    }
    $language = strtolower(substr($language, 0, 2));
    $rtlLanguages = [
        'ar', //  'العربية', Arabic
        'arc', //  'ܐܪܡܝܐ', Aramaic
        'bcc', //  'بلوچی مکرانی', Southern Balochi`
        'bqi', //  'بختياري', Bakthiari
        'ckb', //  'Soranî / کوردی', Sorani Kurdish
        'dv', //  'ދިވެހިބަސް', Dhivehi
        'fa', //  'فارسی', Persian
        'glk', //  'گیلکی', Gilaki
        'he', //  'עברית', Hebrew
        'lrc', //- 'لوری', Northern Luri
        'mzn', //  'مازِرونی', Mazanderani
        'pnb', //  'پنجابی', Western Punjabi
        'ps', //  'پښتو', Pashto
        'sd', //  'سنڌي', Sindhi
        'ug', //  'Uyghurche / ئۇيغۇرچە', Uyghur
        'ur', //  'اردو', Urdu
        'yi', //  'ייִדיש', Yiddish
    ];
    if (in_array($language, $rtlLanguages)) {
        return 'rtl';
    }

    return 'ltr';
}

function rideStatus() {
    return [
        'new_ride_requested' => __('message.new_ride_requested'),
        'pending' => __('message.pending'),
        'accepted' => __('message.accepted'),
        'arriving' => __('message.arriving'),
        'arrived' => __('message.arrived'),
        'in_progress' => __('message.in_progress'),
        'completed' => __('message.completed'),
        'cancelled' => __('message.cancelled'),
    ];
}

function pointInPolygon(array $point, array $polygon): bool
{
    $x = $point[1];
    $y = $point[0];
    $inside = false;

    $numPoints = count($polygon);
    for ($i = 0, $j = $numPoints - 1; $i < $numPoints; $j = $i++) {
        $xi = $polygon[$i][1];
        $yi = $polygon[$i][0];
        $xj = $polygon[$j][1];
        $yj = $polygon[$j][0];

        $intersect = (($yi > $y) !== ($yj > $y)) &&
            ($x < ($xj - $xi) * ($y - $yi) / (($yj - $yi) ?: 1e-10) + $xi);
        if ($intersect) {
            $inside = !$inside;
        }
    }

    return $inside;
}

function getSmsSettings($type = null, $sms_setting_key = null)
{
    if ($type !== null) {
        $sms_setting = SMSSetting::where('status', 1)->where('type', $type)->first();

        if ($sms_setting) {
            return $sms_setting_key === 'get' ? $sms_setting->values : $sms_setting;
        }

        return false;
    }

    $all_sms_settings = SMSSetting::where('status', 1)->get();

    if ($all_sms_settings->isEmpty()) {
        return false;
    }

    return $all_sms_settings->pluck('values', 'type')->toArray();
}

function SMSData($type, $sms_setting_key = null, $message = null, $data = [])
{
    $sms_setting = SMSSetting::where('type', $type)->first();

    if ($sms_setting) {
        $status = $data['status'] ?? null;

        if (!$status) {
            return false;
        }

        // Status ke basis par directly template fetch karo
        $sms_template = SMSTemplate::where('ride_status', $status)->first();

        if (!$sms_template) {
            return false;
        }

        // Template description leke placeholders replace karo
        $message = replacePlaceholders(strip_tags($sms_template->sms_description), $data);

        // Agar "get" pass hua ho to usi message ko return karo
        if ($sms_setting_key === 'get') {
            return $message;
        }
    }

    return false;
}

function replacePlaceholders($message, $data)
{
    foreach ($data as $key => $value) {
        $message = str_replace("[$key]", $value, $message);
    }
    return $message;
}

function otpCode($length = 7)
{
    $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return substr(str_shuffle($characters), 0, $length);
}

function generateRandomCode()
{
    $letters = substr(str_shuffle("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), 0, 2);

    $thirdDigit = substr(str_shuffle("123456789"), 0, 1);

    $validNumbers = [];
    for ($i = 101; $i <= 999; $i++) {
        $numberStr = (string)$i;
        if (strpos($numberStr, '0') === false) {
            $validNumbers[] = $numberStr;
        }
    }
    $lastThreeDigits = $validNumbers[array_rand($validNumbers)];

    $randomCode = $letters . $thirdDigit . $lastThreeDigits;

    return $randomCode;
}

function calculateCommission($service, $amount)
{
    $admin_commission = 0;
    $driver_commission = 0;
    if($service && !empty($service)){
        if ($service->commission_type == 'percentage') {
            $admin_commission = $amount * ($service->admin_commission / 100);
            $fleet_commission = $amount * ($service->fleet_commission / 100);

            $admin_commission += $fleet_commission;
        }else {
            $admin_commission = $service->admin_commission + $service->fleet_commission;
        }
        $driver_commission = $amount - $admin_commission;
    }
    
    return [
        'admin_commission' => $admin_commission,
        'driver_commission' => $driver_commission,
    ];
}