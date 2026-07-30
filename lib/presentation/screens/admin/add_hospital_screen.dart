import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AddHospitalScreen extends StatefulWidget {
  const AddHospitalScreen({super.key});

  @override
  State<AddHospitalScreen> createState() => _AddHospitalScreenState();
}

class _AddHospitalScreenState extends State<AddHospitalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _addressArCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _cityArCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    _addressCtrl.dispose();
    _addressArCtrl.dispose();
    _cityCtrl.dispose();
    _cityArCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مستشفى')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المستشفى (English)'),
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _nameArCtrl,
                decoration: const InputDecoration(labelText: 'اسم المستشفى (عربي)'),
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'العنوان (English)'),
              ),
              TextFormField(
                controller: _addressArCtrl,
                decoration: const InputDecoration(labelText: 'العنوان (عربي)'),
              ),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'المدينة (English)'),
              ),
              TextFormField(
                controller: _cityArCtrl,
                decoration: const InputDecoration(labelText: 'المدينة (عربي)'),
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
                validator: (v) => v != null && v.length < 6 ? '6 أحرف على الأقل' : null,
              ),
              TextFormField(
                controller: _latCtrl,
                decoration: const InputDecoration(labelText: 'خط العرض (Latitude)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _lngCtrl,
                decoration: const InputDecoration(labelText: 'خط الطول (Longitude)'),
                keyboardType: TextInputType.number,
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
                      : const Text('إضافة المستشفى', style: TextStyle(fontSize: 16)),
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
    final success = await admin.addHospital(
      name: _nameCtrl.text,
      nameAr: _nameArCtrl.text,
      address: _addressCtrl.text,
      addressAr: _addressArCtrl.text,
      city: _cityCtrl.text,
      cityAr: _cityArCtrl.text,
      latitude: double.tryParse(_latCtrl.text) ?? 0,
      longitude: double.tryParse(_lngCtrl.text) ?? 0,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة المستشفى بنجاح')),
      );
    }
  }
}
