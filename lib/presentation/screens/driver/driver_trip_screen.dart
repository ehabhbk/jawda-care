import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/booking_service.dart';
import '../../../data/services/bed_service.dart';

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
  final BookingService _bookingService = BookingService();
  final BedService _bedService = BedService();

  Map<String, dynamic>? _bookingData;
  String? _tripId;
  String _tripStatus = 'heading_to_patient';
  double? _patientLat;
  double? _patientLng;
  double? _hospitalLat;
  double? _hospitalLng;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final doc = await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _bookingData = data;
        _patientLat = (data['userLat'] ?? 0).toDouble();
        _patientLng = (data['userLng'] ?? 0).toDouble();
      });
      _loadHospital();
      _createTrip();
    }
  }

  Future<void> _loadHospital() async {
    if (_bookingData?['hospitalId'] == null) return;
    final doc = await FirebaseFirestore.instance.collection('hospitals').doc(_bookingData!['hospitalId']).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _hospitalLat = (data['latitude'] ?? 0).toDouble();
        _hospitalLng = (data['longitude'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _createTrip() async {
    if (_patientLat == null || _hospitalLat == null) return;
    final tripData = {
      'bookingId': widget.bookingId,
      'ambulanceId': widget.ambulanceId,
      'driverId': FirebaseAuth.instance.currentUser!.uid,
      'patientId': _bookingData!['userId'],
      'hospitalId': _bookingData!['hospitalId'],
      'patientLat': _patientLat,
      'patientLng': _patientLng,
      'hospitalLat': _hospitalLat,
      'hospitalLng': _hospitalLng,
      'driverLat': 0,
      'driverLng': 0,
      'status': 'heading_to_patient',
      'createdAt': DateTime.now().toIso8601String(),
    };
    final ref = await FirebaseFirestore.instance.collection('trips').add(tripData);
    setState(() => _tripId = ref.id);
  }

  Future<void> _updateTripStatus(String status) async {
    if (_tripId == null) return;
    final data = <String, dynamic>{'status': status};
    final now = DateTime.now().toIso8601String();
    switch (status) {
      case 'picked_up':
        data['arrivedAtPatientAt'] = now;
        break;
      case 'arrived':
        data['arrivedAtHospitalAt'] = now;
        break;
    }
    await FirebaseFirestore.instance.collection('trips').doc(_tripId!).update(data);
    setState(() => _tripStatus = status);
  }

  Future<void> _arrivedAtHospital() async {
    await _updateTripStatus('arrived');
    await _bookingService.updateBookingStatus(
      bookingId: widget.bookingId,
      status: 'completed',
    );

    final bedId = _bookingData?['bedId'];
    if (bedId != null) {
      await _bedService.updateBedStatus(
        bedId: bedId,
        status: 'occupied',
        patientName: _bookingData?['userName'],
        patientId: _bookingData?['userId'],
        bookingId: widget.bookingId,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الوصول إلى المستشفى')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الرحلة' : 'Trip'),
      ),
      body: _patientLat == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_patientLat!, _patientLng!),
                      zoom: 12,
                    ),
                    markers: {
                      if (_patientLat != null)
                        Marker(
                          markerId: const MarkerId('patient'),
                          position: LatLng(_patientLat!, _patientLng!),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                          infoWindow: InfoWindow(title: _bookingData?['userName'] ?? 'المريض'),
                        ),
                      if (_hospitalLat != null)
                        Marker(
                          markerId: const MarkerId('hospital'),
                          position: LatLng(_hospitalLat!, _hospitalLng!),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                          infoWindow: const InfoWindow(title: 'المستشفى'),
                        ),
                    },
                    polylines: {
                      if (_patientLat != null && _hospitalLat != null)
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: [
                            LatLng(_patientLat!, _patientLng!),
                            LatLng(_hospitalLat!, _hospitalLng!),
                          ],
                          color: Colors.blue,
                          width: 4,
                        ),
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${isAr ? "المريض" : "Patient"}: ${_bookingData?['userName'] ?? ""}', style: const TextStyle(fontSize: 16)),
                        Text('${isAr ? "المستشفى" : "Hospital"}: ${_bookingData?['hospitalNameAr'] ?? _bookingData?['hospitalName'] ?? ""}'),
                        const SizedBox(height: 8),
                        if (_tripStatus == 'heading_to_patient')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              onPressed: () => _updateTripStatus('picked_up'),
                              child: Text(isAr ? 'تم الوصول إلى المريض' : 'Arrived at patient'),
                            ),
                          )
                        else if (_tripStatus == 'picked_up')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              onPressed: _arrivedAtHospital,
                              child: Text(isAr ? 'تم الوصول إلى المستشفى' : 'Arrived at hospital'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
