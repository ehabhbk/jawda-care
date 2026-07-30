import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/booking_model.dart';
import '../../data/services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _bookingsSub;

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  void loadUserBookings(String userId) {
    _isLoading = true;
    notifyListeners();
    _bookingsSub?.cancel();
    _bookingsSub = _bookingService.getUserBookings(userId).listen(
      (bookings) {
        _bookings = bookings;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void loadHospitalBookings(String hospitalId) {
    _isLoading = true;
    notifyListeners();
    _bookingsSub?.cancel();
    _bookingsSub = _bookingService.getHospitalBookings(hospitalId).listen(
      (bookings) {
        _bookings = bookings;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void loadPendingHospitalBookings(String hospitalId) {
    _isLoading = true;
    notifyListeners();
    _bookingsSub?.cancel();
    _bookingsSub = _bookingService.getPendingHospitalBookings(hospitalId).listen(
      (bookings) {
        _bookings = bookings;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<String?> createBookingFromModel(BookingModel bookingModel) async {
    try {
      return await _bookingService.createBooking(bookingModel);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<bool> acceptBooking({
    required String bookingId,
    required String hospitalId,
    required String bedId,
  }) async {
    try {
      await _bookingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'accepted',
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> rejectBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      await _bookingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'rejected',
        cancellationReason: reason,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> assignAmbulanceAndStartTrip({
    required String bookingId,
    required String ambulanceId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String plateNumber,
  }) async {
    try {
      await _bookingService.assignAmbulance(
        bookingId: bookingId,
        ambulanceId: ambulanceId,
        driverId: driverId,
        driverName: driverName,
        driverPhone: driverPhone,
        plateNumber: plateNumber,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
