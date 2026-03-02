<x-master-layout :assets="$assets ?? []">
    <style>
        .tooltip-inner {
            max-width: 400px; /* default is 200px */
            white-space: normal;
            text-align: left;
        }
    </style>
    <div class="container-fluid">
        <div class="row">
            <div class="col-lg-8">
                <div class="card">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h5></h5>
                            <h4 class="card-title mb-0">{{ __('message.riderequest') }} ({{ __('message.'.$data->type) }})</h4>
                            @if(!empty($data->schedule_datetime))
                                <small>{{ __('message.schedule_datetime') }} : {{ $data->schedule_datetime }}</small>
                            @endif
                        </div>
                        <div class="d-flex align-items-center gap-2">
                            @if ($data->status == 'completed')
                                <a href="{{ route('ride-invoice', $data->id) }}" class="badge badge-light-primary p-1 rounded me-2">
                                    <i class="ri-download-2-line mt-2" style="font-size:20px"></i>
                                </a>                                
                            @endif
                            <h4 class="bg-primary rounded p-1 px-3 mb-0 ml-3">#{{ $data->id }}</h4>
                        </div>
                    </div>

                    <div class="card shadow-sm border-0 mb-4">
                        <div class="card-body">
                            <div class="row mb-4">
                                <div class="col-md-6">
                                    <div class="d-flex flex-column">
                                        <span class="text-muted medium mb-1">{{ __('message.pickup_address') }}</span>
                                        <span class="font-weight-bold">{{ $data->start_address }}</span>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="d-flex flex-column">
                                        <span class="text-muted medium mb-1">{{ __('message.drop_address') }}</span>
                                        <span class="font-weight-bold">{{ $data->end_address }}</span>
                                    </div>
                                </div>
                            </div>
                            <hr>

                            <div class="row">
                                <div class="col-md-3 col-6 mb-3 mb-md-0 border-end">
                                    <div class="d-flex flex-column">
                                        <h6 class="text-muted">{{ __('message.total_distance') }}</h6>
                                        <span class="fw-bold">{{ $data->base_distance }} {{ $data->distance_unit }}</span>
                                    </div>
                                </div>
                                <div class="col-md-3 col-6 mb-3 mb-md-0 border-end">
                                    <div class="d-flex flex-column">
                                        <h6 class="text-muted">{{ __('message.total_duration') }}</h6>
                                        <span class="fw-bold">{{ number_format($data->duration, 2) }} {{ __('message.min') }}</span>
                                    </div>
                                </div>
                                <div class="col-md-3 col-6 border-end">
                                    <div class="d-flex flex-column">
                                        <h6 class="text-muted">{{ __('message.admin_commission') }}</h6>
                                        <span class="fw-bold">{{ getPriceFormat(optional($data->payment)->admin_commission ?? 0) }}</span>
                                    </div>
                                </div>
                                <div class="col-md-3 col-6">
                                    <div class="d-flex flex-column">
                                        <h6 class="text-muted">{{ __('message.driver_earning') }}</h6>
                                        <span class="fw-bold">{{ getPriceFormat(optional($data->payment)->driver_commission ?? 0) }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div> 
                {{-- </div> --}}
                @if($data->type == 'transport')
                    <div class="row">
                        <!-- Pickup Section -->
                        <div class="col-md-6">
                            <div class="card shadow-sm border-0">
                                <div class="card-header">
                                    <h6 class="mb-0">{{ __('message.pickup_details') }}</h6>
                                </div>
                                <div class="card-body">
                                    <p><strong>{{ __('message.contact_number') }}:</strong> {{ $data->pickup_contact_number ?? '-' }}</p>
                                    <p><strong>{{ __('message.person_name') }}:</strong> {{ $data->pickup_person_name ?? '-' }}</p>
                                    <p><strong>{{ __('message.description') }}:</strong> {{ $data->pickup_description ?? '-' }}</p>
                                </div>
                            </div>
                        </div>

                        <!-- Delivery Section -->
                        <div class="col-md-6">
                            <div class="card shadow-sm border-0">
                                <div class="card-header">
                                    <h6 class="mb-0">{{ __('message.delivery_details') }}</h6>
                                </div>
                                <div class="card-body">
                                    <p><strong>{{ __('message.contact_number') }}:</strong> {{ $data->delivery_contact_number ?? '-' }}</p>
                                    <p><strong>{{ __('message.person_name') }}:</strong> {{ $data->delivery_person_name ?? '-' }}</p>
                                    <p><strong>{{ __('message.description') }}:</strong> {{ $data->delivery_description ?? '-' }}</p>
                                </div>
                            </div>
                        </div>

                        <!-- Parcel Section -->
                        <div class="col-md-6">
                            <div class="card shadow-sm border-0">
                                <div class="card-header">
                                    <h6 class="mb-0">{{ __('message.parcel_details') }}</h6>
                                </div>
                                <div class="card-body">
                                    <p><strong>{{ __('message.parcel_type') }}:</strong> {{ $data->parcel_description ?? '-' }}</p>
                                    <p><strong>{{ __('message.weight') }}:</strong> {{ $data->weight ?? '-' }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                @else
                    <div class="row">
                        <!-- Ride Detail -->
                        <div class="col-md-12">
                            <div class="card shadow-sm border-0">
                                <div class="card-header">
                                    <h6 class="mb-0"><strong>{{ __('message.ride_detail') }}</strong></h6>
                                </div>
                                <div class="card-body">
                                    <p><strong>{{ __('message.internal_note') }} :</strong> <br> {{ $data->internal_note ?? '-' }}</p>
                                    <p><strong>{{ __('message.driver_note') }} :</strong> <br> {{ $data->driver_note ?? '-' }}</p>
                                </div>
                            </div>
                        </div>
                        @if($data->trip_type == 'airport_pickup' || $data->trip_type == 'airport_drop' || $data->trip_type == 'zone_to_airport' || $data->trip_type == 'airport_to_zone')
                        <div class="col-md-12 mb-4">
                            <div class="card shadow-sm border-0">
                                <div class="card-header">
                                    <h6 class="mb-0"><strong>{{ __('message.flight_details') }}</strong></h6>
                                </div>
                                <div class="card-body">
                                    <div class="row g-3">
                                        <div class="col-md-6">
                                            <p><strong>{{ __('message.trip_type') }}:</strong> {{ $data->trip_type ? ucwords(str_replace('_', ' ', $data->trip_type)) : 'regular' }}</p>
                                            @if($data->trip_type == 'airport_pickup' || $data->trip_type == 'airport_drop' || $data->trip_type == 'zone_to_airport' || $data->trip_type == 'airport_to_zone')
                                            <p><strong>{{ __('message.flight_number') }}:</strong> {{ $data->flight_number ?? '-' }}</p>
                                            <p><strong>{{ __('message.pickup_point') }}:</strong> {{ $data->pickup_point ?? '-' }}</p>
                                            <p><strong>{{ __('message.preferred_pickup_time') }}:</strong> {{ $data->preferred_pickup_time ?? '-' }}</p>
                                            <p><strong>{{ __('message.preferred_dropoff_time') }}:</strong> {{ $data->preferred_dropoff_time ?? '-' }}</p>
                                            @endif
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        @endif

                    <div class="col-md-12 mb-4">
                        <div class="card shadow-sm border-0">
                            <div class="card-header">
                                <h6 class="mb-0"><strong>{{ __('message.passenger_luggage') }}</strong></h6>
                            </div>
                            <div class="card-body">
                                <div class="row g-3">
                                    <div class="col-md-4">
                                        <p class="mb-1 text-muted">{{ __('message.passenger') }}</p>
                                        <p class="fw-semibold">{{ $data->passenger ?? '-' }}</p>
                                    </div>
                                    <div class="col-md-4">
                                        <p class="mb-1 text-muted">{{ __('message.luggage') }}</p>
                                        <p class="fw-semibold">{{ $data->luggage ?? '-' }}</p>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-12">
                                        <p class="mb-1 text-muted">{{ __('message.reason') }}</p>
                                        <p class="fw-semibold view_reason">{{ $data->reason ?? '-' }}</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    {{-- Extra Booking Options --}}
                    @if($data->trip_protection || $data->meet_and_greet || $data->traveling_with_pet || $data->child_seat || $data->extras_amount > 0)
                    <div class="col-md-12 mb-4">
                        <div class="card shadow-sm border-0">
                            <div class="card-header">
                                <h6 class="mb-0"><strong>Extra Booking Options</strong></h6>
                            </div>
                            <div class="card-body">
                                <div class="row g-3">
                                    @if($data->trip_protection)
                                    <div class="col-md-4">
                                        <p class="mb-1 text-muted">Trip Protection</p>
                                        <p class="fw-semibold text-success">
                                            <i class="fa fa-check-circle"></i> Yes
                                            @if($data->trip_protection_price > 0)
                                                ({{ getPriceFormat($data->trip_protection_price) }})
                                            @endif
                                        </p>
                                    </div>
                                    @endif

                                    @if($data->meet_and_greet)
                                    <div class="col-md-4">
                                        <p class="mb-1 text-muted">Meet & Greet</p>
                                        <p class="fw-semibold text-success">
                                            <i class="fa fa-check-circle"></i> Yes
                                            @if($data->meet_and_greet_price > 0)
                                                ({{ getPriceFormat($data->meet_and_greet_price) }})
                                            @endif
                                        </p>
                                        @if($data->meet_greet_name)
                                            <p class="text-muted small">Name: {{ $data->meet_greet_name }}</p>
                                        @endif
                                        @if($data->meet_greet_comments)
                                            <p class="text-muted small">Comments: {{ $data->meet_greet_comments }}</p>
                                        @endif
                                    </div>
                                    @endif

                                    @if($data->traveling_with_pet)
                                    <div class="col-md-4">
                                        <p class="mb-1 text-muted">Traveling with Pet</p>
                                        <p class="fw-semibold text-success">
                                            <i class="fa fa-check-circle"></i> Yes
                                            @if($data->traveling_with_pet_price > 0)
                                                ({{ getPriceFormat($data->traveling_with_pet_price) }})
                                            @endif
                                        </p>
                                    </div>
                                    @endif

                                    @if($data->child_seat)
                                    <div class="col-md-4">
                                        <p class="mb-1 text-muted">Child Seat</p>
                                        <p class="fw-semibold text-success">
                                            <i class="fa fa-check-circle"></i> Yes
                                            @if($data->child_seat_price > 0)
                                                ({{ getPriceFormat($data->child_seat_price) }})
                                            @endif
                                        </p>
                                        @if($data->booster_seat_count > 0)
                                            <p class="text-muted small">Booster Seats: {{ $data->booster_seat_count }}</p>
                                        @endif
                                        @if($data->rear_facing_infant_seat_count > 0)
                                            <p class="text-muted small">Rear Facing (Infant): {{ $data->rear_facing_infant_seat_count }}</p>
                                        @endif
                                        @if($data->forward_facing_toddler_seat_count > 0)
                                            <p class="text-muted small">Forward Facing (Toddler): {{ $data->forward_facing_toddler_seat_count }}</p>
                                        @endif
                                    </div>
                                    @endif

                                    @if($data->extras_amount > 0)
                                    <div class="col-md-4">
                                        <p class="mb-1 text-muted">Total Extras Amount</p>
                                        <p class="fw-semibold text-primary">{{ getPriceFormat($data->extras_amount) }}</p>
                                    </div>
                                    @endif

                                    @if($data->booking_type && $data->booking_type != 'STANDARD')
                                    <div class="col-md-4">
                                        <p class="mb-1 text-muted">Booking Type</p>
                                        <p class="fw-semibold">{{ $data->booking_type }}</p>
                                        @if($data->hours_booked)
                                            <p class="text-muted small">Hours: {{ $data->hours_booked }}</p>
                                        @endif
                                        @if($data->included_miles)
                                            <p class="text-muted small">Included Miles: {{ $data->included_miles }}</p>
                                        @endif
                                    </div>
                                    @endif
                                </div>
                            </div>
                        </div>
                    </div>
                    @endif

                    </div>
                @endif

                <div class="card shadow-sm border-0">
                    <div class="card-header">
                        <h6 class="mb-0"><strong>{{ __('message.payment') }}</strong></h6>
                    </div>
                    <div class="card-body">
                        <div class="row g-3">

                            <div class="col-md-6">
                                <p class="mb-1"><strong>{{ __('message.payment_method') }}</strong></p>
                                <p class="fw-semibold">{{ ucFirst($data->payment_type) ?? '-' }}</p>
                            </div>

                            <div class="col-md-6">
                                <p class="mb-1"><strong>{{ __('message.payment_status') }}</strong></p>
                                <p class="fw-semibold badge badge-light-success">
                                    {{ optional($data->payment)->payment_status ?? __('message.pending') }}
                                </p>
                            </div>

                            <div class="col-md-6">
                                <p class="mb-1"><strong>{{ __('message.extra_charges') }}</strong></p>
                                <p class="fw-semibold">{{ getPriceFormat($data->extra_charges_amount ?? 0) }}</p>
                            </div>

                            @if($data->ride_has_bid == 1)
                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.bid_amount') }}</strong></p>
                                    <p class="fw-semibold">
                                        {{ getPriceFormat(($data->approvedBids->bid_amount ?? 0) + ($data->surge_amount ?? 0)) }}
                                    </p>
                                </div>

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.total_amount') }}</strong></p>
                                    <p class="fw-bold text-success">
                                        {{ getPriceFormat(($data->approvedBids->bid_amount ?? 0) + ($data->extra_charges_amount ?? 0)) }}
                                    </p>
                                </div>
                            @else
                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.base_fare') }}</strong></p>
                                    <p class="fw-semibold view_base_fare">{{ getPriceFormat($data->base_fare ?? 0) }}</p>
                                </div>

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.distance') }}</strong></p>
                                    <p class="fw-semibold">{{ $data->distance ?? 0 }} {{ $data->distance_unit }}</p>
                                </div>

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.per_distance') }}</strong></p>
                                    <p class="fw-semibold">{{ getPriceFormat($data->per_distance ?? 0) }}</p>
                                </div>

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.duration') }}</strong></p>
                                    <p class="fw-semibold">{{ number_format($data->duration ?? 0, 2) }} {{ __('message.min') }}</p>
                                </div>

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.per_minute_drive') }}</strong></p>
                                    <p class="fw-semibold">{{ getPriceFormat($data->per_minute_drive ?? 0) }}</p>
                                </div>

                                @if(($data->waiting_time ?? 0) > 0)
                                    <div class="col-md-6">
                                        <p class="mb-1"><strong>{{ __('message.wait_time') }}</strong></p>
                                        <p class="fw-semibold">{{ number_format($data->waiting_time, 2) }} {{ __('message.min') }}</p>
                                    </div>

                                    <div class="col-md-6">
                                        <p class="mb-1"><strong>{{ __('message.waiting_charge') }}</strong></p>
                                        <p class="fw-semibold">{{ getPriceFormat($data->per_minute_waiting_charge ?? 0) }}</p>
                                    </div>
                                @endif

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.tip') }}</strong></p>
                                    <p class="fw-semibold">{{ getPriceFormat($data->tips ?? 0) }}</p>
                                </div>

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.discount') }}</strong></p>
                                    <p class="fw-semibold text-danger view_discount">-{{ getPriceFormat($data->discount ?? 0) }}</p>
                                </div>

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.surcharge') }}</strong></p>
                                    <p class="fw-semibold text-danger view_surcharge">+{{ getPriceFormat($data->surcharge ?? 0) }}</p>
                                </div>

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.sub_total') }}</strong></p>
                                    <p class="fw-semibold">{{ getPriceFormat($data->subtotal ?? 0) }}</p>
                                </div>

                                @if(($data->coupon_discount ?? 0) > 0)
                                    <div class="col-md-6">
                                        <p class="mb-1"><strong>{{ __('message.coupon_code') }}</strong></p>
                                        <p class="fw-semibold">{{ $data->coupon_code }}</p>
                                    </div>

                                    <div class="col-md-6">
                                        <p class="mb-1"><strong>{{ __('message.coupon_discount') }}</strong></p>
                                        <p class="fw-semibold text-danger">-{{ getPriceFormat($data->coupon_discount) }}</p>
                                    </div>
                                @endif

                                @if(!empty($data->cancelation_charges))
                                    <div class="col-md-6">
                                        <p class="mb-1"><strong>{{ __('message.cancelation_charges') }}</strong></p>
                                        <p class="fw-semibold text-danger">{{ getPriceFormat($data->cancelation_charges) }}</p>
                                    </div>
                                @endif

                                <div class="col-md-6">
                                    <p class="mb-1"><strong>{{ __('message.total_amount') }}</strong></p>
                                    <p class="fw-bold text-success view_total_amount">{{ getPriceFormat($data->total_amount ?? 0) }}</p>
                                </div>
                            @endif
                        </div>
                    </div>
                </div>
                @php
                    $status_name = ['rider_cancelled','completed','cancelled','driver_cancelled'];
                @endphp
                <div class="card card-block border-radius-20 p-2 {{ in_array($data->status,$status_name)  ? 'd-none' : '' }}">
                    <div class="row">
                        @if(!in_array($data->status,$status_name))
                            <div class="col-6 pe-1">
                                <a href="{{ route('cancel.ride', $data->id) }}" class="loadRemoteModel btn btn-sm btn-danger w-100">
                                    {{ __('message.cancel_ride') }}
                                </a>
                            </div>
                        @endif
                        @if($data->status == 'pending')
                            <div class="col-6 ps-1">
                                <a href="{{ route('supplier.payout', ['id' => $data->id, 'fleet_fare' => $data->base_fare, 'surcharge' => $data->surcharge, 'discount' => $data->discount, 'reason' => $data->reason ]) }}" class="loadRemoteModel view_supplier_payout_btn btn btn-sm btn-primary w-100">
                                    {{ __('message.adjust_price') }}
                                </a>
                            </div>
                        @endif
                    </div>
                </div>

            </div>
            <div class="col-lg-4">
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.detail_form_title', [ 'form' => __('message.customer') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-3">
                                <img src="{{ getSingleMedia(optional($data->rider), 'profile_image',null) }}" alt="rider-profile" class="img-fluid avatar-60 rounded-small">
                            </div>
                            <div class="col-9">
                                @if( $data->is_ride_for_other == 0 )
                                {{-- <p class="mb-0">{{ optional($data->rider)->display_name }}</p> --}}
                                    @if ( $data->rider_id != null )
                                        <a href="{{ route('rider.show',$data->rider ?? '') }}" class="mb-0"> {{ optional($data->rider)->display_name ?? '' }}</a>
                                        <p class="mb-0">{{ optional($data->rider)->contact_number }}</p>
                                        <p class="mb-0">{{ optional($data->rider)->email }}</p>
                                    @else
                                        <p class="mb-0">{{ $data->first_name ?? '-' .' '.$data->last_name ?? '-' }}</p>
                                        <p class="mb-0">{{ $data->contact_number }}</p>
                                        <p class="mb-0">{{ $data->email }}</p>
                                    @endif
                                    <p class="mb-0">
                                        @php
                                            $rating = optional($data->rideRequestRiderRating())->rating ?? 0;
                                        @endphp

                                        {{ $rating > 0 ? $rating : '0' }}
                                        
                                        @if($rating > 0)
                                            @for($i = 1; $i <= 5; $i++)
                                                <i class="fa fa-star" style="color: {{ $i <= $rating ? 'gold' : 'grey' }}"></i>
                                            @endfor
                                        @endif
                                    </p>
                                    {{--  <p class="mb-0">{{ optional($data->rideRequestRiderRating())->rating }}
                                        @if( optional($data->rideRequestRiderRating())->rating > 0 )
                                            <i class="fa fa-star" style="color: yellow"></i>
                                        @endif
                                    </p>  --}}
                                @else
                                    <p class="mb-0"><b>{{ __('message.booked_by') }}:</b> {{ optional($data->rider)->display_name }}</p>
                                    @if(!empty($data->other_rider_data))
                                        @foreach($data->other_rider_data as $key)
                                            <p class="mb-0">{{ $key ?? '' }}</p>
                                        @endforeach
                                    @endif
                                @endif
                            </div>
                        </div>
                    </div>
                </div>

                @if( isset($data->driver) )
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.detail_form_title', [ 'form' => __('message.driver') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-3">
                                <img src="{{ getSingleMedia(optional($data->driver), 'profile_image',null) }}" alt="driver-profile" class="img-fluid avatar-60 rounded-small">
                            </div>
                            <div class="col-9">
                                {{-- <p class="mb-0">{{ optional($data->driver)->display_name }}</p> --}}
                                <a href="{{ route('driver.show',$data->driver ?? '') }}" class="mb-0"> {{ optional($data->driver)->display_name ?? '' }}</a>
                                <p class="mb-0">{{ optional($data->driver)->contact_number }}</p>
                                <p class="mb-0">{{ optional($data->driver)->email }}</p>
                                <p class="mb-0">
                                    @php
                                        $rating = optional($data->rideRequestDriverRating())->rating ?? 0;
                                    @endphp

                                    {{ $rating > 0 ? $rating : '0' }}
                                    
                                    @if($rating)
                                        @for($i = 1; $i <= 5; $i++)
                                            <i class="fa fa-star" style="color: {{ $i <= $rating ? 'gold' : 'grey' }}"></i>
                                        @endfor
                                    @endif
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
                @endif
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.detail_form_title', [ 'form' => __('message.service') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-3">
                                <img src="{{ getSingleMedia($data->service, 'service_image',null) }}" alt="service-detail" class="img-fluid avatar-60 rounded-small">
                            </div>
                            <div class="col-3">
                                <h6>{{ __('message.name') }}</h6>
                                {{-- <p class="mb-0">{{ optional($data->service)->name }}</p> --}}
                                <a href="{{ route('service.show',$data->service ?? '') }}" class="mb-0"> {{ optional($data->service)->name ?? '' }}</a>
                            </div>
                            <div class="col-3">
                                <h6>{{ __('message.region') }}</h6>
                                <p class="mb-0">{{ $data->service->region->name ?? '' }}</p>
                            </div>
                            <div class="col-3">
                                <h6>{{ __('message.capacity') }}</h6>
                                <p class="mb-0">{{ $data->service->capacity ?? '' }}</p>
                            </div>
                        </div>
                    </div>
                </div>
                @if( isset($data->corporate) )
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.detail_form_title', [ 'form' => __('message.corporate') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-3">
                                <img src="{{ getSingleMedia(optional($data->corporate), 'profile_image',null) }}" alt="driver-profile" class="img-fluid avatar-60 rounded-small">
                            </div>
                            <div class="col-9">
                                {{-- <p class="mb-0">{{ optional($data->corporate)->FullName }}</p> --}}
                                <a href="{{ route('corporate.show',$data->corporate ?? '') }}" class="mb-0"> {{ optional($data->corporate)->FullName ?? '' }}</a>
                                <p class="mb-0">{{ optional($data->corporate)->contact_number }}</p>
                                <p class="mb-0">{{ optional($data->corporate)->email }}</p>
                            </div>
                        </div>
                    </div>
                </div>
                @endif

                @if(count($data->rideRequestHistory) > 0)
                    <div class="card card-block border-radius-20">
                        <div class="card-header d-flex justify-content-between">
                            <div class="header-title">
                                <h4 class="card-title mb-0">{{ __('message.activity_timeline') }}</h4>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="mm-timeline0 m-0 d-flex align-items-center justify-content-between position-relative">
                                <ul class="list-inline p-0 m-0">
                                    @php
                                        $sequence = [
                                            'pending',
                                            'bid_placed',
                                            'bid_rejected',
                                            'bid_accepted',
                                            'arrived',
                                            'in_progress',
                                            'completed',
                                            'payment_status_message',
                                        ];

                                        $bidPlacedDrivers = [];
                                        $bidRejectedDrivers = [];
                                        $historyEntries = [];

                                        $colorMapping = [
                                            'pending' => 'border-info text-info',
                                            'new_ride_requested' => 'border-primary text-primary',
                                            'accepted' => 'border-success text-success',
                                            'arriving' => 'border-info text-info',
                                            'bid_placed' => 'border-success text-success',
                                            'bid_rejected' => 'border-danger text-danger',
                                            'bid_accepted' => 'border-success text-success',
                                            'arrived' => 'border-warning text-warning',
                                            'in_progress' => 'border-primary text-primary',
                                            'completed' => 'border-success text-success',
                                            'payment_status_message' => 'border-dark text-dark',
                                            'driver_declined' => 'border-danger text-danger',
                                        ];

                                        foreach ($data->rideRequestHistory as $history) {
                                            $historyData = is_string($history->history_data) ? json_decode($history->history_data, true) : $history->history_data; // Decode as associative array

                                            if ($history->history_type === 'driver_declined') {
                                                $historyEntries[] = [
                                                    'type' => 'driver_declined',
                                                    'message' => '<a href="'. route('driver.show', ['driver' => $history->rideRequest->riderequest_in_driver_id]) .'">'. $history->history_message .'</a>',
                                                    'datetime' => $history->datetime,
                                                ];
                                            } elseif (in_array($history->history_type, ['bid_placed', 'bid_rejected'])) {
                                                $driverName = $historyData['driver_name'] ?? '';
                                                $driverId = $historyData['driver_id'] ?? '';
                                                $driverLink = '<a href="'. route('driver.show', ['driver' => $driverId]) .'">'.  $driverName . ' ('.$driverId .')' . '</a>';

                                                if ($history->history_type === 'bid_placed') {
                                                    $bidPlacedDrivers[] = $driverLink;
                                                } else {
                                                    $bidRejectedDrivers[] = $driverLink;
                                                }
                                            } else {
                                                $historyEntries[] = [
                                                    'type' => $history->history_type,
                                                    'message' => $history->history_message,
                                                    'datetime' => $history->datetime,
                                                ];
                                            }
                                        }

                                        if ($bidPlacedDrivers) {
                                            $historyEntries[] = [
                                                'type' => 'bid_placed',
                                                'message' => 'Placed bids drivers: ' . implode(' , ', $bidPlacedDrivers),
                                                'datetime' => now(),
                                            ];
                                        }

                                        if ($bidRejectedDrivers) {
                                            $historyEntries[] = [
                                                'type' => 'bid_rejected',
                                                'message' => 'Rejected bids: ' . implode(' , ', $bidRejectedDrivers),
                                                'datetime' => now(),
                                            ];
                                        }

                                        usort($historyEntries, function ($a, $b) use ($sequence) {
                                            return array_search($a['type'], $sequence) - array_search($b['type'], $sequence);
                                        });
                                    @endphp

                                    @foreach($historyEntries as $entry)
                                        @php
                                            // Get the color class based on the type
                                            $colorClass = $colorMapping[$entry['type']] ?? 'border-primary text-primary';
                                            switch ($entry['type']) {
                                                case 'pending':
                                                    $iconClass = 'fas fa-plus-square';
                                                    break;
                                                case 'new_ride_requested':
                                                    $iconClass = 'fas fa-plus-square';
                                                    break;
                                                case 'accepted':
                                                    $iconClass = 'fas fa-check-square';
                                                    break;
                                                case 'arriving':
                                                    $iconClass = 'fas fa-plane-arrival';
                                                    break;
                                                case 'courier_assigned':
                                                    $iconClass = 'fas fa-file-signature';
                                                    break;
                                                case 'courier_arrived':
                                                    $iconClass = 'fas fa-file-arrow-down';
                                                    break;
                                                case 'courier_picked_up':
                                                    $iconClass = 'fas fa-truck-fast';
                                                    break;
                                                case 'courier_departed':
                                                    $iconClass = 'fas fa-plane-departure';
                                                    break;
                                                case 'payment_status_message':
                                                    $iconClass = 'fas fa-credit-card';
                                                    break;
                                                case 'courier_transfer':
                                                    $iconClass = 'fas fa-box';
                                                    break;
                                                case 'completed':
                                                    $iconClass = 'fas fa-check';
                                                    break;
                                                case 'return':
                                                    $iconClass = "fas fa-rotate";
                                                    break;
                                                case 'courier_auto_assign_cancelled':
                                                    $iconClass = "fas fa-ban";
                                                    break;
                                                case 'cancelled':
                                                    $iconClass = "fas fa-xmark";
                                                    break;
                                                case 'isrechedule':
                                                    $iconClass = "fas fa-calendar-day";
                                                    break;
                                                case 'shipped_order':
                                                    $iconClass = "fas fa-ship";
                                                    break;
                                                case 'bid_placed':
                                                    $iconClass = "fas fa-bell";
                                                    break;
                                                case 'bid_rejected':
                                                    $iconClass = "fas fa-right-from-bracket";
                                                    break;
                                                case 'bid_accepted':
                                                    $iconClass = "fas fa-handshake";
                                                    break;
                                                case 'arrived':
                                                    $iconClass = "fas fa-map-marker-alt";
                                                    break;
                                                case 'in_progress':
                                                    $iconClass = "fas fa-spinner";
                                                    break;
                                                case 'driver_declined':
                                                    $iconClass = "fas fa-user-xmark";
                                                    break;
                                                case 'active':
                                                    $iconClass = "fas fa-car-rear";
                                                    break;
                                                default:
                                                    $iconClass = 'fas fa-question-circle';
                                                    break;
                                            }
                                        @endphp

                                        <li>
                                            <div class="timeline-dots1 {{ $colorClass }}"><i class="{{ $iconClass }}"></i></div>
                                            <h6 class="float-left mb-1">{{ __('message.' . $entry['type']) }}</h6>
                                            <small class="float-right mt-1">{{ $entry['datetime'] }}</small>
                                            <div class="d-inline-block w-100">
                                                <p>{!! $entry['message'] !!}</p>
                                            </div>
                                        </li>
                                    @endforeach
                                </ul>
                            </div>
                        </div>
                    </div>
                @endif
            </div>
        </div>
    </div>
</x-master-layout>
