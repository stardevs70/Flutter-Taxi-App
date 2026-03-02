
<?php $id = $id ?? null;?>
@if(isset($id))
    {{ html()->modelForm($data, 'PATCH', route('withdrawrequest.update', $id))->id('withdrawrequest_form')->open() }}
@else
    {{ html()->form('POST', route('withdrawrequest.store'))->attribute('data-toggle','validator')->id('withdrawrequest_form')->open() }} 
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
                @if(isset($id))
                    <div class="form-group col-md-12">
                        {!! html()->label(__('message.name'))->for('user_id')->class('form-control-label') !!}
                        <p>{{ optional($data->user)->display_name }}</p>
                    </div>
                @endif

                <div class="form-group col-md-12">
                    {!! html()->label(__('message.amount').' <span class="text-danger">*</span>')->for('amount')->class('form-control-label') !!}
                    @if(!isset($id))
                        {!! html()->number('amount', old('amount'))->placeholder(__('message.amount'))->class('form-control')->attribute('min', 0)->attribute('step', 'any')->required() !!}
                    @else
                        <p>{{ $data->amount }}</p>
                    @endif
                </div>
                
            </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-md btn-secondary" data-dismiss="modal">{{ __('message.close') }}</button>
                    <button type="submit" class="btn btn-md btn-primary"id="btn_submit">{{ isset($id) ?  __('message.update') : __('message.save') }}</button>           </div>
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
        $("#withdrawrequest_form").validate({
            rules: {
                amount: {required: true },
            },
            messages: {
                amount: {
                    required: "{{ __('message.please_enter_amount') }}.",
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
