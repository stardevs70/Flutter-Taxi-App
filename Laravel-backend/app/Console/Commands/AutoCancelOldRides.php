<?php
namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\RideRequest;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AutoCancelInactiveRides extends Command
{
    protected $signature = 'rides:auto-cancel-inactive';
    protected $description = 'Auto-cancel inactive rides after schedule or creation time threshold.';

    public function handle()
    {
        $now = now();
        $oneHourAgo = $now->copy()->subHour();
        $twelveHoursAgo = $now->copy()->subHours(12); // You can change to subHours(24) for 24 hours
        $startOfToday = $now->copy()->startOfDay();

        // Cancel scheduled rides: 12+ hours after schedule time + 1 hour inactivity
        $scheduledRides = RideRequest::where('is_schedule', 1)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->where('schedule_datetime', '<=', $twelveHoursAgo)
            ->whereHas('rideRequestHistory', function ($query) use ($oneHourAgo) {
                $query->select(DB::raw('MAX(datetime)'))
                    ->havingRaw('MAX(datetime) <= ?', [$oneHourAgo]);
            })
            ->with(['rideRequestHistory' => function ($query) {
                $query->latest('datetime')->limit(1);
            }])
            ->get();

        // Cancel non-scheduled rides created before today + 1 hour inactivity
        $nonScheduledRides = RideRequest::where('is_schedule', 0)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereDate('created_at', '<', $startOfToday)
            ->whereHas('rideRequestHistory', function ($query) use ($oneHourAgo) {
                $query->select(DB::raw('MAX(datetime)'))
                    ->havingRaw('MAX(datetime) <= ?', [$oneHourAgo]);
            })
            ->with(['rideRequestHistory' => function ($query) {
                $query->latest('datetime')->limit(1);
            }])
            ->get();

        $allRides = $scheduledRides->merge($nonScheduledRides);

        foreach ($allRides as $ride) {
            $ride->status = 'cancelled';
            $ride->cancel_by = 'system';
            $ride->reason = 'Auto cancelled due to inactivity.';
            $ride->save();

            if ($ride->driver_id) {
                $driver = User::find($ride->driver_id);
                if ($driver) {
                    $driver->is_available = 1;
                    $driver->save();
                }
            }

            try {
                $docName = 'ride_' . $ride->id;
                app('firebase.firestore')->database()->collection('rides')->document($docName)->delete();
            } catch (\Throwable $e) {
                Log::error("Failed to delete Firebase document {$docName}: " . $e->getMessage());
            }

            Log::info("RideRequest ID {$ride->id} cancelled due to inactivity.");
        }

        $this->info("Auto-cancel process complete. Total cancelled rides: " . $allRides->count());
    }
}
