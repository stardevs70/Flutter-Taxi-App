<div class="modal-dialog modal-xl" role="document">
    <div class="modal-content">
        <div class="modal-header">
            <h5 class="modal-title" id="exampleModalLabel">{{ $title }}</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
            </button>
        </div>
        <div class="modal-body">
            <div class="row">
                <div class="col-md-12">
                    <table class="table dataTable table-responsive-sm">
                        <tbody>
                            @foreach ($changes['new'] as $key => $newValue)
                                @php
                                    $oldValue = $changes['old'][$key] ?? '(empty)';
                                @endphp
                                <tr>
                                    <td><strong>{{ ucfirst(str_replace('_', ' ', $key)) }}</strong></td>
                                    <td><strong>:</strong></td>
                                    <td>
                                        <span class="text-danger">{{ $oldValue }}</span>
                                        →
                                        <span class="text-success">{{ $newValue }}</span>
                                    </td>
                                </tr>
                            @endforeach
                            @if(empty($changes['new']))
                                <tr><td colspan="3"><em>No changes recorded</em></td></tr>
                            @endif
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn btn-md btn-secondary" data-dismiss="modal">{{ __('message.close') }}</button>
        </div>
    </div>
</div>