import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/admin_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/common/hospital_logo.dart';
import '../../widgets/common/location_picker.dart';

class HospitalsManagementScreen extends StatelessWidget {
  const HospitalsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستشفيات')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addHospital),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: admin.hospitalsStream,
        builder: (ctx, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final hospitals = snap.data!.docs;
          if (hospitals.isEmpty)
            return const Center(child: Text('لا توجد مستشفيات'));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: hospitals.length,
            itemBuilder: (ctx, i) {
              final doc = hospitals[i];
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final isActive = data['isActive'] ?? true;
              return Card(
                color: isActive == true ? null : Colors.grey[200],
                child: ListTile(
                  leading: Icon(
                    Icons.local_hospital,
                    color: isActive == true ? Colors.teal : Colors.grey,
                  ),
                  title: Text(
                    data['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${data['city'] ?? ''} | ${data['phone'] ?? ''}'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive == true
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive == true ? 'نشطة' : 'متوقفة',
                          style: TextStyle(
                            color: isActive == true ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isActive == true
                            ? 'إيقاف (لن تظهر للمرضى)'
                            : 'تفعيل',
                        icon: Icon(
                          isActive == true ? Icons.block : Icons.check_circle,
                          color: isActive == true
                              ? Colors.orange
                              : Colors.green,
                        ),
                        onPressed: () =>
                            admin.toggleHospitalActive(id, isActive != true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editHospital(context, id, data),
                      ),
                      IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(
                          context,
                          admin,
                          id,
                          data['name'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editHospital(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditHospitalScreen(hospitalId: id, hospitalData: data),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AdminProvider admin,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستشفى'),
        content: Text(
          'هل أنت متأكد من حذف "$name"؟\nسيتم حذف كل الأسرة والأقسام وسيارات الإسعاف التابعة لها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await admin.deleteHospital(id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف المستشفى')));
      }
    }
  }
}

class _EditHospitalScreen extends StatefulWidget {
  final String hospitalId;
  final Map<String, dynamic> hospitalData;

  const _EditHospitalScreen({
    required this.hospitalId,
    required this.hospitalData,
  });

  @override
  State<_EditHospitalScreen> createState() => _EditHospitalScreenState();
}

class _EditHospitalScreenState extends State<_EditHospitalScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _phoneCtrl;
  late bool _isActive;
  LatLng? _selectedLocation;
  String? _imageUrl;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    final d = widget.hospitalData;
    _nameCtrl = TextEditingController(text: d['name'] ?? '');
    _addressCtrl = TextEditingController(text: d['address'] ?? '');
    _cityCtrl = TextEditingController(text: d['city'] ?? '');
    _phoneCtrl = TextEditingController(text: d['phone'] ?? '');
    _imageUrl = d['imageUrl'];
    _isActive = d['isActive'] ?? true;
    final lat = (d['latitude'] ?? 0).toDouble();
    final lng = (d['longitude'] ?? 0).toDouble();
    if (lat != 0 || lng != 0) {
      _selectedLocation = LatLng(lat, lng);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final base64 = base64Encode(bytes);
      if (base64.length > 900000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حجم الصورة كبير جداً، اختر صورة أصغر')),
        );
        return;
      }
      setState(() => _imageUrl = 'data:image/jpeg;base64,$base64');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل اختيار الصورة')));
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل المستشفى')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    HospitalLogo(imageUrl: _imageUrl, radius: 45),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickingImage ? null : _pickLogo,
                      icon: _pickingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined),
                      label: Text(
                        _imageUrl != null ? 'تغيير اللوجو' : 'إضافة لوجو',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المستشفى'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'المدينة'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(_isActive ? 'نشط' : 'غير نشط'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 12),
              LocationPicker(
                initialLocation: _selectedLocation,
                onChanged: (pos) => setState(() => _selectedLocation = pos),
              ),
              const SizedBox(height: 20),
              if (admin.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    admin.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: admin.isLoading ? null : _save,
                  child: admin.isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'حفظ التعديلات',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final admin = context.read<AdminProvider>();
    final name = _nameCtrl.text;
    final success = await admin.updateHospital(
      hospitalId: widget.hospitalId,
      name: name,
      nameAr: name,
      address: _addressCtrl.text,
      addressAr: _addressCtrl.text,
      city: _cityCtrl.text,
      cityAr: _cityCtrl.text,
      latitude: _selectedLocation?.latitude ?? 0,
      longitude: _selectedLocation?.longitude ?? 0,
      phone: _phoneCtrl.text,
      isActive: _isActive,
      imageUrl: _imageUrl,
    );
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات')));
    }
  }
}
