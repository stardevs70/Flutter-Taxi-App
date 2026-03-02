<?php

namespace App\Http\Controllers;

use App\DataTables\SpecialServicesDataTable;
use App\Http\Requests\SpecialServicesRequest;
use App\Models\SpecialServices;
use Illuminate\Http\Request;

class SpecialServicesController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(SpecialServicesDataTable $dataTable)
    {
        $pageTitle = __('message.list_form_title',['form' => __('message.special_rates')] );
        $auth_user = authSession();
        $assets = ['datatable'];
        $button = $auth_user->can('special_rate add') ? '<a href="' . route('specialservices.create') . '" class="float-right btn btn-sm border-radius-10 btn-primary me-2"><i class="fa fa-plus-circle"></i> ' . __('message.add_form_title', ['form' => __('message.special_rates')]) . '</a>' : '';
        return $dataTable->render('global.datatable', compact('pageTitle', 'button', 'auth_user'));
    }
    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $pageTitle = __('message.add_form_title',[ 'form' => __('message.special_rates')]);
        
        return view('special-services.form', compact('pageTitle'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(SpecialServicesRequest $request)
    {
        if(env('APP_DEMO')){
            return redirect()->route('specialservices.index')->withErrors(__('message.demo_permission_denied'));
        }
        $service = SpecialServices::create($request->all());
        return redirect()->route('specialservices.index')->withSuccess(__('message.save_form', ['form' => __('message.special_rates')]));
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $pageTitle = __('message.add_form_title',[ 'form' => __('message.special_rates')]);
        $data = SpecialServices::findOrFail($id);

        if (request()->ajax()) {
            return view('special-services.show', compact('data'));
        }
        return view('special-services.show', compact('data'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        $pageTitle = __('message.update_form_title',[ 'form' => __('message.special_rates')]);
        $data = SpecialServices::findOrFail($id);
        
        return view('special-services.form', compact('data', 'pageTitle', 'id'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(SpecialServicesRequest $request, string $id)
    {
        if(env('APP_DEMO')){
            return redirect()->route('service.index')->withErrors(__('message.demo_permission_denied'));
        }
        $service = SpecialServices::findOrFail($id);

        // Service data...
        $service->fill($request->all())->update();

        if(auth()->check()){
            return redirect()->route('specialservices.index')->withSuccess(__('message.update_form',['form' => __('message.special_rates')]));
        }
        return redirect()->back()->withSuccess(__('message.update_form',['form' => __('message.special_rates') ] ));
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
            return redirect()->route('specialservices.index')->withErrors($message);
        }
        $service = SpecialServices::findOrFail($id);
        $status = 'errors';
        $message = __('message.not_found_entry', ['name' => __('message.special_rates')]);

        if($service != '') {
            $service->delete();
            $status = 'success';
            $message = __('message.delete_form', ['form' => __('message.special_rates')]);
        }

        if(request()->ajax()) {
            return response()->json(['status' => true, 'message' => $message ]);
        }

        return redirect()->back()->with($status,$message);
    }
}
