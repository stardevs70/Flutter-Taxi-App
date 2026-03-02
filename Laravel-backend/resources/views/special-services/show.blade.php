<div class="container-fluid">
    <div class="mb-3">
        <h5 class="fw-semibold text-primary mb-1">{{ $data->name }}</h5>
        <span class="badge bg-{{ $data->status ? 'success' : 'secondary' }}">
            {{ $data->status ? __('message.active') : __('message.inactive') }}
        </span>
    </div>

    <div class="row mb-4">
        <div class="col-md-6">
            <label class="text-muted small">{{ __('message.start_date') }}</label>
            <div class="fw-semibold">{{ $data->start_date_time }}</div>
        </div>
        <div class="col-md-6">
            <label class="text-muted small">{{ __('message.end_date') }}</label>
            <div class="fw-semibold">{{ $data->end_date_time }}</div>
        </div>
    </div>

    <div class="mb-3">
        <h6 class="border-bottom pb-1 text-dark fw-semibold mb-2">{{ __('message.fare_details') }}</h6>
        <div class="row g-3">
            @php
                $fareList = [
                    __('message.base_fare') => getPriceFormat($data->base_fare),
                    __('message.minimum_fare') => getPriceFormat($data->minimum_fare),
                    __('message.minimum_distance') => $data->minimum_distance . ' km',
                    __('message.per_distance') => getPriceFormat($data->per_distance),
                    __('message.per_minute_drive') => getPriceFormat($data->per_minute_drive),
                    __('message.per_minute_wait') => getPriceFormat($data->per_minute_wait),
                    // __('message.waiting_time_limit') => $data->waiting_time_limit . ' min',
                    __('message.cancellation_fee') => getPriceFormat($data->cancellation_fee),
                ];
            @endphp

            @foreach ($fareList as $label => $value)
                <div class="col-sm-6 col-lg-4 mb-1">
                    <div class="border rounded p-2 h-100">
                        <label class="text-muted">{{ $label }}</label>
                        <div class="fw-medium">{{ $value }}</div>
                    </div>
                </div>
            @endforeach
        </div>
    </div>

    @if (!empty($data->description))
        <div class="mt-4">
            <h6 class="border-bottom pb-1 text-dark fw-semibold">{{ __('message.description') }}</h6>
            <p class="text-muted mb-0">{{ $data->description }}</p>
        </div>
    @endif
</div>
