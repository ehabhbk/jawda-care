import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/hospital_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/medical_report_service.dart';
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
  String? _errorMessage;
  final _hospitalService = HospitalService();
  final _reportService = MedicalReportService();
  final _imagePicker = ImagePicker();
  String? _reportUrl;
  String? _reportFileName;
  String? _reportError;
  bool _uploadingReport = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? hospitalId;

    if (args is String) {
      hospitalId = args;
    } else if (args is HospitalModel) {
      hospitalId = args.id;
    }

    if (hospitalId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'لم يتم تحديد المستشفى';
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final h = await _hospitalService.getHospitalById(hospitalId);
      if (h == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = 'المستشفى غير موجود';
          });
        }
        return;
      }

      final deptSnap = await FirebaseFirestore.instance
          .collection('departments')
          .where('hospitalId', isEqualTo: hospitalId)
          .get();

      final depts = deptSnap.docs
          .map((d) => {'id': d.id, 'name': d['name'], 'nameAr': d['nameAr']})
          .toList();

      final bedsMap = <String, List<Map<String, dynamic>>>{};
      final results = await Future.wait(
        depts.map(
          (dept) => FirebaseFirestore.instance
              .collection('beds')
              .where('departmentId', isEqualTo: dept['id'])
              .get(),
        ),
      );
      for (var i = 0; i < depts.length; i++) {
        bedsMap[depts[i]['id']] = results[i].docs
            .map(
              (b) => {
                'id': b.id,
                'name': b['name'],
                'nameAr': b['nameAr'],
                'status': b['status'] ?? 'available',
              },
            )
            .toList();
      }

      if (mounted) {
        setState(() {
          _hospital = h;
          _departments = depts;
          _beds = bedsMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _pickCameraPhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    await _uploadReport(
      await file.readAsBytes(),
      file.name,
      contentType: 'image/jpeg',
    );
  }

  Future<void> _pickGalleryImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    await _uploadReport(
      await file.readAsBytes(),
      file.name,
      contentType: 'image/jpeg',
    );
  }

  Future<void> _pickPdf() async {
    const typeGroup = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    await _uploadReport(
      await file.readAsBytes(),
      file.name,
      contentType: 'application/pdf',
    );
  }

  Future<void> _uploadReport(
    Uint8List bytes,
    String fileName, {
    required String contentType,
  }) async {
    setState(() {
      _uploadingReport = true;
      _reportError = null;
    });
    try {
      final url = await _reportService.uploadReport(
        bytes: bytes,
        fileName: '${DateTime.now().millisecondsSinceEpoch}_$fileName',
        contentType: contentType,
      );
      if (!mounted) return;
      setState(() {
        _reportUrl = url;
        _reportFileName = fileName;
        _uploadingReport = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploadingReport = false;
        _reportError = 'فشل رفع التقرير الطبي، حاول مرة أخرى';
      });
    }
  }

  Future<void> _pickReportSource() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(isAr ? 'التقاط صورة بالكاميرا' : 'Take photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(isAr ? 'صورة من المعرض' : 'Image from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(isAr ? 'ملف PDF' : 'PDF file'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'camera':
        await _pickCameraPhoto();
      case 'gallery':
        await _pickGalleryImage();
      case 'pdf':
        await _pickPdf();
    }
  }

  List<Map<String, dynamic>> _visibleBeds(String deptId) {
    return (_beds[deptId] ?? [])
        .where((b) => b['status'] != 'maintenance')
        .toList();
  }

  int get _totalAvailableBeds {
    var count = 0;
    for (final dept in _departments) {
      final deptBeds = _beds[dept['id']] ?? [];
      count += deptBeds.where((b) => b['status'] == 'available').length;
    }
    return count;
  }

  Future<void> _showExistingBookingBlockedDialog(
    BookingModel existing,
    bool isAr,
  ) async {
    final hospitalLabel = isAr
        ? (existing.hospitalNameAr ?? existing.hospitalName)
        : (existing.hospitalName ?? existing.hospitalNameAr);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 48,
        ),
        title: Text(isAr ? 'لا يمكن إتمام الحجز' : 'Booking not allowed'),
        content: Text(
          isAr
              ? 'المريض (${existing.userName}) لديه حجز نشط في مستشفى "$hospitalLabel". '
                    'يجب إلغاء هذا الحجز أولاً قبل حجز سرير في مستشفى آخر.'
              : 'Patient (${existing.userName}) already has an active booking at '
                    '"$hospitalLabel". You must cancel it before booking a bed elsewhere.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: Text(
                  isAr ? 'لنفسي' : 'Myself',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.people),
                onPressed: () => Navigator.pop(ctx, 'other'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: Text(
                  isAr ? 'لمريض آخر' : 'Another patient',
                  style: const TextStyle(color: Colors.white),
                ),
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
    final result = await showDialog<_OtherPatientData>(
      context: context,
      builder: (ctx) => _OtherPatientFormDialog(isAr: isAr),
    );

    if (result != null && mounted) {
      await _submitBooking(result.name, result.phone);
    }
  }

  Future<void> _submitBooking(String? otherName, String? otherPhone) async {
    if (_selectedBedId == null) return;

    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    try {
      final patientName = otherName ?? auth.userModel!.name;
      final patientPhone = otherPhone ?? auth.userModel!.phone;

      final existing = await booking.getActiveAcceptedIcuBooking(
        patientName: patientName,
        patientPhone: patientPhone,
      );

      if (existing != null) {
        if (mounted) {
          await _showExistingBookingBlockedDialog(existing, isAr);
        }
        return;
      }

      if (!mounted) return;
      final pos = await LocationService.getPosition(context);
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب تشغيل الموقع لتأكيد الحجز')),
          );
        }
        return;
      }

      final bookingModel = BookingModel(
        userId: auth.userModel!.id!,
        userName: patientName,
        userPhone: patientPhone,
        userLat: pos.latitude,
        userLng: pos.longitude,
        bookingType: BookingType.icu,
        status: BookingStatus.pending,
        departmentId: _selectedDeptId,
        departmentName: _departments.firstWhere(
          (d) => d['id'] == _selectedDeptId,
        )['name'],
        departmentNameAr: _departments.firstWhere(
          (d) => d['id'] == _selectedDeptId,
        )['nameAr'],
        bedId: _selectedBedId,
        bedName: _selectedBedName,
        bedNameAr: _selectedBedNameAr,
        hospitalId: _hospital!.id,
        hospitalName: _hospital!.name,
        hospitalNameAr: _hospital!.nameAr,
        hospitalAddress: _hospital!.addressAr.isNotEmpty
            ? _hospital!.addressAr
            : _hospital!.address,
        medicalReportUrl: _reportUrl,
      );

      final id = await booking.createBookingFromModel(bookingModel);

      if (mounted && id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم إرسال طلب الحجز. في انتظار موافقة المستشفى'
                  : 'Booking request sent. Waiting for hospital approval.',
            ),
          ),
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
                          ? 'حدث خطأ أثناء تحميل بيانات الحجز'
                          : 'Failed to load booking data',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_errorMessage != null) ...[
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
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              ),
            )
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
                          Text(
                            isAr ? _hospital!.nameAr : _hospital!.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr ? _hospital!.addressAr : _hospital!.address,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.bed,
                                color: Colors.teal,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${isAr ? "الأسرة المتاحة" : "Available beds"}: ${_totalAvailableBeds}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'اختر القسم' : 'Select Department',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_departments.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          isAr
                              ? 'لا توجد أقسام في هذا المستشفى حالياً'
                              : 'No departments in this hospital yet',
                        ),
                      ),
                    )
                  else
                    ..._departments.map((d) {
                      final deptBeds = _beds[d['id']] ?? [];
                      final availableCount = deptBeds
                          .where((b) => b['status'] == 'available')
                          .length;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: RadioListTile<String>(
                          title: Text(
                            d['nameAr'] ?? d['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Row(
                            children: [
                              const Icon(
                                Icons.bed,
                                size: 16,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$availableCount ${isAr ? "أسرة متاحة" : "beds available"}',
                              ),
                            ],
                          ),
                          value: d['id'],
                          groupValue: _selectedDeptId,
                          onChanged: availableCount == 0
                              ? null
                              : (v) {
                                  setState(() {
                                    _selectedDeptId = v;
                                    _selectedBedId = null;
                                  });
                                },
                        ),
                      );
                    }),
                  if (_selectedDeptId != null) ...[
                    if (_visibleBeds(_selectedDeptId!).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'اختر السرير' : 'Select Bed',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ..._visibleBeds(_selectedDeptId!).map(
                      (b) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: b['status'] == 'occupied'
                            ? ListTile(
                                title: Text(
                                  b['nameAr'] ?? b['name'],
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAr
                                          ? 'مشغول - لا يمكن الحجز'
                                          : 'Occupied - cannot book',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RadioListTile<String>(
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
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    isAr
                        ? 'إرفاق تقرير طبي (اختياري)'
                        : 'Medical Report (optional)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _uploadingReport
                                    ? Row(
                                        children: [
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            isAr
                                                ? 'جاري رفع التقرير...'
                                                : 'Uploading report...',
                                          ),
                                        ],
                                      )
                                    : _reportFileName != null
                                    ? Text(
                                        _reportFileName!,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : Text(
                                        isAr
                                            ? 'لم يتم اختيار ملف'
                                            : 'No file selected',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                              ),
                              if (_reportFileName != null && !_uploadingReport)
                                IconButton(
                                  tooltip: isAr ? 'إزالة' : 'Remove',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _reportUrl = null;
                                      _reportFileName = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                          if (_reportError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _reportError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _uploadingReport
                                  ? null
                                  : _pickReportSource,
                              icon: const Icon(Icons.attach_file),
                              label: Text(
                                isAr
                                    ? 'اختيار صورة أو ملف PDF'
                                    : 'Choose image or PDF file',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedBedId == null
                          ? null
                          : _showBookingDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                      ),
                      child: Text(
                        isAr ? 'تأكيد الحجز' : 'Confirm Booking',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _OtherPatientFormDialog extends StatefulWidget {
  final bool isAr;

  const _OtherPatientFormDialog({required this.isAr});

  @override
  State<_OtherPatientFormDialog> createState() =>
      _OtherPatientFormDialogState();
}

class _OtherPatientFormDialogState extends State<_OtherPatientFormDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _nameCtrl.text.trim().isNotEmpty && _phoneCtrl.text.trim().length >= 6;

  void _onChanged(String _) => setState(() {});

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.of(
      context,
    ).pop(_OtherPatientData(_nameCtrl.text.trim(), _phoneCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;

    return AlertDialog(
      title: Text(isAr ? 'بيانات المريض' : 'Patient Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            onChanged: _onChanged,
            decoration: InputDecoration(
              labelText: isAr ? 'اسم المريض' : 'Patient name',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            onChanged: _onChanged,
            decoration: InputDecoration(
              labelText: isAr ? 'رقم الهاتف' : 'Phone number',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              isAr
                  ? 'رقم الهاتف يجب أن يكون 6 أرقام على الأقل'
                  : 'Phone number must be at least 6 digits',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isAr ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _canConfirm ? _confirm : null,
          child: Text(isAr ? 'تأكيد' : 'Confirm'),
        ),
      ],
    );
  }
}

class _OtherPatientData {
  final String name;
  final String phone;

  const _OtherPatientData(this.name, this.phone);
}
