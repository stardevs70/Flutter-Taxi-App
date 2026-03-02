<?php

namespace App\Http\Controllers;

use App\DataTables\ManageCorporateDocumentDataTable;
use App\Models\CorporateDocument;
use App\Models\ManageCorporateDocument;
use Illuminate\Http\Request;

class ManageCorporateDocumentController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(ManageCorporateDocumentDataTable $dataTable)
    {
        $pageTitle = __('message.list_form_title',['form' => __('message.manage_corporate_document')] );
        $auth_user = authSession();
        $assets = ['datatable'];
        $button = $auth_user->can('manage_corporate_document-add') ? '<a href="'.route('corporatedocument.create').'" class="float-right btn btn-sm border-radius-10 btn-primary me-2"><i class="fa fa-plus-circle"></i> '.__('message.add_form_title',['form' => __('message.manage_corporate_document')]).'</a>' : '';
        return $dataTable->render('global.datatable', compact('pageTitle','button','auth_user'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $pageTitle = __('message.add_form_title',[ 'form' => __('message.manage_corporate_document')]);
        
        return view('manage_corporate_document.form', compact('pageTitle'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $data = $request->all();
        $manage_corporatedocument = ManageCorporateDocument::create($data);

        uploadMediaFile($manage_corporatedocument,$request->manage_corporate_document, 'manage_corporate_document');

        $message = __('message.save_form',['form' => __('message.manage_corporate_document')]);

        if(request()->is('api/*')){
            return json_message_response( $message );
        }
        
        return redirect()->route('corporatedocument.index')->withSuccess($message);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $pageTitle = __('message.add_form_title',[ 'form' => __('message.manage_corporate_document')]);
        $data = ManageCorporateDocument::findOrFail($id);

        return view('manage_corporate_document.show', compact('data'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        $pageTitle = __('message.update_form_title',[ 'form' => __('message.manage_corporate_document')]);
        $data = ManageCorporateDocument::findOrFail($id);
        $corporate = optional($data->user)->corporate;
        $corporateOption = $corporate ? [$corporate->id => $corporate->full_name] : [];

        $documentOption = [$data->document_id => $data->corporatedocument->name ?? ''];
        
        return view('manage_corporate_document.form', compact('data', 'pageTitle', 'id','corporateOption','documentOption'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $manage_corporatedocument = ManageCorporateDocument::find($id);
        if (!$manage_corporatedocument) {
            $message = __('message.not_found_entry', ['name' => __('message.manage_corporate_document')]);
    
            if(request()->is('api/*')){
                return json_message_response($message);
            }
    
            return redirect()->route('corporatedocument.index')->withErrors($message);
        }
       
        $manage_corporatedocument->fill($request->all())->update();

        if ($request->hasFile('manage_corporate_document')) {
            $manage_corporatedocument->clearMediaCollection('manage_corporate_document');
            $manage_corporatedocument->addMediaFromRequest('manage_corporate_document')->toMediaCollection('manage_corporate_document');
        }
        $message = __('message.update_form',['form' => __('message.manage_corporate_document') ] );
        if(request()->is('api/*')) {
            return json_message_response( $message );
        }

        if(auth()->check()){
            return redirect()->route('corporatedocument.index')->withSuccess($message);
        }
        return redirect()->back()->withSuccess($message);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        if(env('APP_DEMO')){
            $message = __('message.demo_permission_denied');
            if(request()->ajax()) {
                return response()->json(['status' => true, 'message' => $message ]);
            }
            return redirect()->route('corporatedocument.index')->withErrors($message);
        }
        $manage_corporatedocument = ManageCorporateDocument::find($id);
        $status = 'errors';
        $message = __('message.not_found_entry', ['name' => __('message.manage_corporate_document')]);

        if($manage_corporatedocument != '') {
            $manage_corporatedocument->delete();
            $status = 'success';
            $message = __('message.delete_form', ['form' => __('message.manage_corporate_document')]);
        }
        
        if(request()->is('api/*')){
            return json_message_response( $message );
        }

        if(request()->ajax()) {
            return response()->json(['status' => true, 'message' => $message ]);
        }

        return redirect()->back()->with($status,$message);
    }
}
