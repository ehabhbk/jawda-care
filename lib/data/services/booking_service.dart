import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<BookingModel>> getHospitalBookings(String hospitalId) {
    return _firestore
        .collection('bookings')
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<BookingModel>> getDriverBookings(String driverId) {
    return _firestore
        .collection('bookings')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<BookingModel>> getPendingHospitalBookings(String hospitalId) {
    return _firestore
        .collection('bookings')
        .where('hospitalId', isEqualTo: hospitalId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<BookingModel>> getPendingDriverBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'accepted')
        .where('ambulanceId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<String> createBooking(BookingModel booking) async {
    final docRef = await _firestore.collection('bookings').add(booking.toMap());
    return docRef.id;
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (doc.exists) {
      return BookingModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? cancellationReason,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (cancellationReason != null) {
      data['cancellationReason'] = cancellationReason;
    }
    await _firestore.collection('bookings').doc(bookingId).update(data);
  }

  Future<void> assignAmbulance({
    required String bookingId,
    required String ambulanceId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String plateNumber,
  }) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'ambulanceId': ambulanceId,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'plateNumber': plateNumber,
      'status': 'inProgress',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
