<?php
    $auth_user= authSession();
?>
<div class="d-flex justify-content-end align-items-center">
            @if($auth_user->can('company_type-edit'))
            <a class="mr-2 jqueryvalidationLoadRemoteModel" href="{{ route('comapanytype.edit', $id) }}" title="{{ __('message.update_form_title',['form' => __('message.company_type') ]) }}"><i class="fas fa-edit text-primary"></i></a>
            @endif

            @if($auth_user->can('company_type-delete'))
                {{ html()->form('DELETE', route('comapanytype.destroy', $id))->attribute('data--submit', 'comapanytype'.$id)->open() }}
                    <a class="mr-2 text-danger" href="javascript:void(0)" data--submit="comapanytype{{$id}}"
                        data--confirmation='true' data-title="{{ __('message.delete_form_title',['form'=> __('message.company_type') ]) }}"
                        title="{{ __('message.delete_form_title',['form'=>  __('message.company_type') ]) }}"
                        data-message='{{ __("message.delete_msg") }}'>
                        <i class="fas fa-trash-alt"></i>
                    </a>
                {{ html()->form()->close() }}
            @endif
</div>
