<x-master-layout>
<div class="container-fluid">
    <div class="row">
        <div class="col-lg-12">
            <div class="card card-block card-stretch border-radius-20">
                <div class="card-body p-0">
                    <div class="d-flex justify-content-between align-items-center p-3">
                        <h5 class="font-weight-bold">{{ $pageTitle }}</h5>
                        <a href="{{ route('corporate.index') }}" class="float-right btn btn-sm btn-primary"><i class="fa fa-angle-double-left"></i> {{ __('message.back') }}</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="row">
        <div class="col-lg-12">
            <div class="card border-radius-20">
                <div class="card-body">
                    <ul class="nav nav-tabs" role="tablist">
                        <li class="nav-item">
                            <a href="{{ route('corporate.show',$data->id) }}" class="nav-link {{ $type == 'detail' ? 'active': '' }}"> {{ __('message.detail_form_title',['form'=>__('message.corporate')]) }} </a>
                        </li>
                        <li class="nav-item">
                            <a href="{{ route('corporate.show', [ $data->id, 'type' => 'ride_request']) }}" class="nav-link {{ $type == 'ride_request' ? 'active': '' }}"> {{ __('message.riderequest') }} </a>
                        </li>
                        <li class="nav-item">
                            <a href="{{ route('corporate.show', [ $data->id, 'type' => 'customer']) }}" class="nav-link {{ $type == 'customer' ? 'active': '' }}"> {{ __('message.customer') }} </a>
                        </li>
                        <li class="nav-item">
                            <a href="{{ route('corporate.show', [ $data->id, 'type' => 'driver']) }}" class="nav-link {{ $type == 'driver' ? 'active': '' }}"> {{ __('message.driver') }} </a>
                        </li>

                        <li class="nav-item">
                            <a href="{{ route('corporate.show', [ $data->id, 'type' => 'withdrawal_request']) }}" class="nav-link {{ $type == 'withdrawal_request' ? 'active': '' }}"> {{ __('message.withdrawal_request') }} </a>
                        </li>
                        <li class="nav-item">
                            <a href="{{ route('corporate.show', [ $data->id, 'type' => 'wallet']) }}" class="nav-link {{ $type == 'wallet' ? 'active': '' }}"> {{ __('message.wallet') }} </a>
                        </li>
                        <li class="nav-item">
                            <a href="{{ route('corporate.show', [ $data->id, 'type' => 'documents']) }}" class="nav-link {{ $type == 'documents' ? 'active': '' }}"> {{ __('message.documents') }} </a>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
        @if ( $type == 'detail' )
            <div class="col-lg-4">
                <div class="card card-block p-card border-radius-20">
                    <div class="profile-box">
                        <div class="profile-card border-radius-20">
                            <img src="{{ $profileImage }}" alt="01.jpg" class="avatar-100 rounded d-block mx-auto img-fluid mb-3">
                            <h3 class="font-600 text-white text-center mb-0">{{ $data->FullName }}</h3>
                            <p class="text-white text-center mb-5">

                                @php
                                    $status = 'warning';
                                    switch ($data->status) {
                                        case 'active':
                                            $status = 'success';
                                            break;
                                        case 'inactive':
                                            $status = 'danger';
                                            break;
                                        case 'banned':
                                            $status = 'dark';
                                            break;
                                    }
                                @endphp

                                <span class="text-capitalize badge bg-{{ $status }} ">{{ $data->status }}</span>
                            </p>
                        </div>
                        <div class="pro-content rounded border-radius-20">
                            <div class="d-flex align-items-center mb-3">
                                <div class="p-icon mr-3">
                                    <i class="fas fa-envelope"></i>
                                </div>
                                <p class="mb-0 eml">{{ maskSensitiveInfo('email', $data->email) }}</p>
                            </div>
                            <div class="d-flex align-items-center mb-3">
                                <div class="p-icon mr-3">
                                    <i class="fas fa-phone-alt"></i>
                                </div>
                                <p class="mb-0">{{ maskSensitiveInfo('contact_number', $data->contact_number) }}</p>
                            </div>
                            <div class="d-flex align-items-center mb-3">
                                <div class="p-icon mr-3">
                                    <i class="fa fa-code-branch"></i>
                                </div>
                                <p class="mb-0">{{ __('message.app_version') . ' : ' . (auth()->user()->hasRole('admin') ? ($data->app_version ? : '0') : '0')}}</p>
                            </div>
                            {{-- <div class="d-flex align-items-center mb-3">
                                <div class="p-icon mr-3">

                                    @if( $data->gender == 'female' )
                                        <i class="fas fa-female"></i>
                                    @elseif( $data->gender == 'other' )
                                        <i class="fas fa-transgender"></i>
                                    @else
                                        <i class="fas fa-male"></i>
                                    @endif
                                </div>
                                <p class="mb-0">{{ $data->gender }}</p>
                            </div> --}}
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-8">
                <div class="row">
                    <div class="col-lg-12">
                        <div class="row">
                            <div class="col-md-12">
                                <div class="card border-radius-20">
                                    <div class="card-header d-flex justify-content-between align-items-center">
                                        <h4 class="card-title mb-0">{{ __('message.company_info') }}</h4>
                                    </div>
                                    <div class="card-body">
                                        <div class="row">
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.company_name') }}</h5>
                                                <p class="mb-0">{{ $data->FullName ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.company_type') }}</h5>
                                                <p class="mb-0">{{ optional($data->CompanyType)->name ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.companyid') }}</h5>
                                                <p class="mb-0">{{ $data->companyid ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.invoice_email') }}</h5>
                                                <p class="mb-0">{{ $data->invoice_email ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.commission_type') }}</h5>
                                                <p class="mb-0">{{ $data->commission_type ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.commission') }}</h5>
                                                <p class="mb-0">{{ $data->commission ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.vat_number') }}</h5>
                                                <p class="mb-0">{{ $data->bank_iban ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.url') }}</h5>
                                                <p class="mb-0"> {{ url('/') . '?corp=' }}{{ $data->url ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.company_address') }}</h5>
                                                <p class="mb-0">{{ $data->company_address ?? '-' }}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="card border-radius-20">
                                    <div class="card-header d-flex justify-content-between align-items-center">
                                        <h4 class="card-title mb-0">{{ __('message.bank_info') }}</h4>
                                    </div>
                                    <div class="card-body">
                                        <div class="row">
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_name') }}</h5>
                                                <p class="mb-0">{{ $data->user ? optional($data->user->userBankAccount)->bank_name ?? '-' : '' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_code') }}</h5>
                                                <p class="mb-0">{{ $data->user ? optional($data->user->userBankAccount)->bank_code ?? '-' : '' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.account_holder_name') }}</h5>
                                                <p class="mb-0">{{ $data->user ? optional($data->user->userBankAccount)->account_holder_name ?? '-' : '' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.account_number') }}</h5>
                                                <p class="mb-0">{{ $data->user ? optional($data->user->userBankAccount)->account_number ?? '-' : '' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_address') }}</h5>
                                                <p class="mb-0">{{ $data->user ? optional($data->user->userBankAccount)->bank_address ?? '-' : '' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.routing_number') }}</h5>
                                                <p class="mb-0">{{ $data->user ? optional($data->user->userBankAccount)->routing_number ?? '-' : '' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_iban') }}</h5>
                                                <p class="mb-0">{{ $data->user ? optional($data->user->userBankAccount)->bank_iban ?? '-' : '' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_swift') }}</h5>
                                                <p class="mb-0">{{ $data->user ? optional($data->user->userBankAccount)->bank_swift ?? '-' : '' }}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            {{-- <div class="col-lg-8">
                <div class="row">
                    <div class="col-lg-12">
                        <div class="row">
                            <div class="col-md-12">
                                <div class="card border-radius-20">
                                    <div class="card-header d-flex justify-content-between align-items-center">
                                        <h4 class="card-title mb-0">{{ __('message.detail_form_title', [ 'form' => __('message.bank') ]) }}</h4>
                                    </div>
                                    <div class="card-body">
                                        <div class="row">
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_name') }}</h5>
                                                <p class="mb-0">{{ optional($data->userBankAccount)->bank_name ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_code') }}</h5>
                                                <p class="mb-0">{{ optional($data->userBankAccount)->bank_code ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.account_holder_name') }}</h5>
                                                <p class="mb-0">{{ optional($data->userBankAccount)->account_holder_name ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.account_number') }}</h5>
                                                <p class="mb-0">{{ optional($data->userBankAccount)->account_number ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_address') }}</h5>
                                                <p class="mb-0">{{ optional($data->userBankAccount)->bank_address ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.routing_number') }}</h5>
                                                <p class="mb-0">{{ optional($data->userBankAccount)->routing_number ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_iban') }}</h5>
                                                <p class="mb-0">{{ optional($data->userBankAccount)->bank_iban ?? '-' }}</p>
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <h5>{{ __('message.bank_swift') }}</h5>
                                                <p class="mb-0">{{ optional($data->userBankAccount)->bank_swift ?? '-' }}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div> --}}
        @endif
        @if ( $type == 'ride_request' )
            <div class="col-md-12">
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.list_form_title', [ 'form' => __('message.riderequest') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        {{ $dataTable->table(['class' => 'table  w-100'],false) }}
                    </div>
                </div>
            </div>
        @endif
        @if ( $type == 'customer' )
            <div class="col-md-12">
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.list_form_title', [ 'form' => __('message.customer') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        {{ $dataTable->table(['class' => 'table  w-100'],false) }}
                    </div>
                </div>
            </div>
        @endif
        @if ( $type == 'driver' )
            <div class="col-md-12">
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.list_form_title', [ 'form' => __('message.driver') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        {{ $dataTable->table(['class' => 'table  w-100'],false) }}
                    </div>
                </div>
            </div>
        @endif
        @if ( $type == 'withdrawal_request' )
            <div class="col-md-12">
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.list_form_title', [ 'form' => __('message.withdrawal_request') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        {{ $dataTable->table(['class' => 'table  w-100'],false) }}
                    </div>
                </div>
            </div>
        @endif
        @if( $type == 'wallet' )
            <div class="col-md-4">
                <div class="row">
                    <div class="col-md-12">
                        <div class="card card-block border-radius-20">
                            <div class="card-body">
                                <div class="top-block-one">                                
                                    <p class="mb-1">{{ __('message.wallet_balance') }}</p>
                                    <p></p>
                                    <h5>{{ $data->user ? getPriceFormat(optional($data->user->userWallet)->total_amount) ?? 0 : '' }} </h5>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.add_form_title', [ 'form' => __('message.wallet') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        {!! html()->form('POST', route('savewallet.fund', $data->user_id))->open() !!}
                            <div class="row">
                                <div class="form-group col-md-4">
                                    {!! html()->label(__('message.type') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('type') !!}
                                    {!! html()->select('type', [
                                            'credit' => __('message.credit'),
                                            'debit' => __('message.debit')
                                        ], old('type'))->class('form-control select2js')->required() !!}
                                </div>
                                
                                <div class="form-group col-md-8">
                                    {!! html()->label(__('message.transaction_type') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('transaction_type') !!}
                                    {!! html()->select('transaction_type', [], old('transaction_type'))->class('form-control select2js')->required() !!}
                                </div>
                                
                                <div class="form-group col-md-12">
                                    {!! html()->label(__('message.amount') . ' <span class="text-danger">*</span>')->class('form-control-label')->for('amount') !!}
                                    {!! html()->number('amount', old('amount'))->class('form-control')->attribute('min', 0)->attribute('step', 'any')->required()->placeholder(__('message.amount')) !!}
                                </div>
                                
                                <div class="form-group col-md-12">
                                    {!! html()->label(__('message.description'))->class('form-control-label')->for('description') !!}
                                    {!! html()->textarea('description', old('description'))->class('form-control textarea')->rows(2)->placeholder(__('message.description')) !!}
                                </div>
                            </div>
                            <hr>
                            {!! html()->submit(__('message.save'))->class('btn btn-md btn-primary float-right') !!}
                        {!! html()->form()->close() !!}
                    </div>
                </div>
            </div>
            <div class="col-md-8">
                <div class="card card-block border-radius-20">
                    <div class="card-header d-flex justify-content-between">
                        <div class="header-title">
                            <h4 class="card-title mb-0">{{ __('message.list_form_title', [ 'form' => __('message.wallethistory') ]) }}</h4>
                        </div>
                    </div>
                    <div class="card-body">
                        {{ $dataTable->table(['class' => 'table  w-100'],false) }}
                    </div>
                </div>
            </div>
        @endif
        @if( $type == 'documents' )
        <div class="col-md-12">
            <div class="card card-block border-radius-20">
                <div class="card-header d-flex justify-content-between">
                    <div class="header-title">
                        <h4 class="card-title mb-0">{{ $pageTitle }}</h4>
                    </div>
                </div>
                <div class="card-body">
                    <table class="table table-bordered table-striped table-hover" id="basic-table">
                        <thead>
                            <tr>
                                <th scope='col'>{{ __('message.id') }}</th>
                                <th scope='col'>{{ __('message.name') }}</th>
                                <th scope='col'>{{ __('message.document') }}</th>
                                <th scope='col'>{{ __('message.action') }}</th>
                            </tr>
                        </thead>
                        <tbody>
                            @if(count($documents) > 0)
                            @foreach($documents as $key => $doc)
                                <tr>
                                    <td>{{ $key + 1 }}</td>
                                    <td>{{ $doc->name }}</td>
                                    <td>
                                        @if(getMediaFileExit($doc, 'corporate_document'))
                                            <a href="{{ getSingleMedia($doc, 'corporate_document') }}" target="_blank">{{ __('message.view') }}</a>
                                        @else
                                            -
                                        @endif
                                    </td>
                                    <td>
                                        <form id="document{{ $doc->id }}" action="{{ route('corporate-document.delete', $doc->id) }}" method="POST" onsubmit="return confirm('{{ __('message.delete_form_title', ['form' => __('message.document')]) }}')" class="d-none">
                                            @csrf
                                            @method('DELETE')
                                        </form>
                                        <a href="javascript:void(0)" class="text-danger"
                                            data--submit="document{{ $doc->id }}"
                                            data-message="{{ __('message.delete_msg') }}">
                                            <i class="fas fa-trash-alt"></i>
                                        </a>
                                    </td>
                                </tr>
                                @endforeach
                                @else
                                <tr>
                                    <td colspan="5"  class="text-center text-muted">{{ __('message.no_record_found') }}</td>
                                </tr>
                                @endif
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        @endif
    </div>
</div>
@section('bottom_script')
{{ in_array($type,['ride_request','customer','driver','wallet','withdrawal_request']) ? $dataTable->scripts() : '' }}
<script type="text/javascript">
    $("#basic-table").DataTable({
        "dom":  '<"row align-items-center"<"col-md-2"><"col-md-6" B><"col-md-4"f>><"table-responsive my-3" rt><"d-flex" <"flex-grow-1" l><"p-2" i><"mt-4" p>><"clear">',
        "order": [[0, "desc"]]
    });
        (function($) {
            "use strict";
            $(document).ready(function() {
                
                var type = $("#type :selected").val();
                transactionTypeList(type);
                $(document).on('change', '#type' , function (){
                    var type = $("#type :selected").val();
                    $('#transaction_type').empty();
                    transactionTypeList(type);
                })
            })

            function transactionTypeList(type) {
                var route = "{{ route('ajax-list',['type' => 'transaction_type','user_type' => 'rider', 'type_val' =>'']) }}"+type;
                route = route.replaceAll('amp;','');
                
                $.ajax({
                    url: route,
                    success: function(result){
                        $('#transaction_type').select2({
                            width : '100%',
                            placeholder: "{{ __('message.select_name',['select' => __('message.transaction_type')]) }}",
                            data: result.results
                        });
                        if(type != null ){
                            $("#transaction_type").val(type).trigger('change');
                        }
                    }
                })
            }
        })(jQuery);

        $(document).on('click', '[data--submit]', function (e) {
        e.preventDefault();
        var formId = $(this).attr('data--submit');
        var message = $(this).attr('data-message') || 'Are you sure you want to delete this?';

        if ($(this).attr('data--confirmation') === 'true') {
            if (confirm(message)) {
                $('#' + formId).submit();
            }
        } else {
            $('#' + formId).submit();
        }
    });
    </script>
@endsection
</x-master-layout>
