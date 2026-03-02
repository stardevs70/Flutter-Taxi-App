<x-master-layout :assets="$assets ?? []">
    <div>
        <?php $id = $id ?? null;?>
        @if(isset($id))
            {!! html()->modelForm($data,'PATCH', route('corporatedocument.update', $id))->attribute('enctype', 'multipart/form-data')->open() !!}
        @else
            {!! html()->form('POST', route('corporatedocument.store'))->attribute('enctype', 'multipart/form-data')->open() !!}
        @endif
        <div class="row">
            <div class="col-lg-12 mt-3">
                <div class="card border-radius-20">
                    <div class="card-header d-flex justify-content-between"  style="border-top-left-radius: 20px; border-top-right-radius: 20px;">
                        <div class="header-title">
                            <h4 class="card-title">{{ $pageTitle }}</h4>
                        </div>
                        <a href="{{route('corporatedocument.index')}}" class="float-right btn btn-sm border-radius-10 btn-primary me-2" role="button"><i class="fas fa-arrow-circle-left"></i> {{ __('message.back') }}</a>
                    </div>

                    <div class="card-body">
                        <div class="new-user-info">
                            <div class="row">
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.name').' <span class="text-danger">*</span>')->for('name')->class('form-control-label') !!}
                                    {!! html()->text('name', old('name'))->class('form-control')->placeholder(__('message.name'))->required() !!}
                                </div>
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.corporate') . ' <span class="text-danger">* </span>')->class('form-control-label')->for('corporate_id') !!}
                                    {!! html()->select('corporate_id', isset($id) ? [optional($data->corporate)->id => optional($data->corporate)->full_name ] : [], old('corporate_id'))
                                        ->class('select2js form-group corporate_id')
                                        ->id('corporate_id')
                                        ->required()
                                        ->attribute('data-placeholder', __('message.select_name', ['select' => __('message.corporate')]))
                                        ->attribute('data-ajax--url', route('ajax-list', ['type' => 'corporate'])) !!}
                                </div>
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.documents'))->class('form-control-label')->for('document_id') !!}
                                    {!! html()->select('document_id', $documentOption ?? [], old('document_id', $data->document_id ?? ''))
                                        ->class('form-control select2js')
                                        ->id('document_id')
                                        ->attribute('data-placeholder', __('message.select_name', ['select' => __('message.document')])) !!}
                                </div>
                                

                                <div class="form-group col-md-4">
                                    <label class="form-control-label" for="expire_date">{{ __('message.expire_date') }} <span class="text-danger" id="has_expiry_date"></span> </label>
                                    {!! html()->text('expire_date', old('expire_date'))->class('form-control min-datepicker')->placeholder(__('message.expire_date')) !!}

                                </div>
                                
                                @if(auth()->user()->hasAnyRole(['admin','demo_admin']))
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.is_verify') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('is_verified') !!}
                                    {!! html()->select('is_verified', [
                                            '0' => __('message.pending'), 
                                            '1' => __('message.approved'), 
                                            '2' => __('message.rejected')
                                        ], old('is_verified'))->class('form-control select2js')->id('is_verified')->required() !!}
                                </div>
                                @endif

                                <div class="form-group col-md-4">
                                    <label class="form-control-label" for="manage_corporate_document">{{ __('message.upload_document') }} <span class="text-danger" id="document_required"></span> </label>
                                    <div class="custom-file">
                                        <input type="file" id="manage_corporate_document" name="manage_corporate_document" class="custom-file-input" >
                                        <label class="custom-file-label">{{ __('message.choose_file', [ 'file' => __('message.document') ]) }}</label>
                                    </div>
                                    <span class="selected_file"></span>
                                </div>
                                @if( isset($id) && getMediaFileExit($data, 'manage_corporate_document'))
                                    <div class="col-md-2 mb-2">
                                        <?php
                                            $file_extention = config('constant.IMAGE_EXTENTIONS');
                                            $image = getSingleMedia($data,'manage_corporate_document');
                                            
                                            $extention = in_array(strtolower(imageExtention($image)),$file_extention);
                                        ?>
                                            @if($extention)   
                                                <img id="manage_corporate_document_preview" src="{{ $image }}" alt="#" class="attachment-image mt-1" >
                                            @else
                                                <img id="manage_corporate_document_preview" src="{{ asset('images/file.png') }}" class="attachment-file">
                                            @endif
                                            <a class="text-danger remove-file" href="{{ route('remove.file', ['id' => $data->id, 'type' => 'manage_corporate_document']) }}"
                                                data--submit="confirm_form"
                                                data--confirmation='true'
                                                data--ajax="true"
                                                title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                                data-title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                                data-message='{{ __("message.remove_file_msg") }}'>
                                                <i class="ri-close-circle-line"></i>
                                            </a>
                                            <a href="{{ $image }}" class="d-block mt-2" download target="_blank"><i class="fas fa-download "></i> {{ __('message.download') }}</a>
                                    </div>
                                @endif
                            </div>
                            <hr>
                            {!! html()->submit(__('message.save'))->class('btn border-radius-10 btn-primary float-right') !!}
                        </div>
                    </div>
                </div>
            </div>
        </div>
        {!! html()->form()->close() !!}
    </div>
    @section('bottom_script')
    <script>
        
        $('#corporate_id').on('select2:select', function(e) {
            var selectedData = e.params.data;
            console.log('Selected Corporate ID:', selectedData.id);
            var section_class_route = "{{ route('ajax-list') }}" + "?type=manage_corporate_document&corporate_id=" + selectedData.id;

            $.ajax({
                url: section_class_route,
                success: function(result) {
                    $('#document_id').empty().select2({
                        width: '100%',
                        placeholder: "{{ __('message.select_name',['select' => __('message.document')]) }}",
                        data: result.results
                    });
                }
            });
        });
    </script>
    @endsection
</x-master-layout>
