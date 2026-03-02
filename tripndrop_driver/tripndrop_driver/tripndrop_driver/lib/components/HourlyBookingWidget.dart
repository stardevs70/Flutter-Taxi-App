/// Hourly Booking Widget according to Eagle Rides Development Plan
/// Section 8.2 & 8.3: Hourly booking UI, extension flow, time remaining

import 'dart:async';
import 'package:flutter/material.dart';
import '../model/TripModel.dart';
import '../model/HourlyPricingModel.dart';
import '../Services/HourlyBookingService.dart';
import '../utils/DispatchConstants.dart';

/// Widget to display hourly booking info during trip
class HourlyTripInfoWidget extends StatefulWidget {
  final TripModel trip;
  final VoidCallback? onRequestExtension;

  const HourlyTripInfoWidget({
    Key? key,
    required this.trip,
    this.onRequestExtension,
  }) : super(key: key);

  @override
  State<HourlyTripInfoWidget> createState() => _HourlyTripInfoWidgetState();
}

class _HourlyTripInfoWidgetState extends State<HourlyTripInfoWidget> {
  final HourlyBookingService _hourlyService = HourlyBookingService();
  Timer? _timer;
  HourlyTimeRemaining? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    // Update every second when trip is in progress
    if (widget.trip.status == TripStatus.STARTED) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTimeRemaining();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeRemaining = _hourlyService.calculateRemainingTime(widget.trip);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.trip.isHourlyBooking) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'HOURLY BOOKING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (_timeRemaining != null && _timeRemaining!.isOvertime)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OVERTIME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Time remaining progress
          if (_timeRemaining != null) ...[
            _buildTimeProgress(),
            const SizedBox(height: 16),
          ],

          // Booking details
          _buildBookingDetails(),

          const SizedBox(height: 16),

          // Extension button
          if (widget.trip.status == TripStatus.STARTED)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onRequestExtension,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Request Extension'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeProgress() {
    final remaining = _timeRemaining!;
    final progress = remaining.percentageRemaining;
    final isLow = remaining.remainingMinutes <= 15;
    final isOvertime = remaining.isOvertime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              remaining.formattedRemaining,
              style: TextStyle(
                color: isOvertime ? Colors.red.shade200 : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${remaining.elapsedMinutes}m elapsed',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isOvertime
                  ? Colors.red
                  : isLow
                      ? Colors.orange
                      : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetails() {
    final pricing = widget.trip.pricingSnapshot;
    final hoursBooked = widget.trip.hoursBooked ?? 0;
    final extensionMinutes = widget.trip.extensionMinutesTotal ?? 0;
    final includedMiles = widget.trip.includedMilesTotal ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Hours Booked', '${hoursBooked}h'),
          if (extensionMinutes > 0)
            _buildDetailRow('Extension', '+${extensionMinutes}m'),
          _buildDetailRow('Included Miles', '$includedMiles mi'),
          _buildDetailRow(
            'Extra Mile Fee',
            '\$${pricing?.extraMileFee?.toStringAsFixed(2) ?? '5.50'}/mi',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to request hourly extension
class RequestExtensionDialog extends StatefulWidget {
  final TripModel trip;
  final Function(int minutes)? onConfirm;

  const RequestExtensionDialog({
    Key? key,
    required this.trip,
    this.onConfirm,
  }) : super(key: key);

  @override
  State<RequestExtensionDialog> createState() => _RequestExtensionDialogState();

  static Future<int?> show(BuildContext context, TripModel trip) {
    return showDialog<int>(
      context: context,
      builder: (context) => RequestExtensionDialog(trip: trip),
    );
  }
}

class _RequestExtensionDialogState extends State<RequestExtensionDialog> {
  int _selectedMinutes = 30;
  final List<int> _options = [15, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final roundedMinutes = HourlyBookingConstants.calculateRoundedMinutes(_selectedMinutes);
    final pricing = widget.trip.pricingSnapshot;
    num extensionFee = 0;

    if (pricing != null && pricing.baseHourPrice != null) {
      final perMinuteRate = pricing.baseHourPrice! / 60;
      extensionFee = roundedMinutes * perMinuteRate;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.schedule, color: Colors.purple.shade700),
          const SizedBox(width: 12),
          const Text('Request Extension'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select extension duration:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Duration options
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((minutes) {
              final isSelected = _selectedMinutes == minutes;
              return ChoiceChip(
                label: Text(_formatDuration(minutes)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMinutes = minutes;
                    });
                  }
                },
                selectedColor: Colors.purple.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.purple.shade700 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Fee calculation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Selected Duration'),
                    Text(
                      _formatDuration(_selectedMinutes),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rounded to'),
                    Text(
                      '${roundedMinutes}m',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Extension Fee',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${extensionFee.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Text(
            'Note: Extensions are rounded to ${HourlyBookingConstants.extensionRoundingMinutes}-minute blocks',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedMinutes);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Request Extension'),
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }
}

/// Widget to confirm extension request from rider
class ExtensionConfirmationWidget extends StatelessWidget {
  final ExtensionRequest extension;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  const ExtensionConfirmationWidget({
    Key? key,
    required this.extension,
    this.onConfirm,
    this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_alarm, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Extension Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rider requested to extend the trip by ${extension.roundedMinutes} minutes.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Additional fee: \$${extension.extensionFee?.toStringAsFixed(2) ?? '0.00'}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
