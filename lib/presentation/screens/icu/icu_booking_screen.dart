import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/hospital_service.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';

class IcuBookingScreen extends StatefulWidget {
  const IcuBookingScreen({super.key});

  @override
  State<IcuBookingScreen> createState() => _IcuBookingScreenState();
}

class _IcuBookingScreenState extends State<IcuBookingScreen> {
  HospitalModel? _hospital;
  List<Map<String, dynamic>> _departments = [];
  Map<String, List<Map<String, dynamic>>> _beds = {};
  String? _selectedDeptId;
  String? _selectedBedId;
  String? _selectedBedName;
  String? _selectedBedNameAr;
  bool _loading = true;
  final _hospitalService = HospitalService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? hospitalId;

    if (args is String) {
      hospitalId = args;
    } else if (args is HospitalModel) {
      hospitalId = args.id;
    }

    if (hospitalId == null) return;

    final h = await _hospitalService.getHospitalById(hospitalId);
    if (h == null) return;

    final deptSnap = await FirebaseFirestore.instance
        .collection('departments')
        .where('hospitalId', isEqualTo: hospitalId)
        .get();

    final depts = deptSnap.docs.map((d) => {'id': d.id, 'name': d['name'], 'nameAr': d['nameAr']}).toList();

    final bedsMap = <String, List<Map<String, dynamic>>>{};
    for (final dept in depts) {
      final bedSnap = await FirebaseFirestore.instance
          .collection('beds')
          .where('departmentId', isEqualTo: dept['id'])
          .where('status', isEqualTo: 'available')
          .get();
      bedsMap[dept['id']] = bedSnap.docs.map((b) => {'id': b.id, 'name': b['name'], 'nameAr': b['nameAr']}).toList();
    }

    if (mounted) setState(() {
      _hospital = h;
      _departments = depts;
      _beds = bedsMap;
      _loading = false;
    });
  }

  Future<void> _book() async {
    if (_selectedBedId == null) return;

    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();

    try {
      final pos = await Geolocator.getCurrentPosition();

      final bookingModel = BookingModel(
        userId: auth.userModel!.id!,
        userName: auth.userModel!.name,
        userPhone: auth.userModel!.phone,
        userLat: pos.latitude,
        userLng: pos.longitude,
        bookingType: BookingType.icu,
        status: BookingStatus.pending,
        departmentId: _selectedDeptId,
        departmentName: _departments.firstWhere((d) => d['id'] == _selectedDeptId)['name'],
        departmentNameAr: _departments.firstWhere((d) => d['id'] == _selectedDeptId)['nameAr'],
        bedId: _selectedBedId,
        bedName: _selectedBedName,
        bedNameAr: _selectedBedNameAr,
        hospitalId: _hospital!.id,
        hospitalName: _hospital!.name,
        hospitalNameAr: _hospital!.nameAr,
        hospitalAddress: _hospital!.addressAr.isNotEmpty ? _hospital!.addressAr : _hospital!.address,
      );

      await booking.createBookingFromModel(bookingModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب الحجز. في انتظار موافقة المستشفى')),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.myBookings);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الحجز. حاول مرة أخرى')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isAr ? 'حجز سرير' : 'Book a Bed')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? _hospital!.nameAr : _hospital!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(isAr ? _hospital!.addressAr : _hospital!.address),
                          Text('${isAr ? "أسرة متاحة" : "Available beds"}: ${_hospital!.availableBeds}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(isAr ? 'اختر القسم' : 'Select Department', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._departments.map((d) => RadioListTile<String>(
                    title: Text(d['nameAr'] ?? d['name']),
                    subtitle: Text('${(_beds[d['id']] ?? []).length} ${isAr ? "أسرة متاحة" : "beds available"}'),
                    value: d['id'],
                    groupValue: _selectedDeptId,
                    onChanged: (_beds[d['id']] ?? []).isEmpty ? null : (v) {
                      setState(() {
                        _selectedDeptId = v;
                        _selectedBedId = null;
                      });
                    },
                  )),
                  if (_selectedDeptId != null && (_beds[_selectedDeptId] ?? []).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(isAr ? 'اختر السرير' : 'Select Bed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_beds[_selectedDeptId] ?? []).map((b) => RadioListTile<String>(
                      title: Text(b['nameAr'] ?? b['name']),
                      value: b['id'],
                      groupValue: _selectedBedId,
                      onChanged: (v) {
                        setState(() {
                          _selectedBedId = v;
                          _selectedBedName = b['name'];
                          _selectedBedNameAr = b['nameAr'];
                        });
                      },
                    )),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedBedId == null ? null : _book,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                      ),
                      child: Text(isAr ? 'تأكيد الحجز' : 'Confirm Booking', style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
