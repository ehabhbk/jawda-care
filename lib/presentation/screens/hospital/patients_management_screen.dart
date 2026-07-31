import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/bed_model.dart';
import '../../../data/services/bed_service.dart';
import '../../../data/services/department_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class PatientsManagementScreen extends StatefulWidget {
  const PatientsManagementScreen({super.key});

  @override
  State<PatientsManagementScreen> createState() =>
      _PatientsManagementScreenState();
}

class _PatientsManagementScreenState extends State<PatientsManagementScreen> {
  final _bedService = BedService();
  final _departmentService = DepartmentService();
  StreamSubscription? _sub;
  List<BedModel> _occupiedBeds = [];
  Map<String, String> _deptNamesAr = {};
  bool _loading = true;
  String? _errorMessage;
  String? _hospitalId;

  @override
  void initState() {
    super.initState();
    _hospitalId = context.read<AuthProvider>().userModel?.hospitalId;
    if (_hospitalId != null) {
      _loadDepartments();
      _sub = _bedService
          .getOccupiedBedsByHospital(_hospitalId!)
          .listen(
            (beds) {
              if (mounted) {
                setState(() {
                  _occupiedBeds = beds;
                  _loading = false;
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _errorMessage = error.toString();
                  _loading = false;
                });
              }
            },
          );
    } else {
      _loading = false;
      _errorMessage = 'لم يتم تحديد المستشفى';
    }
  }

  Future<void> _loadDepartments() async {
    if (_hospitalId == null) return;
    try {
      final depts = await _departmentService.getDepartments(_hospitalId!).first;
      if (mounted) {
        setState(() {
          _deptNamesAr = {
            for (final d in depts)
              d.id!: (d.nameAr.isNotEmpty ? d.nameAr : d.name),
          };
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _dischargePatient(BedModel bed) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bookingId = bed.bookingId;
    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'لا يوجد حجز مرتبط بهذا السرير'
                : 'No booking linked to this bed',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'إخراج المريض' : 'Discharge Patient'),
        content: Text(
          isAr
              ? 'هل أنت متأكد من إخراج المريض "${bed.patientName ?? ''}"؟ سيعود السرير "${bed.nameAr.isNotEmpty ? bed.nameAr : bed.name}" متاحاً.'
              : 'Are you sure you want to discharge "${bed.patientName ?? ''}"? The bed "${bed.nameAr.isNotEmpty ? bed.nameAr : bed.name}" will become available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'رجوع' : 'Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              isAr ? 'إخراج' : 'Discharge',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bp = context.read<BookingProvider>();
      final ok = await bp.dischargePatient(
        bookingId: bookingId,
        bedId: bed.id!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? (isAr
                        ? 'تم إخراج المريض والسرير أصبح متاحاً'
                        : 'Patient discharged, bed is available')
                  : (isAr
                        ? 'فشل الإخراج: ${bp.errorMessage ?? ''}'
                        : 'Discharge failed: ${bp.errorMessage ?? ''}'),
            ),
          ),
        );
      }
    }
  }

  void _showPatientDetails(BedModel bed) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final deptName = _deptNamesAr[bed.departmentId] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'بيانات المريض' : 'Patient Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow(isAr ? 'اسم المريض' : 'Name', bed.patientName ?? '—'),
            _detailRow(
              isAr ? 'القسم' : 'Department',
              deptName.isEmpty ? '—' : deptName,
            ),
            _detailRow(
              isAr ? 'السرير' : 'Bed',
              bed.nameAr.isNotEmpty ? bed.nameAr : bed.name,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إغلاق' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _dischargePatient(bed);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              isAr ? 'إخراج المريض' : 'Discharge Patient',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'إدارة المرضى' : 'Patients Management'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAr
                          ? 'حدث خطأ أثناء تحميل المرضى'
                          : 'Failed to load patients',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _occupiedBeds.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bed_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    isAr
                        ? 'لا يوجد مرضى مقيمون حالياً'
                        : 'No patients currently admitted',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _occupiedBeds.length,
              itemBuilder: (ctx, i) {
                final bed = _occupiedBeds[i];
                final deptName = _deptNamesAr[bed.departmentId] ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      bed.patientName ?? (isAr ? 'مريض' : 'Patient'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (deptName.isNotEmpty)
                          Text(
                            isAr ? 'قسم: $deptName' : 'Dept: $deptName',
                            style: const TextStyle(fontSize: 12),
                          ),
                        Text(
                          '${isAr ? "السرير" : "Bed"}: ${bed.nameAr.isNotEmpty ? bed.nameAr : bed.name}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => _showPatientDetails(bed),
                  ),
                );
              },
            ),
    );
  }
}
