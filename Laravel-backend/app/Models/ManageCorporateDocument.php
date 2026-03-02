<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;
use Illuminate\Database\Eloquent\SoftDeletes;

class ManageCorporateDocument extends BaseModel implements HasMedia
{
    use HasFactory, InteractsWithMedia, SoftDeletes;

    protected $fillable = [ 'name', 'corporate_id','document_id', 'is_verified', 'expire_date' ];

    protected $casts = [
        'corporate_id' => 'integer',
        'is_verified' => 'integer'
    ];

    public function corporate(){
        return $this->belongsTo(Corporate::class,'corporate_id', 'id');
    }
    
    public function corporatedocument(){
        return $this->belongsTo(CorporateDocument::class,'document_id', 'id');
    }

}
