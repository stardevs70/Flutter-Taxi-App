<?php

namespace App\Traits;

use App\Models\Wallet;
use App\Models\WalletHistory;
use Illuminate\Support\Facades\DB;

trait WalletHistoryTrait {

    private function saveUserWalletHistory($data,$user_id)
    {
        $data = $data;

        $wallet =  Wallet::firstOrCreate(
            [ 'user_id' => $user_id ]
        );

        if( $data['type'] == 'credit' ) {
            $total_amount = $wallet->total_amount + $data['amount'];
        }

        if( $data['type'] == 'debit' ) {
            $total_amount = $wallet->total_amount - $data['amount'];
        }
        $currency_code = SettingData('CURRENCY', 'CURRENCY_CODE') ?? 'USD';
        $wallet->currency = strtolower($currency_code);

        $wallet->total_amount = $total_amount;

        try
        {
            DB::beginTransaction();
            $wallet->save();
            $data['user_id'] = $wallet->user_id;
            $data['balance'] = $total_amount;
            $data['datetime'] = date('Y-m-d H:i:s');
            $data['transaction_type'] = $data['transaction_type'] ?? null;
            $result = WalletHistory::create($data);
            DB::commit();
        } catch(\Exception $e) {
            DB::rollBack();
            return $e;
        }
        return true;
    }

}