import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class BookingNotificationWatcher {
  BookingNotificationWatcher._();
  static final BookingNotificationWatcher instance = BookingNotificationWatcher._();

  StreamSubscription<QuerySnapshot>? _patientSub;
  StreamSubscription<QuerySnapshot>? _hospitalSub;
  StreamSubscription<QuerySnapshot>? _driverSub;

  final Map<String, String> _patientStatus = {};
  final Map<String, String> _hospitalStatus = {};
  final Map<String, String> _driverStatus = {};

  void start({required String userId, String? hospitalId}) {
    stop();
    _startPatientWatch(userId);
    if (hospitalId != null && hospitalId.isNotEmpty) _startHospitalWatch(hospitalId);
  }

  void startDriverWatch(String ambulanceId) {
    _driverSub?.cancel();
    _driverSub = null;
    _driverStatus.clear();

    _driverSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('ambulanceId', isEqualTo: ambulanceId)
        .snapshots()
        .listen(
      (snap) {
        for (final change in snap.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;
          _handleDriverBooking(change.doc.id, data, change.type);
        }
      },
      onError: (_) {},
    );
  }

  void stop() {
    _patientSub?.cancel();
    _patientSub = null;
    _hospitalSub?.cancel();
    _hospitalSub = null;
    _driverSub?.cancel();
    _driverSub = null;
    _patientStatus.clear();
    _hospitalStatus.clear();
    _driverStatus.clear();
  }

  void _startPatientWatch(String userId) {
    _patientStatus.clear();
    _patientSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snap) {
        for (final change in snap.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;
          _handlePatientBooking(change.doc.id, data, change.type);
        }
      },
      onError: (_) {},
    );
  }

  void _startHospitalWatch(String hospitalId) {
    _hospitalStatus.clear();
    _hospitalSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .listen(
      (snap) {
        for (final change in snap.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>;
          _handleHospitalBooking(change.doc.id, data, change.type);
        }
      },
      onError: (_) {},
    );
  }

  void _handlePatientBooking(String id, Map<String, dynamic> data, DocumentChangeType type) {
    final status = (data['status'] ?? '').toString();
    if (_patientStatus.isEmpty) {
      _patientStatus[id] = status;
      return;
    }
    final prev = _patientStatus[id];
    _patientStatus[id] = status;
    if (prev == null || prev == status) return;

    final isIcu = data['bookingType'] == 'icu';
    switch (status) {
      case 'accepted':
        if (isIcu) {
          NotificationService.showLocalNotification(
            'تم تأكيد حجز السرير',
            'تم حجز السرير ${data['bedName'] ?? ''} بنجاح.',
          );
        } else {
          NotificationService.showLocalNotification(
            'تم تعيين سيارة إسعاف',
            'السائق: ${data['driverName'] ?? ''} - اللوحة: ${data['plateNumber'] ?? ''}',
          );
        }
        break;
      case 'confirmed':
        NotificationService.showLocalNotification(
          'تم تأكيد حجز السرير',
          'تم حجز السرير ${data['bedName'] ?? ''} بنجاح.',
        );
        break;
      case 'headingToPatient':
        NotificationService.showLocalNotification(
          'السائق في الطريق إليك',
          'سيارة الإسعاف قادمة إليك. تتبع موقعها الآن.',
        );
        break;
      case 'pickedUp':
        NotificationService.showLocalNotification(
          'تم الاستلام',
          'تم استلامك، نحن في الطريق إلى الوجهة.',
        );
        break;
      case 'arrived':
        NotificationService.showLocalNotification(
          'وصلنا إلى الوجهة',
          'تم الوصول. نتمنى الشفاء العاجل.',
        );
        break;
      case 'rejected':
        NotificationService.showLocalNotification(
          'تم رفض الطلب',
          isIcu ? 'نعتذر، لم يتم قبول طلب حجز السرير.' : 'نعتذر، لم يتمكن السائق من تنفيذ طلبك.',
        );
        break;
      case 'completed':
        NotificationService.showLocalNotification(
          'اكتمل الحجز',
          'نتمنى الشفاء العاجل.',
        );
        break;
    }
  }

  void _handleHospitalBooking(String id, Map<String, dynamic> data, DocumentChangeType type) {
    final status = (data['status'] ?? '').toString();
    if (_hospitalStatus.isEmpty) {
      _hospitalStatus[id] = status;
      return;
    }
    final prev = _hospitalStatus[id];
    _hospitalStatus[id] = status;

    if (prev == null && type == DocumentChangeType.added && status == 'pending') {
      NotificationService.showLocalNotification(
        'طلب حجز سرير جديد',
        '${data['userName'] ?? ''} طلب حجز سرير في ${data['hospitalName'] ?? 'المستشفى'}',
      );
    } else if (prev != null && prev != status && status == 'cancelled') {
      NotificationService.showLocalNotification(
        'تم إلغاء الحجز',
        'ألغى ${data['userName'] ?? ''} طلب حجز السرير.',
      );
    }
  }

  void _handleDriverBooking(String id, Map<String, dynamic> data, DocumentChangeType type) {
    final status = (data['status'] ?? '').toString();
    if (_driverStatus.isEmpty) {
      _driverStatus[id] = status;
      return;
    }
    final prev = _driverStatus[id];
    _driverStatus[id] = status;

    if (prev == null && type == DocumentChangeType.added && status == 'accepted') {
      NotificationService.showLocalNotification(
        'طلب إسعاف جديد',
        'تم تعيينك لطلب إسعاف جديد للمريض ${data['userName'] ?? ''}.',
      );
    } else if (prev != null && prev != status && status == 'cancelled') {
      NotificationService.showLocalNotification(
        'تم إلغاء الطلب',
        'ألغى المريض طلب الإسعاف.',
      );
    }
  }
}
