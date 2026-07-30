import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';

class AmbulanceTrackingScreen extends StatefulWidget {
  final String bookingId;

  const AmbulanceTrackingScreen({super.key, required this.bookingId});

  @override
  State<AmbulanceTrackingScreen> createState() => _AmbulanceTrackingScreenState();
}

class _AmbulanceTrackingScreenState extends State<AmbulanceTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.ambulanceRed,
        title: Text(isAr ? 'تتبع الإسعاف' : 'Ambulance Tracking'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots(),
        builder: (ctx, bookingSnap) {
          if (!bookingSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bookingData = bookingSnap.data!.data() as Map<String, dynamic>?;

          final ambulanceId = bookingData?['ambulanceId'];
          if (ambulanceId == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.airport_shuttle, size: 80, color: AppColors.ambulanceRed),
                  const SizedBox(height: 16),
                  Text(isAr ? 'في انتظار تعيين سيارة إسعاف' : 'Waiting for ambulance assignment'),
                ],
              ),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('ambulances').doc(ambulanceId).snapshots(),
            builder: (ctx, ambSnap) {
              final ambData = ambSnap.data?.data() as Map<String, dynamic>?;
              final driverLat = (ambData?['currentLat'] ?? 0).toDouble();
              final driverLng = (ambData?['currentLng'] ?? 0).toDouble();
              final patientLat = (bookingData?['userLat'] ?? 0).toDouble();
              final patientLng = (bookingData?['userLng'] ?? 0).toDouble();

              return Column(
                children: [
                  Expanded(
                    child: driverLat == 0 && driverLng == 0
                        ? Center(
                            child: Text(isAr ? 'جار الحصول على موقع الإسعاف...' : 'Getting ambulance location...'),
                          )
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(patientLat, patientLng),
                              zoom: 12,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('driver'),
                                position: LatLng(driverLat, driverLng),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                infoWindow: InfoWindow(title: isAr ? 'الإسعاف' : 'Ambulance'),
                              ),
                              Marker(
                                markerId: const MarkerId('patient'),
                                position: LatLng(patientLat, patientLng),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                                infoWindow: InfoWindow(title: isAr ? 'موقعي' : 'My Location'),
                              ),
                            },
                          ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(isAr ? 'السائق: ${bookingData?["driverName"] ?? "..."}' : 'Driver: ${bookingData?["driverName"] ?? "..."}'),
                          Text(isAr ? 'اللوحة: ${bookingData?["plateNumber"] ?? "..."}' : 'Plate: ${bookingData?["plateNumber"] ?? "..."}'),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.phone),
                              label: Text(isAr ? 'اتصال بالسائق' : 'Call Driver'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
