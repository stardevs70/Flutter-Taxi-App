<?php

namespace App\DataTables;

use App\Models\Corporate;
use Yajra\DataTables\Html\Button;
use Yajra\DataTables\Html\Column;
use Yajra\DataTables\Html\Editor\Editor;
use Yajra\DataTables\Html\Editor\Fields;
use Yajra\DataTables\Services\DataTable;

use App\Traits\DataTableTrait;

class CorporateDataTable extends DataTable
{
    use DataTableTrait;
    /**
     * Build DataTable class.
     *
     * @param mixed $query Results from query() method.
     * @return \Yajra\DataTables\DataTableAbstract
     */
    public function dataTable($query)
    {
        return datatables()
            ->eloquent($query)
            
            ->editColumn('status', function($query) {
                $status = 'warning';
                switch ($query->status) {
                    case 'active':
                        $status = 'primary';
                        break;
                    case 'inactive':
                        $status = 'danger';
                        break;
                    case 'banned':
                        $status = 'dark';
                        break;
                }
                return '<span class="text-capitalize text-' .$status .' badge badge-light-'.$status.'">'.$query->status.'</span>';
            })
            ->addColumn('name', function ($query) {
                return '<a href="'.route('corporate.show',$query->id).'">'.$query->full_name.'</span></a>';
            })
            ->editColumn('company_type_id' , function ( $company_type ) {
                return $company_type->company_type_id != null ? optional($company_type->CompanyType)->name : '';
            })        
          
            ->editColumn('email', function($query) {
                return auth()->user()->hasRole('admin') ? $query->email : maskSensitiveInfo('email', $query->email);
            })
            ->editColumn('contact_number' , function ( $query ) {
                // return $query->country_code . $query->contact_number;
                return maskSensitiveInfo('contact_number', $query->contact_number);
            })
            ->editColumn('commission', function ( $row ) {
                return getPriceFormat( $row->commission) ?? '-';
            })
            ->editColumn('email', function($query) {
                return auth()->user()->hasRole('admin') ? maskSensitiveInfo('email', $query->email) : maskSensitiveInfo('email', $query->email);
            })
            // ->editColumn('url', function ($query) {
            //     return $query->url
            //         ? '<a href="' . $query->url . '" target="_blank">' . $query->url . '</a>'
            //         : '-';
            // })
            ->editColumn('url', function ($query) {
                $url = $query->url;
                if (!$url) {
                    return '-';
                }
                $fullUrl = url('/') . '?corp=' . $url;
                return '<a href="' . $fullUrl . '" target="_blank">' . $fullUrl . '</a>';
            })
            
            ->editColumn('created_at', function ($query) {
                return dateAgoFormate($query->created_at, true);
            })
            ->addIndexColumn()
            ->addColumn('action', 'corporate.action')
            ->order(function ($query) {
                if (request()->has('order')) {
                    $order = request()->order[0];
                    $column_index = $order['column'];

                    $column_name = 'created_at';
                    $direction = 'desc';
                    if( $column_index != 0) {
                        $column_name = request()->columns[$column_index]['data'];
                        $direction = $order['dir'];
                    }
    
                    $query->orderBy($column_name, $direction);
                }
            })
            ->rawColumns(['action','status','url','name']);
    }

    /**
     * Get query source of dataTable.
     *
     * @param \App\Models\Corporate $model
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function query()
    {
        $model = Corporate::query();
        return $this->applyScopes($model);
    }

    /**
     * Get columns.
     *
     * @return array
     */
    protected function getColumns()
    {
        return [
            Column::make('DT_RowIndex')
                ->searchable(false)
                ->title(__('message.srno'))
                ->orderable(false)
                ->width(60),
            Column::make('name')->title( __('message.name') ),
            Column::make('email')->title( __('message.email') ),
            Column::make('contact_number')->title( __('message.contact_number') ),
            Column::make('company_name')->title( __('message.company_name') ),
            Column::make('company_type_id')->title( __('message.company_type') ),
            Column::make('companyid')->title( __('message.companyid') ),
            Column::make('invoice_email')->title( __('message.invoice_email') ),
            Column::make('url')->title( __('message.url') ),
            Column::make('commission_type')->title( __('message.commission_type') ),
            Column::make('commission')->title( __('message.commission') ),
            Column::make('VAT_number')->title( __('message.vat_number') ),
            Column::make('created_at')->title( __('message.created_at') ),
            Column::make('status'),
            Column::computed('action')
                  ->exportable(false)
                  ->printable(false)
                  ->width(60)
                  ->addClass('text-center'),
        ];
    }
}
