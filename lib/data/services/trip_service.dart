import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createTrip(TripModel trip) async {
    final docRef = await _firestore.collection('trips').add(trip.toMap());
    return docRef.id;
  }

  Stream<TripModel?> getTripByBookingId(String bookingId) {
    return _firestore
        .collection('trips')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return TripModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    });
  }

  Stream<TripModel?> getTripByDriverId(String driverId) {
    return _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['heading_to_patient', 'picked_up', 'in_transit'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return TripModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    });
  }

  Future<void> updateDriverLocation({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    await _firestore.collection('trips').doc(tripId).update({
      'driverLat': lat,
      'driverLng': lng,
    });
  }

  Future<void> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    final data = <String, dynamic>{
      'status': status,
    };
    final now = DateTime.now().toIso8601String();
    switch (status) {
      case 'picked_up':
        data['arrivedAtPatientAt'] = now;
        break;
      case 'arrived':
        data['arrivedAtHospitalAt'] = now;
        break;
      case 'completed':
        data['completedAt'] = now;
        break;
    }
    await _firestore.collection('trips').doc(tripId).update(data);
  }
}
