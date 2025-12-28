/// Incoming Request Screen according to Eagle Rides Development Plan
/// Section 7.1: Driver app - Incoming request screen with Accept/Reject + countdown

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/TripModel.dart';
import '../model/OfferModel.dart';
import '../Services/DispatchService.dart';
import '../utils/DispatchConstants.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../main.dart';

class IncomingRequestScreen extends StatefulWidget {
  final OfferModel offer;
  final TripModel trip;
  final VoidCallback? onAccepted;
  final VoidCallback? onRejected;
  final VoidCallback? onExpired;

  const IncomingRequestScreen({
    Key? key,
    required this.offer,
    required this.trip,
    this.onAccepted,
    this.onRejected,
    this.onExpired,
  }) : super(key: key);

  @override
  State<IncomingRequestScreen> createState() => _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends State<IncomingRequestScreen>
    with SingleTickerProviderStateMixin {
  final DispatchService _dispatchService = DispatchService();

  Timer? _countdownTimer;
  int _remainingSeconds = DispatchConstants.offerCountdownSeconds;
  bool _isProcessing = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
    _initializeAnimations();
    _setupMapMarkers();
  }

  void _initializeCountdown() {
    // Use remaining seconds from offer if available
    _remainingSeconds = widget.offer.remainingSeconds;
    if (_remainingSeconds <= 0) {
      _remainingSeconds = DispatchConstants.offerCountdownSeconds;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          timer.cancel();
          _handleExpired();
        }
      }
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _setupMapMarkers() async {
    if (widget.trip.pickup?.lat != null && widget.trip.pickup?.lng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.trip.pickup!.lat!, widget.trip.pickup!.lng!),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: widget.trip.pickup?.address ?? '',
          ),
        ),
      );
    }

    if (widget.trip.dropoff?.lat != null && widget.trip.dropoff?.lng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(widget.trip.dropoff!.lat!, widget.trip.dropoff!.lng!),
          infoWindow: InfoWindow(
            title: 'Dropoff',
            snippet: widget.trip.dropoff?.address ?? '',
          ),
        ),
      );
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    _countdownTimer?.cancel();

    final driverId = sharedPref.getInt(USER_ID)?.toString() ?? '';
    final result = await _dispatchService.acceptTrip(widget.trip.id!, driverId);

    if (result.success) {
      widget.onAccepted?.call();
      if (mounted) {
        Navigator.of(context).pop(true);
        toast('Trip accepted successfully');
      }
    } else {
      setState(() {
        _isProcessing = false;
      });

      if (result.isAlreadyAccepted) {
        toast('This trip has already been taken by another driver');
        widget.onRejected?.call();
        if (mounted) Navigator.of(context).pop(false);
      } else if (result.isExpired) {
        toast('Offer has expired');
        widget.onExpired?.call();
        if (mounted) Navigator.of(context).pop(false);
      } else {
        toast(result.error ?? 'Failed to accept trip');
      }
    }
  }

  Future<void> _handleReject() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    _countdownTimer?.cancel();

    final driverId = sharedPref.getInt(USER_ID)?.toString() ?? '';
    await _dispatchService.rejectTrip(widget.trip.id!, driverId);

    widget.onRejected?.call();
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  void _handleExpired() {
    widget.onExpired?.call();
    if (mounted) {
      toast('Request timed out');
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        body: Stack(
          children: [
            // Map background
            _buildMap(),

            // Content overlay
            _buildContentOverlay(),

            // Countdown timer at top
            _buildCountdownTimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final initialPosition = widget.trip.pickup?.lat != null
        ? LatLng(widget.trip.pickup!.lat!, widget.trip.pickup!.lng!)
        : const LatLng(0, 0);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 14,
      ),
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
        _fitBounds();
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }

  void _fitBounds() {
    if (_markers.length < 2 || _mapController == null) return;

    final bounds = _calculateBounds();
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  LatLngBounds _calculateBounds() {
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    for (final marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildCountdownTimer() {
    final progress = _remainingSeconds / DispatchConstants.offerCountdownSeconds;
    final isUrgent = _remainingSeconds <= 5;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUrgent ? Colors.red.shade900 : Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer,
                  color: isUrgent ? Colors.white : Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'NEW RIDE REQUEST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Countdown progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade700,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUrgent ? Colors.red : Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_remainingSeconds seconds remaining',
              style: TextStyle(
                color: isUrgent ? Colors.white : Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.offer.isPriorityOffer) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '⭐ PRIORITY OFFER',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip type badge
                _buildTripTypeBadge(),
                const SizedBox(height: 16),

                // Pickup location
                _buildLocationRow(
                  icon: Icons.radio_button_checked,
                  iconColor: Colors.green,
                  title: 'PICKUP',
                  address: widget.trip.pickup?.address ?? 'Unknown location',
                ),

                // Dotted line connector
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Container(
                    width: 2,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                ),

                // Dropoff location (if available)
                if (widget.trip.dropoff?.address != null) ...[
                  _buildLocationRow(
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    title: 'DROPOFF',
                    address: widget.trip.dropoff!.address!,
                  ),
                  const SizedBox(height: 16),
                ],

                // Trip info row
                _buildTripInfoRow(),
                const SizedBox(height: 20),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripTypeBadge() {
    final isHourly = widget.trip.isHourlyBooking;
    final isScheduled = widget.trip.scheduledAt != null &&
        widget.trip.scheduledAt!.isAfter(DateTime.now());

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHourly ? Colors.purple.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isHourly ? '⏱ HOURLY BOOKING' : '🚗 STANDARD TRIP',
            style: TextStyle(
              color: isHourly ? Colors.purple.shade800 : Colors.blue.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        if (isScheduled) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '📅 SCHEDULED',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripInfoRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Distance
          if (widget.offer.distanceKm != null)
            _buildInfoItem(
              icon: Icons.directions_car,
              value: '${widget.offer.distanceKm!.toStringAsFixed(1)} km',
              label: 'Distance',
            ),

          // Hours (for hourly booking)
          if (widget.trip.isHourlyBooking && widget.trip.hoursBooked != null)
            _buildInfoItem(
              icon: Icons.schedule,
              value: '${widget.trip.hoursBooked}h',
              label: 'Duration',
            ),

          // Scheduled time
          if (widget.trip.scheduledAt != null)
            _buildInfoItem(
              icon: Icons.access_time,
              value: _formatTime(widget.trip.scheduledAt!),
              label: 'Pickup Time',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade700, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Reject button
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _isProcessing ? null : _handleReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'REJECT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Accept button with pulse animation
        Expanded(
          flex: 2,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ACCEPT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
