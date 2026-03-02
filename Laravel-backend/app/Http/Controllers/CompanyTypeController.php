<?php

namespace App\Http\Controllers;

use App\DataTables\CompanyTypeDataTable;
use App\Models\CompanyType;
use Illuminate\Http\Request;

class CompanyTypeController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(CompanyTypeDataTable $dataTable)
    {
        $pageTitle = __('message.list_form_title',['form' => __('message.company_type')] );
        $auth_user = authSession();
        $assets = ['datatable'];
        $button = $auth_user->can('company_type-add') ? '<a href="'.route('comapanytype.create').'" class="float-right btn btn-sm border-radius-10 btn-primary me-2 jqueryvalidationLoadRemoteModel"><i class="fa fa-plus-circle"></i> '.__('message.add_form_title',['form' => __('message.company_type')]).'</a>' : '';

        return $dataTable->render('global.agent-datatable', compact('assets','pageTitle','button','auth_user'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $pageTitle = __('message.add_form_title',[ 'form' => __('message.company_type')]);
        return view('company-type.form', compact('pageTitle'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $data = $request->all();
        $comanytype = CompanyType::create($data);
        $message = __('message.save_form', ['form' => __('message.company_type')]);

        return redirect()->back()->withSuccess($message);
    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $pageTitle = __('message.view_form_title', ['form' => __('message.company_type')]);
        $data = CompanyType::findOrFail($id);

        return view('company-type.form', compact('pageTitle', 'data', 'id'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit($id)
    {
        $pageTitle = __('message.update_form_title', ['form' => __('message.company_type')]);
        $data = CompanyType::findOrFail($id);

        return view('company-type.form', compact('data', 'pageTitle', 'id'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        $companytype = CompanyType::find($id);
        $message = __('message.not_found_entry', ['name' => __('message.company_type')]);
        if ($companytype == null) {
            return json_custom_response(['status' => false, 'message' => $message]);
        }

        $companytype->update($request->all());

        $message = __('message.update_form', ['form' => __('message.company_type')]);
        if ($request->is('api/*')) {
            return json_message_response($message);
        }
        return redirect()->back()->withSuccess($message);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        if(env('APP_DEMO')){
            $message = __('message.demo_permission_denied');
            if(request()->is('api/*')){
                return response()->json(['status' => true, 'message' => $message ]);
            }
            if(request()->ajax()) {
                return response()->json(['status' => false, 'message' => $message, 'event' => 'validation']);
            }
            return redirect()->route('comapanytype.index')->withErrors($message);
        }
        $companytype = CompanyType::find($id);

        $message = __('message.not_found_entry', ['name' => __('message.company_type')]);
        if ($companytype == null) {
            return json_message_response($message, 400);
        }
        if ($companytype != '') {
            $companytype->delete();
            $message = __('message.delete_form', ['form' => __('message.company_type')]);
        }
        if (request()->is('api/*')) {
            return json_message_response($message);
        }

        if (request()->ajax()) {
            return response()->json(['status' => true, 'message' => $message]);
        }
        return redirect()->route('comapanytype.index')->withSuccess($message);
    }
}
