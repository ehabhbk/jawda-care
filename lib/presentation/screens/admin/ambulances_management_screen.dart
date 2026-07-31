import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/admin_provider.dart';
import '../../../core/routes/app_routes.dart';

class AmbulancesManagementScreen extends StatelessWidget {
  const AmbulancesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة سيارات الإسعاف')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addAmbulance),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: admin.ambulancesStream,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final ambulances = snap.data!.docs;
          if (ambulances.isEmpty) return const Center(child: Text('لا توجد سيارات إسعاف'));
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: ambulances.length,
            itemBuilder: (ctx, i) {
              final doc = ambulances[i];
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.airport_shuttle,
                    color: data['status'] == 'available' ? Colors.green : Colors.orange,
                  ),
                  title: Text(data['driverName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${data['plateNumber'] ?? ''} | ${data['driverPhone'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editAmbulance(context, id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAmbulance(context, admin, id),
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

  void _editAmbulance(BuildContext context, String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _EditAmbulanceScreen(ambulanceId: id, ambulanceData: data)),
    );
  }

  void _deleteAmbulance(BuildContext context, AdminProvider admin, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف سيارة الإسعاف'),
        content: const Text('هل أنت متأكد من حذف سيارة الإسعاف هذه؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              admin.deleteAmbulance(id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EditAmbulanceScreen extends StatefulWidget {
  final String ambulanceId;
  final Map<String, dynamic> ambulanceData;

  const _EditAmbulanceScreen({required this.ambulanceId, required this.ambulanceData});

  @override
  State<_EditAmbulanceScreen> createState() => _EditAmbulanceScreenState();
}

class _EditAmbulanceScreenState extends State<_EditAmbulanceScreen> {
  late TextEditingController _plateCtrl;
  late TextEditingController _driverNameCtrl;
  late TextEditingController _driverPhoneCtrl;
  String _selectedHospitalId = '';
  String _selectedStatus = 'available';
  List<QueryDocumentSnapshot> _hospitals = [];
  bool _loadingHospitals = true;

  @override
  void initState() {
    super.initState();
    final d = widget.ambulanceData;
    _plateCtrl = TextEditingController(text: d['plateNumber'] ?? '');
    _driverNameCtrl = TextEditingController(text: d['driverName'] ?? '');
    _driverPhoneCtrl = TextEditingController(text: d['driverPhone'] ?? '');
    _selectedHospitalId = d['hospitalId'] ?? '';
    _selectedStatus = d['status'] ?? 'available';
    _loadHospitals();
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHospitals() async {
    final snap = await FirebaseFirestore.instance.collection('hospitals').where('isActive', isEqualTo: true).get();
    if (mounted) {
      setState(() {
        _hospitals = snap.docs;
        _loadingHospitals = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل سيارة الإسعاف')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_loadingHospitals)
              const CircularProgressIndicator()
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'المستشفى'),
                value: _selectedHospitalId,
                items: _hospitals.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(value: doc.id, child: Text(d['name'] ?? ''));
                }).toList(),
                onChanged: (v) => setState(() => _selectedHospitalId = v ?? ''),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plateCtrl,
              decoration: const InputDecoration(labelText: 'رقم اللوحة'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _driverNameCtrl,
              decoration: const InputDecoration(labelText: 'اسم السائق'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _driverPhoneCtrl,
              decoration: const InputDecoration(labelText: 'رقم هاتف السائق'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'الحالة'),
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'available', child: Text('متاح')),
                DropdownMenuItem(value: 'occupied', child: Text('مشغول')),
                DropdownMenuItem(value: 'maintenance', child: Text('صيانة')),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v ?? 'available'),
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
    );
  }

  Future<void> _save() async {
    final admin = context.read<AdminProvider>();
    final success = await admin.updateAmbulance(
      ambulanceId: widget.ambulanceId,
      hospitalId: _selectedHospitalId,
      plateNumber: _plateCtrl.text,
      driverName: _driverNameCtrl.text,
      driverPhone: _driverPhoneCtrl.text,
      status: _selectedStatus,
    );
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات')),
      );
    }
  }
}
