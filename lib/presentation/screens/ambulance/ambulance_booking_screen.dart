import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/geocoding_service.dart';
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

  String? _linkedIcuBookingId;
  String? _linkedHospitalId;
  String? _linkedHospitalName;
  String? _linkedHospitalNameAr;

  final _patientSearchController = TextEditingController();
  final _destinationSearchController = TextEditingController();
  Timer? _patientSearchDebounce;
  Timer? _destinationSearchDebounce;
  List<PlaceResult> _patientSuggestions = [];
  List<PlaceResult> _destinationSuggestions = [];
  bool _searchingPatient = false;
  bool _searchingDestination = false;
  final _patientFocus = FocusNode();
  final _destinationFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readArguments();
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _patientSearchController.dispose();
    _destinationSearchController.dispose();
    _patientSearchDebounce?.cancel();
    _destinationSearchDebounce?.cancel();
    _patientFocus.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  void _onPatientSearchChanged(String value) {
    _patientSearchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _patientSuggestions = [];
        _searchingPatient = false;
      });
      return;
    }
    setState(() => _searchingPatient = true);
    _patientSearchDebounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await GeocodingService.search(query);
      if (!mounted || _patientSearchController.text.trim() != query) return;
      setState(() {
        _patientSuggestions = results;
        _searchingPatient = false;
      });
    });
  }

  void _onDestinationSearchChanged(String value) {
    _destinationSearchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _destinationSuggestions = [];
        _searchingDestination = false;
      });
      return;
    }
    setState(() => _searchingDestination = true);
    _destinationSearchDebounce = Timer(
      const Duration(milliseconds: 600),
      () async {
        final results = await GeocodingService.search(query);
        if (!mounted || _destinationSearchController.text.trim() != query) {
          return;
        }
        setState(() {
          _destinationSuggestions = results;
          _searchingDestination = false;
        });
      },
    );
  }

  void _selectPatientPlace(PlaceResult place) {
    _patientSearchController.text = place.name;
    _patientFocus.unfocus();
    setState(() {
      _patientSuggestions = [];
      _patientLocation = LatLng(place.latitude, place.longitude);
      _destinationLocation = null;
      _nearbyAmbulances.clear();
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_patientLocation!, 15),
    );
    _loadNearbyAmbulances();
  }

  void _selectDestinationPlace(PlaceResult place) {
    _destinationSearchController.text = place.name;
    _destinationFocus.unfocus();
    setState(() {
      _destinationSuggestions = [];
      _destinationLocation = LatLng(place.latitude, place.longitude);
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_destinationLocation!, 15),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required String label,
    required bool searching,
    required List<PlaceResult> suggestions,
    required ValueChanged<String> onChanged,
    required ValueChanged<PlaceResult> onSelect,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          focusNode: focusNode,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: searching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              itemBuilder: (ctx, i) {
                final place = suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place, size: 18),
                  title: Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => onSelect(place),
                );
              },
            ),
          ),
      ],
    );
  }

  void _readArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _linkedIcuBookingId = args['icuBookingId'];
      _linkedHospitalId = args['hospitalId'];
      _linkedHospitalName = args['hospitalName'];
      _linkedHospitalNameAr = args['hospitalNameAr'];
    } else if (args is BookingModel) {
      final b = args;
      _linkedIcuBookingId = b.id;
      _linkedHospitalId = b.hospitalId;
      _linkedHospitalName = b.hospitalName;
      _linkedHospitalNameAr = b.hospitalNameAr;
    }
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
    _applyLinkedDestination();
  }

  Future<void> _applyLinkedDestination() async {
    final hospitalId = _linkedHospitalId;
    if (hospitalId == null || _destinationLocation != null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hospitals')
          .doc(hospitalId)
          .get();
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;
      final lat = double.tryParse('${data['latitude'] ?? ''}');
      final lng = double.tryParse('${data['longitude'] ?? ''}');
      if (lat != null && lng != null && (lat != 0 || lng != 0)) {
        setState(() {
          _destinationLocation = LatLng(lat, lng);
          _linkedHospitalName ??= data['name'];
          _linkedHospitalNameAr ??= data['nameAr'];
        });
      }
    } catch (_) {}
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

  Future<void> _submit() async {
    if (_patientLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد موقعك على الخريطة')),
      );
      return;
    }

    if (_destinationLocation == null) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى تحديد الوجهة على الخريطة'
                : 'Please set the destination on the map',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();

    final bookingModel = BookingModel(
      userId: auth.userModel!.id!,
      userName: auth.userModel!.name,
      userPhone: auth.userModel!.phone,
      userLat: _patientLocation!.latitude,
      userLng: _patientLocation!.longitude,
      bookingType: BookingType.ambulance,
      status: BookingStatus.pending,
      destinationLat: _destinationLocation?.latitude,
      destinationLng: _destinationLocation?.longitude,
      icuBookingId: _linkedIcuBookingId,
      hospitalId: _linkedHospitalId,
      hospitalName: _linkedHospitalName,
      hospitalNameAr: _linkedHospitalNameAr,
    );

    final bookingId = await booking.createBookingFromModel(bookingModel);

    if (bookingId != null && mounted) {
      setState(() => _submitting = false);
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.ambulanceTracking, arguments: bookingId);
    } else {
      setState(() => _submitting = false);
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
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.satellite,
                  initialCameraPosition: CameraPosition(
                    target: _patientLocation ?? const LatLng(24.7136, 46.6753),
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
                          _buildSearchField(
                            controller: _patientSearchController,
                            focusNode: _patientFocus,
                            label: isAr
                                ? '📍 موقع المريض'
                                : '📍 Patient location',
                            hint: isAr
                                ? 'اكتب اسم المكان أو العنوان'
                                : 'Type a place name or address',
                            searching: _searchingPatient,
                            suggestions: _patientSuggestions,
                            onChanged: _onPatientSearchChanged,
                            onSelect: _selectPatientPlace,
                          ),
                          const SizedBox(height: 8),
                          _buildSearchField(
                            controller: _destinationSearchController,
                            focusNode: _destinationFocus,
                            label: isAr ? '🏥 الوجهة' : '🏥 Destination',
                            hint: isAr
                                ? 'اكتب اسم الوجهة أو المستشفى'
                                : 'Type destination name or hospital',
                            searching: _searchingDestination,
                            suggestions: _destinationSuggestions,
                            onChanged: _onDestinationSearchChanged,
                            onSelect: _selectDestinationPlace,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr
                                ? 'اضغط على الخريطة أيضاً لتحديد الموقع والوجهة'
                                : 'You can also tap the map to set location & destination',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          if (_patientLocation == null) ...[
                            const SizedBox(height: 4),
                            Text(
                              isAr
                                  ? 'تعذر تحديد موقعك تلقائياً. اضغط على الخريطة أو ابحث بالاسم.'
                                  : 'Could not get your location automatically. Tap the map or search by name.',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          Text(
                            '${isAr ? "موقعك" : "Your location"} ${_patientLocation != null ? "✓" : "..."}',
                          ),
                          if (_linkedHospitalName != null)
                            Text(
                              '${isAr ? "الوجهة" : "Destination"}: ${isAr ? (_linkedHospitalNameAr ?? _linkedHospitalName!) : _linkedHospitalName!}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (_linkedHospitalName == null)
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
                if (_gettingLocation)
                  Positioned(
                    top: 110,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAr
                                  ? 'جار تحديد موقعك...'
                                  : 'Getting your location...',
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
                            ? 'سيتم إرسال طلبك لأقرب سائق متاح وسيتوجب عليه القبول'
                            : 'Your request will be sent to the nearest available driver for acceptance',
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
