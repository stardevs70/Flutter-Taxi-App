<?php

namespace App\DataTables;

use App\Models\Service;
use Yajra\DataTables\Html\Button;
use Yajra\DataTables\Html\Column;
use Yajra\DataTables\Html\Editor\Editor;
use Yajra\DataTables\Html\Editor\Fields;
use Yajra\DataTables\Services\DataTable;

use App\Traits\DataTableTrait;

class ServiceDataTable extends DataTable
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

            ->editColumn('name', function ($query) {
                return '<a href="'.route('service.show',$query->id).'">'.$query->name.'</span></a>';
            })

            ->editColumn('service_type', function ($query) {
                return isset($query->service_type) ? __('message.'.$query->service_type) : '-';
            })
            
            ->editColumn('region_id' , function ( $service ) {
                return $service->region_id != null ? optional($service->region)->name : '';
            })

            ->filterColumn('region_id', function( $query, $keyword ){
                $query->whereHas('region', function ($q) use($keyword){
                    $q->where('name', 'like' , '%'.$keyword.'%');
                });
            })
            ->editColumn('created_at', function ($query) {
                return dateAgoFormate($query->created_at, true);
            })
            ->editColumn('commission_type', function ($query) {
                return ucfirst($query->commission_type);
            })
          ->editColumn('payment_method', function ($query) {
                $methods = is_array($query->payment_method) ? $query->payment_method : [];

                if (empty($methods)) {
                    return '-';
                }

                return implode(' or ', array_map(fn($m) => ucfirst(str_replace('_', ' ', $m)), $methods));
            })
            ->addIndexColumn()
            ->addColumn('action', 'service.action')
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
            ->rawColumns([ 'action','name' ]);
    }

    /**
     * Get query source of dataTable.
     *
     * @param \App\Models\Service $model
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function query()
    {
        $model = Service::query();
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
            Column::make('region_id')->title( __('message.region') ),
            Column::make('service_type')->title( __('message.service_type') ),
            Column::make('base_fare')->title( __('message.base_fare') ),
            Column::make('payment_method'),
            Column::make('commission_type'),
            Column::make('created_at')->title( __('message.created_at') ),
            Column::computed('action')
                  ->exportable(false)
                  ->printable(false)
                  ->width(60)
                  ->addClass('text-center'),
        ];
    }
}
