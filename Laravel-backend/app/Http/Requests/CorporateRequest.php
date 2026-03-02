<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;


class CorporateRequest extends FormRequest
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
        $user_id = $this->route()->corporate;

        $rules = [];
        switch ($method) {
            case 'post':
                $rules = [
                    'username' => 'required|unique:users,username',
                    'first_name' => 'required',
                    'last_name' => 'required',
                    'password' => 'required|min:8',
                    'email' => 'required|email|unique:users',
                    'contact_number' => 'max:20|unique:users,contact_number',
                    'company_name' => 'required',
                    'company_type_id' => 'required',
                    'companyid' => 'required',
                    'company_address' => 'required',
                    'invoice_email' => 'required',
                    'corp_value' => 'required',
                    'commission' => 'required',
                    'VAT_number' => 'required',
                ];
                break;
            case 'patch':
                $rules = [
                    'username'  => 'required|unique:users,username,'.$user_id,
                    'email'     => 'required|email|unique:users,email,'.$user_id,
                    'contact_number' => 'max:20|unique:users,contact_number,'.$user_id,
                    'first_name' => 'required',
                    'last_name' => 'required',
                    'company_name' => 'required',
                    'company_type_id' => 'required',
                    'companyid' => 'required',
                    'company_address' => 'required',
                    'invoice_email' => 'required',
                    'corp_value' => 'required',
                    'commission' => 'required',
                    'VAT_number' => 'required',
                ];
                break;
        }

        return $rules;
    }

    public function messages()
    {
        return [
            'userProfile.dob.*'  =>'DOB is required.',
        ];
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
