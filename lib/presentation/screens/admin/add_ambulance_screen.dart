import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void dispose() {
    _plateCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _driverEmailCtrl.dispose();
    _driverPassCtrl.dispose();
    super.dispose();
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
              TextFormField(
                controller: _plateCtrl,
                decoration: const InputDecoration(labelText: 'رقم اللوحة'),
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _driverNameCtrl,
                decoration: const InputDecoration(labelText: 'اسم السائق'),
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _driverPhoneCtrl,
                decoration: const InputDecoration(labelText: 'رقم هاتف السائق'),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _driverEmailCtrl,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني للسائق'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _driverPassCtrl,
                decoration: const InputDecoration(labelText: 'كلمة المرور للسائق'),
                obscureText: true,
                validator: (v) => v != null && v.length < 6 ? '6 أحرف على الأقل' : null,
              ),
              const SizedBox(height: 24),
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
