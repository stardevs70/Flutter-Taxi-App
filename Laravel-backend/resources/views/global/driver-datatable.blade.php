<x-master-layout :assets="$assets ?? []">
    <div class="container-fluid">
        <div class="row">
            <div class="col-lg-12">
                <div class="card card-block card-stretch card-height border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ $pageTitle ?? ''}}</h4>
                        </div>
                        
                        <div class="d-flex">
                            <div class="me-2">
                                {!! $button !!}
                            </div>
                            <button id="filterToggle" class="float-right btn btn-sm border-radius-10 btn-warning ml-2" type="button" data-bs-toggle="modal" data-bs-target="#filterModal">
                                <i class="fas fa-filter"></i> {{ __('message.filter') }}
                            </button>                                                                                                           
                        </div>
                    </div>
                    <div class="card-body">
                        @if(isset($multi_checkbox_delete))
                            {!! $multi_checkbox_delete !!}
                        @endif
                        {{ $dataTable->table(['class' => 'table table table-hover  w-100'],false) }}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade fixed-right" id="filterModal" tabindex="-1" aria-labelledby="filterModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-aside">
            <div class="modal-content h-100">
                <div class="modal-header">
                    <h5 class="modal-title" id="filterModalLabel">{{ __('message.filter') }}</h5>
                    <a href="javascript:void();" data-bs-dismiss="modal" aria-label="Close"><i class="ri-close-circle-fill" style="font-size: 25px"></i></a>
                </div>
                <div class="modal-body">
                        {!! html()->form('GET')->id('driver-filter-form')->open() !!}
    
                        <div class="form-group mb-3">
                            {!! html()->label(__('message.driver'))->for('driver_id')->class('form-label') !!}
                            {!! html()->select('driver_id', [], request('driver_id'))
                                ->class('form-control select2')
                                ->attribute('data-ajax--url', route('ajax-list', ['type' => 'driver']))
                                ->attribute('data-placeholder', __('message.select_field', ['name' => __('message.driver')]))
                                ->attribute('data-allow-clear', 'true') !!}
                        </div>

                        <div class="form-group">
                            {!! html()->label(__('message.status') . ' <span data-toggle="tooltip" data-html="true" data-placement="top" title="Active user: Who last activated date in 1 day<br>
                                Engaged user: Who last activated date in 2-15 days<br>
                                Inactive user: Who last activated date in more than 15 days">(info)</span>')
                                ->for('last_actived_at')
                                ->class('form-control-label') !!}
                            
                            {!! html()->select('last_actived_at', [
                                '' => __('message.all'), 
                                'active_user' => __('message.active_user'), 
                                'engaged_user' => __('message.engaged_user'), 
                                'inactive_user' => __('message.inactive_user')
                            ], request('last_actived_at'))
                                ->class('form-control select2js')
                                ->id('last_active')
                                ->attribute('data-allow-clear', 'true') !!}
                        </div>

                        <div class="form-group">
                            {!! html()->label(__('message.service'))->for('service_id')->class('form-control-label') !!}
                            {!! html()->select('service_id', [], request('service_id'))
                                ->class('form-control select2')
                                ->attribute('data-ajax--url', route('ajax-list', ['type' => 'service']))
                                ->attribute('data-placeholder', __('message.select_field', ['name' => __('message.service')]))
                                ->attribute('data-allow-clear', 'true') !!}
                        </div>

                        <div class="form-group mb-3">
                            {!! html()->label(__('message.contact_number'))->for('contact_number')->class('form-label') !!}
                            {!! html()->number('contact_number', request('contact_number'))
                                ->class('form-control')
                                ->id('contact_number')
                                ->attribute('data-placeholder', __('message.please_enter_contact_number'))
                                ->attribute('data-allow-clear', 'true') !!}
                        </div>

                </div>
                <div class="modal-footer">
                    <button id="reset-filter-btn" type="button" class="btn btn-warning btn-sm border-radius-10 me-2 text-decoration-none">
                        {{ __('message.reset_filter') }}
                    </button>
                    <button type="submit" class="btn btn-primary btn-sm border-radius-10">{{ __('message.apply_filter') }}</button>
                </div>
                    {!! html()->form()->close() !!}
            </div>
        </div>
    </div>


    @section('bottom_script')
        {{ $dataTable->scripts() }}
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
        <script>
            $(document).ready(function() {
                $('.select2').select2({
                    dropdownParent: $('#filterModal'),
                });
                $('#driver-filter-form').on('submit', function(e) {
                    e.preventDefault();
                    var formData = $(this).serialize();
                    var table = $('#dataTableBuilder').DataTable();
                    table.ajax.url('{{ route('driver.index') }}?' + formData).load();
                });
               
                $('#reset-filter-btn').on('click', function(e) {
                    e.preventDefault();
                    $('#driver_id').val('').trigger('change');  
                    $('#last_active').val('').trigger('change');
                    $('#contact_number').val('').trigger('change');
                    $('#service_id').val('').trigger('change');
                    var table = $('#dataTableBuilder').DataTable();
                    table.ajax.url('{{ route('driver.index') }}').load();
                });
            });
        </script>        
        
    @endsection

</x-master-layout>
