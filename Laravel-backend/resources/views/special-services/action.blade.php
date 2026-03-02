
<?php
    $auth_user= authSession();
?>
{{ html()->form('DELETE', route('specialservices.destroy', $id))->attribute('data--submit', 'special' . $id)->open()}}

<div class="d-flex justify-content-end align-items-center">
    @if($auth_user->can('special_rate edit'))
    <a class="mr-2" href="{{ route('specialservices.edit', $id) }}" title="{{ __('message.update_form_title',['form' => __('message.special') ]) }}"><i class="fas fa-edit text-primary"></i></a>
    @endif
    
    @if($auth_user->can('special_rate delete'))
    <a class="mr-2 text-danger" href="javascript:void(0)" data--submit="special{{$id}}" 
        data--confirmation='true' data-title="{{ __('message.delete_form_title',['form'=> __('message.special') ]) }}"
        title="{{ __('message.delete_form_title',['form'=>  __('message.special') ]) }}"
        data-message='{{ __("message.delete_msg") }}'>
        <i class="fas fa-trash-alt"></i>
    </a>
    @endif
</div>
{!! html()->form()->close() !!}