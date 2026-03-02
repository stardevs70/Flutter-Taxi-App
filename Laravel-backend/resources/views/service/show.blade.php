<x-master-layout>
    <div class="container-fluid">
        <div class="row">
            <div class="col-lg-12">
                <div class="card shadow-sm border-0">
                    <div class="card-header border-bottom">
                        <div class="d-flex justify-content-between align-items-center">
                            <h5 class="mb-0">{{ $pageTitle }}</h5>
                            <a href="{{ route('service.index') }}" class="btn btn-sm btn-primary">
                                <i class="fa fa-angle-double-left me-1"></i> {{ __('message.back') }}
                            </a>
                        </div>
                    </div>
                    <div class="card-body">
                        @if ($data)
                            <div class="row g-4">
                                <div class="col-md-6 col-lg-3">
                                    <div class="border rounded p-3 h-100">
                                        <h6 class="text-primary border-bottom pb-2 mb-3">
                                            <i class="fa fa-car me-1"></i> {{ $pageTitle }}
                                        </h6>
                                        <dl class="row mb-0">
                                            <dt class="col-6">{{ __('message.name') }}</dt>
                                            <dd class="col-6">{{ $data->name }}</dd>
        
                                            <dt class="col-6">{{ __('message.service_type') }}</dt>
                                            <dd class="col-6">{{ str_replace('_',' ', ucfirst($data->service_type ?? 'N/A')) }}</dd>
        
                                            <dt class="col-6">{{ __('message.region') }}</dt>
                                            <dd class="col-6">{{ optional($data->region)->name }}</dd>
                                            @if(in_array($data->service_type, ['book_ride','both']))
                                                <dt class="col-6">{{ __('message.capacity') }}</dt>
                                                <dd class="col-6">{{ $data->capacity }}</dd>
                                            @endif    
                                        </dl>
                                    </div>
                                </div>
        
                                {{-- Fare Details --}}
                                <div class="col-md-6 col-lg-3">
                                    <div class="border rounded p-3 h-100">
                                        <h6 class="text-success border-bottom pb-2 mb-3">
                                            <i class="fa fa-money-bill me-1"></i> {{ __('message.fare_details') }}
                                        </h6>
                                        <dl class="row mb-0">
                                            @if(in_array($data->service_type, ['book_ride', 'both']))
                                                <dt class="col-7">{{ __('message.base_fare') }}</dt>
                                                <dd class="col-5">{{ getPriceFormat($data->base_fare) ?? 0 }}</dd>
                                        
                                                <dt class="col-7">{{ __('message.minimum_fare') }}</dt>
                                                <dd class="col-5">{{ getPriceFormat($data->minimum_fare) ?? 0 }}</dd>
                                        
                                                <dt class="col-7">{{ __('message.per_distance') }}</dt>
                                                <dd class="col-5">{{ getPriceFormat($data->per_distance) }}</dd>
                                        
                                                <dt class="col-7">{{ __('message.per_minute_drive') }}</dt>
                                                <dd class="col-5">{{ getPriceFormat($data->per_minute_drive) }}</dd>
                                        
                                                {{-- <dt class="col-7">{{ __('message.per_minute_wait') }}</dt>
                                                <dd class="col-5">{{ getPriceFormat($data->per_minute_wait) }}</dd>
                                        
                                                <dt class="col-7">{{ __('message.waiting_time_limit') }}</dt>
                                                <dd class="col-5">{{ $data->waiting_time_limit }}</dd> --}}
                                        
                                                <dt class="col-7">{{ __('message.cancellation_fee') }}</dt>
                                                <dd class="col-5">{{ getPriceFormat($data->cancellation_fee) ?? 0 }}</dd>
                                        
                                                <dt class="col-7">{{ __('message.minimum_distance') }}</dt>
                                                <dd class="col-5">{{ $data->minimum_distance ?? 0 }}</dd>
                                            @endif
                                        
                                            @if(in_array($data->service_type, ['transport', 'both']))
                                                {{-- Check to avoid duplicate base_fare if 'both' --}}
                                                @if($data->service_type != 'both')
                                                    <dt class="col-7">{{ __('message.base_fare') }}</dt>
                                                    <dd class="col-5">{{ getPriceFormat($data->base_fare) ?? 0 }}</dd>
                                                    <dt class="col-7">{{ __('message.minimum_distance') }}</dt>
                                                    <dd class="col-5">{{ $data->minimum_distance }} km</dd>
                                            
                                                @endif
                                                <dt class="col-7">{{ __('message.per_distance_charge') }}</dt>
                                                <dd class="col-5">{{ getPriceFormat($data->per_distance_charge) }}</dd>
                                        
                                                <dt class="col-7">{{ __('message.cancellation_fee') }}</dt>
                                                <dd class="col-5">{{ getPriceFormat($data->cancellation_fee) ?? 0 }}</dd>
                                        
                                                <dt class="col-7">{{ __('message.per_weight_charge') }}</dt>
                                                <dd class="col-5">{{ getPriceFormat($data->per_weight_charge) ?? 0 }}</dd>
                                        
                                                <dt class="col-7">{{ __('message.minimum_weight') }}</dt>
                                                <dd class="col-5">{{ $data->minimum_weight ?? 0 }}</dd>
                                            @endif
                                        </dl>
                                    </div>
                                </div>
        
                                {{-- Commission Info --}}
                                <div class="col-md-6 col-lg-3">
                                    <div class="border rounded p-3 h-100">
                                        <h6 class="text-warning border-bottom pb-2 mb-3">
                                            <i class="fa fa-percent me-1"></i> {{ __('message.commission_details') }}
                                        </h6>
                                        <dl class="row mb-0">
                                            <dt class="col-7">{{ __('message.commission_type') }}</dt>
                                            <dd class="col-5">{{ ucfirst($data->commission_type) }}</dd>
        
                                            <dt class="col-7">{{ __('message.admin_commission') }}</dt>
                                            <dd class="col-5">{{ $data->admin_commission }}{{ $data->commission_type == 'percentage' ? '%' : '' }}</dd>

                                            {{--  <dt class="col-7">{{ __('message.fleet_commission') }}</dt>
                                            <dd class="col-5">{{ $data->fleet_commission }}%</dd>  --}}
        
                                            <dt class="col-7">{{ __('message.payment_method') }}</dt>
                                            {{-- <dd class="col-5">{{ str_replace('_',' & ',ucfirst($data->payment_method)) }}</dd> --}}
                                            <dd class="col-5">
                                                {{ collect($data->payment_method)->map(fn($m) => ucfirst(str_replace('_', ' ', $m)))->implode(' & ') }}
                                            </dd>

                                        </dl>
        
                                        @if(!empty($data->description))
                                            <h6 class="mt-3 mb-1 text-muted">{{ __('message.description') }}</h6>
                                            <p class="small text-muted">{{ $data->description }}</p>
                                        @endif
                                    </div>
                                </div>
        
                                {{-- Additional Info --}}
                                <div class="col-md-6 col-lg-3">
                                    <div class="border rounded p-3 h-100">
                                        <h6 class="text-info border-bottom pb-2 mb-3">
                                            <i class="fa fa-info-circle me-1"></i> {{ __('message.additional_info') }}
                                        </h6>
                                        <dl class="row mb-0">
                                            <dt class="col-6">{{ __('message.created_at') }}</dt>
                                            <dd class="col-6">{{ $data->created_at->format('Y-m-d H:i') ?? '-' }}</dd>
        
                                            <dt class="col-6">{{ __('message.status') }}</dt>
                                            <dd class="col-6">
                                                @php
                                                    $status = $data->status == '1' ? 'success' : 'danger';
                                                    $status_name = $data->status == '1' ? __('message.active') : __('message.inactive');
                                                @endphp
                                                <span class="badge bg-{{ $status }}">{{ $status_name }}</span>
                                            </dd>
                                        </dl>
                                    </div>
                                </div>
                            </div>
                        @else
                            <div class="alert alert-info mt-4">
                                {{ __('message.no_record_found') }}
                            </div>
                        @endif
                    </div>
                </div>
            </div>
        </div>        
        
        <div class="row mt-4">
            <div class="col-lg-12">
                <div class="card shadow-sm">
                    <div class="card-header d-flex align-items-center justify-content-between">
                        <h4 class="card-title mb-0">{{ __('message.special_rates_detail') }}</h4>
                        <a href="{{ route('specialservices.create') }}" class="btn btn-sm border-radius-10 btn-primary me-2">
                            <i class="fa fa-plus-circle"></i> {{ __('message.add_form_title',['form' => __('message.special_rates')]) }}
                        </a>
                    </div>                    
                    <div class="card-body table-responsive">
                        <table class="table table-bordered text-center mb-0">
                            <thead>
                                <tr>
                                    <th>{{ __('message.no') }}</th>
                                    <th>{{ __('message.name') }}</th>
                                    <th>{{ __('message.start_date') }}</th>
                                    <th>{{ __('message.end_date') }}</th>
                                    <th>{{ __('message.status') }}</th>
                                    <th>{{ __('message.action') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($special_data as $key => $special)
                                    <tr>
                                        <td>{{ $key + 1 }}</td>
                                        <td>{{ $special->name }}</td>
                                        <td>{{ $special->start_date_time}}</td>
                                        <td>{{ $special->end_date_time}}</td>
                                        <td>
                                            @php
                                                $status = 'danger';
                                                $status_name = __('message.inactive');
                                                if ($special->status == '1') {
                                                    $status = 'success';
                                                    $status_name = __('message.active');
                                                }
                                            @endphp
                                            <span class="badge bg-{{ $status }}">{{ $status_name }}</span>
                                        </td>
                                        <td>
                                            <a class="mr-2" href="{{ route('specialservices.edit', $special->id) }}" title="{{ __('message.update_form_title',['form' => __('message.special_rates') ]) }}"><i class="fas fa-edit text-primary"></i></a>
                                            <a href="javascript:void(0)" class="viewSpecialRate mr-2" data-id="{{ $special->id }}" title="{{ __('message.view_details') }}"><i class="fas fa-eye text-secondary"></i></a>
                                            <a class="mr-2 text-danger" href="javascript:void(0)" data--submit="special{{$special->id}}" 
                                                data--confirmation='true' data-title="{{ __('message.delete_form_title',['form'=> __('message.special') ]) }}"
                                                title="{{ __('message.delete_form_title',['form'=>  __('message.special') ]) }}"
                                                data-message='{{ __("message.delete_msg") }}'>
                                                <i class="fas fa-trash-alt"></i>
                                            </a>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="6">{{ __('message.no_record_found') }}</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="specialRateModal" tabindex="-1" aria-labelledby="specialRateModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="specialRateModalLabel">{{ __('message.special_rates_detail') }}</h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body" id="specialRateContent">
                        <div class="text-center py-5">
                            
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-md btn-secondary" data-dismiss="modal">{{ __('message.close') }}</button>
                    </div>
                </div>
            </div>
        </div>


        @section('bottom_script')
        <script>
            // Enable DataTables if needed
            $(".table").DataTable();

            $(document).on('click', '.viewSpecialRate', function () {
                const id = $(this).data('id');
                const modal = $('#specialRateModal');
                const content = $('#specialRateContent');
        
                // Show modal
                modal.modal('show');
        
                // Fetch data via AJAX
                $.ajax({
                    url: "{{ route('specialservices.show', ['specialservice' => ':id']) }}".replace(':id', id),
                    method: 'GET',
                    success: function (response) {
                        $('#specialRateContent').html(response);
                    },
                    error: function () {
                        $('#specialRateContent').html('<div class="alert alert-danger text-center">{{ __("message.error_occurred") }}</div>');
                    }
                });                
            });
        </script>
        @endsection
    </div>
</x-master-layout>
