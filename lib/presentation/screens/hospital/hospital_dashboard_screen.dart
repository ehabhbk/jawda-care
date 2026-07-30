import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';

class HospitalDashboardScreen extends StatelessWidget {
  const HospitalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hospital = auth.hospitalAccount;
    return Scaffold(
      appBar: AppBar(
        title: Text(hospital?.nameAr ?? 'لوحة تحكم المستشفى'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
