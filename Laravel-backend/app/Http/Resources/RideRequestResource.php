<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class RideRequestResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $pdfUrl = null;
        if($this->status == 'completed' ){
            $pdfUrl = route('ride-invoice', ['id' => $this->id]);
        }
        $getBidAmount = $this->approvedBids()->first();

        return [
            'id'                => $this->id,
            'type'              => $this->type,
            'rider_id'          => $this->rider_id,
            'service_id'        => $this->service_id,
            'datetime'          => $this->datetime,
            'is_schedule'       => $this->is_schedule,
            'schedule_datetime'       => $this->schedule_datetime,
            'ride_attempt'      => $this->ride_attempt,
            'otp'               => $this->otp,
            'total_amount' => $this->total_amount,
            'subtotal'          => (!empty($getBidAmount) && $this->ride_has_bid == 1) ? $getBidAmount->bid_amount : $this->subtotal,
            'extra_charges_amount'  => $this->extra_charges_amount,
            'driver_id'         => $this->driver_id,
            'driver_name'       => optional($this->driver)->display_name,
            'rider_name'        => optional($this->rider)->display_name,
            'driver_email'       => optional($this->driver)->email,
            'rider_email'        => optional($this->rider)->email,
            'driver_contact_number' => optional($this->driver)->contact_number,
            'rider_contact_number'  => optional($this->rider)->contact_number,
            'driver_profile_image' => getSingleMedia(optional($this->driver), 'profile_image',null),
            'rider_profile_image' => getSingleMedia(optional($this->rider), 'profile_image',null),
            'start_latitude'    => $this->start_latitude,
            'start_longitude'   => $this->start_longitude,
            'start_address'     => $this->start_address,
            'end_latitude'      => $this->end_latitude,
            'end_longitude'     => $this->end_longitude,
            'end_address'       => $this->end_address,
            'distance_unit'     => $this->distance_unit,
            'start_time'        => $this->rideRequestStartTime() ?? null,
            'end_time'          => $this->rideRequestCompletedTime() ?? null,
            'riderequest_in_driver_id' => $this->riderequest_in_driver_id,
            'distance'          => $this->distance,
            'base_distance'     => $this->base_distance,
            'dropoff_distance_in_km'    => $this->base_distance,
            'duration'          => $this->duration,
            'seat_count'        => $this->seat_count,
            'reason'            => $this->reason,
            'status'            => $this->status,
            'tips'              => $this->tips,
            'base_fare'         => $this->base_fare,
            'minimum_fare'      => $this->minimum_fare,
            'per_distance'      => $this->per_distance,
            'per_distance_charge' => $this->per_distance_charge,
            'per_minute_drive'  => $this->per_minute_drive,
            'per_minute_drive_charge' => $this->per_minute_drive_charge,
            'per_minute_waiting'=> $this->per_minute_waiting ?? 0,
            'waiting_time'      => $this->waiting_time,
            'waiting_time_limit'    => $this->waiting_time_limit ?? 0,
            'per_minute_waiting_charge'  => $this->per_minute_waiting_charge ?? 0,
            'cancelation_charges'   => $this->cancelation_charges,
            'cancel_by'         => $this->cancel_by,
            'payment_id'        => optional($this->payment)->id,
            'payment_type'      => $this->payment_type,
            // Check ride request's own payment_status first (for pay-at-start), then fall back to payment relationship
            'payment_status'    => $this->payment_status ?? optional($this->payment)->payment_status ?? 'pending',
            'extra_charges'     => $this->extra_charges,
            'fixed_charge'     => $this->surge_amount ?? 0,
            'coupon_discount'   => $this->coupon_discount,
            'coupon_code'       => $this->coupon_code,
            'coupon_data'       => $this->coupon_data,
            'is_rider_rated'    => $this->is_rider_rated,
            'is_driver_rated'   => $this->is_driver_rated,
            'max_time_for_find_driver_for_ride_request' => $this->max_time_for_find_driver_for_ride_request,

            'traveler_info' => $this->traveler_info,
            'contact_number' => $this->contact_number,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'email' => $this->email,
            'passenger' => $this->passenger,
            'luggage' => $this->luggage,
            'driver_note' => $this->driver_note,
            'internal_note' => $this->internal_note,
            'surcharge' => $this->surcharge,
            'corporate_id' => $this->corporate_id,
            'corporate_name' => optional($this->corporate)->full_name,
            'weight' => $this->weight,
            'total_weight' => $this->total_weight,
            'parcel_description' => $this->parcel_description,
            'pickup_contact_number' => $this->pickup_contact_number,
            'pickup_person_name' => $this->pickup_person_name,
            'pickup_description' => $this->pickup_description,
            'delivery_contact_number' => $this->delivery_contact_number,
            'delivery_person_name' => $this->delivery_person_name,
            'delivery_description' => $this->delivery_description,
            'discount' => $this->discount,
            'trip_type' => $this->trip_type,
            'flight_number' => $this->flight_number,
            'pickup_point' => $this->pickup_point,
            'preferred_pickup_time' => $this->preferred_pickup_time,
            'preferred_dropoff_time' => $this->preferred_dropoff_time,
            'corporate_commission' => $this->corporate_commission,
            // 'zone_pickup' => optional($this->zoneprice->zonepickup)->zone_pickup ?? null,
            // 'zone_dropoff' => optional($this->zoneprice->zonedropoff)->zone_dropoff ?? null,
            // 'zone_price' => optional($this->zoneprice)->zone_price,
            // 'airport_pickup' => optional($this->zoneprice->airportpickup)->airport_pickup ,
            // 'airport_dropoff' => optional($this->zoneprice->airportdropoff)->airport_dropoff ,

            'created_at'        => $this->created_at,
            'updated_at'        => $this->updated_at,
            'region_id'         => optional($this->service)->region_id,
            'is_ride_for_other' => $this->is_ride_for_other,
            'other_rider_data'  => $this->other_rider_data ?? null,
            'invoice_url' => $pdfUrl,
            'invoice_name' => 'Ride_' . $this->id,
            'ride_history' => optional($this)->rideRequestHistory,

            // Extra booking options
            'trip_protection' => $this->trip_protection ?? 0,
            'trip_protection_price' => $this->trip_protection_price ?? 0,
            'meet_and_greet' => $this->meet_and_greet ?? 0,
            'meet_and_greet_price' => $this->meet_and_greet_price ?? 0,
            'meet_greet_name' => $this->meet_greet_name,
            'meet_greet_comments' => $this->meet_greet_comments,
            'traveling_with_pet' => $this->traveling_with_pet ?? 0,
            'traveling_with_pet_price' => $this->traveling_with_pet_price ?? 0,
            'child_seat' => $this->child_seat ?? 0,
            'child_seat_price' => $this->child_seat_price ?? 0,
            'booster_seat_count' => $this->booster_seat_count ?? 0,
            'rear_facing_infant_seat_count' => $this->rear_facing_infant_seat_count ?? 0,
            'forward_facing_toddler_seat_count' => $this->forward_facing_toddler_seat_count ?? 0,
            'extras_amount' => $this->extras_amount ?? 0,

            // Hourly booking
            'booking_type' => $this->booking_type ?? 'STANDARD',
            'hours_booked' => $this->hours_booked,
            'included_miles' => $this->included_miles,
        ];
    }
}