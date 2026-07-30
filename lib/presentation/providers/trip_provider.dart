import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/trip_model.dart';
import '../../data/services/trip_service.dart';
import '../../data/services/booking_service.dart';
import '../../data/services/bed_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();
  final BookingService _bookingService = BookingService();
  final BedService _bedService = BedService();

  TripModel? _currentTrip;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _tripSubscription;

  TripModel? get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }

  void listenToTripByBookingId(String bookingId) {
    _tripSubscription?.cancel();
    _tripSubscription = _tripService.getTripByBookingId(bookingId).listen((trip) {
      _currentTrip = trip;
      notifyListeners();
    });
  }

  void listenToTripByDriverId(String driverId) {
    _tripSubscription?.cancel();
    _tripSubscription = _tripService.getTripByDriverId(driverId).listen((trip) {
      _currentTrip = trip;
      notifyListeners();
    });
  }

  Future<bool> createTrip({
    required String bookingId,
    required String ambulanceId,
    required String driverId,
    required String patientId,
    required String hospitalId,
    required double patientLat,
    required double patientLng,
    required double hospitalLat,
    required double hospitalLng,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final trip = TripModel(
        bookingId: bookingId,
        ambulanceId: ambulanceId,
        driverId: driverId,
        patientId: patientId,
        hospitalId: hospitalId,
        patientLat: patientLat,
        patientLng: patientLng,
        hospitalLat: hospitalLat,
        hospitalLng: hospitalLng,
      );
      await _tripService.createTrip(trip);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateDriverLocation({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    await _tripService.updateDriverLocation(tripId: tripId, lat: lat, lng: lng);
  }

  Future<void> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    await _tripService.updateTripStatus(tripId: tripId, status: status);
  }

  Future<void> arrivedAtPatient({
    required String tripId,
    required String bookingId,
  }) async {
    await _tripService.updateTripStatus(tripId: tripId, status: 'picked_up');
    await _bookingService.updateBookingStatus(bookingId: bookingId, status: 'inProgress');
  }

  Future<void> arrivedAtHospital({
    required String tripId,
    required String bookingId,
    required String bedId,
    required String patientName,
    required String patientId,
  }) async {
    await _tripService.updateTripStatus(tripId: tripId, status: 'arrived');
    await _bookingService.updateBookingStatus(bookingId: bookingId, status: 'completed');
    await _bedService.updateBedStatus(
      bedId: bedId,
      status: 'occupied',
      patientName: patientName,
      patientId: patientId,
      bookingId: bookingId,
    );
  }

  void cancelListening() {
    _tripSubscription?.cancel();
    _currentTrip = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
