<?php

namespace App\DataTables;

use App\Models\ManageCancelledReason;
use Yajra\DataTables\Html\Button;
use Yajra\DataTables\Html\Column;
use Yajra\DataTables\Html\Editor\Editor;
use Yajra\DataTables\Html\Editor\Fields;
use Yajra\DataTables\Services\DataTable;

use App\Traits\DataTableTrait;

class ManageCancelledResonDataTable extends DataTable
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
            ->editColumn('created_at', function ($query) {
                return dateAgoFormate($query->created_at, true);
            })
            ->editColumn('type', function ($query) {
                return isset($query->type) ? $query->type : '-';
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
            ->addColumn('action', function($row){
                $id = $row->id;
                return view('manage-cancelreson.action',compact('id'))->render();
            })
            ->rawColumns(['action','status']);
    }

    /**
     * Get query source of dataTable.
     *
     * @param \App\Models\ManageCancelledReason $model
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function query()
    {
        $model = ManageCancelledReason::query();

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
                Column::make('type')->title( __('message.type') ),
            Column::make('reason')->title( __('message.name') ),
            Column::make('created_at')->title( __('message.created_at') ),
            Column::computed('action')
                  ->exportable(false)
                  ->printable(false)
                  ->width(60)
                  ->addClass('text-center'),
        ];
    }
}
