<!-- Modal -->

<div class="modal-dialog" role="document">
    <div class="modal-content">
        <div class="modal-header">
            <h5 class="modal-title" id="exampleModalLabel">{{ $title }}</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
            </button>
        </div>
        @if (isset($id))
            {{ html()->form('POST',route('update.supplier.payout'))->open() }}
            {{ html()->hidden('id',$id) }}
        @endif
        <div class="modal-body">
            {{ html()->hidden('fleet_fare')->id('fleet_fare_modal') }}
            {{ html()->hidden('main_fleet_fare', $fleet_fare)->id('main_fleet_fare') }}
            <table class="table table-borderless">
                <tbody>
                    <tr>
                        <th>{{ __('message.base_fare') }}{!! isset($id) ? ' <span class="text-danger">*</span>' : '' !!}</th>
                        <td>{{ html()->number('base_fare', ($request->estimate_type != 'update' ? $fleet_fare : $request->base_fare) ?? old('base_fare'))->class('form-control')->attribute('min',0)->placeholder(__('message.base_fare')) }}</td>
                    </tr>
                    <tr class="border-bottom">
                        <th>{{ __('message.surcharge') }}</th>
                        <td>{{ html()->number('surcharge', $request->surcharge ?? old('surcharge'))->class('form-control')->attribute('min',0)->placeholder(__('message.surcharge')) }}</td>
                    </tr>
                    <tr>
                        <th>{{ __('message.sub_total') }}</th>
                        <td><span id="sub_total" class="font-weight-bold">0.00</span></td>
                    </tr>
                    <tr>
                        <th>{{ __('message.discount') }}</th>
                        <td>{{ html()->number('discount', $request->discount ?? old('discount'))->class('form-control')->attribute('min',0)->placeholder(__('message.discount')) }}</td>
                    </tr>
                    <tr>
                        <th>{{ __('message.total') }}</th>
                        <td><span id="total">0.00</span></td>
                    </tr>
                </tbody>
            </table>
            <div class="form-group col-md-12">
                {{ html()->label(__('message.reason'),'reason')->class('form-control-label') }}
                {{ html()->textarea('reason', $request->reason ?? old('reason'))->id('estimate_reason')->class('form-control')->placeholder(__('message.reason')) }}
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ __('message.close') }}</button>
            @if(isset($id))
                <button type="submit" class="btn border-radius-10 btn-primary" id="btn_submit" data-form="ajax" >{{ __('message.save') }}</button>
                {{ html()->form()->close() }}
            @else
                <button type="submit" class="btn btn-primary" id="btn_submit" data-dismiss="modal">{{ __('message.save') }}</button>
            @endif
        </div>
    </div>
</div>
<script>
    $(".select2js").select2({
        width: "100%",
        tags: true
    });
    $(document).ready(function() {
        function calculateTotal() {
            const base_fare = parseFloat($('#base_fare').val()) || 0;
            const surcharge = parseFloat($('#surcharge').val()) || 0;
            const sub_total = base_fare + surcharge;
            const discount = parseFloat($('#discount').val()) || 0;
            const total = sub_total - discount;
            
            $('#sub_total').text(getFormatPrice(sub_total));
            $('#total').text(getFormatPrice(total));        
            $('#fleet_fare_modal').val(total.toFixed(2));        
        }
        
        $('#base_fare, #surcharge, #discount').on('input change', calculateTotal);
        calculateTotal();

        // $('#cancelled_reason_id').on('change', function () {
        //     const selected_option = $(this).select2('data')[0];
        //     if (selected_option) $('#estimate_reason').val(selected_option.text);
        // });

        $('#btn_submit').on('click', function() {
            const fleetFare = $('#fleet_fare_modal').val();            
            $('#fleet_fare').text(fleetFare);
            $('#fleet_fare_change').text('{{ $fleet_fare }}');

            var base_fare = $('#base_fare').val();
            var surcharge = $('#surcharge').val();
            var discount = $('#discount').val();
            var main_fleet_fare = $('#main_fleet_fare').val();
            var estimate_reason = $('#estimate_reason').val();

            $('#estimate_fleet_fare').val(main_fleet_fare);
            $('#modal_base_fare').val(base_fare);
            $('#modal_surcharge').val(surcharge);
            $('#modal_discount').val(discount);
            //$('#data_model_estimate_type').val('update');
            $('#data_model_estimate_type').val('');
            $('#reason').val(estimate_reason);
            $('.total_amount').val(fleetFare);

            const supplier_payout_route = "{{ route('supplier.payout') }}" + "?fleet_fare=" + main_fleet_fare + "&base_fare=" + base_fare + "&surcharge=" + surcharge +"&discount=" + discount + "&estimate_type=" + 'update' +"&reason=" + estimate_reason;

            // ride request show data
            var data_id = '{{ $id }}';
            if ( data_id ) {
                $('.view_base_fare').text(getFormatPrice(base_fare));
                $('.view_surcharge').text(getFormatPrice(surcharge));
                $('.view_discount').text(getFormatPrice(discount));
                $('.view_reason').text(estimate_reason);
                $('.view_total_amount').text(getFormatPrice(fleetFare));                
                $('.view_supplier_payout_btn').attr('href',supplier_payout_route + "&id=" + data_id);
            }

            $('.supplier_payout_btn').attr('href',supplier_payout_route);
        });
    });
</script>

