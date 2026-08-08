import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../l10n/localization.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/services/hospital_service.dart';
import '../../../data/services/location_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/hospital_logo.dart';
import '../../widgets/common/theme_toggle_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HospitalModel> _nearestHospitals = [];
  Map<String, int> _availableCounts = {};
  Map<String, int> _deptAvailableCounts = {};
  Map<String, List<Map<String, dynamic>>> _departmentsByHospital = {};
  bool _loadingLocation = true;
  final _hospitalService = HospitalService();

  @override
  void initState() {
    super.initState();
    _loadNearestHospitals();
  }

  Future<void> _loadNearestHospitals() async {
    try {
      final results = await Future.wait([
        _hospitalService.getHospitalsWithAvailableBeds(),
        _hospitalService.countAvailableBedsByHospital(),
        _hospitalService.countAvailableBedsByDepartment(),
        _hospitalService.getDepartmentsByHospital(),
      ]);
      final hospitals = results[0] as List<HospitalModel>;
      final counts = results[1] as Map<String, int>;
      final deptCounts = results[2] as Map<String, int>;
      final deptByHospital =
          results[3] as Map<String, List<Map<String, dynamic>>>;

      if (mounted) {
        setState(() {
          _nearestHospitals = hospitals.take(5).toList();
          _availableCounts = counts;
          _deptAvailableCounts = deptCounts;
          _departmentsByHospital = deptByHospital;
          _loadingLocation = false;
        });
      }

      final pos = await LocationService.getPosition(context);
      if (pos != null && mounted) {
        setState(() {
          _nearestHospitals.sort((a, b) {
            final da = _distance(
              pos.latitude,
              pos.longitude,
              a.latitude,
              a.longitude,
            );
            final db = _distance(
              pos.latitude,
              pos.longitude,
              b.latitude,
              b.longitude,
            );
            return da.compareTo(db);
          });
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
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
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
          const ThemeToggleButton(),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context, t, isAr),
            const SizedBox(height: 24),
            Text(
              isAr
                  ? 'أقرب المستشفيات (أسرة متاحة)'
                  : 'Nearest Hospitals (Available Beds)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _loadingLocation
                ? const Center(child: CircularProgressIndicator())
                : _nearestHospitals.isEmpty
                ? Text(
                    isAr
                        ? 'لا توجد مستشفيات قريبة بأسرة متاحة'
                        : 'No nearby hospitals with available beds',
                  )
                : Column(
                    children: _nearestHospitals
                        .map(
                          (h) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.icuBooking,
                                arguments: h.id,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HospitalLogo(
                                      imageUrl: h.imageUrl,
                                      radius: 30,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAr ? h.nameAr : h.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (h.addressAr.isNotEmpty ||
                                              h.address.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 15,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    isAr
                                                        ? (h
                                                                  .addressAr
                                                                  .isNotEmpty
                                                              ? h.addressAr
                                                              : h.address)
                                                        : h.address,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (h.cityAr.isNotEmpty ||
                                              h.city.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              isAr
                                                  ? (h.cityAr.isNotEmpty
                                                        ? h.cityAr
                                                        : h.city)
                                                  : h.city,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                          if (h.phone.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.phone,
                                                  size: 15,
                                                  color: Colors.teal,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  h.phone,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.teal,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          ...(() {
                                            final depts =
                                                _departmentsByHospital[h.id] ??
                                                [];
                                            final visibleDepts = depts
                                                .where(
                                                  (d) =>
                                                      (_deptAvailableCounts[d['id']] ??
                                                          0) >
                                                      0,
                                                )
                                                .toList();
                                            if (visibleDepts.isNotEmpty) {
                                              return visibleDepts
                                                  .map(
                                                    (d) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 3,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.bed,
                                                            size: 16,
                                                            color: Colors.teal,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '${isAr ? (d['nameAr'] ?? d['name']) : d['name']}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                          ),
                                                          Text(
                                                            '${_deptAvailableCounts[d['id']]}',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .teal,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            isAr
                                                                ? 'أسرة متاحة'
                                                                : 'beds',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: AppColors
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList();
                                            }
                                            return [
                                              Text(
                                                '${isAr ? "أسرة متاحة" : "Available beds"}: ${_availableCounts[h.id] ?? 0}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.teal,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ];
                                          }()),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'كيف يمكننا مساعدتك اليوم؟' : 'How can we help you today?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    AppLocalization t,
    bool isAr,
  ) {
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
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.ambulanceBooking),
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
          color: AppColors.surface,
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
