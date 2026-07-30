import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/bed_provider.dart';

class ManageBedsScreen extends StatefulWidget {
  const ManageBedsScreen({super.key});

  @override
  State<ManageBedsScreen> createState() => _ManageBedsScreenState();
}

class _ManageBedsScreenState extends State<ManageBedsScreen> {
  String? _selectedDeptId;
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
              decoration: const InputDecoration(labelText: 'اسم السرير (English)'),
            ),
            TextField(
              controller: _nameArCtrl,
              decoration: const InputDecoration(labelText: 'اسم السرير (عربي)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (_selectedDeptId == null) return;
              final auth = context.read<AuthProvider>();
              final provider = context.read<BedProvider>();
              await provider.addBed(
                departmentId: _selectedDeptId!,
                hospitalId: auth.userModel!.hospitalId!,
                name: _nameCtrl.text,
                nameAr: _nameArCtrl.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
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
                  context.read<BedProvider>().updateBedStatus(bedId: bedId, status: v!);
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
                  context.read<BedProvider>().updateBedStatus(bedId: bedId, status: v!);
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
      appBar: AppBar(title: const Text('الأسرة')),
      body: Column(
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
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (bedProvider.beds.isEmpty) {
                        return const Center(child: Text('لا توجد أسرة في هذا القسم'));
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
                              statusColor = Colors.red;
                              statusText = 'مشغول - ${bed.patientName ?? ""}';
                              break;
                            default:
                              statusColor = Colors.grey;
                              statusText = bed.status;
                          }
                          return Card(
                            child: ListTile(
                              title: Text(bed.nameAr.isNotEmpty ? bed.nameAr : bed.name),
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
                                  if (bed.status != 'occupied')
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showStatusDialog(bed.id!, bed.status),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => bedProvider.deleteBed(bed.id!),
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
