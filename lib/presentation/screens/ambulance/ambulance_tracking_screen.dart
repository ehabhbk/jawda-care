import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';

class AmbulanceTrackingScreen extends StatefulWidget {
  final String bookingId;

  const AmbulanceTrackingScreen({super.key, required this.bookingId});

  @override
  State<AmbulanceTrackingScreen> createState() =>
      _AmbulanceTrackingScreenState();
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
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .snapshots(),
        builder: (ctx, bookingSnap) {
          if (!bookingSnap.hasData)
            return const Center(child: CircularProgressIndicator());
          final bookingData = bookingSnap.data!.data() as Map<String, dynamic>?;

          final status = bookingData?['status'] ?? 'pending';
          final ambulanceId = bookingData?['ambulanceId'];
          final patientLat = (bookingData?['userLat'] ?? 0).toDouble();
          final patientLng = (bookingData?['userLng'] ?? 0).toDouble();
          final destLat = (bookingData?['destinationLat']).toDouble();
          final destLng = (bookingData?['destinationLng']).toDouble();

          if (ambulanceId == null) {
            return Stack(
              children: [
                if (destLat != null &&
                    destLat != 0 &&
                    destLng != null &&
                    destLng != 0)
                  GoogleMap(
                    mapType: MapType.satellite,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(patientLat, patientLng),
                      zoom: 12,
                    ),
                    markers: {
                      if (patientLat != 0)
                        Marker(
                          markerId: const MarkerId('patient'),
                          position: LatLng(patientLat, patientLng),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                        ),
                      Marker(
                        markerId: const MarkerId('destination'),
                        position: LatLng(destLat, destLng),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                        infoWindow: InfoWindow(
                          title:
                              (bookingData?['hospitalNameAr'] ??
                                  bookingData?['hospitalName']) ??
                              (isAr ? 'الوجهة' : 'Destination'),
                        ),
                      ),
                    },
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.airport_shuttle,
                        size: 80,
                        color: AppColors.ambulanceRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAr
                            ? 'في انتظار قبول سائق الإسعاف...'
                            : 'Waiting for a driver to accept...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'سيصلك إشعار فور قبول السائق. سيتم تحويل الطلب تلقائياً لأقرب سائق آخر إذا رفض أي سائق.'
                            : 'You will be notified once a driver accepts. The request is automatically offered to the next nearest driver if one declines.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ambulances')
                .doc(ambulanceId)
                .snapshots(),
            builder: (ctx, ambSnap) {
              final ambData = ambSnap.data?.data() as Map<String, dynamic>?;
              final driverLat = (ambData?['currentLat'] ?? 0).toDouble();
              final driverLng = (ambData?['currentLng'] ?? 0).toDouble();
              final driverName = bookingData?['driverName'] ?? '...';
              final driverPhone = bookingData?['driverPhone'] ?? '...';
              final plateNumber = bookingData?['plateNumber'] ?? '...';

              final distance = (driverLat != 0 && patientLat != 0)
                  ? _distanceInKm(driverLat, driverLng, patientLat, patientLng)
                  : null;
              final eta = distance != null
                  ? (distance / 40 * 60).round()
                  : null;

              final markers = <Marker>{
                if (patientLat != 0)
                  Marker(
                    markerId: const MarkerId('patient'),
                    position: LatLng(patientLat, patientLng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue,
                    ),
                    infoWindow: const InfoWindow(title: 'موقعي'),
                  ),
                if (driverLat != 0)
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: LatLng(driverLat, driverLng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: InfoWindow(
                      title: isAr ? 'الإسعاف' : 'Ambulance',
                    ),
                  ),
                if (destLat != null && destLat != 0)
                  Marker(
                    markerId: const MarkerId('destination'),
                    position: LatLng(destLat, destLng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                    infoWindow: InfoWindow(
                      title: isAr ? 'الوجهة' : 'Destination',
                    ),
                  ),
              };

              return Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      mapType: MapType.satellite,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(patientLat, patientLng),
                        zoom: 12,
                      ),
                      markers: markers,
                      polylines: {
                        if (driverLat != 0 && patientLat != 0)
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: [
                              LatLng(driverLat, driverLng),
                              LatLng(patientLat, patientLng),
                            ],
                            color: Colors.blue,
                            width: 4,
                          ),
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (distance != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _InfoChip(
                                label: isAr ? 'المسافة' : 'Distance',
                                value: distance < 1
                                    ? '${(distance * 1000).round()} م'
                                    : '${distance.toStringAsFixed(1)} كم',
                              ),
                              _InfoChip(
                                label: isAr ? 'الوصول المتوقع' : 'ETA',
                                value: eta! < 1
                                    ? '${isAr ? "أقل من دقيقة" : "Less than 1 min"}'
                                    : '$eta ${isAr ? "دقيقة" : "min"}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: AppColors.ambulanceRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$driverName | $plateNumber',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (driverPhone != '...')
                                    Text(
                                      driverPhone,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.teal),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _StatusChip(status: status, isAr: isAr),
                      ],
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

  double _distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = 6371;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return c * (2 * asin(sqrt(a)));
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isAr;
  const _StatusChip({required this.status, required this.isAr});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    switch (status) {
      case 'accepted':
        text = isAr ? 'تم التعيين ✓' : 'Assigned ✓';
        color = Colors.blue;
        break;
      case 'headingToPatient':
        text = isAr ? '🚑 الإسعاف في الطريق' : '🚑 Ambulance en route';
        color = Colors.orange;
        break;
      case 'pickedUp':
        text = isAr
            ? '🚑 تم الاستلام - متجه للوجهة'
            : '🚑 Heading to destination';
        color = Colors.teal;
        break;
      case 'arrived':
      case 'completed':
        text = isAr ? '✅ تمت الرحلة بنجاح' : '✅ Trip completed';
        color = Colors.green;
        break;
      default:
        text = isAr ? 'في الانتظار...' : 'Pending...';
        color = Colors.grey;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ambulanceRed,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
