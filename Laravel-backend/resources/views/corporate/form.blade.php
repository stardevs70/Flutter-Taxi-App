<x-master-layout :assets="$assets ?? []">
    <div>
        <?php $id = $id ?? null;?>
        @if(isset($id))
            {!! html()->modelForm($data,'PATCH', route('corporate.update', $id))->attribute('enctype', 'multipart/form-data')->id('corporate_form')->open() !!}
        @else
            {!! html()->form('POST', route('corporate.store'))->attribute('enctype', 'multipart/form-data')->id('corporate_form')->open() !!}

        @endif
        <div class="row">
            <div class="col-xl-3 col-lg-4 mt-3">
                <div class="card border-radius-20">
                    <div class="card-header d-flex justify-content-between"  style="border-top-left-radius: 20px; border-top-right-radius: 20px;">
                        <div class="header-title">
                            <h4 class="card-title">{{ $pageTitle }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="form-group">
                            <div class="crm-profile-img-edit position-relative text-center">
                                <img src="{{ $profileImage ?? asset('images/user/1.jpg')}}" alt="User-Profile" class="crm-profile-pic rounded-circle avatar-100">
                                <div class="crm-p-image bg-primary">
                                    <svg class="upload-button" width="14" height="14" viewBox="0 0 24 24">
                                        <path fill="#ffffff" d="M14.06,9L15,9.94L5.92,19H5V18.08L14.06,9M17.66,3C17.41,3 17.15,3.1 16.96,3.29L15.13,5.12L18.88,8.87L20.71,7.04C21.1,6.65 21.1,6 20.71,5.63L18.37,3.29C18.17,3.09 17.92,3 17.66,3M14.06,6.19L3,17.25V21H6.75L17.81,9.94L14.06,6.19Z" />
                                    </svg>
                                    <input class="file-upload" type="file" accept="image/*" name="profile_image">
                                </div>
                            </div>
                            <div class="img-extension mt-3">
                                <div class="d-inline-block align-items-center">
                                    <span>{{ __('message.only') }}</span>
                                    @foreach(config('constant.IMAGE_EXTENTIONS') as $extention)
                                        <a href="javascript:void();">.{{ $extention }}</a>
                                    @endforeach
                                    <span>{{ __('message.allowed') }}</span>
                                </div>
                                <hr>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="form-label">{{ __('message.status') }}</label>
                            <div class="row" style="--bs-gap: 1rem;">
                                <div class="col-md-6">
                                    <div class="custom-control custom-radio custom-control-inline">
                                        {!! html()->radio('status', old('status','active') === 'active', 'active')->class('custom-control-input')->id('status-active') !!}
                                        {!! html()->label(__('message.active'))->class('custom-control-label')->for('status-active') !!}
                                    </div>
                                    <div class="custom-control custom-radio custom-control-inline">
                                        {!! html()->radio('status', old('status','active') === 'inactive', 'inactive')->class('custom-control-input')->id('status-inactive') !!}
                                        {!! html()->label(__('message.inactive'))->class('custom-control-label')->for('status-inactive') !!}
                                    </div>
                                </div>
                                    <div class="col-md-6">
                                        <div class="custom-control custom-radio custom-control-inline">
                                            {!! html()->radio('status', old('status','pending') === 'pending', 'pending')->class('custom-control-input')->id('status-pending') !!}
                                            {!! html()->label(__('message.pending'))->class('custom-control-label')->for('status-pending') !!}
                                        </div>
                                        <div class="custom-control custom-radio custom-control-inline">
                                            {!! html()->radio('status', old('status') === 'banned','banned')->class('custom-control-input')->id('status-banned') !!}
                                            {!! html()->label(__('message.banned'))->class('custom-control-label')->for('status-banned') !!}
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="custom-control custom-radio custom-control-inline">
                                            {!! html()->radio('status' ,old('status') === 'reject', 'reject')->class('custom-control-input')->id('status-reject')!!}
                                            {!! html()->label(__('message.reject'))->class('custom-control-label')->for('status-reject') !!}
                                        </div>
                                    </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-xl-9 col-lg-8 mt-3">
                <div class="card border-radius-20">
                    <div class="card-header d-flex justify-content-between" style="border-top-left-radius: 20px; border-top-right-radius: 20px;">
                        <div class="header-title">
                            <h4 class="card-title">{{ $pageTitle }} {{ __('message.information') }}</h4>
                        </div>
                        <a href="{{route('corporate.index')}}" class="btn border-radius-10 btn-sm btn-primary float-right" role="button"><i class="fas fa-arrow-circle-left"></i> {{ __('message.back') }}</a>
                    </div>
                    <div class="card-body">
                        <div class="new-user-info">
                            <div class="row">
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.first_name') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('first_name') !!}
                                    {!! html()->text('first_name', old('first_name'))->class('form-control')->placeholder(__('message.first_name')) !!}
                                </div>
                                
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.last_name') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('last_name') !!}
                                    {!! html()->text('last_name', old('last_name'))->class('form-control')->placeholder(__('message.last_name')) !!}
                                </div>
                                @php
                                   $readonly = (isset($id) && !$usercheck) ? 'readonly' : '';
                                @endphp
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.email') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('email') !!}
                                    {!! html()->email('email', isset($id) ? optional($data)->email : old('email'))->class('form-control')->placeholder(__('message.email'))->attribute($readonly) !!}
                                </div>
                                
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.username') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('username') !!}
                                    {!! html()->text('username', old('username'))->class('form-control')->placeholder(__('message.username')) !!}
                                </div>
                               
                                {{-- <div class="form-group col-md-6">
                                    {!! html()->label(__('message.password') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('password') !!}
                                    {!! html()->password('password')->class('form-control')->placeholder(__('message.password')) !!}
                                </div> --}}
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.password') . ' <span class="text-danger">*</span>')->class('form-control-label') !!}
                                    <div class="input-group">
                                        {!! html()->password('password')->class('form-control')->placeholder(__('message.password'))->id('password') !!}
                                        <div class="input-group-append">
                                            <span class="input-group-text hide-show-password" style="cursor: pointer;">
                                                <i class="fas fa-eye-slash"></i>
                                            </span>
                                        </div>
                                    </div>
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.contact_number') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('contact_number') !!}
                                    {!! html()->text('contact_number', old('contact_number'))->class('form-control')->id('phone')->placeholder(__('message.contact_number'))->attribute($readonly) !!}
                                </div>
                            </div>
                            <hr>
                            <div class="row">
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.company_name') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('company_name') !!}
                                    {!! html()->text('company_name', old('company_name'))->class('form-control')->placeholder(__('message.company_name')) !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.company_type'). ' <span class="text-danger">*</span>')->class('form-control-label')->for('company_type_id') !!}
                                    {!! html()->select('company_type_id', isset($data) ? [$data->CompanyType->id => optional($data->CompanyType)->name] : [], old('company_type'))
                                        ->class('form-control select2js')
                                        ->id('company_type_id')
                                        ->attribute('data-ajax--url', route('ajax-list', [ 'type' => 'company-type' ]))
                                        ->attribute('data-placeholder', __('message.select_field', [ 'name' => __('message.company_type') ]))
                                         !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.companyid') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('companyid') !!}
                                    {!! html()->text('companyid', old('companyid'))->class('form-control')->placeholder(__('message.companyid')) !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.invoice_email') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('invoice_email') !!}
                                    {!! html()->email('invoice_email', old('invoice_email'))->class('form-control')->placeholder(__('message.invoice_email')) !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.commission_type'))->for('commission_type')->class('form-control-label') !!}
                                    {!! html()->select('commission_type', ['fixed' => __('message.fixed'),'percentage' => __('message.percentage')], old('commission_type'))->class('form-control select2js')->required() !!}
                                </div>

                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.commission') . ' <span class="text-danger">*</span>')->for('commission')->class('form-control-label') !!}
                                    {!! html()->number('commission', old('commission'))->attribute('min', 0)->attribute('step', 'any')->placeholder(__('message.commission'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.vat_number') . ' <span class="text-danger">*</span>')->for('commission')->class('form-control-label') !!}
                                    {!! html()->text('VAT_number', old('VAT_number'))->placeholder(__('message.vat_number'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.company_address'). ' <span class="text-danger">*</span>')->class('form-control-label')->for('company_address') !!}
                                    {!! html()->textarea('company_address')->class('form-control textarea')->rows(2)->placeholder(__('message.company_address')) !!}
                                </div>
                            </div>
                            <hr>
                            @php
                                $userbankaccount = isset($data) && isset($data->user) ? $data->user->userBankAccount : null;
                            @endphp
                            <div class="row">
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.bank_name'))->class('form-control-label')->for('bank_name') !!}
                                    {!! html()->text('bank_name',$userbankaccount->bank_name ?? null)->placeholder(__('message.bank_name'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.bank_account_number'))->class('form-control-label')->for('bank_account_number') !!}
                                    {!! html()->text('account_number',$userbankaccount->account_number ?? null)->placeholder(__('message.bank_account_number'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.bank_account_holder_name'))->class('form-control-label')->for('bank_account_holder_name') !!}
                                    {!! html()->text('account_holder_name',$userbankaccount->account_holder_name ?? null)->placeholder(__('message.bank_account_holder_name'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.bank_ifsc_code'))->class('form-control-label')->for('bank_ifsc_code') !!}
                                    {!! html()->text('bank_code',$userbankaccount->bank_code ?? null)->placeholder(__('message.bank_ifsc_code'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.bank_address'))->class('form-control-label')->for('bank_address') !!}
                                    {!! html()->text('bank_address',$userbankaccount->bank_address ?? null)->placeholder(__('message.bank_address'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.routing_number'))->class('form-control-label')->for('routing_number') !!}
                                    {!! html()->text('routing_number',$userbankaccount->routing_number ?? null)->placeholder(__('message.routing_number'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.bank_iban'))->class('form-control-label')->for('bank_iban') !!}
                                    {!! html()->text('bank_iban',$userbankaccount->bank_iban ?? null)->placeholder(__('message.bank_iban'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-6">
                                    {!! html()->label(__('message.bank_swift'))->class('form-control-label')->for('bank_swift') !!}
                                    {!! html()->text('bank_swift',$userbankaccount->bank_swift ?? null)->placeholder(__('message.bank_swift'))->class('form-control') !!}
                                </div>
                                <div class="form-group col-md-4">
                                    <label class="form-control-label" for="corporate_logo">{{ __('message.corporate_logo') }}</label>
                                    <div class="custom-file">
                                    {{ html()->file('corporate_logo')
                                        ->class('custom-file-input')
                                        ->id('corporate_logo')
                                        ->attribute('data--target', 'corporate_logo_preview')
                                        ->attribute('lang', 'en')
                                        ->accept('image/*') }}
                                        <label class="custom-file-label">{{ __('message.choose_file', ['file' => __('message.corporate_logo')]) }}</label>
                                    </div>
                                    <span class="selected_file"></span>
                                </div>
                                <div class="col-md-2 mb-2">
                                    @if(isset($id) && getMediaFileExit($data, 'corporate_logo') && getSingleMedia($data, 'corporate_logo'))
                                        <img id="corporate_logo_preview"
                                            src="{{ getSingleMedia($data, 'corporate_logo') ?? asset('images/default.png') }}"
                                            alt="image"
                                            class="attachment-image mt-1 corporate_logo_preview">
                                            {{-- <img id="corporate_logo_preview"
                                                src="{{ getSingleMedia($data, 'corporate_logo') }}"
                                                alt="image"
                                                class="attachment-image mt-1 corporate_logo_preview"> --}}

                                        <a class="text-danger remove-file"
                                            href="{{ route('remove.file', ['id' => $data->id, 'type' => 'corporate_logo', 'sub_type' => 'corporate_logo']) }}"
                                            data--submit='confirm_form'
                                            data--confirmation='true'
                                            data--ajax='true'
                                            data-toggle='tooltip'
                                            title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                            data-title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                            data-message='{{ __("message.remove_file_msg") }}'>
                                                <i class="ri-close-circle-line"></i>
                                        </a>
                                        <p class="text-success mt-2">Corporate logo is already uploaded. You can remove or replace it.</p>
                                    @else
                                       <img id="corporate_logo_preview" src="{{ asset('images/default.png') }}" alt="image" class="attachment-image mt-1 corporate_logo_preview">
                                    @endif
                                </div>
                                <div class="form-group col-md-4">
                                    <label class="form-control-label" for="corporate_background">{{ __('message.corporate_background') }}</label>
                                    <div class="custom-file">
                                    {{ html()->file('corporate_background')
                                        ->class('custom-file-input')
                                        ->id('corporate_background')
                                        ->attribute('data--target', 'corporate_background_preview')
                                        ->attribute('lang', 'en')
                                        ->accept('image/*') }}
                                        <label class="custom-file-label">{{ __('message.choose_file', ['file' => __('message.image')]) }}</label>
                                    </div>
                                    <span class="selected_file"></span>
                                </div>
                                <div class="col-md-2 mb-2">
                                    @if(isset($id) && getMediaFileExit($data, 'corporate_background'))
                                        <img id="corporate_background_preview" src="{{ getSingleMedia($data, 'corporate_background' ?? 'images/default.png') }}" alt="image" class="attachment-image mt-1 corporate_background_preview">
                                        <a class="text-danger remove-file"
                                            href="{{ route('remove.file', ['id' => $data->id, 'type' => 'corporate_background', 'sub_type' => 'corporate_background']) }}"
                                            data--submit='confirm_form'
                                            data--confirmation='true'
                                            data--ajax='true'
                                            data-toggle='tooltip'
                                            title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                            data-title='{{ __("message.remove_file_title" , ["name" =>  __("message.image") ]) }}'
                                            data-message='{{ __("message.remove_file_msg") }}'>
                                            <i class="ri-close-circle-line"></i>
                                        </a>

                                        <p class="text-success mt-2">Corporate background is already uploaded. You can remove or replace it.</p>
                                    @else
                                        <img id="corporate_background_preview" src="{{ asset('images/default.png') }}" alt="image" class="attachment-image mt-1 corporate_background_preview">
                                    @endif
                                </div>
                                {{-- <div class="form-group d-flex align-items-center">
                                    <div class="form-group col-md-">
                                        <span class="mr-3 pl-3" style="font-weight: 400;">http://127.0.0.1:8000/?corp=</span>
                                    </div>
                                    <div class="form-group col-md-4">
                                        <input type="text" id="corp_value" name="corp_value" class="form-control" placeholder="Enter" oninput="updateFullUrl()" />
                                        <input type="hidden" id="url" name="url" value="" />
                                    </div>    
                                </div> --}}
                                @php
                                    $readonly = isset($id) ? 'readonly' : '';
                                @endphp
                                <div class="form-group d-flex align-items-center">
                                    <div class="form-group col-md-">
                                        <span class="mr-3 pl-3" style="font-weight: 400;">
                                            {{ url('/') . '?corp=' }}
                                        </span>
                                    </div>
                                    <div class="form-group col-md-4">
                                        <input type="text" id="corp_value" name="corp_value" class="form-control" placeholder="Enter"
                                            value="{{ old('corp_value', $corp_value ?? '') }}" {{ $readonly }} />
                                    </div>    
                                </div>
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
</x-master-layout>
    <script>
        $(document).ready(function(){

            $('.hide-show-password').on('click', function() {
            var passwordInput = $('#password');
                var eyeIcon = $('.hide-show-password i');

                var passwordFieldType = passwordInput.attr('type');
                if (passwordFieldType === 'password') {
                    passwordInput.attr('type', 'text');
                    eyeIcon.removeClass('fa-eye-slash').addClass('fa-eye');
                } else {
                    passwordInput.attr('type', 'password');
                    eyeIcon.removeClass('fa-eye').addClass('fa-eye-slash');
                }
            });
            
          
            formValidation("#corporate_form", {
                first_name: { required: true },
                last_name: { required: true },
                email: { required: true, email: true },
                username: { required: true },
                // password: { required: true },
                contact_number: { required: true },
                company_name: { required: true },
                invoice_email: { required: true },
                companyid: { required: true },
                commission_type: { required: true },
                commission: { required: true },
                company_address: { required: true },
                corp_value: { required: true },
                VAT_number: { required: true },
            }, {
                first_name: { required: "{{__('message.please_enter_first_name')}}" },
                last_name: { required: "{{__('message.please_enter_last_name')}}" },
                email: { required: "{{__('message.please_enter_email')}}", email: "{{__('message.please_enter_valid_email')}}" },
                username: { required: "{{__('message.please_enter_username')}}" },
                // password: { required: "{{__('message.please_enter_password')}}" },
                contact_number: { required: "{{__('message.please_enter_contact_number')}}" },
                company_name: { required: "{{__('message.please_enter_company_name')}}" },
                invoice_email: { required: "{{__('message.please_enter_invoice_email')}}" },
                companyid: { required: "{{__('message.please_enter_companyid')}}" },
                commission_type: { required: "{{__('message.please_enter_commission_type')}}" },
                commission: { required: "{{__('message.please_enter_commission')}}" },
                company_address: { required: "{{__('message.please_enter_company_address')}}" },
                corp_value: { required: "{{__('message.please_enter_url')}}" },
                VAT_number: { required: "{{__('message.please_enter_vat_number')}}" },
            });
         });
    </script>
