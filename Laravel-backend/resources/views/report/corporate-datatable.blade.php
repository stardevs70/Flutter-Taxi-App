<x-master-layout>
    <div class="container-fluid">
        <div class="row">
            <div class="col-lg-12">
                <div class="card card-block card-stretch card-height border-radius-20">
                    <div class="card-header d-flex flex-sm-nowrap flex-wrap justify-content-between align-items-center">
                        <div class="header-title w-100">
                            <h4 class="card-title mb-0">{{ $pageTitle ?? ''}}</h4>
                        </div>
                        <div class="d-flex justify-content-end w-100 flex-wrap mt-sm-0 mt-3">
                            <div class="dropdown">
                                <button class="btn btn-primary btn-sm border-radius-10 dropdown-toggle me-2" type="button" id="exportDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                                    <i class="fas fa-file-export"></i> {{ __('message.export') }}
                                </button>
                                <ul class="dropdown-menu border-radius-10" aria-labelledby="exportDropdown">
                                    <li><a class="dropdown-item text-decoration-none border-radius-10" href="#" id="export-csv"><i class="fas fa-file-csv"></i> {{__('message.excel')}}</a></li>
                                    <li><a class="dropdown-item text-decoration-none border-radius-10" href="#" id="export-pdf"><i class="fas fa-file-pdf"></i> {{__('message.pdf')}}</a></li>
                                </ul>
                            </div>
                            <button class="btn btn-warning btn-sm border-radius-10 ml-2" type="button" id="openFilterModal" data-bs-toggle="modal" data-bs-target="#filterModal">
                                <i class="fas fa-filter"></i> {{ __('message.filter') }}
                            </button>
                        </div>
                    </div>

                    <div class="card-body table-responsive">
                        <table id="basic-table" class="table table-hover mb-1 text-center" role="grid">
                            <thead>
                                <tr>
                                    <th scope='col'>{{ __('message.name') }}</th>
                                    <th scope='col'>{{ __('message.email') }}</th>
                                    <th scope='col'>{{ __('message.contact_number') }}</th>
                                    <th scope='col'>{{ __('message.company_name') }}</th>
                                    <th scope='col'>{{ __('message.company_type') }}</th>
                                    <th scope='col'>{{ __('message.companyid') }}</th>
                                    <th scope='col'>{{ __('message.invoice_email') }}</th>
                                    <th scope='col'>{{ __('message.commission_type') }}</th>
                                    <th scope='col'  class="text-center">{{ __('message.commission') }}</th>
                                    <th scope='col'>{{ __('message.vat_number') }}</th>
                                    <th scope='col'>{{ __('message.created_at') }}</th>
                                </tr>
                            </thead>
                            <tfoot>
                                <tr>
                                    <td colspan="2" class="font-weight-700">{{ __('message.total_amount') }}</td>
                                    <td></td>
                                    <td></td>
                                    <td></td>
                                    <td></td>
                                    <td></td>
                                    <td></td>
                                    <td id="total-admin-commission" class="font-weight-700">0.00</td>
                                    <td></td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    @include('report.corporate-filter')

    @section('bottom_script')
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
        <script>
            $(document).ready(function() {
                $('.select2').select2({
                    dropdownParent: $('#filterModal'),
                });
                const table = $('#basic-table').DataTable({
                    processing: true,
                    serverSide: true,
                    searching: false,
                    ajax: {
                        url: '{{ route("corporate.report") }}',
                        data: function(d) {
                            d.from_date = $('#from_date_main').val();
                            d.to_date = $('#to_date_main').val();
                            d.company_type_id = $('#company_type_id').val();
                            console.log(d.from_date);
                        },
                        
                        dataSrc: function (json) {
                            // Update the totals in the footer
                            $('#total-admin-commission').html(json.totalAdminCommission.toFixed(2));
                            return json.data; // Ensure this is returning an array of data
                        }
                    },
                    columns: [
                        { data: 'corporate_display_name', defaultContent: '-' },
                        { data: 'email', defaultContent: '-' },
                        { data: 'contact_number', defaultContent: '-' },
                        { data: 'company_name', defaultContent: '-' },
                        { data: 'company_type_id', defaultContent: '-' },
                        { data: 'companyid', defaultContent: '-' },
                        { data: 'invoice_email', defaultContent: '-' },
                        { data: 'commission_type', defaultContent: '-' },
                        { data: 'commission', defaultContent: '-' },
                        { data: 'VAT_number', defaultContent: '-' },
                        { data: 'created_at', defaultContent: '-' }
                    ]
                });

                $('#corporate_report_filter_form').on('submit', function(e) {
                    e.preventDefault();
                    $('#basic-table').DataTable().ajax.reload();
                });
                // $('#apply_filter').on('click', function(e){
                //     $('#filterModal').modal('hide');
                // });
        
                $('#reset-filter-btn').on('click', function() {
                    $('#from_date_main').val('').trigger('change');
                    $('#to_date_main').val('').trigger('change');
                    $('#company_type_id').val('').trigger('change');

                    $('#basic-table').DataTable().ajax.reload();
                });
        
                $('#export-csv').on('click', function(e) {
                    e.preventDefault();
                    const fromDate = $('#from_date_main').val() || '';
                    const toDate = $('#to_date_main').val() || '';
                    const companytypeid = $('#company_type_id').val() || '';
                    const exportUrl = `{{ route('download.corporate.report') }}?from_date=${fromDate}&to_date=${toDate}&company_type_id=${companytypeid}`;
                    window.location.href = exportUrl;
                });
        
                $('#export-pdf').on('click', function(e) {
                    e.preventDefault();
                    const fromDate = $('#from_date_main').val() || '';
                    const toDate = $('#to_date_main').val() || '';
                    const companytypeid = $('#company_type_id').val() || '';
                    const exportUrl = `{{ route('download.corporate.report.pdf') }}?from_date=${fromDate}&to_date=${toDate}&company_type_id=${companytypeid}`;
                    window.location.href = exportUrl;
                });
            });
            
            
        </script>
    @endsection
</x-master-layout>
