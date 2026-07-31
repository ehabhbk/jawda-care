import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/localization.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  String? _selectedBloodType;

  final _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emergencyNameController = TextEditingController(
      text: user?.emergencyContactName ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: user?.emergencyContactPhone ?? '',
    );
    _selectedBloodType = user?.bloodType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'emergencyContactName': _emergencyNameController.text.isNotEmpty
          ? _emergencyNameController.text.trim()
          : null,
      'emergencyContactPhone': _emergencyPhoneController.text.isNotEmpty
          ? _emergencyPhoneController.text.trim()
          : null,
      'bloodType': _selectedBloodType,
    };

    await context.read<AuthProvider>().updateProfile(data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(t.translate('editProfile'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                label: t.translate('name'),
                prefixIcon: Icons.person,
                validator: Validators.name,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: t.translate('phone'),
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodType,
                decoration: InputDecoration(
                  labelText: t.translate('bloodType'),
                  prefixIcon: const Icon(Icons.bloodtype),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _bloodTypes
                    .map((bt) => DropdownMenuItem(value: bt, child: Text(bt)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBloodType = v),
              ),
              const SizedBox(height: 24),
              Text(
                t.translate('emergencyContact'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emergencyNameController,
                label: t.translate('emergencyContactName'),
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emergencyPhoneController,
                label: t.translate('emergencyContactPhone'),
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              CustomButton(text: t.translate('save'), onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
