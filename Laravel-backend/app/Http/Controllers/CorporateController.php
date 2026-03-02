<?php

namespace App\Http\Controllers;

use App\DataTables\CorporateDataTable;
use App\DataTables\DriverDataTable;
use App\DataTables\RiderDataTable;
use App\DataTables\RideRequestDataTable;
use App\DataTables\WalletHistoryDataTable;
use App\DataTables\WithdrawRequestDataTable;
use App\Http\Requests\CorporateRequest;
use App\Models\Corporate;
use App\Models\CorporateDocument;
use App\Models\RideRequest;
use App\Models\User;
use App\Models\UserBankAccount;
use Illuminate\Http\Request;

class CorporateController extends Controller
{ 
    /**
     * Display a listing of the resource.
     */
    public function index(CorporateDataTable $dataTable)
    {

        $pageTitle = __('message.list_form_title',['form' => __('message.corporate')] );
        $auth_user = authSession();
        $assets = ['datatable'];
        $button = $auth_user->can('corporate-add') ? '<a href="'.route('corporate.create').'" class="float-right btn btn-sm border-radius-10 btn-primary me-2"><i class="fa fa-plus-circle"></i> '.__('message.add_form_title',['form' => __('message.corporate')]).'</a>' : '';

        return $dataTable->render('global.agent-datatable', compact('assets','pageTitle','button','auth_user'));
    }
    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $auth_user = auth()->user();
        $usercheck = $auth_user->user_type === 'admin';
        $data = null;
        $pageTitle = __('message.add_form_title',[ 'form' => __('message.corporate')]);
        $assets = ['phone'];
        return view('corporate.form', compact('pageTitle','assets','usercheck','data'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(CorporateRequest $request)
    {
        $corpValue = $request->input('corp_value');
        $exists = Corporate::where('url', $corpValue)->exists();

        if ($exists) {
            $message = __('message.url_already_exists_in_corporates');
            return redirect()->back()->withErrors($message);
        }
        $corporateData = $request->all();
        $corporateData['url'] = $corpValue;
        $corporate = Corporate::create($corporateData);
        uploadMediaFile($corporate,$request->corporate_logo, 'corporate_logo');
        uploadMediaFile($corporate,$request->corporate_background , 'corporate_background');

        $userData = [
            'password'       => bcrypt($request->password),
            'first_name'     =>$request->first_name,
            'last_name'      =>$request->last_name,
            'email'          =>$request->email,
            'username'       => $request->username ?? stristr($request->email, "@", true) . rand(100, 1000),
            'display_name'   => $request->first_name . ' ' . $request->last_name,
            'contact_number' => $request->contact_number,
            'user_type'      => 'corporate',
            'status'      => $request->status,
            'corporate_id'   => $corporate->id,
        ];
        $user = User::create($userData);
        $corporate->user_id = $user->id;
        $corporate->save();
        uploadMediaFile($user, $request->profile_image, 'profile_image');
        $user->assignRole('corporate');

        // bank account data
        $bankData = [
            'user_id'             => $user->id,
            'bank_name'           => $request->bank_name,
            'account_number'      => $request->account_number,
            'account_holder_name' => $request->account_holder_name,
            'bank_code'           => $request->bank_code,
            'bank_address'        => $request->bank_address,
            'routing_number'      => $request->routing_number,
            'bank_iban'           => $request->bank_iban,
            'bank_swift'          => $request->bank_swift,
        ];

        UserBankAccount::create($bankData);
    
        return redirect()->route('corporate.index')->withSuccess(__('message.save_form', ['form' => __('message.corporate')]));
    }
    

    /**
     * Display the specified resource.
     */
    public function show(RideRequestDataTable $rideRequestDataTable, RiderDataTable $riderDataTable, DriverDataTable $driverDataTable,WalletHistoryDataTable $walletHistoryDataTable,WithdrawRequestDataTable $withdrawRequestDataTable, $id)
    {
        if (!auth()->user()->can('corporate-show')) {
            $message = __('message.demo_permission_denied');
            return redirect()->back()->withErrors($message);
        }
        $pageTitle = __('message.corporate');
        $data = Corporate::findOrFail($id);
        $type = request('type') ?? 'detail';
        switch ($type) {
            case 'ride_request':
                return $rideRequestDataTable->with('corporate_id',$id)->render('corporate.show', compact('pageTitle', 'data', 'type' ));
                break;
            case 'customer':
                return $riderDataTable->with('view_corporate_id',$id)->render('corporate.show', compact('pageTitle', 'data', 'type' ));
                break;
            case 'driver':
                return $driverDataTable->with('view_corporate_id',$id)->render('corporate.show', compact('pageTitle', 'data', 'type' ));
                break;
            case 'wallet':
                return $walletHistoryDataTable->with('user_id',$data->user_id)->render('corporate.show', compact('pageTitle', 'data', 'type' ));
                break;
            case 'withdrawal_request':
                return $withdrawRequestDataTable->with(['corporate_id' => $data->user_id,'corporate_withdraw_type' => 'all'])->render('corporate.show', compact('pageTitle', 'data', 'type' ));
                break;
            case 'documents':
                $pageTitle = __('message.document');
                $user = $data->user;
                $documents = CorporateDocument::where('corporate_id', $user->id)->get();
                return view('corporate.show', compact('pageTitle', 'data', 'type', 'documents', 'user'));
                break;
            
            default:
                # code...
                break;
        }
        $profileImage = getSingleMedia($data, 'profile_image');

        return view('corporate.show', compact('data','pageTitle','profileImage','type'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit($id)
    {
        $pageTitle = __('message.list_form_title',['form' => __('message.corporate')] );        
        $data = Corporate::with('user.userBankAccount')->findOrFail($id);
        $profileImage = getSingleMedia($data, 'profile_image');
        $corporate_logo = getSingleMedia($data, 'corporate_logo');
        $corporate_background = getSingleMedia($data, 'corporate_background');
        $assets = ['phone'];
        $corp_value = '';
        $auth_user = auth()->user();
        $usercheck = $auth_user->user_type === 'admin';
        $corp_value = $data->url;
        // $corp_value = $data->url && str_contains($data->url, '=') ? explode('=', $data->url)[1] ?? '' : '';
        return view('corporate.form', compact('data','pageTitle','assets','id','corp_value','usercheck'));
    }


    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        $corporate = Corporate::findOrFail($id);
        // uploadMediaFile($corporate,$request->corporate_logo, 'corporate_logo');
        // uploadMediaFile($corporate,$request->corporate_background , 'corporate_background');
        if ($request->hasFile('corporate_logo')) {
            uploadMediaFile($corporate, $request->file('corporate_logo'), 'corporate_logo');
        }
    
        if ($request->hasFile('corporate_background')) {
            uploadMediaFile($corporate, $request->file('corporate_background'), 'corporate_background');
        }

        // $corporate->update($request->all());
        $data = $request->all();
        if ($request->filled('password')) {
            $data['password'] = bcrypt($request->input('password'));
        } else {
            unset($data['password']);
        }
        $corporate->update($data);

        $user = User::where('corporate_id', $corporate->id)->first();

        if ($user) {
            $user->update([
                'first_name'     =>$request->first_name,
                'last_name'      =>$request->last_name,
                'username'       => $request->username ?? $user->username,
                'display_name'   => $request->first_name . ' ' . $request->last_name,
                'password'      => bcrypt($request->password),
                'status'      => $request->status,
                'contact_number' => $request->contact_number,
            ]);

            if ($request->hasFile('profile_image')) {
                uploadMediaFile($user, $request->profile_image, 'profile_image');
            }
        }
        $bankData = [
            'bank_name'           => $request->bank_name,
            'account_number'      => $request->account_number,
            'account_holder_name' => $request->account_holder_name,
            'bank_code'           => $request->bank_code,
            'bank_address'        => $request->bank_address,
            'routing_number'      => $request->routing_number,
            'bank_iban'           => $request->bank_iban,
            'bank_swift'          => $request->bank_swift,
        ];
        if ($user->userBankAccount) {
            $user->userBankAccount->update($bankData);
        } else {
            $user->userBankAccount()->create($bankData);
        }


        return redirect()->route('corporate.index')->withSuccess(__('message.update_form', ['form' => __('message.corporate')]));
    }


    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $corporate = Corporate::with('user.userBankAccount')->findOrFail($id);
    
        // Delete related user
        $user = User::where('corporate_id', $corporate->id)->first();
        if ($user) {
            $user->delete();
            $user->userBankAccount()->delete();
        }
        $corporate->delete();
    
        return redirect()->route('corporate.index')->withSuccess(__('message.delete_form', ['form' => __('message.corporate')]));
    }
    
}
