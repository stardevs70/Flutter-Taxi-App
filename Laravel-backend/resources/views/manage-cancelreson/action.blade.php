<?php
    $auth_user= authSession();
?>
<div class="d-flex justify-content-end align-items-center">
    @if($auth_user->can('cancelled_reason-edit'))
    <a class="mr-2 jqueryvalidationLoadRemoteModel" href="{{ route('cancelledreason.edit', $id) }}" title="{{ __('message.update_form_title',['form' => __('message.manage_cancelled_reason') ]) }}"><i class="fas fa-edit text-primary"></i></a>
    @endif

    @if($auth_user->can('cancelled_reason-delete'))
        {{ html()->form('DELETE', route('cancelledreason.destroy', $id))->attribute('data--submit', 'cancelledreason'.$id)->open() }}
            <a class="mr-2 text-danger" href="javascript:void(0)" data--submit="cancelledreason{{$id}}"
                data--confirmation='true' data-title="{{ __('message.delete_form_title',['form'=> __('message.manage_cancelled_reason') ]) }}"
                title="{{ __('message.delete_form_title',['form'=>  __('message.manage_cancelled_reason') ]) }}"
                data-message='{{ __("message.delete_msg") }}'>
                <i class="fas fa-trash-alt"></i>
            </a>
        {{ html()->form()->close() }}
    @endif
</div>
