import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
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
              icon: Icons.local_hospital,
              title: 'إضافة مستشفى',
              subtitle: 'إضافة مستشفى جديد مع حساب خاص',
              onTap: () => Navigator.pushNamed(context, AppRoutes.addHospital),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.airport_shuttle,
              title: 'إضافة سيارة إسعاف',
              subtitle: 'إضافة سيارة إسعاف جديدة مع حساب سائق',
              onTap: () => Navigator.pushNamed(context, AppRoutes.addAmbulance),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.admin_panel_settings,
              title: 'إضافة أدمن جديد',
              subtitle: 'إنشاء حساب أدمن جديد',
              onTap: () => Navigator.pushNamed(context, AppRoutes.addAdmin),
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
