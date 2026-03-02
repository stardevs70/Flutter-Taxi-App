<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\RideRequest;
use App\Http\Resources\RideRequestResource;
use Illuminate\Support\Facades\Http;

class OrderController extends Controller
{
    public function MyOrderList(Request $request)
    {
        $riderequest = RideRequest::where('rider_id',auth()->id())->getOrder();

        $riderequest->when(request('service_id'), function ($q) {
            return $q->where('service_id', request('service_id'));
        });

        $riderequest->when(request('driver_id'), function ($query) {
            return $query->whereHas('driver',function ($q) {
                $q->where('driver_id',request('driver_id'));
            });
        });

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

        $riderequest = $riderequest->orderBy('id','desc')->paginate($per_page);
        $items = RideRequestResource::collection($riderequest);

        $response = [
            'pagination' => json_pagination_response($items),
            'data' => $items,
        ];
        
        return json_custom_response($response);
    }

    public function OrderTrackingDetail(Request $request)
    {
        $riderequest = RideRequest::where('id',request('id'))->getOrder();

        $riderequest->when(request('service_id'), function ($q) {
            return $q->where('service_id', request('service_id'));
        });

        $riderequest->when(request('driver_id'), function ($query) {
            return $query->whereHas('driver',function ($q) {
                $q->where('driver_id',request('driver_id'));
            });
        });

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

        $riderequest = $riderequest->orderBy('id','desc')->paginate($per_page);

        $apiKey = env('GOOGLE_MAP_KEY');
        $latitude = request('latitude');
        $longitude = request('longitude');
        $url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey";

        $response = Http::get($url);
        $locationResults = $response->json()['results'];

        $city = null;

        foreach ($locationResults as $result) {
            foreach ($result['address_components'] as $component) {
                if (in_array('locality', $component['types'])) {
                    $city = $component['long_name'];
                    break 2; 
                }
            }
        }
        $items = RideRequestResource::collection($riderequest);

        $response = [
            'pagination' => json_pagination_response($items),
            'data' => $items,
            // 'location' => $city,
        ];
        
        return json_custom_response($response);
    }

    public function DriverOrderList(Request $request)
    {
        $riderequest = RideRequest::where('driver_id',auth()->id())->getOrder();

        $riderequest->when(request('service_id'), function ($q) {
            return $q->where('service_id', request('service_id'));
        });

        $riderequest->when(request('status'), function ($q) {
            return $q->where('status', request('status'));
        });

        $riderequest->when(request('driver_id'), function ($query) {
            return $query->whereHas('driver',function ($q) {
                $q->where('driver_id',request('driver_id'));
            });
        });

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

        $riderequest = $riderequest->orderBy('id','desc')->paginate($per_page);
        $items = RideRequestResource::collection($riderequest);

        $response = [
            'pagination' => json_pagination_response($items),
            'data' => $items,
        ];
        
        return json_custom_response($response);
    }
}