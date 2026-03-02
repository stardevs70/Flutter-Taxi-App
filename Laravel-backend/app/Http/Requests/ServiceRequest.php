<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;


class ServiceRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize()
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules()
    {
        $method = strtolower($this->method());
        $serviceType = $this->get('service_type');

        $rules = [];
        switch ($method) {
            case 'post':
                $rules = [
                    'name' => 'required',
                    'service_type' => 'required|in:transport,book_ride,both',
                    'region_id' => 'required|exists:regions,id',
                    'payment_method' => 'required',
                    'status' => 'required|in:0,1',
                    'admin_commission' => 'required|numeric|min:0',
                ];

                if ($serviceType !== 'delivery') {
                    // transport or both
                    $rules['minimum_weight'] = 'nullable|numeric|min:0';
                    $rules['per_weight_charge'] = 'nullable|numeric|min:0';
                }

                if ($serviceType !== 'transport') {
                    // delivery or both
                    $rules['capacity'] = 'required|numeric|min:1';
                    $rules['base_fare'] = 'required|numeric|min:0';
                    $rules['minimum_fare'] = 'required|numeric|min:0';
                    $rules['per_distance'] = 'required|numeric|min:0';
                    $rules['per_minute_drive'] = 'required|numeric|min:0';
                    $rules['cancellation_fee'] = 'required|numeric|min:0';
                }

                break;

            case 'patch':
                $rules = [
                    'name' => 'required',
                    'service_type' => 'required|in:transport,book_ride,both',
                    'region_id' => 'required|exists:regions,id',
                    'payment_method' => 'required',
                    'status' => 'required|in:0,1',
                    'admin_commission' => 'required|numeric|min:0',
                ];

                if ($serviceType !== 'delivery') {
                    $rules['minimum_weight'] = 'nullable|numeric|min:0';
                    $rules['per_weight_charge'] = 'nullable|numeric|min:0';
                }

                if ($serviceType !== 'transport') {
                    $rules['capacity'] = 'required|numeric|min:1';
                    $rules['base_fare'] = 'required|numeric|min:0';
                    $rules['minimum_fare'] = 'required|numeric|min:0';
                    $rules['per_distance'] = 'required|numeric|min:0';
                    $rules['per_minute_drive'] = 'required|numeric|min:0';
                    $rules['cancellation_fee'] = 'required|numeric|min:0';
                }

                break;
        }

        return $rules;
    }


    public function messages()
    {
        return [ ];
    }

     /**
     * @param Validator $validator
     */
    protected function failedValidation(Validator $validator) {
        $data = [
            'status' => true,
            'message' => $validator->errors()->first(),
            'all_message' =>  $validator->errors()
        ];

        if ( request()->is('api*')){
           throw new HttpResponseException( response()->json($data,422) );
        }

        if ($this->ajax()) {
            throw new HttpResponseException(response()->json($data,422));
        } else {
            throw new HttpResponseException(redirect()->back()->withInput()->with('errors', $validator->errors()));
        }
    }
}
