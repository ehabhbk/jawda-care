import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/services/hospital_service.dart';
import '../../../data/services/location_service.dart';

class IcuListScreen extends StatefulWidget {
  const IcuListScreen({super.key});

  @override
  State<IcuListScreen> createState() => _IcuListScreenState();
}

class _IcuListScreenState extends State<IcuListScreen> {
  List<HospitalModel> _hospitals = [];
  Map<String, int> _availableCounts = {};
  bool _loading = true;
  bool _error = false;
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
      final pos = await LocationService.getPosition(context);

      final hospitals = await _hospitalService.getHospitalsWithAvailableBeds();
      final counts = await _hospitalService.countAvailableBedsByHospital();

      if (pos != null) {
        hospitals.sort((a, b) {
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
      }

      if (mounted) {
        setState(() {
          _hospitals = hospitals;
          _availableCounts = counts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
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
                  ),
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
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_hospital,
                      color: Colors.teal,
                    ),
                    title: Text(isAr ? h.nameAr : h.name),
                    subtitle: Text(
                      '${isAr ? "أسرة متاحة" : "Available beds"}: $count | ${h.cityAr.isNotEmpty ? h.cityAr : h.city}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.icuBooking,
                      arguments: h.id,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
