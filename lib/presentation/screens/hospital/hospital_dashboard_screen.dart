import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../auth/login_screen.dart';

class HospitalDashboardScreen extends StatelessWidget {
  const HospitalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hospital = auth.hospitalAccount;
    final hospitalId = auth.userModel?.hospitalId;
    return Scaffold(
      appBar: AppBar(
        title: Text(hospital?.nameAr ?? 'لوحة تحكم المستشفى'),
        actions: [
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
            if (hospitalId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('hospitalId', isEqualTo: hospitalId)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                  }
                  final bookings = snap.data!.docs;
                  final total = bookings.length;
                  final icu = bookings.where((d) => (d.data() as Map)['bookingType'] == 'icu').length;
                  final ambulance = bookings.where((d) => (d.data() as Map)['bookingType'] == 'ambulance').length;
                  final pending = bookings.where((d) => (d.data() as Map)['status'] == 'pending').length;
                  final accepted = bookings.where((d) => (d.data() as Map)['status'] == 'accepted').length;
                  final inProgress = bookings.where((d) => (d.data() as Map)['status'] == 'inProgress').length;
                  final completed = bookings.where((d) => (d.data() as Map)['status'] == 'completed').length;
                  final cancelled = bookings.where((d) => (d.data() as Map)['status'] == 'cancelled').length;
                  final rejected = bookings.where((d) => (d.data() as Map)['status'] == 'rejected').length;

                  return Column(
                    children: [
                      _SectionTitle(title: 'إحصائيات الطلبات'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _StatCard(icon: Icons.medical_services, label: 'حجوزات أسرة', value: '$icu', color: Colors.teal)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatCard(icon: Icons.airport_shuttle, label: 'طلبات إسعاف', value: '$ambulance', color: Colors.orange)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatCard(icon: Icons.receipt_long, label: 'الإجمالي', value: '$total', color: Colors.blueGrey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionTitle(title: 'حسب الحالة'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _StatCard(icon: Icons.hourglass_top, label: 'قيد الانتظار', value: '$pending', color: Colors.amber)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatCard(icon: Icons.check, label: 'مقبول', value: '$accepted', color: Colors.lightGreen)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatCard(icon: Icons.sync, label: 'قيد التنفيذ', value: '$inProgress', color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _StatCard(icon: Icons.check_circle, label: 'مكتملة', value: '$completed', color: Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatCard(icon: Icons.cancel, label: 'ملغية', value: '$cancelled', color: Colors.grey)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatCard(icon: Icons.block, label: 'مرفوضة', value: '$rejected', color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            _SectionTitle(title: 'القائمة'),
            const SizedBox(height: 8),
            _MenuCard(
              icon: Icons.category,
              title: 'إدارة الأقسام',
              subtitle: 'إضافة أقسام العناية (مركزة - وسطى - قلبية)',
              onTap: () => Navigator.pushNamed(context, AppRoutes.manageDepartments),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.bed,
              title: 'إدارة الأسرة',
              subtitle: 'إضافة وتعديل الأسرة في كل قسم',
              onTap: () => Navigator.pushNamed(context, AppRoutes.manageBeds),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.pending_actions,
              title: 'طلبات الحجز',
              subtitle: 'قبول أو رفض طلبات حجز الأسرة',
              onTap: () => Navigator.pushNamed(context, AppRoutes.bookingRequests),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
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
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
