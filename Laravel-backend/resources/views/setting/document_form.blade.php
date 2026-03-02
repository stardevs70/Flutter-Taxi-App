<div class="row mt-4">
    <div class="col-md-12">
        <h5>{{ __('message.list_form_title',['form' => __('message.document')]) }}</h5>
        <a href="{{ route('corporate.document.form') }}" class="loadRemoteModel float-right btn btn-sm border-radius-10 btn-primary me-2"><i class="fa fa-plus-circle"></i>{{ __('message.add_form_title',[ 'form' => __('message.document')]) }}</a>

        <table class="table table-bordered table-striped table-hover">
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
                        <td colspan="6" class="text-center text-muted">{{ __('message.no_record_found') }}</td>
                    </tr>
                    @endif
            </tbody>
        </table>
    </div>
</div>
<script>
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
