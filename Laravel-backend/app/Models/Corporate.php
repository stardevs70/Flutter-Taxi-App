<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Spatie\Permission\Traits\HasRoles;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Illuminate\Database\Eloquent\Model;

class Corporate extends BaseModel implements HasMedia
{
    use HasFactory , HasRoles, InteractsWithMedia; 
    protected $fillable = ['first_name', 'last_name', 'email', 'password', 'username','contact_number','company_name','company_type_id','companyid','user_id','company_address','invoice_email','status','url','commission_type','commission','VAT_number'];

    public function CompanyType(){
        return $this->belongsTo(CompanyType::class,'company_type_id','id');
    }
    
    public function user()
    {
        return $this->belongsTo(User::class,'user_id','id');
    }

    public function getFullNameAttribute()
    {
        return ucfirst($this->first_name). ' ' . ucfirst($this->last_name);
    }

    public function scopeMyCorporate($query){
        $user = auth()->user();
        if($user->user_type == 'admin') {
            return $query;
        }
        if($user->user_type == 'corporate') {  
            return $query->where('user_id', $user->id);
        }
        return $query;
    }
    protected static function boot()
    {
        parent::boot();
        static::deleting(function ($corporate) {
            // logger('User: '.optional($corporate->user)->id);
            if ($corporate->user) {
                $corporate->user->userBankAccount()->delete();
                $corporate->user->delete();
            }
        });
    }
}
