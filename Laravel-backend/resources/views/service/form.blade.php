<x-master-layout :assets="$assets ?? []">
    <div>
        <?php $id = $id ?? null;?>
        @if(isset($id))
            {!! html()->modelForm($data,'PATCH', route('service.update', $id))->attribute('enctype', 'multipart/form-data')->open() !!}
        @else
            {!! html()->form('POST', route('service.store'))->attribute('enctype', 'multipart/form-data')->open() !!}
        @endif
        <div class="row">
            <div class="col-lg-12 mt-3">
                <div class="card border-radius-20">
                    <div class="card-header d-flex justify-content-between"  style="border-top-left-radius: 20px; border-top-right-radius: 20px;">
                        <div class="header-title">
                            <h4 class="card-title">{{ $pageTitle }}</h4>
                        </div>
                        <a href="{{route('service.index')}}" class="float-right btn btn-sm border-radius-10 btn-primary me-2" role="button"><i class="fas fa-arrow-circle-left"></i> {{ __('message.back') }}</a>
                    </div>

                    <div class="card-body">
                        <div class="new-user-info">
                            <div class="row">
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.name').' <span class="text-danger">*</span>')->class('form-control-label') !!}
                                    {!! html()->text('name',old('name'))->class('form-control')->placeholder(__('message.name')) !!}
                                </div>

                                <div class="form-group col-md-4">
                                    @if ( $id == null )
                                        <label class="form-control-label" for="region_id">{{ __('message.region') }} <span class="text-danger" id="distance_unit">* </span></label>
                                    @else
                                        <label class="form-control-label" for="region_id">{{ __('message.region') }} <span class="text-danger" id="distance_unit">* (<small>{{ __('message.distance_in_'.optional($data->region)->distance_unit )  }}</small>)</span> </label>
                                    @endif
                                    {{-- {!! html()->label(__('message.region') . ' <span class="text-danger">*</span>')->for('region_id')->class('form-control-label') !!} --}}
                                    {!! html()->select('region_id', isset($id) ? [ optional($data->region)->id => optional($data->region)->name ] : [], old('region_id'))
                                        ->attribute('data-ajax--url', route('ajax-list', ['type' => 'region']))
                                        ->attribute('data-placeholder', __('message.select_field', ['name' => __('message.region')]))
                                        ->class('form-control select2js')
                                        ->attribute('data-distance-unit', isset($id) ? optional($data->region)->distance_unit : '')
                                        ->id('region_id') !!}
                                </div>

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.service_type').' <span class="text-danger">*</span>')->class('form-control-label') !!}
                                    {!! html()->select('service_type', ['transport' => __('message.transport'),'book_ride' => __('message.book_ride'), 'both' => __('message.both')], old('service_type'))->class('form-control select2js') !!}
                                </div>

                                <div class="form-group col-md-4" style="display: none;" id="transport-min-weight">
                                    {!! html()->label(__('message.minimum_weight'))->for('minimum_weight')->class('form-control-label') !!}
                                    {!! html()->number('minimum_weight', old('minimum_weight'))->class('form-control')->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.minimum_weight')) !!}
                                </div>
                                <div class="form-group col-md-4" style="display: none;" id="transport-fields">
                                    {!! html()->label(__('message.per_weight_charge'))->for('per_weight_charge')->class('form-control-label') !!}
                                    {!! html()->number('per_weight_charge', old('per_weight_charge'))->class('form-control')->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.per_weight_charge')) !!}
                                </div>
                                
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.capacity') . ' <span class="text-danger">*</span>')->for('capacity')->class('form-control-label') !!}
                                    {!! html()->number('capacity', old('capacity'))->id('capacity')->class('form-control') !!}
                                </div>
                                
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.base_fare') . ' <span class="text-danger">*</span>')->for('base_fare')->class('form-control-label') !!}
                                    {!! html()->number('base_fare', old('base_fare'))->id('base_fare')->class('form-control')->placeholder(__('message.base_fare')) !!}
                                </div>

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.minimum_fare') . ' <span class="text-danger">*</span>')->for('minimum_fare')->class('form-control-label') !!}
                                    {!! html()->number('minimum_fare', old('minimum_fare'))->class('form-control')->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.minimum_fare')) !!}
                                </div>
                                
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.per_distance') . ' <span class="text-danger">*</span>')->for('per_distance')->class('form-control-label') !!}
                                    {!! html()->number('per_distance', old('per_distance'))->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.per_distance'))->class('form-control') !!}
                                </div>

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.per_minute_drive') . ' <span class="text-danger">*</span>')->for('per_minute_drive')->class('form-control-label') !!}
                                    {!! html()->number('per_minute_drive', old('per_minute_drive'))->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.per_minute_drive'))->class('form-control') !!}
                                </div>
                                
                                 {{-- <div class="form-group col-md-4">
                                    {!! html()->label(__('message.waiting_time_limit') . '(' . __('message.in_minutes') . ')<span class="text-danger">*</span>')->for('waiting_time_limit')->class('form-control-label') !!}
                                    {!! html()->number('waiting_time_limit', old('waiting_time_limit'))->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.waiting_time_limit'))->class('form-control') !!}
                                </div>
                                
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.per_minute_wait') . ' <span class="text-danger">*</span>')->for('per_minute_wait')->class('form-control-label') !!}
                                    {!! html()->number('per_minute_wait', old('per_minute_wait'))->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.per_minute_wait'))->class('form-control') !!}
                                </div>  --}}

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.cancellation_fee') . ' <span class="text-danger">*</span>')->for('cancellation_fee')->class('form-control-label') !!}
                                    {!! html()->number('cancellation_fee', old('cancellation_fee'))->id('cancellation_fee')->class('form-control')->placeholder(__('message.cancellation_fee')) !!}
                                </div>

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.minimum_distance') . ' <span class="text-danger">*</span>')->for('minimum_distance')->class('form-control-label') !!}
                                    {!! html()->number('minimum_distance', old('minimum_distance'))->id('minimum_distance')->class('form-control')->placeholder(__('message.minimum_distance')) !!}
                                </div>
                                {{--  <div class="form-group col-md-4">
                                    {!! html()->label(__('message.per_distance_charge') . ' <span class="text-danger">*</span>')->for('per_distance_charge')->class('form-control-label') !!}
                                    {!! html()->number('per_distance_charge', old('per_distance_charge'))->id('per_distance_charge')->class('form-control')->placeholder(__('message.per_distance_charge')) !!}
                                </div>  --}}
                                
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.payment_method') . ' <span class="text-danger">*</span>')->for('payment_method')->class('form-control-label') !!}
                                    {!! html()->multiselect('payment_method[]', [
                                            'online' => __('message.online'),
                                            'cash' => __('message.cash'),
                                            'wallet' => __('message.wallet'),
                                        ], old('payment_method',$data->payment_method ?? []))->class('form-control select2js') !!}
                                </div>

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.commission_type'))->for('commission_type')->class('form-control-label') !!}
                                    {!! html()->select('commission_type', ['fixed' => __('message.fixed'),'percentage' => __('message.percentage')], old('commission_type'))->class('form-control select2js') !!}
                                </div>

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.admin_commission') . ' <span class="text-danger">*</span>')->for('admin_commission')->class('form-control-label') !!}
                                    {!! html()->number('admin_commission', old('admin_commission'))->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.admin_commission'))->class('form-control') !!}
                                </div>
                                
                                {{-- <div class="form-group col-md-4">
                                    {!! html()->label(__('message.fleet_commission') . ' <span class="text-danger">*</span>')->for('fleet_commission')->class('form-control-label') !!}
                                    {!! html()->number('fleet_commission', old('fleet_commission'))->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.fleet_commission'))->class('form-control') !!}
                                </div> --}}
                                
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.status') . ' <span class="text-danger">*</span>')->for('status')->class('form-control-label') !!}
                                    {!! html()->select('status', ['1' => __('message.active'),'0' => __('message.inactive')], old('status'))->class('form-control select2js') !!}
                                </div>

                                <div class="form-group col-md-4">
                                    <label class="form-control-label" for="image">{{ __('message.image') }} </label>
                                    <div class="custom-file">
                                        <input type="file" name="service_image" class="custom-file-input" accept="image/*">
                                        <label class="custom-file-label">{{  __('message.choose_file',['file' =>  __('message.image') ]) }}</label>
                                    </div>
                                    <span class="selected_file"></span>
                                </div>

                                @if( isset($id) && getMediaFileExit($data, 'service_image'))
                                    <div class="col-md-2 mb-2">
                                        <img id="service_image_preview" src="{{ getSingleMedia($data,'service_image') }}" alt="service-image" class="attachment-image mt-1">
                                        <a class="text-danger remove-file" href="{{ route('remove.file', ['id' => $data->id, 'type' => 'service_image']) }}"
                                            data--submit='confirm_form'
                                            data--confirmation='true'
                                            data--ajax='true'
                                            data-toggle='tooltip'
                                            title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                            data-title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                            data-message='{{ __("message.remove_file_msg") }}'>
                                            <i class="ri-close-circle-line"></i>
                                        </a>
                                    </div>
                                @endif

                                <div class="form-group col-md-4">
                                    <label class="form-control-label" for="image">{{ __('message.service_marker') }} </label>
                                    <div class="custom-file">
                                        <input type="file" name="service_marker" class="custom-file-input" accept="image/*">
                                        <label class="custom-file-label">{{  __('message.choose_file',['file' =>  __('message.image') ]) }}</label>
                                        <small>Max 89 x 89</small>
                                    </div>
                                    {{--  <span class="selected_file"></span>  --}}
                                </div>

                                @if( isset($id) && getMediaFileExit($data, 'service_marker'))
                                    <div class="col-md-2 mb-2">
                                        <img id="service_marker_preview" src="{{ getSingleMedia($data,'service_marker') }}" alt="service-image" class="attachment-image mt-1">
                                        <a class="text-danger remove-file" href="{{ route('remove.file', ['id' => $data->id, 'type' => 'service_marker']) }}"
                                            data--submit='confirm_form'
                                            data--confirmation='true'
                                            data--ajax='true'
                                            data-toggle='tooltip'
                                            title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                            data-title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                            data-message='{{ __("message.remove_file_msg") }}'>
                                            <i class="ri-close-circle-line"></i>
                                        </a>
                                    </div>
                                @endif
                               <div class="form-group col-md-6">
                                    {!! html()->label(__('message.description'))->for('description')->class('form-control-label') !!}
                                    {!! html()->textarea('description')->class('form-control textarea')->rows(3)->placeholder(__('message.description')) !!}
                                </div>
                            </div>
                            <hr>
                            {!! html()->submit(__('message.save'))->class('btn border-radius-10 btn-primary float-right') !!}                        </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        {!! html()->form()->close() !!}
    </div>
    @section('bottom_script')
    <script type="text/javascript">
        (function($) {
            "use strict";
            $(document).ready(function() {
                $(document).on('change', '#region_id' , function () {

                    var data = $(this).select2('data')[0];

                    var data_distance_unit = $('#region_id').attr('data-distance-unit',)
                    var distance_unit = data.distance_unit != undefined ? data.distance_unit : data_distance_unit;
                    
                    var text = "{{  __('message.distance_in_km') }}";
                    if ( distance_unit == 'mile' ) {
                        text = "{{  __('message.distance_in_mile') }}";
                    }
                    $('#distance_unit').html("* (<small>"+ text +"</small>)");
                });
    
                $('#service_type').change(function () {
                    var serviceType = $(this).val();
                
                    const toggleField = (selector, show, makeRequired = false) => {
                        const $input = $(selector);
                        const $formGroup = $input.closest('.form-group');
                    
                        if (show) {
                            $formGroup.show();
                            if (makeRequired) {
                                $input.prop('required', true);
                            }
                        } else {
                            $formGroup.hide();
                            $input.prop('required', false);
                        }
                    };
                    
                
                    toggleField('input[name="per_weight_charge"]', serviceType !== 'book_ride', false);
                    toggleField('input[name="minimum_weight"]', serviceType !== 'book_ride', false);
                    toggleField('#capacity', serviceType !== 'transport', true);
                    // toggleField('#per_distance_charge', serviceType !== 'book_ride', true);
                    toggleField('#minimum_fare', serviceType !== 'transport', true);
                    // toggleField('#per_distance', serviceType !== 'transport', false);
                    toggleField('#per_minute_drive', serviceType !== 'transport', false);
                    toggleField('#per_minute_wait', serviceType !== 'transport', false);
                    toggleField('#waiting_time_limit', serviceType !== 'transport', false);
                    // toggleField('#cancellation_fee', serviceType !== 'transport', true);
                });
                
    
                $('#service_type').trigger('change'); // Trigger the change event to apply initial state
            });
        })(jQuery);
    </script>
    
    @endsection
</x-master-layout>
