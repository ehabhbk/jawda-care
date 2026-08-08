import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/services/hospital_service.dart';
import '../../../data/services/location_service.dart';
import '../../widgets/common/hospital_logo.dart';

class IcuListScreen extends StatefulWidget {
  const IcuListScreen({super.key});

  @override
  State<IcuListScreen> createState() => _IcuListScreenState();
}

class _IcuListScreenState extends State<IcuListScreen> {
  List<HospitalModel> _hospitals = [];
  Map<String, int> _availableCounts = {};
  Map<String, int> _deptAvailableCounts = {};
  Map<String, List<Map<String, dynamic>>> _departmentsByHospital = {};
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;
  final _hospitalService = HospitalService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
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
          _hospitals = hospitals;
          _availableCounts = counts;
          _deptAvailableCounts = deptCounts;
          _departmentsByHospital = deptByHospital;
          _loading = false;
        });
      }

      final pos = await LocationService.getPosition(context);
      if (pos != null && mounted) {
        setState(() {
          _hospitals.sort((a, b) {
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
          _errorMessage = e.toString();
        });
      }
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isAr ? 'حجز سرير' : 'Book a Bed')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 56,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr
                        ? 'حدث خطأ أثناء تحميل المستشفيات'
                        : 'Failed to load hospitals',
                    textAlign: TextAlign.center,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              ),
            )
          : _hospitals.isEmpty
          ? Center(
              child: Text(
                isAr
                    ? 'لا توجد مستشفيات بأسرة متاحة'
                    : 'No hospitals with available beds',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _hospitals.length,
              itemBuilder: (ctx, i) {
                final h = _hospitals[i];
                final count = _availableCounts[h.id] ?? 0;
                final depts = _departmentsByHospital[h.id] ?? [];
                final visibleDepts = depts
                    .where((d) => (_deptAvailableCounts[d['id']] ?? 0) > 0)
                    .toList();
                return Card(
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
                          HospitalLogo(imageUrl: h.imageUrl, radius: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                          color: AppColors.textSecondary,
                                        ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          isAr
                                              ? (h.addressAr.isNotEmpty
                                                    ? h.addressAr
                                                    : h.address)
                                              : h.address,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
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
                                if (visibleDepts.isNotEmpty)
                                  ...visibleDepts.map(
                                    (d) => Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.bed,
                                            size: 16,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${isAr ? (d['nameAr'] ?? d['name']) : d['name']}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${_deptAvailableCounts[d['id']]}',
                                            style: const TextStyle(
                                              color: Colors.teal,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isAr ? 'أسرة متاحة' : 'beds',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    '${isAr ? "أسرة متاحة" : "Available beds"}: $count',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.teal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
