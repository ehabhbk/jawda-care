import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/common/theme_toggle_button.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final users = snap.data!.docs;
                final patients = users
                    .where((d) => (d.data() as Map)['role'] == 'patient')
                    .length;
                final admins = users
                    .where((d) => (d.data() as Map)['role'] == 'admin')
                    .length;
                final hospitals = users
                    .where((d) => (d.data() as Map)['role'] == 'hospital')
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إحصائيات النظام',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.person,
                            label: 'المستخدمون',
                            value: '$patients',
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.admin_panel_settings,
                            label: 'المشرفون',
                            value: '$admins',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_hospital,
                            label: 'المستشفيات',
                            value: '$hospitals',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ambulances')
                          .snapshots(),
                      builder: (ctx2, ambulancesSnap) {
                        final ambulances =
                            ambulancesSnap.hasData
                                ? ambulancesSnap.data!.docs.length
                                : 0;
                        return Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.airport_shuttle,
                                label: 'سيارات الإسعاف',
                                value: '$ambulances',
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.group,
                                label: 'إجمالي المستخدمين',
                                value: '${users.length}',
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Container()),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final bookings = snap.data!.docs;
                final total = bookings.length;
                final icu = bookings
                    .where((d) => (d.data() as Map)['bookingType'] == 'icu')
                    .length;
                final ambulance = bookings
                    .where(
                      (d) => (d.data() as Map)['bookingType'] == 'ambulance',
                    )
                    .length;
                final pending = bookings
                    .where((d) => (d.data() as Map)['status'] == 'pending')
                    .length;
                final inProgress = bookings
                    .where((d) => (d.data() as Map)['status'] == 'inProgress')
                    .length;
                final completed = bookings
                    .where((d) => (d.data() as Map)['status'] == 'completed')
                    .length;
                final cancelled = bookings
                    .where((d) => (d.data() as Map)['status'] == 'cancelled')
                    .length;
                final rejected = bookings
                    .where((d) => (d.data() as Map)['status'] == 'rejected')
                    .length;

                return Column(
                  children: [
                    _StatsGrid(icu: icu, ambulance: ambulance, total: total),
                    const SizedBox(height: 16),
                    _StatusGrid(
                      pending: pending,
                      inProgress: inProgress,
                      completed: completed,
                      cancelled: cancelled,
                      rejected: rejected,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'الإدارة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.local_hospital,
              title: 'إدارة المستشفيات',
              subtitle: 'عرض، إضافة، تعديل، تفعيل أو إلغاء المستشفيات',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.hospitalsManagement),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.airport_shuttle,
              title: 'إدارة سيارات الإسعاف',
              subtitle: 'عرض، إضافة، تعديل، حذف سيارات الإسعاف',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.ambulancesManagement),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.admin_panel_settings,
              title: 'إدارة المشرفين',
              subtitle: 'عرض المشرفين وإضافة مشرف جديد',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.adminsManagement),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int icu;
  final int ambulance;
  final int total;

  const _StatsGrid({
    required this.icu,
    required this.ambulance,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إحصائيات الطلبات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.medical_services,
                label: 'حجوزات أسرة',
                value: '$icu',
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.airport_shuttle,
                label: 'طلبات إسعاف',
                value: '$ambulance',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long,
                label: 'إجمالي',
                value: '$total',
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusGrid extends StatelessWidget {
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int rejected;

  const _StatusGrid({
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حسب الحالة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.hourglass_top,
                label: 'قيد الانتظار',
                value: '$pending',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.sync,
                label: 'قيد التنفيذ',
                value: '$inProgress',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                label: 'مكتملة',
                value: '$completed',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.cancel,
                label: 'ملغية',
                value: '$cancelled',
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.block,
                label: 'مرفوضة',
                value: '$rejected',
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.teal),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
