import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/bed_provider.dart';
import '../../../data/models/bed_model.dart';

class ManageBedsScreen extends StatefulWidget {
  const ManageBedsScreen({super.key});

  @override
  State<ManageBedsScreen> createState() => _ManageBedsScreenState();
}

class _ManageBedsScreenState extends State<ManageBedsScreen> {
  String? _selectedDeptId;
  String? _hospitalId;
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();

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
        title: const Text('إضافة سرير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم السرير (English)',
              ),
            ),
            TextField(
              controller: _nameArCtrl,
              decoration: const InputDecoration(labelText: 'اسم السرير (عربي)'),
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
              if (_selectedDeptId == null) return;
              final auth = context.read<AuthProvider>();
              final provider = context.read<BedProvider>();
              final ok = await provider.addBed(
                departmentId: _selectedDeptId!,
                hospitalId: auth.userModel!.hospitalId!,
                name: _nameCtrl.text,
                nameAr: _nameArCtrl.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (!ok && mounted) {
                final msg = provider.errorMessage ?? '';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'فشل حفظ السرير${msg.isNotEmpty ? ': $msg' : ''}',
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

  void _showEditDialog(String bedId, String currentName, String currentNameAr) {
    _nameCtrl.text = currentName;
    _nameArCtrl.text = currentNameAr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل السرير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم السرير (English)',
              ),
            ),
            TextField(
              controller: _nameArCtrl,
              decoration: const InputDecoration(labelText: 'اسم السرير (عربي)'),
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
              final provider = context.read<BedProvider>();
              final ok = await provider.updateBedName(
                bedId: bedId,
                name: _nameCtrl.text,
                nameAr: _nameArCtrl.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (!ok && mounted) {
                final msg = provider.errorMessage ?? '';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'فشل تعديل السرير${msg.isNotEmpty ? ': $msg' : ''}',
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

  Future<void> _confirmDeleteBed(BedModel bed) async {
    final name = bed.nameAr.isNotEmpty ? bed.nameAr : bed.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السرير'),
        content: Text('هل أنت متأكد من حذف السرير "$name"؟'),
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
      final ok = await context.read<BedProvider>().deleteBed(bed.id!);
      if (!ok && mounted) {
        final msg = context.read<BedProvider>().errorMessage ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف السرير${msg.isNotEmpty ? ': $msg' : ''}'),
          ),
        );
      }
    }
  }

  void _showStatusDialog(String bedId, String currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير حالة السرير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('متاح'),
              leading: Radio<String>(
                value: 'available',
                groupValue: currentStatus,
                onChanged: (v) {
                  context.read<BedProvider>().updateBedStatus(
                    bedId: bedId,
                    status: v!,
                  );
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              title: const Text('صيانة'),
              leading: Radio<String>(
                value: 'maintenance',
                groupValue: currentStatus,
                onChanged: (v) {
                  context.read<BedProvider>().updateBedStatus(
                    bedId: bedId,
                    status: v!,
                  );
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deptProvider = context.watch<DepartmentProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأسرة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _selectedDeptId == null ? null : _showAddDialog,
          ),
        ],
      ),
      body: deptProvider.errorMessage != null
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
                      deptProvider.errorMessage!,
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'اختر القسم'),
                    items: deptProvider.departments.map((d) {
                      return DropdownMenuItem(
                        value: d.id,
                        child: Text(d.nameAr.isNotEmpty ? d.nameAr : d.name),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedDeptId = v);
                      if (v != null) {
                        context.read<BedProvider>().loadBedsByDepartment(v);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _selectedDeptId == null
                      ? const Center(child: Text('اختر قسماً لعرض الأسرة'))
                      : Consumer<BedProvider>(
                          builder: (ctx, bedProvider, _) {
                            if (bedProvider.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (bedProvider.errorMessage != null) {
                              return Center(
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
                                        'فشل تحميل الأسرة',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        bedProvider.errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => context
                                            .read<BedProvider>()
                                            .loadBedsByDepartment(
                                              _selectedDeptId!,
                                            ),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('إعادة المحاولة'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (bedProvider.beds.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('لا توجد أسرة في هذا القسم'),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _showAddDialog,
                                      icon: const Icon(Icons.add),
                                      label: const Text('إضافة سرير'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: bedProvider.beds.length + 1,
                              itemBuilder: (ctx, i) {
                                if (i == bedProvider.beds.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ElevatedButton.icon(
                                      onPressed: _showAddDialog,
                                      icon: const Icon(Icons.add),
                                      label: const Text('إضافة سرير'),
                                    ),
                                  );
                                }
                                final bed = bedProvider.beds[i];
                                Color statusColor;
                                String statusText;
                                switch (bed.status) {
                                  case 'available':
                                    statusColor = Colors.green;
                                    statusText = 'متاح';
                                    break;
                                  case 'maintenance':
                                    statusColor = Colors.orange;
                                    statusText = 'صيانة';
                                    break;
                                  case 'occupied':
                                    statusColor = Colors.orange;
                                    statusText =
                                        'مشغول - ${bed.patientName ?? ""}';
                                    break;
                                  default:
                                    statusColor = Colors.grey;
                                    statusText = bed.status;
                                }
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      bed.nameAr.isNotEmpty
                                          ? bed.nameAr
                                          : bed.name,
                                    ),
                                    subtitle: Text(statusText),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _showEditDialog(
                                            bed.id!,
                                            bed.name,
                                            bed.nameAr,
                                          ),
                                        ),
                                        if (bed.status != 'occupied')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.build_circle,
                                              color: Colors.orange,
                                            ),
                                            tooltip: 'تغيير الحالة',
                                            onPressed: () => _showStatusDialog(
                                              bed.id!,
                                              bed.status,
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _confirmDeleteBed(bed),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
