<?php

namespace App\DataTables;

use App\Models\SpecialServices;
use Yajra\DataTables\Html\Button;
use Yajra\DataTables\Html\Column;
use Yajra\DataTables\Html\Editor\Editor;
use Yajra\DataTables\Html\Editor\Fields;
use Yajra\DataTables\Services\DataTable;

use App\Traits\DataTableTrait;

class SpecialServicesDataTable extends DataTable
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
            ->editColumn('service_id' , function ( $service ) {
                return $service->service_id != null ? optional($service->service)->name : '';
            })
            ->editColumn('created_at', function ($query) {
                return dateAgoFormate($query->created_at, true);
            })
            ->editColumn('special_amount', function ( $row ) {
                return getPriceFormat($row->special_amount);
            })
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
            ->addIndexColumn()
            ->addColumn('action', 'special-services.action')
            ->rawColumns([ 'action' ]);
    }

    /**
     * Get query source of dataTable.
     *
     * @param \App\Models\SpecialServices $model
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function query()
    {
        $model = SpecialServices::query();
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
            Column::make('service_id')->title( __('message.service') ),
            Column::make('base_fare')->title( __('message.base_fare') ),
            Column::make('created_at')->title( __('message.created_at') ),
            Column::computed('action')
                  ->exportable(false)
                  ->printable(false)
                  ->width(60)
                  ->addClass('text-center'),
        ];
    }
}
