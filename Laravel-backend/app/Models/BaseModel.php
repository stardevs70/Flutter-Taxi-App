<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Schema;

class BaseModel extends Model
{
    protected static function booted()
    {
        static::updated(function ($model) {
            if (!config('settings.activity_log_enabled') || !Schema::hasTable('activity_log')) return;

            $user = auth()->user();
            $ip = request()->ip();

            $exclude = $model->excludeFromLog ?? ['updated_at', 'created_at','otp'];
            $changes = collect($model->getChanges())->except($exclude);
            if ($changes->isEmpty()) return;

            $formatKey = fn($key) => ucfirst(str_replace('_', ' ', preg_replace('/_id$/', ' ID', $key)));

            $formattedChanges = $changes->map(function ($new, $key) use ($model) {
                $old = $model->getOriginal($key);
                return [
                    'from' => $old === '' || $old === null ? '(empty)' : $old,
                    'to'   => $new === '' || $new === null ? '(empty)' : $new,
                ];
            });

            $logChanges = $formattedChanges->map(function ($change, $key) use ($formatKey) {
                return $formatKey($key) . ' changed from "' . $change['from'] . '" to "' . $change['to'] . '"';
            })->implode(', ');

            $properties = [
                'attributes' => $formattedChanges->mapWithKeys(fn($v, $k) => [$formatKey($k) => $v['to']]),
                'old'        => $formattedChanges->mapWithKeys(fn($v, $k) => [$formatKey($k) => $v['from']]),
                'ip'         => $ip,
            ];

            $log = activity(class_basename($model))
                ->performedOn($model)
                ->withProperties($properties);

            if ($user) {
                $log->causedBy($user)
                    ->log("{$user->display_name} updated " . class_basename($model) . " #{$model->id} – $logChanges");
            } else {
                $log->log(class_basename($model) . " #{$model->id} updated – $logChanges (system or unauthenticated)");
            }
        });

        static::created(function ($model) {
            if (!config('settings.activity_log_enabled') || !Schema::hasTable('activity_log')) return;

            $user = auth()->user();

            $log = activity(class_basename($model))
                ->performedOn($model)
                ->withProperties([
                    'ip' => request()->ip(),
                ]);

            if ($user) {
                $log->causedBy($user)
                    ->log("{$user->display_name} added " . class_basename($model) . " #{$model->id}");
            } else {
                $log->log(class_basename($model) . " #{$model->id} added (system or unauthenticated)");
            }
        });

        static::deleted(function ($model) {
            if (!config('settings.activity_log_enabled') || !Schema::hasTable('activity_log')) return;

            $user = auth()->user();
            $log = activity(class_basename($model))
                ->performedOn($model)
                ->withProperties([
                    'ip' => request()->ip(),
                ]);

            if ($user) {
                $log->causedBy($user)
                    ->log("{$user->display_name} deleted " . class_basename($model) . " #{$model->id}");
            } else {
                $log->log(class_basename($model) . " #{$model->id} deleted (system or unauthenticated)");
            }
        });
    }
}

