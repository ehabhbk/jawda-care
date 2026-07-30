import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../l10n/localization.dart';
import '../../../data/models/hospital_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HospitalModel> _nearestHospitals = [];
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadNearestHospitals();
  }

  Future<void> _loadNearestHospitals() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _loadingLocation = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition();
      final snap = await FirebaseFirestore.instance
          .collection('hospitals')
          .where('isActive', isEqualTo: true)
          .get();

      final hospitals = snap.docs
          .map((d) => HospitalModel.fromMap(d.data(), d.id))
          .where((h) => h.availableBeds > 0)
          .toList();

      hospitals.sort((a, b) {
        final da = _distance(pos.latitude, pos.longitude, a.latitude, a.longitude);
        final db = _distance(pos.latitude, pos.longitude, b.latitude, b.longitude);
        return da.compareTo(db);
      });

      if (mounted) {
        setState(() {
          _nearestHospitals = hospitals.take(5).toList();
          _loadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * asin(sqrt(a));
  }

  double _rad(double d) => d * pi / 180;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalization.of(context);
    final auth = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>();
    final isAr = lang.isArabic;
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.translate('appName')),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () => lang.toggleLanguage(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context, user?.name ?? 'User', isAr),
            const SizedBox(height: 24),
            Text(
              t.translate('quickActions'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context, t, isAr),
            const SizedBox(height: 24),
            Text(
              isAr ? 'أقرب المستشفيات (أسرة متاحة)' : 'Nearest Hospitals (Available Beds)',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _loadingLocation
                ? const Center(child: CircularProgressIndicator())
                : _nearestHospitals.isEmpty
                    ? Text(isAr ? 'لا توجد مستشفيات قريبة بأسرة متاحة' : 'No nearby hospitals with available beds')
                    : Column(
                        children: _nearestHospitals.map((h) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.local_hospital, color: Colors.teal),
                            title: Text(isAr ? h.nameAr : h.name),
                            subtitle: Text('${isAr ? "أسرة متاحة" : "Available beds"}: ${h.availableBeds}'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.icuBooking, arguments: h.id),
                          ),
                        )).toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String name, bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'مرحباً، $name' : 'Hello, $name',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'كيف يمكننا مساعدتك اليوم؟' : 'How can we help you today?',
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalization t, bool isAr) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.local_hospital,
            color: AppColors.icuGreen,
            label: isAr ? 'حجز سرير' : 'Book Bed',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.icuList),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.airport_shuttle,
            color: AppColors.ambulanceRed,
            label: isAr ? 'إسعاف' : 'Ambulance',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.ambulanceBooking),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.calendar_today,
            color: AppColors.warning,
            label: isAr ? 'حجوزاتي' : 'Bookings',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.myBookings),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
