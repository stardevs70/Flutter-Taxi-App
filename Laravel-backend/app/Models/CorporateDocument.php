<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Model;


class CorporateDocument extends BaseModel implements HasMedia
{
    use HasFactory, InteractsWithMedia, SoftDeletes;
    protected $fillable = [ 'name','corporate_id'];

    protected $casts = [
        'corporate_id' => 'integer',
    ];

    public function user(){
        return $this->belongsTo(User::class,'corporate_id', 'id');
    }  

}
