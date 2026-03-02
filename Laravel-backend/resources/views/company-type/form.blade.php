
<?php $id = $id ?? null;?>
@if(isset($id))
    {{ html()->modelForm($data, 'PATCH', route('comapanytype.update', $id))->id('comapanytype_form')->open() }}
@else
    {{ html()->form('POST', route('comapanytype.store'))->attribute('data-toggle','validator')->id('comapanytype_form')->open() }} 
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
                <div class="col-md-12 form-group">
                    {!! html()->label(__('message.name') . ' <span class="text-danger">*</span>')->for('name')->class('form-control-label')!!}
                    {!! html()->text('name')->placeholder(__('message.name'))->class('form-control') !!}
                 </div>
                 <div class="col-md-12 form-group">
                    {!! html()->label(__('message.status') . ' <span class="text-danger">*</span>')->for('status')->class('form-control-label') !!}
                    {!! html()->select('status', ['1' => __('message.active'),'0' => __('message.inactive')], old('status'))->class('form-control select2js')->required() !!}
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
        $("#comapanytype_form").validate({
            rules: {
                name: {required: true },
            },
            messages: {
                name: {
                    required: "{{ __('message.please_enter_name') }}.",
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
