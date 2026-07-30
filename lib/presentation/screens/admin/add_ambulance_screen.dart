import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/admin_provider.dart';

class AddAmbulanceScreen extends StatefulWidget {
  const AddAmbulanceScreen({super.key});

  @override
  State<AddAmbulanceScreen> createState() => _AddAmbulanceScreenState();
}

class _AddAmbulanceScreenState extends State<AddAmbulanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _driverEmailCtrl = TextEditingController();
  final _driverPassCtrl = TextEditingController();
  String? _selectedHospitalId;
  List<QueryDocumentSnapshot> _hospitals = [];
  bool _loadingHospitals = true;

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _driverEmailCtrl.dispose();
    _driverPassCtrl.dispose();
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
      appBar: AppBar(title: const Text('إضافة سيارة إسعاف')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_loadingHospitals)
                const CircularProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'المستشفى'),
                  items: _hospitals.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['nameAr'] ?? data['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) => _selectedHospitalId = v,
                  validator: (v) => v == null ? 'اختر مستشفى' : null,
                ),
              TextFormField(
                controller: _plateCtrl,
                decoration: const InputDecoration(labelText: 'رقم اللوحة'),
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _driverNameCtrl,
                decoration: const InputDecoration(labelText: 'اسم السائق'),
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _driverPhoneCtrl,
                decoration: const InputDecoration(labelText: 'رقم هاتف السائق'),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _driverEmailCtrl,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني للسائق'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _driverPassCtrl,
                decoration: const InputDecoration(labelText: 'كلمة المرور للسائق'),
                obscureText: true,
                validator: (v) => v != null && v.length < 6 ? '6 أحرف على الأقل' : null,
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
                  onPressed: admin.isLoading ? null : _submit,
                  child: admin.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('إضافة السيارة', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final admin = context.read<AdminProvider>();
    final success = await admin.addAmbulance(
      hospitalId: _selectedHospitalId!,
      plateNumber: _plateCtrl.text,
      driverName: _driverNameCtrl.text,
      driverPhone: _driverPhoneCtrl.text,
      driverEmail: _driverEmailCtrl.text,
      driverPassword: _driverPassCtrl.text,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة سيارة الإسعاف بنجاح')),
      );
    }
  }
}
