<?php

namespace App\Exports;

use App\Models\Corporate;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use Maatwebsite\Excel\Concerns\WithEvents;
use Maatwebsite\Excel\Events\AfterSheet;

class CorporateExport implements FromCollection, WithHeadings, WithMapping, ShouldAutoSize, WithStyles, WithEvents
{
    protected $request;
    protected $counter;
    protected $admin_commission;
    protected $endDate;
    protected $companytypeid;

    public function __construct(Request $request)
    {
        $this->request = $request;
        $this->counter = 1;
        $this->admin_commission;
        $this->endDate;
        $this->companytypeid;
    }

    public function collection()
    {

        $model = Corporate::where('status', 'active');

        $fromDate = $this->request->input('from_date');
        $toDate = $this->request->input('to_date');
        $corporateId = $this->request->input('company_type_id');

        if (!empty($fromDate)) {
            $model->whereDate('created_at', '>=', $fromDate);
        }

        if (!empty($toDate)) {
            $model->whereDate('created_at', '<=', $toDate);
        }

        if (!empty($corporateId)) {
            $model->where('company_type_id', $corporateId);
            $model->where('company_type_id', $corporateId);
        }

        $corporate = $model->get();

        $this->admin_commission = $corporate->sum('commission');

        $data = $corporate->map(function ($q) {
            return [
                'id' => $q->id,
                'corporate_display_name' => $q->FullName,
                'email' => $q->email,
                'contact_number' => $q->contact_number,
                'company_name' => $q->company_name,
                'company_type_id' => optional($q->CompanyType)->name,
                'companyid' => $q->companyid,
                'invoice_email' => $q->invoice_email,
                'commission_type' => $q->commission_type,
                'commission' => getPriceFormat($q->commission),
                'VAT_number' => $q->VAT_number,
                'created_at' => dateAgoFormate($q->created_at,true),
            ];
        })->toArray();

        $data[] = [
            ''  => '',
            'id' => '',
            'corporate_display_name' => 'Total',
            'email' => '',
            'contact_number' => '',
            'company_name' => '',
            'company_type_id' => '',
            'companyid' => '',
            'invoice_email' => '',
            'commission_type' => '',
            'commission' => getPriceFormat($this->admin_commission) ?? '-',
            'created_at' => ''
        ];
        return collect($data);
    }

    public function map($corporate): array
    {
        if ($corporate['email'] === 'Total') {
            return [
                'Total',
                '',
                '',
                '',
                '',
                '',
                '',
                $corporate['commission'],
                '',
            ];
        }
        return [
            $this->counter++,
            $corporate['corporate_display_name'] ?? '-',
            $corporate['email'] ?? '-',
            $corporate['contact_number'] ?? '-',
            $corporate['company_name'] ?? '-',
            $corporate['company_type_id'] ?? '-',
            $corporate['companyid'] ?? '-',
            $corporate['invoice_email'] ?? '-',
            $corporate['commission_type'] ?? '-',
            $corporate['commission'] ?? '-',
            $corporate['created_at'] ?? '-',
        ];
    }

    public function headings($exportType = 'excel'): array
    {
        if ($exportType === 'excel') {
            $fromDate = $this->request->input('from_date');
            $toDate = $this->request->input('to_date');
            $date = ($fromDate && $toDate) ? 'From Date: ' . ($fromDate ?: '-') . ' To Date ' . ($toDate ?: '-') : null;
    
            $headings = [
                [
                   'Corporate Report' . ($date ? ' : ' . $date : ''),
                ],
                [''],
                [
                    __('message.no'),
                    __('message.name'),
                    __('message.email'),
                    __('message.contact_number'),
                    __('message.company_name'),
                    __('message.company_type'),
                    __('message.companyid'),
                    __('message.invoice_email'),
                    __('message.commission_type'),
                    __('message.commission'),
                    __('message.created_at'),
                ],
            ];
        } else {
            $headings = [
                __('message.no'),
                __('message.name'),
                __('message.email'),
                __('message.contact_number'),
                __('message.company_name'),
                __('message.company_type'),
                __('message.companyid'),
                __('message.invoice_email'),
                __('message.commission_type'),
                __('message.commission'),
                __('message.created_at'),
            ];
        }
    
        return $headings;
    }
    
    public function styles(Worksheet $sheet)
    {
        $highestRow = $sheet->getHighestRow();
        $highestColumn = $sheet->getHighestColumn();

        $sheet->mergeCells('A1:' . $highestColumn . '1');
        $sheet->getStyle('A1')->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);

        for ($row = 1; $row <= $highestRow; $row++) {

            if ($row == 1) {
                $sheet->getStyle('A3:' . $highestColumn . '3')->applyFromArray([
                    'font' => [
                        'bold' => true,
                    ],
                ]);
            }
            if ($row == 3) {
                $sheet->getStyle('A1:' . $highestColumn . '1')->applyFromArray([
                    'font' => [
                        'bold' => true,
                    ],
                ]);
            }

            $cellValueI = $sheet->getCell('H' . $row)->getValue();
            if ($cellValueI) {
                $sheet->getCell('H' . $row)->setValue(ucfirst(strtolower($cellValueI)));
            }

            if ($row === 1 || $sheet->getCell('B' . $row)->getValue() === 'Total') {
                $sheet->getStyle('B' . $row . ':' . $highestColumn . $row)->applyFromArray([
                    'font' => [
                        'bold' => true,
                    ],
                    'alignment' => [
                        'horizontal' => Alignment::HORIZONTAL_CENTER,
                        'vertical' => Alignment::VERTICAL_CENTER,
                    ],
                ]);
            }
        }
    }


    public function registerEvents(): array
    {
        return [
            AfterSheet::class => function(AfterSheet $event) {
                $event->sheet->getDelegate()->getStyle('A:J')
                    ->getAlignment()
                    ->setHorizontal(Alignment::HORIZONTAL_CENTER);
            },
        ];
    }

    public function getDriverSumData()
    {
        return getPriceFormat($this->admin_commission);
    }
}