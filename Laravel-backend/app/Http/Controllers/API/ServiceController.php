<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Service;
use App\Models\Region;
use Grimzy\LaravelMysqlSpatial\Types\Point;
use App\Http\Resources\ServiceResource;
use App\Http\Resources\EstimateServiceResource;
use App\Http\Requests\ETARequest;
use App\Models\Coupon;
use Carbon\Carbon;

class ServiceController extends Controller
{
    public function getList(Request $request)
    {
        $service = Service::query();

        $service->when(request('region_id'), function ($q) {
            return $q->where('region_id', request('region_id'));
        });

        $service->when(request('name'), function ($q) {
            return $q->where('name', 'LIKE', '%' . request('name') . '%');
        });

        if( $request->has('latitude') && isset($request->latitude) && $request->has('longitude') && isset($request->longitude) )
        {
            $latitude = (float) $request->latitude;
            $longitude = (float) $request->longitude;

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

        $per_page = config('constant.PER_PAGE_LIMIT');
        if( $request->has('per_page') && !empty($request->per_page)){
            if(is_numeric($request->per_page))
            {
                $per_page = $request->per_page;
            }
            if($request->per_page == -1 ){
                $per_page = $service->count();
            }
        }

        $service = $service->orderBy('name','asc')->paginate($per_page);
        $items = ServiceResource::collection($service);

        $response = [
            'pagination' => json_pagination_response($items),
            'data' => $items,
        ];
        
        return json_custom_response($response);
    }
    
    public function estimatePriceTime(ETARequest $request)
    {
        $service = Service::where('status', 1);

        $service->when(request('service_type'), function ($q) {
            return $q->whereIn('service_type', [request('service_type'),'both']);
        });

        $service->when(request('region_id'), function ($q) {
            return $q->where('region_id', request('region_id'));
        });

        $service->when(request('id'), function ($q) {
            return $q->where('id', request('id'));
        });

        if( $request->has('pick_lat') && isset($request->pick_lat) && $request->has('pick_lng') && isset($request->pick_lng) )
        {
            $latitude = (float) $request->pick_lat;
            $longitude = (float) $request->pick_lng;

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

        $per_page = config('constant.PER_PAGE_LIMIT');
        if( $request->has('per_page') && !empty($request->per_page)){
            if(is_numeric($request->per_page))
            {
                $per_page = $request->per_page;
            }
            if($request->per_page == -1 ){
                $per_page = $service->count();
            }
        }

        $service = $service->orderBy('name','asc')->paginate($per_page);

        $place_details = mighty_get_distance_matrix(request('pick_lat'), request('pick_lng'), request('drop_lat'), request('drop_lng'));
        $dropoff_distance_in_meters = distance_value_from_distance_matrix($place_details);
        $dropoff_time_in_seconds = duration_value_from_distance_matrix($place_details);

        $distance_in_unit = 0;
        if ($dropoff_distance_in_meters) {
            // Region->distance_unit == km ( convert meter to km )
            $distance_in_unit = $dropoff_distance_in_meters / 1000;
        }

        $coupon_code = $request->coupon_code;
        if($coupon_code){
            $coupon = Coupon::where('code', $coupon_code)->first();
            $today = Carbon::today();
            $start_date = Carbon::parse($coupon->start_date);
            $end_date = Carbon::parse($coupon->end_date);
            if ($today->gt($end_date)) {
                $status = 400;
            } elseif ($today->lt($start_date) || $today->gt($end_date)) {
                $status = 405;
            }else{
                $status = 200;
            }
    
            if ($status !== 200) {
                $response = couponVerifyResponse($status);
                $response['status'] = $status;
                return $response;
            }
            $request['coupon'] = $coupon;
        }
     
        $request['distance_in_unit'] = $distance_in_unit;
        $request['dropoff_distance_in_meters'] = $dropoff_distance_in_meters ;
        $request['dropoff_time_in_seconds'] = $dropoff_time_in_seconds ;

        EstimateServiceResource::$dropoffTimeInSeconds = $dropoff_time_in_seconds;
        EstimateServiceResource::$dropoff_distance_in_meters = $dropoff_distance_in_meters;

        $items = EstimateServiceResource::collection($service);

        $response = [
            'pagination' => json_pagination_response($items),
            'data' => $items,
            'message' => $items->total() <= 0 ? __('message.service_not_available') : null
        ];
        
        return json_custom_response($response);
    }
}