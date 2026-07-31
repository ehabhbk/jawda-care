import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return BookingModel.fromMap(doc.data(), doc.id);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<BookingModel>> getHospitalBookings(String hospitalId) {
    return _firestore
        .collection('bookings')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return BookingModel.fromMap(doc.data(), doc.id);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<BookingModel>> getDriverBookings(String driverId) {
    return _firestore
        .collection('bookings')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return BookingModel.fromMap(doc.data(), doc.id);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<BookingModel>> getPendingHospitalBookings(String hospitalId) {
    return _firestore
        .collection('bookings')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .where((booking) => booking.status == BookingStatus.pending)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<BookingModel>> getPendingDriverBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .where((booking) => booking.ambulanceId == null)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
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
