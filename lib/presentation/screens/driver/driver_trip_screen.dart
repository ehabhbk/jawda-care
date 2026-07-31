import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';

class DriverTripScreen extends StatefulWidget {
  final String bookingId;
  final String ambulanceId;

  const DriverTripScreen({
    super.key,
    required this.bookingId,
    required this.ambulanceId,
  });

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  GoogleMapController? _mapController;
  Map<String, dynamic>? _bookingData;
  String _tripStatus = 'headingToPatient';
  double? _patientLat;
  double? _patientLng;
  double? _destLat;
  double? _destLng;
  double _driverLat = 0;
  double _driverLng = 0;
  Timer? _gpsTimer;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _startGpsUpdates();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    final doc = await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    setState(() {
      _bookingData = data;
      _patientLat = (data['userLat'] ?? 0).toDouble();
      _patientLng = (data['userLng'] ?? 0).toDouble();
      _destLat = (data['destinationLat'] ?? 0).toDouble();
      _destLng = (data['destinationLng'] ?? 0).toDouble();
    });
  }

  void _startGpsUpdates() {
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (!mounted) return;
        setState(() {
          _driverLat = pos.latitude;
          _driverLng = pos.longitude;
        });
        await FirebaseFirestore.instance.collection('ambulances').doc(widget.ambulanceId).update({
          'currentLat': _driverLat,
          'currentLng': _driverLng,
        });
      } catch (_) {}
    });
  }

  Future<void> _updateTripStatus(String status) async {
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{'status': status};
    if (status == 'pickedUp') data['pickedUpAt'] = now;
    if (status == 'arrived') data['completedAt'] = now;

    await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update(data);
    if (mounted) setState(() => _tripStatus = status);

    if (status == 'arrived') {
      await FirebaseFirestore.instance.collection('ambulances').doc(widget.ambulanceId).update({
        'status': 'available',
      });
    }
  }

  Future<void> _rejectTrip() async {
    await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
      'status': 'rejected',
      'ambulanceId': FieldValue.delete(),
      'driverName': FieldValue.delete(),
      'driverPhone': FieldValue.delete(),
      'plateNumber': FieldValue.delete(),
    });
    await FirebaseFirestore.instance.collection('ambulances').doc(widget.ambulanceId).update({
      'status': 'available',
    });
    if (mounted) Navigator.pop(context);
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      if (_patientLat != null)
        Marker(
          markerId: const MarkerId('patient'),
          position: LatLng(_patientLat!, _patientLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: _bookingData?['userName'] ?? 'مريض'),
        ),
      if (_destLat != null && _destLat != 0)
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(_destLat!, _destLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'الوجهة'),
        ),
      if (_driverLat != 0)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(_driverLat, _driverLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'موقعي'),
        ),
    };
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.ambulanceRed,
        title: Text(isAr ? 'الرحلة' : 'Trip'),
        actions: [
          TextButton.icon(
            onPressed: _rejectTrip,
            icon: const Icon(Icons.close, color: Colors.white),
            label: Text(isAr ? 'رفض' : 'Reject', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _patientLat == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_patientLat!, _patientLng!),
                      zoom: 13,
                    ),
                    onMapCreated: (ctrl) => _mapController = ctrl,
                    markers: _buildMarkers(),
                    polylines: {
                      if (_patientLat != null && _destLat != null && _destLat != 0)
                        Polyline(
                          polylineId: const PolylineId('route_to_patient'),
                          points: [
                            if (_driverLat != 0) LatLng(_driverLat, _driverLng),
                            LatLng(_patientLat!, _patientLng!),
                          ],
                          color: Colors.blue,
                          width: 4,
                        ),
                      if (_destLat != null && _destLat != 0)
                        Polyline(
                          polylineId: const PolylineId('route_to_dest'),
                          points: [
                            LatLng(_patientLat!, _patientLng!),
                            LatLng(_destLat!, _destLng!),
                          ],
                          color: Colors.teal,
                          width: 3,
                        ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(backgroundColor: AppColors.ambulanceRed, child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_bookingData?['userName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(_bookingData?['userPhone'] ?? '', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_tripStatus == 'headingToPatient')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _updateTripStatus('pickedUp'),
                            child: Text(isAr ? '✅ تم الوصول إلى المريض' : '✅ Picked up patient'),
                          ),
                        )
                      else if (_tripStatus == 'pickedUp')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _updateTripStatus('arrived'),
                            child: Text(isAr ? '🏥 تم الوصول إلى الوجهة' : '🏥 Arrived at destination'),
                          ),
                        )
                      else if (_tripStatus == 'arrived' || _tripStatus == 'completed')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'تم الانتهاء من الرحلة' : 'Trip completed',
                                style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
