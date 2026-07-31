import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/hospital_service.dart';
import '../../../data/services/location_service.dart';
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

  Future<void> _showBookingDialog() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حجز السرير' : 'Book Bed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isAr ? 'هذا الحجز لمن؟' : 'Who is this booking for?'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person),
                onPressed: () => Navigator.pop(ctx, 'myself'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
                label: Text(isAr ? 'لنفسي' : 'Myself', style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.people),
                onPressed: () => Navigator.pop(ctx, 'other'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(vertical: 14)),
                label: Text(isAr ? 'لمريض آخر' : 'Another patient', style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'other') {
      await _showOtherPatientForm(isAr);
    } else {
      await _submitBooking(null, null);
    }
  }

  Future<void> _showOtherPatientForm(bool isAr) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'بيانات المريض' : 'Patient Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: isAr ? 'اسم المريض' : 'Patient name', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: isAr ? 'رقم الهاتف' : 'Phone number', border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty
                ? null
                : () => Navigator.pop(ctx, true),
            child: Text(isAr ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _submitBooking(nameCtrl.text.trim(), phoneCtrl.text.trim());
    }
  }

  Future<void> _submitBooking(String? otherName, String? otherPhone) async {
    if (_selectedBedId == null) return;

    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    try {
      final pos = await LocationService.getPosition(context);
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب تشغيل الموقع لتأكيد الحجز')),
          );
        }
        return;
      }

      final patientName = otherName ?? auth.userModel!.name;
      final patientPhone = otherPhone ?? auth.userModel!.phone;

      final bookingModel = BookingModel(
        userId: auth.userModel!.id!,
        userName: patientName,
        userPhone: patientPhone,
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

      final id = await booking.createBookingFromModel(bookingModel);

      if (mounted && id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'تم إرسال طلب الحجز. في انتظار موافقة المستشفى' : 'Booking request sent. Waiting for hospital approval.')),
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.bed, color: Colors.teal, size: 20),
                              const SizedBox(width: 6),
                              Text('${isAr ? "إجمالي الأسرة النشطة" : "Total active beds"}: ${_hospital!.availableBeds}',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(isAr ? 'اختر القسم' : 'Select Department', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._departments.map((d) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      title: Text(d['nameAr'] ?? d['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.bed, size: 16, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text('${(_beds[d['id']] ?? []).length} ${isAr ? "أسرة متاحة" : "beds available"}'),
                        ],
                      ),
                      value: d['id'],
                      groupValue: _selectedDeptId,
                      onChanged: (_beds[d['id']] ?? []).isEmpty ? null : (v) {
                        setState(() {
                          _selectedDeptId = v;
                          _selectedBedId = null;
                        });
                      },
                    ),
                  )),
                  if (_selectedDeptId != null && (_beds[_selectedDeptId] ?? []).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(isAr ? 'اختر السرير' : 'Select Bed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(_beds[_selectedDeptId] ?? []).map((b) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<String>(
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
                      ),
                    )),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedBedId == null ? null : _showBookingDialog,
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
