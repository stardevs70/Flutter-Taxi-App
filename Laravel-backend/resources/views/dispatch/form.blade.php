<x-master-layout :assets="$assets ?? []">
    <div>
        <?php $id = $id ?? null; ?>
        @if (isset($id))
            {{ html()->modelForm($data, 'PATCH', route('dispatch.update', $id))->attribute('data-toggle', 'validator')->open() }}
        @else
            {{ html()->form('POST', route('dispatch.store'))->attribute('data-toggle', 'validator')->open() }}
        @endif
        {{ html()->hidden('special_services', 'not_available')->id('special_services') }}
        <meta name="csrf-token" content="{{ csrf_token() }}">
        <div class="row">
            <div class="col-lg-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title">{{ $pageTitle }}</h4>
                        </div>
                        {{ html()->submit(__('message.save'))->class('btn border-radius-10 btn-primary float-right') }}
                    </div>

                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-lg-8">
                <div class="card card-body">
                    <div class="row">
                        {{ html()->hidden('start_latitude')->id('start_latitude') }}
                        {{ html()->hidden('start_longitude')->id('start_longitude') }}
                        {{ html()->hidden('end_latitude')->id('end_latitude') }}
                        {{ html()->hidden('end_longitude')->id('end_longitude') }}

                        {{ html()->hidden('fleet_fare')->id('estimate_fleet_fare') }}
                        {{ html()->hidden('base_fare')->id('modal_base_fare') }}
                        {{ html()->hidden('surcharge')->id('modal_surcharge') }}
                        {{ html()->hidden('discount')->id('modal_discount') }}
                        {{ html()->hidden('data_model_estimate_type')->id('data_model_estimate_type') }}
                        {{ html()->hidden('reason')->id('reason') }}
                        {{ html()->hidden('country_code', $data->country_code ?? '')->id('country_code') }}

                        <div class="form-group col-md-4">
                            <div class="row">
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.type'), 'type')->class('form-control-label') }}
                                    {{ html()->select('type', ['book_ride' => __('message.book_ride'), 'transport' => __('message.transport')], old('type'))->class('form-control select2js')->required() }}
                                </div>
                                <div class="form-group col-md-12" id="schedule_wrapper">
                                    {{ html()->label(__('message.pickup_date_time'), 'pickup_date_time')->class('form-control-label') }}
                                    {{ html()->text('schedule_datetime', now() ?? old('schedule_datetime'))->class('form-control futuredatetimepicker')->placeholder(__('message.pickup_date_time')) }}
                                </div>
                                <div class="form-group col-md-12" id="trip-type-sec">
                                    {{ html()->label(__('message.trip_type'), 'trip_type_lbl')->class('form-control-label') }}
                                    {{ html()->select(
                                            'trip_type',
                                            [
                                                'regular' => __('message.regular'),
                                                'airport_pickup' => __('message.airport_pickup'),
                                                'airport_drop' => __('message.airport_drop'),
                                                'zone_wise' => __('message.zone_wise'),
                                                'zone_to_airport' => __('message.zone_to_airport'),
                                                'airport_to_zone' => __('message.airport_to_zone'),
                                            ],
                                        )->class('form-control select2js trip_type')->required() }}
                                </div>

                                {{-- Pickup Zone Dropdown --}}
                                <div class="form-group col-md-12 d-none" id="pickup_zone_wrapper">
                                    <label for="pickup_zone_id">{{ __('message.pickup_address') }}</label>
                                    <select name="pickup_zone_id" id="pickup_zone_id" class="form-control select2js">
                                        <option value="">Select Zone</option>
                                        @foreach($zoneList as $key => $zone)
                                            <option value="{{ $zone['id'] }}" data-lat="{{ $zone['latitude'] }}" data-lng="{{ $zone['longitude'] }}">{{ $zone['name'] }}</option>
                                        @endforeach
                                    </select>
                                </div>

                                {{-- Pickup Airport Dropdown --}}
                                <div class="form-group col-md-12 d-none" id="pickup_airport_wrapper">
                                    <label for="pickup_airport_id">{{ __('message.pickup_address') }}</label>
                                    <select name="pickup_airport_id" id="pickup_airport_id" class="form-control">
                                        <option value="">Select Airport</option>
                                    </select>
                                </div>


                                <div class="form-group col-md-12" id="start_address">
                                    {{ html()->label(__('message.pickup_address') . ' <span class="text-danger">*</span>', 'pickup_address')->class('form-control-label') }}
                                    <div id="start_address_wrapper"></div>
                                </div>

                                {{-- Drop Zone Dropdown --}}
                                <div class="form-group col-md-12 d-none" id="drop_zone_wrapper">
                                    <label for="drop_zone_id">{{ __('message.drop_address') }}</label>
                                    <select name="drop_zone_id" id="drop_zone_id" class="form-control select2js">
                                        <option value="">Select Zone</option>
                                        @foreach($zoneList as $key => $zone)
                                            <option value="{{ $zone['id'] }}" data-lat="{{ $zone['latitude'] }}" data-lng="{{ $zone['longitude'] }}">{{ $zone['name'] }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                 {{-- Drop Airport Dropdown --}}
                                 <div class="form-group col-md-12 d-none" id="drop_airport_wrapper">
                                    <label for="drop_airport_id">{{ __('message.drop_address') }}</label>
                                    <select name="drop_airport_id" id="drop_airport_id" class="form-control">
                                        <option value="">Select Airport</option>
                                    </select>
                                </div>
                                <div class="form-group col-md-12" id="end_address">
                                    {{ html()->label(__('message.drop_address') . ' <span class="text-danger">*</span>', 'drop_address')->class('form-control-label') }}
                                    <div id="end_address_wrapper"></div>
                                </div>

                                <div class="form-group col-md-12 d-none" id="flight_number_wrapper">
                                    {{ html()->label(__('message.flight_number') .' <span class="text-danger">*</span>', 'flight_number')->class('form-control-label') }}
                                    {{ html()->text('flight_number')->class('form-control')->id('flight_number') }}
                                </div>

                                <div class="form-group col-md-12 d-none" id="pickup_point_wrapper">
                                    {{ html()->label(__('message.pickup_point') .' <span class="text-danger">*</span>', 'pickup_point')->class('form-control-label') }}
                                    {{ html()->text('pickup_point')->class('form-control')->id('pickup_point') }}
                                    <span class="text-muted">(like Arrival Gate A, Terminal 3, etc.)</span>
                                </div>

                                <div class="form-group col-md-12 d-none" id="preferred_pickup_time_wrapper">
                                    {{ html()->label(__('message.preferred_pickup_time') .' <span class="text-danger">*</span>', 'preferred_pickup_time')->class('form-control-label') }}
                                    {{  html()->text('preferred_pickup_time')->class('form-control futuredatetimepicker')->placeholder(__('message.preferred_pickup_time')) }}
                                </div>

                                <div class="form-group col-md-12 d-none" id="preferred_dropoff_time_wrapper">
                                    {{ html()->label(__('message.preferred_dropoff_time') .' <span class="text-danger">*</span>', 'preferred_dropoff_time')->class('form-control-label') }}
                                    {{  html()->text('preferred_dropoff_time')->class('form-control futuredatetimepicker')->placeholder(__('message.preferred_dropoff_time')) }}
                                </div>
                            </div>
                        </div>
                        <div class="form-group col-md-4">
                            <div class="row">
                                <div class="form-group col-md-12">
                                    <label class="d-block">{{ __('message.traveler_info') }} </label>
                                    <div class="custom-control custom-radio custom-control-inline col-5">
                                        {{ html()->radio('traveler_info', old('traveler_info') || true, 'individual')->class('custom-control-input traveler_info')->id('traveler_info-individual') }}
                                        {{ html()->label(__('message.individual'), 'traveler_info-individual')->class('custom-control-label') }}
                                    </div>
                                    <div class="custom-control custom-radio custom-control-inline col-5">
                                        {{ html()->radio('traveler_info', old('traveler_info'), 'corporate')->class('custom-control-input traveler_info')->id('traveler_info-corporate') }}
                                        {{ html()->label(__('message.corporate'), 'traveler_info-corporate')->class('custom-control-label') }}
                                    </div>
                                </div>
                                <div class="form-group col-md-12 corporate_div">
                                    {{ html()->label(__('message.corporate'), 'corporate_id')->class('form-control-label') }}
                                    {{ html()->select(
                                            'corporate_id',
                                            isset($data) ? [optional($data->corporate)->id => optional($data->corporate)->full_name] : [],
                                        )->class('form-control select2js')->attribute('data-ajax--url', route('ajax-list', ['type' => 'corporate']))->attribute('data-placeholder', __('message.select_field', ['name' => __('message.corporate')])) }}
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.service') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('service_id') }}
                                    <a class="float-right serviceList" href="javascript:void(0)"><i
                                            class="ri-refresh-line"></i></a>
                                    {{ html()->select(
                                            'service_id',
                                            isset($data) ? [optional($data->service)->id => optional($data->service)->display_name] : [],
                                            old('service_id'),
                                        )->class('select2js form-group service')->id('service_id')->required()->attribute('data-placeholder', __('message.select_name', ['select' => __('message.service')])) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.driver'))->class('form-control-label')->for('driver_id') }}
                                    <a class="float-right driverList" href="#"><i class="ri-refresh-line"></i></a>
                                    {{ html()->select(
                                            'driver_id',
                                            isset($data) ? [optional($data->driver)->id => optional($data->driver)->display_name] : [],
                                            old('driver_id'),
                                        )->class('select2js form-group driver')->attribute('data-placeholder', __('message.select_name', ['select' => __('message.driver')])) }}
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.customer'), 'rider_id')->class('form-control-label') }}
                                    {{ html()->select('rider_id', isset($data) ? [optional($data->rider)->id => optional($data->rider)->display_name] : [])->class('form-control select2js')->attribute('data-allow-clear', true)->attribute('data-ajax--url', route('ajax-list', ['type' => 'rider']))->attribute('data-placeholder', __('message.select_field', ['name' => __('message.customer')])) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.phone_number'), 'phone_number')->class('form-control-label') }}
                                    <a class="float-right customForm" href="#"><i class="ri-refresh-line"></i></a>
                                    {{ html()->text('contact_number')->class('form-control phone_number')->id('contact_number')->placeholder(__('message.phone_number')) }}
                                </div>
                                <div class="form-group col-md-6">
                                    {{ html()->label(__('message.first_name'), 'first_name')->class('form-control-label') }}
                                    {{ html()->text('first_name', old('first_name'))->class('form-control')->placeholder(__('message.first_name')) }}
                                </div>
                                <div class="form-group col-md-6">
                                    {{ html()->label(__('message.last_name'), 'last_name')->class('form-control-label') }}
                                    {{ html()->text('last_name', old('last_name'))->class('form-control')->placeholder(__('message.last_name')) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.email_address'), 'email_address')->class('form-control-label') }}
                                    {{ html()->email('email', old('email'))->class('form-control')->placeholder(__('message.email_address')) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.payment_method') . ' <span class="text-danger">*</span>')->for('payment_method')->class('form-control-label') }}
                                    <a class="float-right paymentmethodList" href="#"><i class="ri-refresh-line"></i></a>
                                    {{ html()->select('payment_method', [])->class('form-control select2js payment_method')->id('paymentmethod') }}
                                </div>
                            </div>
                            <div class="row transport_detail">
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.weight'), 'weight')->class('form-control-label') }}
                                    {{ html()->number('weight', old('weight'))->class('form-control')->attribute('min', 0)->placeholder(__('message.weight')) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.parcel_description'), 'parcel_description')->class('form-control-label') }}
                                    {{ html()->textarea('parcel_description', old('parcel_description'))->rows(2)->class('form-control textaraea')->placeholder(__('message.parcel_description')) }}
                                </div>
                            </div>
                        </div>
                        <div class="form-group col-md-4 transport_detail">
                            <div class="row">
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.pickup_form', ['name' => __('message.person_name')]), 'pickup_person_name')->class('form-control-label') }}
                                    {{ html()->text('pickup_person_name')->class('form-control')->placeholder(__('message.pickup_form', ['name' => __('message.person_name')])) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.pickup_form', ['name' => __('message.contact_number')]), 'pickup_contact_number')->class('form-control-label') }}
                                    {{ html()->text('pickup_contact_number')->class('form-control')->id('phone')->placeholder(__('message.pickup_form', ['name' => __('message.contact_number')])) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.pickup_form', ['name' => __('message.description')]), 'pickup_description')->class('form-control-label') }}
                                    {{ html()->textarea('pickup_description')->class('form-control')->placeholder(__('message.pickup_form', ['name' => __('message.description')])) }}
                                </div>

                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.delivery_form', ['name' => __('message.person_name')]), 'delivery_person_name')->class('form-control-label') }}
                                    {{ html()->text('delivery_person_name')->class('form-control')->placeholder(__('message.delivery_form', ['name' => __('message.person_name')])) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.delivery_form', ['name' => __('message.contact_number')]), 'delivery_contact_number')->class('form-control-label') }}
                                    {{ html()->text('delivery_contact_number')->class('form-control')->id('mobile_number')->placeholder(__('message.delivery_form', ['name' => __('message.contact_number')])) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.delivery_form', ['name' => __('message.description')]), 'delivery_description')->class('form-control-label') }}
                                    {{ html()->textarea('delivery_description')->class('form-control')->placeholder(__('message.delivery_form', ['name' => __('message.description')])) }}
                                </div>
                            </div>
                        </div>
                        <div class="form-group col-md-4 book_a_ride_detail">
                            <div class="row">
                                <div class="form-group col-md-6">
                                    {{ html()->label(__('message.passenger'), 'passenger')->class('form-control-label') }}
                                    {{ html()->number('passenger', old('passenger'))->class('form-control passenger')->attribute('disabled', true)->attribute('min', 1)->placeholder(__('message.passenger')) }}
                                </div>
                                <div class="form-group col-md-6">
                                    {{ html()->label(__('message.luggage'), 'luggage')->class('form-control-label') }}
                                    {{ html()->number('luggage', old('luggage'))->class('form-control')->attribute('min', 0)->placeholder(__('message.luggage')) }}
                                </div>
                                
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.external_trip_id'), 'external_trip_id')->class('form-control-label') }}
                                    {{ html()->text('external_trip_id')->class('form-control')->placeholder(__('message.external_trip_id')) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.driver_note'), 'driver_note')->class('form-control-label') }}
                                    {{ html()->textarea('driver_note', old('driver_note'))->rows(2)->class('form-control textaraea')->placeholder(__('message.driver_note')) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.internal_note'), 'internal_note')->class('form-control-label') }}
                                    {{ html()->textarea('internal_note', old('internal_note'))->rows(2)->class('form-control textaraea')->placeholder(__('message.internal_note')) }}
                                </div>
                                <div class="form-group col-md-12">
                                    {{ html()->label(__('message.customer_note'), 'customer_note')->class('form-control-label') }}
                                    {{ html()->textarea('customer_note', old('customer_note'))->rows(2)->class('form-control textaraea')->placeholder(__('message.customer_note')) }}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-4">
                <div class="row">
                    <div class="form-group col-md-12">
                        <div class="card card-body">
                            <div class="row" style="padding:10px">
                                <div style="height: 355px;width: 600px;" id="map"></div>
                            </div>
                        </div>
                    </div>
                    <div class="form-group col-md-12">
                        <div class="card">
                            <div class="card-header d-flex justify-content-between">
                                <div class="header-title">
                                    <h4 class="card-title">{{ __('message.trip_estimate') }}</h4>
                                </div>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-4">
                                        {{ html()->label(__('message.distance'), 'Distance')->class('form-control-label') }}
                                        <p id="distance"></p>
                                        {{ html()->hidden('distance')->class('distance') }}
                                    </div>
                                    <div class="col-md-4">
                                        {{ html()->label(__('message.duration'), 'duration')->class('form-control-label') }}
                                        <p id="duration"></p>
                                        {{ html()->hidden('duration')->class('duration') }}
                                    </div>
                                    <div class="col-md-4">
                                        {{ html()->label(__('message.fleet_fare'), 'fleet_fare')->class('form-control-label') }}
                                        {{ html()->hidden('total_amount')->class('total_amount') }}
                                        <a href="#" class="supplier_payout_btn loadRemoteModel d-none" id="supplier_payout_btn">
                                            <i class="fa fa-plus-circle"></i>
                                            {{-- <i class="bg-primary border-radius-20 p-1 fa fa-pen"></i> --}}
                                        </a>
                                        <p id="fleet_fare"></p>
                                        <p><del id="fleet_fare_change"></del></p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        {{ html()->form()->close() }}
    </div>

    @section('bottom_script')
        <script>
            $('#pickup_airport_id, #drop_airport_id').select2({
                placeholder: 'Select Airport',
                ajax: {
                    url: "{{ route('ajax-list') }}",
                    dataType: 'json',
                    delay: 250,
                    data: function (params) {
                        return {
                            q: params.term || '',
                            page: params.page || 1,
                            type: 'airport'
                        };
                    },
                    processResults: function (data, params) {
                        params.page = params.page || 1;

                        return {
                            results: data.results,
                            pagination: {
                                more: data.pagination.more
                            }
                        };
                    },
                    cache: true
                },
                minimumInputLength: 0
            });
            const tripTypeSelect = $('#trip_type');
            const pickup_zoneWrapper = $('#pickup_zone_wrapper');
            const drop_zoneWrapper = $('#drop_zone_wrapper');
            const pickup_airportWrapper = $('#pickup_airport_wrapper');
            const drop_airportWrapper = $('#drop_airport_wrapper');
            const startAddressWrapper = $('#start_address');
            const endAddressWrapper = $('#end_address');

            function toggleFields() {
                const tripType = tripTypeSelect.val();

                pickup_zoneWrapper.addClass('d-none');
                drop_zoneWrapper.addClass('d-none');
                pickup_airportWrapper.addClass('d-none');
                drop_airportWrapper.addClass('d-none');
                startAddressWrapper.addClass('d-none');
                endAddressWrapper.addClass('d-none');

                $('#flight_number_wrapper').addClass('d-none');
                $('#pickup_point_wrapper').addClass('d-none');
                $('#preferred_pickup_time_wrapper').addClass('d-none');
                $('#preferred_dropoff_time_wrapper').addClass('d-none');

                switch (tripType) {
                    case 'regular':
                        startAddressWrapper.removeClass('d-none');
                        endAddressWrapper.removeClass('d-none');
                        break;
                    case 'airport_pickup':
                        pickup_airportWrapper.removeClass('d-none');
                        endAddressWrapper.removeClass('d-none');
                        break;
                    case 'airport_drop':
                        startAddressWrapper.removeClass('d-none');
                        drop_airportWrapper.removeClass('d-none');
                        break;
                    case 'zone_wise':
                        pickup_zoneWrapper.removeClass('d-none');
                        pickup_zoneWrapper.removeClass('d-none');
                        drop_zoneWrapper.removeClass('d-none');
                        drop_zoneWrapper.removeClass('d-none');
                        break;
                    case 'zone_to_airport':
                        pickup_zoneWrapper.removeClass('d-none');
                        drop_airportWrapper.removeClass('d-none');
                        break;
                    case 'airport_to_zone':
                        pickup_airportWrapper.removeClass('d-none');
                        drop_zoneWrapper.removeClass('d-none');
                        break;
                }

                // Show flight/preferred time fields only when trip type involves an airport
                if (['airport_pickup', 'airport_drop', 'zone_to_airport', 'airport_to_zone'].includes(tripType)) {
                    $('#flight_number_wrapper').removeClass('d-none');
                    $('#pickup_point_wrapper').removeClass('d-none');
                    // $('#preferred_pickup_time_wrapper').removeClass('d-none');
                    // $('#preferred_dropoff_time_wrapper').removeClass('d-none');
                }
            }

            $(document).ready(function() {
                tripTypeSelect.on('change', toggleFields);
                toggleFields();
                initMap();
            });

            let map, polyline, startMarker, endMarker, infoWindow;
            let locations = {
                start: null,
                end: null
            };

            async function initMap() {
                const [{
                    Map
                }, {
                    Marker
                }, {
                    PlaceAutocompleteElement
                }] = await Promise.all([
                    google.maps.importLibrary("maps"),
                    google.maps.importLibrary("marker"),
                    google.maps.importLibrary("places")
                ]);

                map = new Map(document.getElementById("map"), {
                    zoom: 14,
                    center: {
                        lat: 22.310696,
                        lng: 70.802288
                    },
                    mapId: '4504f8b37365c3d0',
                    mapTypeControl: false
                });

                infoWindow = new google.maps.InfoWindow();
                polyline = new google.maps.Polyline({
                    strokeColor: '#4788ff',
                    strokeOpacity: 0.8,
                    strokeWeight: 6,
                    map: map
                });

                // Dropdowns logic
                $('#pickup_zone_id').on('select2:select', function(e) {
                    const selected = e.params.data.element;
                    if (selected && selected.dataset.lat && selected.dataset.lng) {
                        const lat = parseFloat(selected.dataset.lat);
                        const lng = parseFloat(selected.dataset.lng);
                        const loc = { lat, lng };

                        // Update start location
                        locations.start = loc;
                        $('#start_latitude').val(loc.lat);
                        $('#start_longitude').val(loc.lng);

                        // Update map marker
                        if (startMarker) startMarker.setMap(null);
                        startMarker = new google.maps.Marker({
                            map,
                            position: loc,
                            label: "1"
                        });

                        map.setCenter(loc);

                        // Call service list with the selected location
                        serviceList(loc.lat, loc.lng);

                        if (locations.end) {
                            drawRoute();
                            getFareEstimate();
                        }
                    }
                });

                $('#drop_zone_id').on('select2:select', function(e) {
                    const selected = e.params.data.element;
                    if (selected && selected.dataset.lat && selected.dataset.lng) {
                        const lat = parseFloat(selected.dataset.lat);
                        const lng = parseFloat(selected.dataset.lng);
                        const loc = { lat, lng };

                        // Update end location
                        locations.end = loc;
                        $('#end_latitude').val(loc.lat);
                        $('#end_longitude').val(loc.lng);

                        // Update map marker
                        if (endMarker) endMarker.setMap(null);
                        endMarker = new google.maps.Marker({
                            map,
                            position: loc,
                            label: "2"
                        });

                        map.setCenter(loc);

                        if (locations.start) {
                            drawRoute();
                            getFareEstimate();
                        }
                    }
                });

                $('#pickup_airport_id').on('select2:select', function(e) {
                    const selected = e.params.data;
                    if (selected && selected.lat && selected.lng) {
                        const lat = parseFloat(selected.lat);
                        const lng = parseFloat(selected.lng);
                        const loc = { lat, lng };

                        // Update start location
                        locations.start = loc;
                        $('#start_latitude').val(loc.lat);
                        $('#start_longitude').val(loc.lng);

                        // Update map marker
                        if (startMarker) startMarker.setMap(null);
                        startMarker = new google.maps.Marker({
                            map,
                            position: loc,
                            label: "1"
                        });

                        map.setCenter(loc);

                        // Call service list with the selected location
                        serviceList(loc.lat, loc.lng);

                        if (locations.end) {
                            drawRoute();
                            getFareEstimate();
                        }
                    }
                });

                $('#drop_airport_id').on('select2:select', function(e) {
                    const selected = e.params.data;
                    if (selected && selected.lat && selected.lng) {
                        const lat = parseFloat(selected.lat);
                        const lng = parseFloat(selected.lng);
                        const loc = { lat, lng };

                        // Update end location
                        locations.end = loc;
                        $('#end_latitude').val(loc.lat);
                        $('#end_longitude').val(loc.lng);

                        // Update map marker
                        if (endMarker) endMarker.setMap(null);
                        endMarker = new google.maps.Marker({
                            map,
                            position: loc,
                            label: "2"
                        });

                        map.setCenter(loc);

                        if (locations.start) {
                            drawRoute();
                            getFareEstimate();
                        }
                    }
                });

                const startWrapper = document.getElementById('start_address_wrapper');
                const endWrapper = document.getElementById('end_address_wrapper');

                if (startWrapper && !startWrapper.querySelector('gmpx-placeautocomplete')) {
                    const startAutocomplete = new PlaceAutocompleteElement();
                    startAutocomplete.id = 'start_address';
                    startAutocomplete.setAttribute('name', 'start_address');
                    startAutocomplete.locationBias = map.getCenter();
                    startWrapper.innerHTML = '';
                    startWrapper.appendChild(startAutocomplete);

                    startAutocomplete.addEventListener('gmp-select', async ({
                        placePrediction
                    }) => {
                        const place = placePrediction.toPlace();
                        await place.fetchFields({
                            fields: ['location']
                        });
                        const loc = place.location;

                        $('#start_latitude').val(loc.lat());
                        $('#start_longitude').val(loc.lng());
                        locations.start = {
                            lat: loc.lat(),
                            lng: loc.lng()
                        };

                        if (startMarker) startMarker.setMap(null);
                        startMarker = new google.maps.Marker({
                            map,
                            position: loc,
                            label: "1"
                        });

                        map.setCenter(loc);

                        serviceList(loc.lat(), loc.lng());
                        if (locations.end) {
                            drawRoute();
                            getFareEstimate();
                        }
                    });
                }

                if (endWrapper && !endWrapper.querySelector('gmpx-placeautocomplete')) {
                    const endAutocomplete = new PlaceAutocompleteElement();
                    endAutocomplete.id = 'end_address';
                    endAutocomplete.setAttribute('name', 'end_address');
                    endAutocomplete.locationBias = map.getCenter();
                    endWrapper.innerHTML = '';
                    endWrapper.appendChild(endAutocomplete);

                    endAutocomplete.addEventListener('gmp-select', async ({
                        placePrediction
                    }) => {
                        const place = placePrediction.toPlace();
                        await place.fetchFields({
                            fields: ['location', 'displayName', 'formattedAddress']
                        });
                        const loc = place.location;

                        $('#end_latitude').val(loc.lat());
                        $('#end_longitude').val(loc.lng());
                        locations.end = {
                            lat: loc.lat(),
                            lng: loc.lng()
                        };

                        if (endMarker) endMarker.setMap(null);
                        endMarker = new google.maps.Marker({
                            map,
                            position: loc,
                            label: "2"
                        });

                        map.setCenter(loc);
                        infoWindow.setContent(
                            `<strong>${place.displayName || ''}</strong><br>${place.formattedAddress || ''}`
                        );
                        infoWindow.setPosition(loc);
                        infoWindow.open(map, endMarker);

                        if (locations.start) {
                            drawRoute();
                            getFareEstimate();
                        }
                    });
                }
            }

            $('.serviceList').on('click', function() {
                resetServiceFields();
                const start_latitude = $('#start_latitude').val();
                const start_longitude = $('#start_longitude').val();

                if (start_latitude && start_longitude) {
                    serviceList(start_latitude, start_longitude);
                } else {
                    $('.service').empty();
                }

                if ($('#data_model_estimate_type').val() != 'update') {
                    $("#distance").text('');
                    $(".distance").val('');
                    $("#duration").text('');
                    $(".duration").val('');
                    $("#fleet_fare").text('');
                    $(".total_amount").val('');
                    $('.supplier_payout_btn').attr('href', '#');

                    adjustPriceDataClear();
                }
            });
            $('#service_id').on('change', function () {
                const serviceId = $(this).val();
                $('#driver_id').empty().trigger('change'); // if using Select2
                $('.driver').empty();
                if (serviceId) {
                    fetchPaymentMethods(serviceId);
                    passengerValidtion(serviceId);
                } else {
                    $('.payment_method').empty().trigger('change');
                }
            });

            $('.paymentmethodList').on('click', function () {
                const serviceId = $('#service_id').val();
                console.log("Selected service ID: ", serviceId);

                if (serviceId != null) {
                    fetchPaymentMethods(serviceId);
                    passengerValidtion(serviceId);
                } else {
                    $('.payment_method').empty();
                }
            });
            $('.driverList').on('click', function() {
                const service_id = $('#service_id').val();
                const driver_id = $('#driver_id').val();
                if (service_id != null) {
                    driverList(service_id);
                } else {
                    $('.driver').empty();
                }
            });
            $('.customForm').on('click', function(e) {
                e.preventDefault(); // Prevent default anchor behavior
                $('#contact_number').val('');
                $('#first_name').val('');
                $('#last_name').val('');
                $('#email').val('');
            });


            function drawRoute() {
                if (!locations.start || !locations.end) return;

                const path = [`${locations.start.lat},${locations.start.lng}`, `${locations.end.lat},${locations.end.lng}`];

                $.post("{{ url('api/snap-to-roads') }}", {
                    path
                }, function(data) {
                    const encoded = data.routes?.[0]?.polyline?.encodedPolyline;
                    if (encoded) {
                        try {
                            const decoded = google.maps.geometry.encoding.decodePath(encoded);
                            polyline.setPath(decoded);
                            const bounds = new google.maps.LatLngBounds();
                            decoded.forEach(point => bounds.extend(point));
                            map.fitBounds(bounds);
                        } catch (e) {
                            fallbackToStraightLine();
                        }
                    } else {
                        fallbackToStraightLine();
                    }
                }).fail(fallbackToStraightLine);

                function fallbackToStraightLine() {
                    const straight = [locations.start, locations.end];
                    polyline.setPath(straight.map(p => new google.maps.LatLng(p.lat, p.lng)));
                    const bounds = new google.maps.LatLngBounds();
                    straight.forEach(p => bounds.extend(p));
                    map.fitBounds(bounds);
                }
            }

            function adjustPriceDataClear() {
                $('#fleet_fare_change').text('');
                $('#estimate_fleet_fare').val('');
                $('#modal_base_fare').val('');
                $('#modal_surcharge').val('');
                $('#modal_discount').val('');
                $('#reason').val('');
                $('#fleet_fare_change').text('');
            }

            function getFareEstimate() {
                const serviceId = $('#service_id').val();
                resetServiceFields();
                if (!locations.start || !locations.end || !serviceId) return;

                const data = {
                    pick_lat: locations.start.lat,
                    pick_lng: locations.start.lng,
                    drop_lat: locations.end.lat,
                    drop_lng: locations.end.lng,
                    drop_latlng: locations.drop ? [{
                        lat: locations.drop.lat,
                        lng: locations.drop.lng
                    }] : [],
                    id: serviceId
                };

                $.post("{{ url('api/estimate-price-time') }}", data, function(response) {
                    if (response?.data?.length) {
                        const service = response.data[0];
                        $('#supplier_payout_btn').removeClass('d-none');

                        const distance = service.dropoff_distance_in_km;
                        $("#distance").text(distance.toFixed(2) + " " + service.distance_unit);
                        $(".distance").val(distance);

                        const mins = parseFloat(service.duration);
                        const formatted = `${Math.floor(mins / 60)} hr ${Math.round(mins % 60)} min`;
                        $("#duration").text(formatted);
                        $(".duration").val(formatted);

                        const fleet_fare = service.total_amount.toFixed(2);
                        $("#fleet_fare").text(fleet_fare);
                        $(".total_amount").val(fleet_fare);
                        adjustPriceDataClear();

                        const supplier_payout_route = "{{ route('supplier.payout') }}" + "?fleet_fare=" + fleet_fare;
                        $('.supplier_payout_btn').attr('href', supplier_payout_route);

                        // ➕ Check for zone/airport discounted fare if trip type is NOT regular
                        const tripType = $('.trip_type').val();
                        if (tripType && tripType !== 'regular') {
                            $.get('{{ route("fleet-fare-ajax") }}', {
                                trip_type: tripType,
                                pickup_zone_id: $('#pickup_zone_id').val(),
                                drop_zone_id: $('#drop_zone_id').val(),
                                pickup_airport_id: $('#pickup_airport_id').val(),
                                drop_airport_id: $('#drop_airport_id').val()
                            }, function(discountResponse) {
                                if (discountResponse.success && discountResponse.price) {
                                    // Override with discounted fare
                                    const discountedFare = parseFloat(discountResponse.price).toFixed(2);
                                    $("#fleet_fare").text(discountedFare);
                                    $(".total_amount").val(discountedFare)
                                    $('.supplier_payout_btn').attr('href', "{{ route('supplier.payout') }}" + "?fleet_fare=" + discountedFare);
                                } else {
                                    $("#fleet_fare_change").text(''); // No discount, keep only original
                                }
                            });
                        } else {
                            $("#fleet_fare_change").text(''); // Regular trip, no strike-through needed
                        }


                        if ($('#type').val() === 'transport') {
                            scheduleDatetime();
                        }
                    } else {
                        alert('No service available');
                    }
                });
            }

            function resetServiceFields() {
                $("#distance").text("");
                $(".distance").val('');
                $("#duration").text("");
                $(".duration").val('');
                $("#fleet_fare").text("0.00");
                $(".total_amount").val('');
                $("#distance").val('');
            }

            bookRide();
            $(document).on('change', '#type', function() {
                const lat = $('#start_latitude').val();
                const lng = $('#start_longitude').val();
                if (lat && lng) {
                    $('.service').empty();
                    serviceList(lat, lng);
                }

                toggleFields();
                bookRide();

                if ($(this).val() == 'transport') {
                    scheduleDatetime();
                }
            });

            function bookRide() {
                $('.book_a_ride_div').hide();
                $('.transport_detail').hide();
                $('.book_a_ride_detail').show();
                $('#trip-type-sec').show();

                if ($('#type').val() == 'transport') {
                    $('.book_a_ride_div').fadeIn(1000);
                    $('.transport_detail').fadeIn(1000);
                    $('.book_a_ride_detail').fadeOut(1000);
                    $('.trip-type').empty();
                    $('#trip-type-sec').hide();

                    $('#pickup_zone_wrapper').addClass('d-none');
                    $('#drop_zone_wrapper').addClass('d-none');
                    $('#pickup_airport_wrapper').addClass('d-none');
                    $('#drop_airport_wrapper').addClass('d-none');
                    $('#start_address').removeClass('d-none');
                    $('#end_address').removeClass('d-none');
                }
            }

            travelerInfo();
            $(document).on('change', 'input[name="traveler_info"]', travelerInfo);

            // Update the travelerInfo function to reset service and driver
            function travelerInfo() {
                $('.corporate_div').hide();
                
                // Reset service_id and driver_id when traveler_info changes
                $('#service_id').val(null).trigger('change');
                $('#driver_id').val(null).trigger('change');
                $('.service').empty();
                $('.driver').empty();
                $('.payment_method').empty().trigger('change');
                
                // Reset fare estimate fields
                resetServiceFields();
                adjustPriceDataClear();
                
                if ($('input[name="traveler_info"]:checked').val() == 'corporate') {
                    $('.corporate_div').fadeIn(1000);
                }
                
                // Refresh service list if location is available
                const start_latitude = $('#start_latitude').val();
                const start_longitude = $('#start_longitude').val();
                
                if (start_latitude && start_longitude) {
                    serviceList(start_latitude, start_longitude);
                }

                const serviceId = $('#service_id').val();
                if (serviceId) {
                    $('.driver').empty();
                    driverList(serviceId);
                }
            }

            // Also add a specific handler for corporate_id change to refresh driver list
            $(document).on('change', '#corporate_id', function() {
                $('#driver_id').val('').trigger('change');
                $('.driver').empty();
                const serviceId = $('#service_id').val();
                
                if (serviceId) {
                    driverList(serviceId);
                }
            });

            function scheduleDatetime() {
                let date_time = $('#schedule_datetime').val();
                let service_id = $('#service_id').val();
                let service_type = $('#type').val();
                let weight = $('#weight').val();
                let distance = $('.distance').val();

                if ($('#data_model_estimate_type').val() != 'update') {
                    $.ajax({
                        url: '{{ route('check.special.services') }}',
                        method: 'GET',
                        data: {
                            date_time,
                            service_id,
                            service_type,
                            weight,
                            distance
                        },
                        success: function(response) {
                            if (response.status) {
                                $('#special_services').val('available');
                                $("#fleet_fare").text(response.total_amount.toFixed(2));
                                $('.total_amount').val(response.total_amount.toFixed(2));
                                const supplier_payout_route = "{{ route('supplier.payout') }}" + "?fleet_fare=" +
                                    response.total_amount.toFixed(2);
                                $('.supplier_payout_btn').attr('href', supplier_payout_route);
                            } else {
                                $('#special_services').val('not_available');
                            }
                        }
                    });
                }
            }

            function serviceList(latitude, longitude) {
                var rideType = $('#type').val();
                var route = "{{ route('ajax-list',[ 'type' => 'service_for_ride']) }}&latitude=" + latitude + "&longitude=" + longitude + "&rideType=" + rideType;
                route = route.replaceAll('amp;', '');
        
                $.ajax({
                    url: route,
                    success: function (result) {
                        $('.service').select2({
                            width: '100%',
                            placeholder: "{{ __('message.select_name',[ 'select' => __('message.service') ]) }}",
                            data: result.results
                        });
        
                        $(".service").val(latitude).trigger('change');
                    }
                });
            }


            function driverList(serviceId) {
                const latitude = $('#start_latitude').val();
                const longitude = $('#start_longitude').val();
                const corporateId = $('#corporate_id').val();
                const travelerInfo = $('input[name="traveler_info"]:checked').val();

                if (!latitude || !longitude) {
                    console.warn("Missing lat/lng for driverList", {
                        latitude,
                        longitude
                    });
                    return;
                }

                let route = "{{ route('ajax-list', ['type' => 'driver_for_ride']) }}";
                route += `&service_id=${serviceId}&latitude=${latitude}&longitude=${longitude}`;

                // Append corporate ID if present
                if (travelerInfo === 'corporate' && corporateId) {
                    route += `&corporate_id=${corporateId}`;
                }

                $.ajax({
                    url: route.replaceAll('amp;', ''),
                    success: function(result) {
                        $('.driver').select2({
                            width: '100%',
                            placeholder: "{{ __('message.select_name', ['select' => __('message.driver')]) }}",
                            data: result.results
                        });

                        $(".driver").val(null).trigger('change');
                    }
                });
            }
            function fetchPaymentMethods(serviceId) {
                const route = "{{ route('ajax-list', ['type' => 'service_base_payment_method']) }}&service_id=" + serviceId;

                $.ajax({
                    url: route.replaceAll('amp;', ''),
                    success: function (result) {
                        $('.payment_method').select2({
                            width: '100%',
                            placeholder: "{{ __('message.select_name', ['select' => __('message.payment_method')]) }}",
                            data: result.results
                        });

                        $(".payment_method").val(null).trigger('change');
                    }
                });
            }

            function passengerValidtion(serviceId) {
                const route = "{{ route('ajax-list', ['type' => 'service_based_passenger']) }}&service_id=" + serviceId;

                $.ajax({
                    url: route.replaceAll('amp;', ''),
                    success: function (result) {
                        const maxPassengers = result.max_passenger || 0;

                        const $passengerInput = $('.passenger');

                        $passengerInput
                            .removeAttr('disabled') // 👈 enable field
                            .attr('max', maxPassengers)
                            .attr('placeholder', 'Max: ' + maxPassengers)
                            .off('input')
                            .on('input', function () {
                                const val = parseInt($(this).val());
                                if (val > maxPassengers) {
                                    $(this).val(maxPassengers);
                                }
                            });
                    }
                });
            }

            function toggleFieldsByType() {
                const type = $('#type').val();
                if (type === 'transport') {
                    $('#weight_wrapper').show();
                } else if (type === 'book_ride') {
                    $('#weight_wrapper').hide();
                    $('#schedule_wrapper').show();
                } else {
                    $('#weight_wrapper, #schedule_wrapper').hide();
                }
            }

            $(document).ready(function() {
                window.initMap = initMap;
                if (typeof google !== 'undefined' && google.maps) initMap();

                $('#type').on('change', function() {
                    toggleFieldsByType();
                });

                $('#service_id').on('change', function() {
                    const serviceId = $(this).val();
                    $('#special_services').val('');

                    if ($('#data_model_estimate_type').val() !== 'update') {
                        drawRoute();
                        getFareEstimate();
                    }

                    if (serviceId) {
                        driverList(serviceId);
                    }
                });

                function dispatchFirstRider(contact_number) {
                    const rider_id = $('#rider_id').val();
                    $.get("{{ route('ajax-list', ['type' => 'dispatch-first-rider']) }}", {
                        rider_id,
                        contact_number
                    }, function(data) {

                        var user_contact_number = data.results.contact_number;
                        if (user_contact_number) {
                            var contact_input = document.querySelector("#contact_number");
                            var iti = window.intlTelInputGlobals.getInstance(contact_input);
                            if (rider_id) iti.setNumber(data.results.contact_number);
                        } else {
                            // $('#contact_number').val('');
                        }

                        $('#first_name').val(data.results.first_name);
                        $('#last_name').val(data.results.last_name);
                        $('#email').val(data.results.email);
                    }).fail(() => false);
                }

                $(document).on('change', '#rider_id', function() {
                    dispatchFirstRider();
                });

                $('#schedule_datetime').on('change', scheduleDatetime);
                let scheduleTimer;
                $('#weight').on('keyup', function() {
                    clearTimeout(scheduleTimer);
                    scheduleTimer = setTimeout(scheduleDatetime, 500);
                    adjustPriceDataClear();
                });

               /* function changeContactNumber(input) {
                    var iti = window.intlTelInputGlobals.getInstance(input);
                    var dialCode = iti.getSelectedCountryData().dialCode;
                    var number = $(input).val();
                    var contact_number = '+' + dialCode + number;
                    if (!$('#rider_id').val()) dispatchFirstRider(contact_number);
                }
                
                $('#contact_number').on('keyup change countrychange', function() {
                    changeContactNumber(this);
                });*/

                function changeContactNumber(input) {
                    var iti = window.intlTelInputGlobals.getInstance(input);
                    var dialCode = iti.getSelectedCountryData().dialCode;
                    var number = $(input).val();
                    var contact_number = '+' + dialCode + number;

                    // Set dialCode in hidden field
                    $('#country_code').val(dialCode);

                    // Optional: send contact number to backend or function
                    if (!$('#rider_id').val()) dispatchFirstRider(contact_number);
                }
                $('#contact_number').on('keyup change countrychange', function() {
                    changeContactNumber(this);
                });



                toggleFieldsByType();
                scheduleDatetime();
            });
        </script>
    @endsection
</x-master-layout>
