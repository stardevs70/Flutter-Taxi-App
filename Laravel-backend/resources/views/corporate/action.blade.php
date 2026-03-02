
<?php
    $auth_user= authSession();
?>
{{ html()->form('DELETE', route('corporate.destroy', $id))->attribute('data--submit', 'corporate' . $id)->open()}}
<div class="d-flex justify-content-end align-items-center">
    @if($auth_user->can('corporate-edit'))
    <a class="mr-2" href="{{ route('corporate.edit', $id) }}" title="{{ __('message.update_form_title',['form' => __('message.corporate') ]) }}"><i class="fas fa-edit text-primary"></i></a>
    @endif

    @if($auth_user->can('corporate-show'))
        <a class="mr-2" href="{{ route('corporate.show',$id) }}"><i class="fas fa-eye text-secondary"></i></a>
    @endif

    @if($auth_user->can('corporate-delete'))
    <a class="mr-2 text-danger" href="javascript:void(0)" data--submit="corporate{{$id}}" 
        data--confirmation='true' data-title="{{ __('message.delete_form_title',['form'=> __('message.corporate') ]) }}"
        title="{{ __('message.delete_form_title',['form'=>  __('message.corporate') ]) }}"
        data-message='{{ __("message.delete_msg") }}'>
        <i class="fas fa-trash-alt"></i>
    </a>
    @endif
</div>
{!! html()->form()->close() !!}