<x-master-layout :assets="$assets ?? []">
  
    <div class="container">
        <h2>System Activity History</h2>

        <div class="table-responsive">
            <table id="activityTable" class="table table-responsive">
                <thead>
                    <tr>
                        <th>Event</th>
                        <th>Model</th>
                        <th>Model ID</th>
                        <th>User</th>
                        <th>Time</th>
                        <th>Changes</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($activities as $activity)
                        <tr>
                            <td>{{ $activity->description }}</td>
                            <td>{{ class_basename($activity->subject_type) ?? 'N/A' }}</td>
                            <td>{{ $activity->subject_id ?? 'N/A' }}</td>
                            <td>{{ $activity->causer?->display_name ?? '' }}</td>
                            <td>{{ $activity->created_at->format('d M Y, h:i A') }}</td>
                            <td>
                                @php $changes = $activity->changes(); @endphp
                                @if (!empty($changes['attributes']))
                                    <div class="text-sm">
                                        @foreach ($changes['attributes'] as $key => $newValue)
                                            <div>
                                                <strong>{{ $key }}</strong>:
                                                <span class="text-muted">
                                                    {{ isset($changes['old'][$key]) ? json_encode($changes['old'][$key]) : '—' }}
                                                </span>
                                                <span class="text-primary">→</span>
                                                <span class="text-success">{{ json_encode($newValue) }}</span>
                                            </div>
                                        @endforeach
                                    </div>
                                @else
                                    —
                                @endif
                            </td>

                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>

    <script>
        $(document).ready(function() {
            $('#activityTable').DataTable({
                "pageLength": 10,
                "order": [[4, 'desc']], // Sort by Time descending
                "columnDefs": [
                    { "orderable": false, "targets": 5 } // Disable sorting on 'Changes'
                ]
            });
        });
    </script>

</x-master-layout>
