<x-master-layout :assets="$assets ?? []">
    <div>
        <?php $id = $id ?? null;?>
        @if(isset($id))
            {!! html()->modelForm($data,'PATCH', route('specialservices.update', $id))->open() !!}
        @else
            {!! html()->form('POST', route('specialservices.store'))->open() !!}
        @endif
        <div class="row">
            <div class="col-lg-12 mt-3">
                <div class="card border-radius-20">
                    <div class="card-header d-flex justify-content-between"  style="border-top-left-radius: 20px; border-top-right-radius: 20px;">
                        <div class="header-title">
                            <h4 class="card-title">{{ $pageTitle }}</h4>
                        </div>
                        <a href="{{route('specialservices.index')}}" class="float-right btn btn-sm border-radius-10 btn-primary me-2" role="button"><i class="fas fa-arrow-circle-left"></i> {{ __('message.back') }}</a>
                    </div>

                    <div class="card-body">
                        <div class="new-user-info">
                            <div class="row">
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.name').' <span class="text-danger">*</span>')->class('form-control-label') !!}
                                    {!! html()->text('name',old('name'))->class('form-control')->placeholder(__('message.name'))->required() !!}
                                </div>

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.select_name', ['select' => __('message.service')]).' <span class="text-danger">*</span>')->for('service_id')->class('form-control-label') !!}
                                    {!! html()->select('service_id', isset($id) ? [optional($data->service)->id => optional($data->service)->name] : [], old('service_id'))
                                        ->class('select2js form-group service')
                                        ->attribute('data-placeholder', __('message.select_name', ['select' => __('message.service')]))
                                        ->attribute('data-ajax--url', route('ajax-list', ['type' => 'service'])) !!}
                                </div>

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.start_date'))->class('form-control-label')->for('start_date') !!}
                                    {!! html()->text('start_date_time', old('start_date_time'))->class('form-control datetimepicker')->placeholder(__('message.start_date')) !!}
                                </div>
                                
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.end_date'))->class('form-control-label')->for('end_date') !!}
                                    {!! html()->text('end_date_time', old('end_date_time'))->class('form-control datetimepicker')->placeholder(__('message.end_date')) !!}
                                </div>
                                
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.base_fare') . ' <span class="text-danger">*</span>')->for('base_fare')->class('form-control-label') !!}
                                    {!! html()->number('base_fare', old('base_fare'))->class('form-control')->attribute('min', 0)->attribute('step', 'any')->required()->placeholder(__('message.base_fare')) !!}
                                </div>

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.minimum_fare') . ' <span class="text-danger">*</span>')->for('minimum_fare')->class('form-control-label') !!}
                                    {!! html()->number('minimum_fare', old('minimum_fare'))->class('form-control')->attribute('min', 0)->attribute('step', 'any')->required()->placeholder(__('message.minimum_fare')) !!}
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
                                </div> --}}

                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.cancellation_fee') . ' <span class="text-danger">*</span>')->for('cancellation_fee')->class('form-control-label') !!}
                                    {!! html()->number('cancellation_fee', old('cancellation_fee'))->class('form-control')->attribute('min', 0)->attribute('step', 'any')->required()->placeholder(__('message.cancellation_fee')) !!}
                                </div>
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.status') . ' <span class="text-danger">*</span>')->for('status')->class('form-control-label') !!}
                                    {!! html()->select('status', ['1' => __('message.active'),'0' => __('message.inactive')], old('status'))->class('form-control select2js')->required() !!}
                                </div>

                            </div>
                            <hr>
                            {!! html()->submit( isset($id) ? __('message.update') : __('message.save') )->class('btn border-radius-10 btn-primary float-right') !!}                        </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        {!! html()->form()->close() !!}
    </div>
</x-master-layout>
