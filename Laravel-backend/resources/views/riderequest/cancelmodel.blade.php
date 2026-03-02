<!-- Modal -->
<div class="modal-dialog modal-md modal-dialog-centered" role="document">
    {{ html()->form('POST', route('ridecancel.save'))->open() }} 
    {{ html()->hidden('id', $id) }}
    <div class="modal-content">
        <div class="modal-header">
            <h5 class="modal-title">{{ $pageTitle }}</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
            </button>
        </div>
        <div class="modal-body">
            <div class="form-group col-md-12">
                {!! html()->label(__('message.reason') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('reason') !!}
                {!! html()->select('reason', old('reason'))
                    ->class('form-control select2js')
                    ->id('reason')
                    ->attribute('data-ajax--url', route('ajax-list', ['type' => 'manage-cancelledReason']))
                    ->attribute('data-placeholder', __('message.select_field', ['name' => __('message.cancel_reason')])) !!}
            </div>
            {{ html()->submit(__('message.submit'))->class('btn w-100 btn-primary float-right') }}
        </div>
    </div>
    {{ html()->form()->close() }}
</div>

<script>
    $(".select2js").select2({
        width: "100%",
        tags: true
    });
</script>
