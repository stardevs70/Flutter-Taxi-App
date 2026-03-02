<!-- Modal -->
<div class="modal-dialog modal-md" role="document">
    {{ html()->form('POST', route('corporate-document'))->attribute('enctype', 'multipart/form-data')->open() }} 
    {{-- {{ html()->hidden('id', $id) }} --}}
    <div class="modal-content">
        <div class="modal-header">
            <h5 class="modal-title">{{ $pageTitle }}</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
            </button>
        </div>
        <div class="modal-body">
            <div class="form-group col-md-12">
                {!! html()->label(__('message.name').' <span class="text-danger">*</span>')->for('name')->class('form-control-label') !!}
                {!! html()->text('name', old('name'))->class('form-control')->placeholder(__('message.name'))->required() !!}
            </div>
            <div class="form-group col-md-12">
                <label class="form-control-label" for="corporate_document">{{ __('message.upload_document') }}</label>
                <div class="custom-file">
                    <input type="file" id="corporate_document" name="corporate_document" class="custom-file-input">
                    <label class="custom-file-label">{{ __('message.choose_file') }}</label>
                </div>
            </div>
            {{ html()->submit(__('message.submit'))->class('btn btn-md btn-primary float-right') }}
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
