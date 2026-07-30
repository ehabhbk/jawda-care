import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  BookingModel? _booking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? bookingId;
    if (args is String) {
      bookingId = args;
    } else if (args is BookingModel) {
      bookingId = args.id;
    }

    if (bookingId == null) return;

    final doc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
    if (doc.exists && mounted) {
      setState(() {
        _booking = BookingModel.fromMap(doc.data()!, doc.id);
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.pendingOrange;
      case 'accepted':
      case 'confirmed':
        return AppColors.success;
      case 'inProgress':
        return AppColors.info;
      case 'completed':
        return AppColors.textSecondary;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _acceptBooking() async {
    final bp = context.read<BookingProvider>();
    final auth = context.read<AuthProvider>();
    final hospital = auth.hospitalAccount;

    final bedId = _booking?.bedId;
    if (bedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم تحديد سرير')),
      );
      return;
    }

    await bp.acceptBooking(
      bookingId: _booking!.id!,
      hospitalId: hospital!.id!,
      bedId: bedId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول الحجز')),
      );
      _load();
    }
  }

  Future<void> _rejectBooking() async {
    final bp = context.read<BookingProvider>();
    await bp.rejectBooking(bookingId: _booking!.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض الحجز')),
      );
      _load();
    }
  }

  Future<void> _cancelBooking() async {
    final bp = context.read<BookingProvider>();
    await bp.rejectBooking(bookingId: _booking!.id!, reason: 'ألغاه المستخدم');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الحجز')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final auth = context.watch<AuthProvider>();

    if (_loading) return Scaffold(appBar: AppBar(title: const Text('')), body: const Center(child: CircularProgressIndicator()));
    if (_booking == null) return Scaffold(appBar: AppBar(title: const Text('')), body: const Center(child: Text('لا توجد بيانات')));

    final b = _booking!;
    final isIcu = b.bookingType.name == 'icu';
    final isHospitalUser = auth.isHospital;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isAr ? 'تفاصيل الحجز' : 'Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusColor(b.status.name).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      isIcu ? Icons.bed : Icons.airport_shuttle,
                      size: 40,
                      color: _statusColor(b.status.name),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? b.statusLabelAr : b.statusLabel,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _statusColor(b.status.name)),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(isAr ? 'المريض' : 'Patient', b.userName, Icons.person),
                  _buildInfoRow(isAr ? 'الهاتف' : 'Phone', b.userPhone, Icons.phone),
                  if (b.hospitalName != null)
                    _buildInfoRow(isAr ? 'المستشفى' : 'Hospital', isAr ? (b.hospitalNameAr ?? b.hospitalName!) : b.hospitalName!, Icons.local_hospital),
                  if (b.departmentName != null)
                    _buildInfoRow(isAr ? 'القسم' : 'Department', isAr ? (b.departmentNameAr ?? b.departmentName!) : b.departmentName!, Icons.category),
                  if (b.bedName != null)
                    _buildInfoRow(isAr ? 'السرير' : 'Bed', isAr ? (b.bedNameAr ?? b.bedName!) : b.bedName!, Icons.bed),
                  if (b.driverName != null)
                    _buildInfoRow(isAr ? 'السائق' : 'Driver', b.driverName!, Icons.person),
                  if (b.driverPhone != null)
                    _buildInfoRow(isAr ? 'هاتف السائق' : 'Driver Phone', b.driverPhone!, Icons.phone),
                  if (b.plateNumber != null)
                    _buildInfoRow(isAr ? 'رقم اللوحة' : 'Plate', b.plateNumber!, Icons.directions_car),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isHospitalUser && b.status == BookingStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _acceptBooking,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text(isAr ? 'قبول' : 'Accept', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _rejectBooking,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(isAr ? 'رفض' : 'Reject', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            if (!isHospitalUser && (b.status == BookingStatus.pending || b.status == BookingStatus.accepted))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cancelBooking,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(isAr ? 'إلغاء الحجز' : 'Cancel Booking', style: const TextStyle(color: Colors.white)),
                ),
              ),
            if (b.status == BookingStatus.accepted || b.status == BookingStatus.inProgress)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.ambulanceTracking, arguments: b.id),
                  icon: const Icon(Icons.map),
                  label: Text(isAr ? 'تتبع الحجز' : 'Track Booking'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
