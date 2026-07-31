import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/admin_provider.dart';
import '../../../core/routes/app_routes.dart';

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
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final hospitals = snap.data!.docs;
          if (hospitals.isEmpty) return const Center(child: Text('لا توجد مستشفيات'));
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
                  leading: Icon(Icons.local_hospital, color: isActive == true ? Colors.teal : Colors.grey),
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${data['city'] ?? ''} | ${data['phone'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isActive == true ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => admin.toggleHospitalActive(id, isActive != true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editHospital(context, id, data),
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

  void _editHospital(BuildContext context, String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _EditHospitalScreen(hospitalId: id, hospitalData: data)),
    );
  }
}

class _EditHospitalScreen extends StatefulWidget {
  final String hospitalId;
  final Map<String, dynamic> hospitalData;

  const _EditHospitalScreen({required this.hospitalId, required this.hospitalData});

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
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    final d = widget.hospitalData;
    _nameCtrl = TextEditingController(text: d['name'] ?? '');
    _addressCtrl = TextEditingController(text: d['address'] ?? '');
    _cityCtrl = TextEditingController(text: d['city'] ?? '');
    _phoneCtrl = TextEditingController(text: d['phone'] ?? '');
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
    _mapController?.dispose();
    super.dispose();
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
              Text('اختر موقع المستشفى على الخريطة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation ?? const LatLng(24.7136, 46.6753),
                      zoom: 12,
                    ),
                    onMapCreated: (ctrl) => _mapController = ctrl,
                    onTap: (pos) => setState(() => _selectedLocation = pos),
                    markers: _selectedLocation != null
                        ? {
                            Marker(
                              markerId: const MarkerId('hospital'),
                              position: _selectedLocation!,
                            ),
                          }
                        : {},
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
              ),
              if (_selectedLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 20),
              if (admin.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(admin.errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: admin.isLoading ? null : _save,
                  child: admin.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('حفظ التعديلات', style: TextStyle(fontSize: 16)),
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
    );
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات')),
      );
    }
  }
}
