/// Cancellation Lock Widget according to Eagle Rides Development Plan
/// Section 7.4: Driver cancellation lock UX
/// Shows disabled cancel button + message when within 4 hours of pickup

import 'package:flutter/material.dart';
import '../model/TripModel.dart';
import '../utils/DispatchConstants.dart';

class CancellationLockWidget extends StatelessWidget {
  final TripModel trip;
  final VoidCallback? onCancelPressed;
  final VoidCallback? onContactAdminPressed;

  const CancellationLockWidget({
    Key? key,
    required this.trip,
    this.onCancelPressed,
    this.onContactAdminPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canCancel = trip.canDriverCancel();
    final lockInfo = _getCancellationLockInfo();

    if (canCancel) {
      return _buildCancelButton(context, enabled: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Locked cancel button
        _buildCancelButton(context, enabled: false),

        const SizedBox(height: 12),

        // Lock message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_clock,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancellation Locked',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lockInfo.message,
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Contact admin button
        OutlinedButton.icon(
          onPressed: onContactAdminPressed,
          icon: const Icon(Icons.support_agent),
          label: const Text('Contact Admin to Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange.shade700,
            side: BorderSide(color: Colors.orange.shade300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context, {required bool enabled}) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: enabled ? onCancelPressed : null,
        icon: Icon(
          enabled ? Icons.cancel_outlined : Icons.lock,
          size: 20,
        ),
        label: Text(
          enabled ? 'Cancel Trip' : 'Cancel Locked',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.red : Colors.grey.shade400,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  CancellationLockInfo _getCancellationLockInfo() {
    if (trip.scheduledAt == null) {
      return CancellationLockInfo(
        isLocked: false,
        message: '',
        hoursUntilPickup: 0,
      );
    }

    final now = DateTime.now();
    final hoursUntilPickup = trip.scheduledAt!.difference(now).inHours;
    final minutesUntilPickup = trip.scheduledAt!.difference(now).inMinutes;

    String message;
    if (minutesUntilPickup < 60) {
      message = 'Cannot cancel within ${minutesUntilPickup} minutes of scheduled pickup. '
          'Contact admin for emergency cancellation.';
    } else {
      message = 'Cannot cancel within ${hoursUntilPickup} hours of scheduled pickup. '
          'Contact admin for emergency cancellation.';
    }

    return CancellationLockInfo(
      isLocked: hoursUntilPickup <= DispatchConstants.cancellationLockHours,
      message: message,
      hoursUntilPickup: hoursUntilPickup,
    );
  }
}

class CancellationLockInfo {
  final bool isLocked;
  final String message;
  final int hoursUntilPickup;

  CancellationLockInfo({
    required this.isLocked,
    required this.message,
    required this.hoursUntilPickup,
  });
}

/// Compact version of cancellation lock indicator
class CancellationLockIndicator extends StatelessWidget {
  final TripModel trip;

  const CancellationLockIndicator({
    Key? key,
    required this.trip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (trip.canDriverCancel()) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_clock,
            size: 14,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Cancel locked',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to show when driver tries to cancel a locked trip
class CancellationLockedDialog extends StatelessWidget {
  final TripModel trip;
  final VoidCallback? onContactAdmin;

  const CancellationLockedDialog({
    Key? key,
    required this.trip,
    this.onContactAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hoursUntilPickup = trip.scheduledAt != null
        ? trip.scheduledAt!.difference(DateTime.now()).inHours
        : 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_clock,
              color: Colors.orange.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Cancellation Locked'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You cannot cancel this trip because it is scheduled within ${DispatchConstants.cancellationLockHours} hours.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time until pickup',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      hoursUntilPickup > 0
                          ? '$hoursUntilPickup hours'
                          : 'Less than 1 hour',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'If you need to cancel due to an emergency, please contact admin for an override.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onContactAdmin?.call();
          },
          icon: const Icon(Icons.support_agent, size: 18),
          label: const Text('Contact Admin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context,
    TripModel trip, {
    VoidCallback? onContactAdmin,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CancellationLockedDialog(
        trip: trip,
        onContactAdmin: onContactAdmin,
      ),
    );
  }
}
