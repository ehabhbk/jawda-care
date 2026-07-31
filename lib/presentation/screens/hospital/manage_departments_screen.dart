import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../../data/models/department_model.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({super.key});

  @override
  State<ManageDepartmentsScreen> createState() =>
      _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  String? _hospitalId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _hospitalId = auth.userModel?.hospitalId;
    if (_hospitalId != null) {
      context.read<DepartmentProvider>().loadDepartments(_hospitalId!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    _nameCtrl.clear();
    _nameArCtrl.clear();
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final provider = context.read<DepartmentProvider>();
              final ok = await provider.addDepartment(
                hospitalId: auth.userModel!.hospitalId!,
                name: _nameCtrl.text,
                nameAr: _nameArCtrl.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _nameCtrl.clear();
              _nameArCtrl.clear();
              if (!ok && mounted) {
                final msg = provider.errorMessage ?? '';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'فشل حفظ القسم${msg.isNotEmpty ? ': $msg' : ''}',
                    ),
                  ),
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    String deptId,
    String currentName,
    String currentNameAr,
  ) {
    _nameCtrl.text = currentName;
    _nameArCtrl.text = currentNameAr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل القسم'),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<DepartmentProvider>();
              final ok = await provider.updateDepartment(
                departmentId: deptId,
                name: _nameCtrl.text,
                nameAr: _nameArCtrl.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (!ok && mounted) {
                final msg = provider.errorMessage ?? '';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'فشل تعديل القسم${msg.isNotEmpty ? ': $msg' : ''}',
                    ),
                  ),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDepartment(DepartmentModel dept) async {
    final name = dept.nameAr.isNotEmpty ? dept.nameAr : dept.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القسم'),
        content: Text(
          'هل أنت متأكد من حذف قسم "$name"؟ سيتم حذف جميع الأسرة التابعة له.',
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
    if (confirmed == true && mounted) {
      final ok = await context
          .read<DepartmentProvider>()
          .deleteDepartmentWithBeds(dept.id!);
      if (!ok && mounted) {
        final msg = context.read<DepartmentProvider>().errorMessage ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف القسم${msg.isNotEmpty ? ': $msg' : ''}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DepartmentProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقسام'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'فشل تحميل الأقسام من قاعدة البيانات',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _hospitalId == null
                          ? null
                          : () => context
                                .read<DepartmentProvider>()
                                .loadDepartments(_hospitalId!),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          : provider.departments.isEmpty
          ? const Center(child: Text('لا توجد أقسام بعد'))
          : ListView.builder(
              itemCount: provider.departments.length,
              itemBuilder: (ctx, i) {
                final dept = provider.departments[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      dept.nameAr.isNotEmpty ? dept.nameAr : dept.name,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showEditDialog(dept.id!, dept.name, dept.nameAr),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteDepartment(dept),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
