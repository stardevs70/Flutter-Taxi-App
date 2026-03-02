<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Schema;

class User extends Authenticatable implements HasMedia
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles, InteractsWithMedia, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'first_name', 'last_name', 'email', 'password', 'username','country_code', 'contact_number', 'gender', 'email_verified_at', 'address', 'user_type', 'player_id', 'fcm_token', 'fleet_id', 'latitude', 'longitude', 'last_notification_seen', 'status', 'is_online', 'is_available', 'uid', 'login_type', 'display_name', 'timezone', 'service_id', 'is_verified_driver', 'service_type', 'driver_type', 'last_location_update_at', 'otp_verify_at','last_actived_at','app_version','corporate_id','referral_code','partner_referral_code'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_available'  => 'integer',
        'service_id'        => 'integer',
        'fleet_id'          => 'integer',
        'is_verified_driver'=> 'integer',
        'is_online'         => 'integer',
        'last_location_update_at'   => 'datetime',
        'otp_verify_at'     => 'datetime',
        'corporate_id'         => 'integer',
    ];

    public function userDetail() {
        return $this->hasOne(UserDetail::class, 'user_id', 'id');
    }

    public function userBankAccount() {
        return $this->hasOne(UserBankAccount::class, 'user_id', 'id');
    }

    public function fleet() {
        return $this->belongsTo(User::class, 'fleet_id', 'id');
    }

    public function userWallet() {
        return $this->hasOne(Wallet::class, 'user_id', 'id');
    }

    public function scopeAdmin($query) {
        return $query->where('user_type', 'admin')->first();
    }
    public function corporate()
    {
        return $this->belongsTo(Corporate::class);
    }


    public function scopeGetUser($query, $user_type=null)
    {
        $auth_user = auth()->user();

        if( $auth_user->hasAnyRole(['admin']) ) {
            $query->where('user_type', $user_type)->where('status','active');
            return $query;
        }
        if( $auth_user->hasRole('fleet') ) {
            return $query->where('user_type', 'driver')->where('fleet_id', $auth_user->id);
        }
        if( $auth_user->hasRole('corporate') ) {
            return $query->where('user_type', 'corporate')->where('corporate_id', $auth_user->id);
        }
    }

    public function riderRideRequestDetail() {
        return $this->hasMany(RideRequest::class, 'rider_id', 'id');
    }

    public function driverRideRequestDetail() {
        return $this->hasMany(RideRequest::class, 'driver_id', 'id');
    }

    public function driverDocument(){
        return $this->hasMany(DriverDocument::class, 'driver_id', 'id');
    }
    public function corporateDocument(){
        return $this->hasMany(CorporateDocument::class, 'corporate_id', 'id');
    }

    public function service() {
        return $this->belongsTo(Service::class, 'service_id', 'id');
    }

    public function riderRating(){
        return $this->hasMany(RideRequestRating::class, 'rider_id', 'id');
    }

    public function driverRating(){
        return $this->hasMany(RideRequestRating::class, 'driver_id', 'id');
    }

    public function routeNotificationForOneSignal()
    {
        return $this->player_id;
    }

    public function routeNotificationForFcm($notification)
    {
        return $this->fcm_token;
    }

    public function userWithdraw(){
        return $this->hasMany(WithdrawRequest::class, 'user_id', 'id');
    }

    public function bids()
    {
        return $this->hasMany(RideRequestBid::class, 'driver_id');
    }
    protected static function boot(){
        parent::boot();
        static::deleted(function ($row) {
            $row->userDetail()->delete();
            $row->userWithdraw()->delete();
            $row->userWallet()->delete();
            switch ($row->user_type) {
                case 'rider':
                    $row->riderRideRequestDetail()->delete();
                    break;
                case 'driver':
                    $row->userBankAccount()->delete();
                    // $row->driverDocument()->delete();
                    $row->driverRideRequestDetail()->delete();
                    break;
                default:
                    # code...
                    break;
            }
        });
    }

    public function getPayment(){
        
        return $this->hasManyThrough( 
            Payment::class,
            RideRequest::class,
            'driver_id',
            'ride_request_id',
            'id',
            'id'
        )->where('payment_status','paid');
    }

    
    protected static function booted()
    {
        static::updated(function ($model) {
            if (!config('settings.activity_log_enabled') || !Schema::hasTable('activity_log')) return;

            $user = auth()->user();
            $exclude = $model->excludeFromLog ?? ['updated_at', 'created_at','last_actived_at','latitude','longitude'];

            $changes = collect($model->getChanges())->except($exclude);
            if ($changes->isEmpty()) return;

            $formatKey = fn($key) => ucfirst(str_replace('_', ' ', preg_replace('/_id$/', ' ID', $key)));

            $formattedChanges = $changes->map(function ($new, $key) use ($model) {
                $old = $model->getOriginal($key);
                return [
                    'from' => $old === '' || $old === null ? '(empty)' : $old,
                    'to'   => $new === '' || $new === null ? '(empty)' : $new,
                    'ip'         => request()->ip(),
                ];
            });

            $logChanges = $formattedChanges->map(function ($change, $key) use ($formatKey) {
                return $formatKey($key) . ' changed from "' . $change['from'] . '" to "' . $change['to'] . '"';
            })->implode(', ');

            $properties = [
                'attributes' => $formattedChanges->mapWithKeys(fn($v, $k) => [$formatKey($k) => $v['to']]),
                'old' => $formattedChanges->mapWithKeys(fn($v, $k) => [$formatKey($k) => $v['from']]),
            ];

            $log = activity(class_basename($model))
                ->performedOn($model)
                ->withProperties($properties);

            if ($user) {
                $log->causedBy($user)
                    ->log("{$user->display_name} updated " . class_basename($model) . " #{$model->id} – $logChanges");
            } else {
                $log->log(class_basename($model) . " #{$model->id} updated – $logChanges (system or unauthenticated)");
            }
        });

        static::created(function ($model) {
            if (!config('settings.activity_log_enabled') || !Schema::hasTable('activity_log')) return;

            $user = auth()->user();
            $log = activity(class_basename($model))
                ->performedOn($model)
                ->withProperties([
                    'ip' => request()->ip(),
                ]);

            if ($user) {
                $log->causedBy($user)
                    ->log("{$user->display_name} added " . class_basename($model) . " #{$model->id}");
            } else {
                $log->log(class_basename($model) . " #{$model->id} added (system or unauthenticated)");
            }
        });

        static::deleted(function ($model) {
            if (!config('settings.activity_log_enabled') || !Schema::hasTable('activity_log')) return;

            $user = auth()->user();
            $log = activity(class_basename($model))
                ->performedOn($model)
                ->withProperties([
                    'ip' => request()->ip(),
                ]);

            if ($user) {
                $log->causedBy($user)
                    ->log("{$user->display_name} deleted " . class_basename($model) . " #{$model->id}");
            } else {
                $log->log(class_basename($model) . " #{$model->id} deleted (system or unauthenticated)");
            }
        });
    }
}
