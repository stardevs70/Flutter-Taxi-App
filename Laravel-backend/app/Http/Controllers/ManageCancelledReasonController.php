<?php

namespace App\Http\Controllers;

use App\DataTables\ManageCancelledResonDataTable;
use App\Http\Resources\CancelReasonResource;
use App\Models\ManageCancelledReason;
use Illuminate\Http\Request;

class ManageCancelledReasonController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(ManageCancelledResonDataTable $dataTable)
    {
        $pageTitle = __('message.list_form_title', ['form' => __('message.manage_cancelled_reason')]);
        $auth_user = authSession();
        $assets = ['datatable'];
        $button = $auth_user->can('cancelled_reason-add') ? '<a href="' . route('cancelledreason.create') . '" class="float-right btn btn-sm border-radius-10 btn-primary me-2 jqueryvalidationLoadRemoteModel"><i class="fa fa-plus-circle"></i> ' . __('message.add_form_title', ['form' => __('message.manage_cancelled_reason')]) . '</a>' : '';

        return $dataTable->render('global.agent-datatable', compact('assets', 'pageTitle', 'button', 'auth_user'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $pageTitle = __('message.add_form_title', ['form' => __('message.manage_cancelled_reason')]);
        return view('manage-cancelreson.form', compact('pageTitle'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $data = $request->all();
        $cancelreson = ManageCancelledReason::create($data);
        $message = __('message.save_form', ['form' => __('message.manage_cancelled_reason')]);

        return redirect()->back()->withSuccess($message);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $pageTitle = __('message.view_form_title', ['form' => __('message.manage_cancelled_reason')]);
        $data = ManageCancelledReason::findOrFail($id);

        return view('manage-cancelreson.form', compact('pageTitle', 'data', 'id'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        $pageTitle = __('message.update_form_title', ['form' => __('message.manage_cancelled_reason')]);
        $data = ManageCancelledReason::findOrFail($id);

        return view('manage-cancelreson.form', compact('data', 'pageTitle', 'id'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $cancelreson = ManageCancelledReason::find($id);
        $message = __('message.not_found_entry', ['name' => __('message.manage_cancelled_reason')]);
        if ($cancelreson == null) {
            return json_custom_response(['status' => false, 'message' => $message]);
        }

        $cancelreson->update($request->all());

        $message = __('message.update_form', ['form' => __('message.manage_cancelled_reason')]);
        if ($request->is('api/*')) {
            return json_message_response($message);
        }
        return redirect()->back()->withSuccess($message);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        if (env('APP_DEMO')) {
            $message = __('message.demo_permission_denied');
            if (request()->is('api/*')) {
                return response()->json(['status' => true, 'message' => $message]);
            }
            if (request()->ajax()) {
                return response()->json(['status' => false, 'message' => $message, 'event' => 'validation']);
            }
            return redirect()->back()->withErrors($message);
        }
        $cancelreson = ManageCancelledReason::find($id);

        $message = __('message.not_found_entry', ['name' => __('message.manage_cancelled_reason')]);
        if ($cancelreson == null) {
            return json_message_response($message, 400);
        }
        if ($cancelreson != '') {
            $cancelreson->delete();
            $message = __('message.delete_form', ['form' => __('message.manage_cancelled_reason')]);
        }
        if (request()->is('api/*')) {
            return json_message_response($message);
        }

        if (request()->ajax()) {
            return response()->json(['status' => true, 'message' => $message]);
        }
        return redirect()->back()->withSuccess($message);
    }

    public function getList(Request $request)
    {

        $cancelreson = ManageCancelledReason::query();

        $cancelreson->when(request('type'), function ($q) {
            return $q->where('type', request('type'));
        });

        $per_page = config('constant.PER_PAGE_LIMIT');

        if ($request->has('per_page') && !empty($request->per_page)) {
            if (is_numeric($request->per_page)) {
                $per_page = $request->per_page;
            }
            if ($request->per_page == -1) {
                $per_page = $cancelreson->count();
            }
        }

        $cancelreson = $cancelreson->orderBy('id', 'desc')->paginate($per_page);
        $items = CancelReasonResource::collection($cancelreson);

        $response = [
            'pagination' => json_pagination_response($items),
            'data' => $items,
        ];

        return json_custom_response($response);
    }
}
