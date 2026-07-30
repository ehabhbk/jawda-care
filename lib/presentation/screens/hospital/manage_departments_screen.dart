import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({super.key});

  @override
  State<ManageDepartmentsScreen> createState() => _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.userModel?.hospitalId;
    if (hospitalId != null) {
      context.read<DepartmentProvider>().loadDepartments(hospitalId);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة قسم جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم (English)'),
            ),
            TextField(
              controller: _nameArCtrl,
              decoration: const InputDecoration(labelText: 'الاسم (عربي)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final provider = context.read<DepartmentProvider>();
              await provider.addDepartment(
                hospitalId: auth.userModel!.hospitalId!,
                name: _nameCtrl.text,
                nameAr: _nameArCtrl.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _nameCtrl.clear();
              _nameArCtrl.clear();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DepartmentProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقسام'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.departments.isEmpty
              ? const Center(child: Text('لا توجد أقسام بعد'))
              : ListView.builder(
                  itemCount: provider.departments.length,
                  itemBuilder: (ctx, i) {
                    final dept = provider.departments[i];
                    return Card(
                      child: ListTile(
                        title: Text(dept.nameAr.isNotEmpty ? dept.nameAr : dept.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => provider.deleteDepartment(dept.id!),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
