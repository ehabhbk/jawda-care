import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/location_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class AmbulanceBookingScreen extends StatefulWidget {
  const AmbulanceBookingScreen({super.key});

  @override
  State<AmbulanceBookingScreen> createState() => _AmbulanceBookingScreenState();
}

class _AmbulanceBookingScreenState extends State<AmbulanceBookingScreen> {
  GoogleMapController? _mapController;
  LatLng? _patientLocation;
  LatLng? _destinationLocation;
  bool _gettingLocation = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _nearbyAmbulances = [];
  bool _loadingAmbulances = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final pos = await LocationService.getPosition(context);
    if (!mounted) return;
    if (pos == null) {
      setState(() => _gettingLocation = false);
      return;
    }
    setState(() {
      _patientLocation = LatLng(pos.latitude, pos.longitude);
      _gettingLocation = false;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_patientLocation!, 14),
    );
    _loadNearbyAmbulances();
  }

  Future<void> _loadNearbyAmbulances() async {
    if (_patientLocation == null) return;
    setState(() => _loadingAmbulances = true);
    final snap = await FirebaseFirestore.instance
        .collection('ambulances')
        .where('status', isEqualTo: 'available')
        .get();
    final ambulances = snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
    ambulances.sort((a, b) {
      final distA = _distanceInKm(
        _patientLocation!.latitude,
        _patientLocation!.longitude,
        (a['currentLat'] ?? 0).toDouble(),
        (a['currentLng'] ?? 0).toDouble(),
      );
      final distB = _distanceInKm(
        _patientLocation!.latitude,
        _patientLocation!.longitude,
        (b['currentLat'] ?? 0).toDouble(),
        (b['currentLng'] ?? 0).toDouble(),
      );
      return distA.compareTo(distB);
    });
    if (mounted)
      setState(() {
        _nearbyAmbulances = ambulances;
        _loadingAmbulances = false;
      });
  }

  double _distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = 6371;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return c * (2 * asin(sqrt(a)));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_patientLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد موقعك على الخريطة')),
      );
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final bookingModel = BookingModel(
      userId: auth.userModel!.id!,
      userName: auth.userModel!.name,
      userPhone: auth.userModel!.phone,
      userLat: _patientLocation!.latitude,
      userLng: _patientLocation!.longitude,
      bookingType: BookingType.ambulance,
    );

    final bookingId = await booking.createBookingFromModel(bookingModel);

    if (bookingId != null && mounted) {
      if (_nearbyAmbulances.isNotEmpty) {
        final nearest = _nearbyAmbulances.first;
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
              'ambulanceId': nearest['id'],
              'driverName': nearest['driverName'],
              'driverPhone': nearest['driverPhone'],
              'plateNumber': nearest['plateNumber'],
              'status': 'accepted',
              'destinationLat': _destinationLocation?.latitude,
              'destinationLng': _destinationLocation?.longitude,
            });
        await FirebaseFirestore.instance
            .collection('ambulances')
            .doc(nearest['id'])
            .update({'status': 'occupied'});
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.ambulanceTracking,
          arguments: bookingId,
        );
      } else {
        setState(() => _submitting = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                isAr ? 'لا توجد سيارات إسعاف' : 'No ambulances available',
              ),
              content: Text(
                isAr
                    ? 'عذراً، لا توجد سيارات إسعاف متاحة حالياً. يرجى المحاولة لاحقاً.'
                    : 'Sorry, no ambulances are available right now. Please try again later.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(isAr ? 'حسناً' : 'OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_patientLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('patient'),
          position: _patientLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'موقعي'),
        ),
      );
    }
    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'الوجهة'),
        ),
      );
    }
    for (final amb in _nearbyAmbulances) {
      final lat = (amb['currentLat'] ?? 0).toDouble();
      final lng = (amb['currentLng'] ?? 0).toDouble();
      if (lat != 0 || lng != 0) {
        markers.add(
          Marker(
            markerId: MarkerId('amb_${amb['id']}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: 'سيارة إسعاف - ${amb['plateNumber'] ?? ''}',
            ),
          ),
        );
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.ambulanceRed,
        title: Text(isAr ? 'طلب إسعاف' : 'Ambulance Request'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _gettingLocation
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      GoogleMap(
                        mapType: MapType.satellite,
                        initialCameraPosition: CameraPosition(
                          target:
                              _patientLocation ??
                              const LatLng(24.7136, 46.6753),
                          zoom: 14,
                        ),
                        onMapCreated: (ctrl) => _mapController = ctrl,
                        onTap: (pos) {
                          setState(() {
                            if (_patientLocation == null) {
                              _patientLocation = pos;
                            } else if (_destinationLocation == null) {
                              _destinationLocation = pos;
                            } else {
                              _patientLocation = pos;
                              _destinationLocation = null;
                              _nearbyAmbulances.clear();
                              _loadNearbyAmbulances();
                            }
                          });
                        },
                        markers: _buildMarkers(),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isAr
                                      ? '📍 اضغط على الخريطة لتحديد:'
                                      : '📍 Tap map to set:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (_patientLocation == null) ...[
                                  Text(
                                    isAr
                                        ? 'تعذر تحديد موقعك تلقائياً. اضغط على الخريطة لتحديد موقعك ثم الوجهة.'
                                        : 'Could not get your location automatically. Tap the map to set your location, then the destination.',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  '${isAr ? "موقعك" : "Your location"} ${_patientLocation != null ? "✓" : "..."}',
                                ),
                                Text(
                                  '${isAr ? "الوجهة" : "Destination"} ${_destinationLocation != null ? "✓" : "..."}',
                                ),
                                if (_nearbyAmbulances.isNotEmpty)
                                  Text(
                                    '${isAr ? "سيارات إسعاف متاحة" : "Available ambulances"}: ${_nearbyAmbulances.length}',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loadingAmbulances) const LinearProgressIndicator(),
                  if (_nearbyAmbulances.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        isAr
                            ? 'سيتم إرسال أقرب سيارة إسعاف إليك'
                            : 'Nearest ambulance will be sent to you',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ambulanceRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isAr ? 'طلب الإسعاف' : 'Request Ambulance',
                              style: const TextStyle(fontSize: 18),
                            ),
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
