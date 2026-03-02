
<?php $id = $id ?? null;?>
@if(isset($id))
    {{ html()->modelForm($data, 'PATCH', route('cancelledreason.update', $id))->id('cancelledreason_form')->open() }}
@else
    {{ html()->form('POST', route('cancelledreason.store'))->attribute('data-toggle','validator')->id('cancelledreason_form')->open() }} 
@endif
<div class="modal-dialog modal-dialog-centered" role="document">
    <div class="modal-content ">
            <div class="modal-header">
                <h5 class="modal-title" id="exampleModalLabel">{{$pageTitle}}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
        <div class="modal-body">
            <div class="row">
                <div class="form-group col-md-12">
                    {!! html()->label(__('message.type') . ' <span class="text-danger">*</span>')->for('type')->class('form-control-label') !!}
                    {!! html()->select('type', ['driver' => __('message.driver'),'customer' => __('message.customer'),'customer_order' => __('message.customer_order'),'driver_order' => __('message.driver_order')], old('type'))->class('form-control select2js') !!}
                </div>
                <div class="col-md-12 form-group">
                    {!! html()->label(__('message.reason') . ' <span class="text-danger">*</span>')->for('reason')->class('form-control-label')!!}
                    {!! html()->text('reason')->placeholder(__('message.reason'))->class('form-control') !!}
                 </div>
            </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-md btn-secondary" data-dismiss="modal">{{ __('message.close') }}</button>
                    <button type="submit" class="btn btn-md btn-primary"id="btn_submit">{{ isset($id) ?  __('message.update') : __('message.save') }}</button>
                </div>
        </div>
        {!! html()->form()->close() !!}
    </div>
</div>
<script>
    $(document).ready(function(){
        $(".select2js").select2({
            width: "100%",
            tags: true
        });
        $("#cancelledreason_form").validate({
            rules: {
                reason: { required: true },
            },
            messages: {
                reason: {
                    required: "{{ __('message.please_enter_reason') }}.",
                }
            },
            errorElement: "div",
            errorPlacement: function(error, element) {
                error.addClass("invalid-feedback");
                element.closest(".form-group").append(error);
            },
            highlight: function(element) {
                $(element).addClass("is-invalid");
            },
            unhighlight: function(element) {
                $(element).removeClass("is-invalid");
            }
        });
    });
</script>
