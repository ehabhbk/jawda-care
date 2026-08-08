import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../../data/models/ambulance_model.dart';
import '../../../data/services/booking_notification_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/common/theme_toggle_button.dart';
import '../auth/login_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  AmbulanceModel? _ambulance;
  StreamSubscription? _ambSub;

  @override
  void initState() {
    super.initState();
    _loadAmbulance();
  }

  void _loadAmbulance() {
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;
    _ambSub = FirebaseFirestore.instance
        .collection('ambulances')
        .where(
          'driverEmail',
          isEqualTo: context.read<AuthProvider>().userModel?.email,
        )
        .limit(1)
        .snapshots()
        .listen((snap) {
          if (snap.docs.isNotEmpty) {
            setState(() {
              _ambulance = AmbulanceModel.fromMap(
                snap.docs.first.data(),
                snap.docs.first.id,
              );
            });
            BookingNotificationWatcher.instance.startDriverWatch(
              snap.docs.first.id,
            );
          }
        });
  }

  @override
  void dispose() {
    _ambSub?.cancel();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    if (_ambulance?.id == null) return;
    await FirebaseFirestore.instance
        .collection('ambulances')
        .doc(_ambulance!.id!)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _ambulance != null
              ? '${isAr ? "سيارة" : "Car"} ${_ambulance!.plateNumber}'
              : (isAr ? 'لوحة تحكم السائق' : 'Driver Dashboard'),
        ),
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
      body: _ambulance == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isAr ? "رقم اللوحة" : "Plate"}: ${_ambulance!.plateNumber}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${isAr ? "السائق" : "Driver"}: ${_ambulance!.driverName}',
                          ),
                          Text(
                            '${isAr ? "الهاتف" : "Phone"}: ${_ambulance!.driverPhone}',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(isAr ? 'الحالة: ' : 'Status: '),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _ambulance!.status == 'available'
                                      ? Colors.green
                                      : _ambulance!.status == 'maintenance'
                                      ? Colors.orange
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _ambulance!.status == 'available'
                                      ? (isAr ? 'متاح' : 'Available')
                                      : _ambulance!.status == 'maintenance'
                                      ? (isAr ? 'صيانة' : 'Maintenance')
                                      : (isAr ? 'مشغول' : 'Occupied'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'تغيير الحالة:' : 'Change Status:',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _ambulance!.status == 'available'
                              ? null
                              : () => _updateStatus('available'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text(isAr ? 'متاح' : 'Available'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _ambulance!.status == 'maintenance'
                              ? null
                              : () => _updateStatus('maintenance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: Text(isAr ? 'صيانة' : 'Maintenance'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_ambulance!.id != null)
                    _PendingRequestsSection(ambulance: _ambulance!),
                  const SizedBox(height: 20),
                  if (_ambulance!.id != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('ambulanceId', isEqualTo: _ambulance!.id)
                          .snapshots(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        final bookings = snap.data!.docs;
                        final total = bookings.length;
                        final completed = bookings
                            .where(
                              (d) => (d.data() as Map)['status'] == 'completed',
                            )
                            .length;
                        final inProgress = bookings.where((d) {
                          final s = (d.data() as Map)['status'];
                          return s == 'headingToPatient' || s == 'pickedUp';
                        }).length;
                        final cancelled = bookings
                            .where(
                              (d) => (d.data() as Map)['status'] == 'cancelled',
                            )
                            .length;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'إحصائيات الرحلات' : 'Trip Stats',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.receipt_long,
                                    label: isAr ? 'إجمالي' : 'Total',
                                    value: '$total',
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.sync,
                                    label: isAr ? 'قيد التنفيذ' : 'Active',
                                    value: '$inProgress',
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.check_circle,
                                    label: isAr ? 'مكتملة' : 'Done',
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
                                    label: isAr ? 'ملغية' : 'Cancelled',
                                    value: '$cancelled',
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Container()),
                                const SizedBox(width: 8),
                                Expanded(child: Container()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  Text(
                    isAr ? 'الرحلات المخصصة:' : 'Assigned Trips:',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('ambulanceId', isEqualTo: _ambulance!.id)
                        .where(
                          'status',
                          whereIn: ['accepted', 'headingToPatient', 'pickedUp'],
                        )
                        .snapshots(),
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            isAr ? 'لا توجد رحلات مخصصة' : 'No assigned trips',
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final status = data['status'] ?? '';
                          String statusText;
                          Color statusColor;
                          switch (status) {
                            case 'accepted':
                              statusText = isAr ? 'مقبول' : 'Accepted';
                              statusColor = Colors.blue;
                              break;
                            case 'headingToPatient':
                              statusText = isAr
                                  ? 'في الطريق للمريض'
                                  : 'Heading to patient';
                              statusColor = Colors.orange;
                              break;
                            case 'pickedUp':
                              statusText = isAr ? 'تم الاستلام' : 'Picked up';
                              statusColor = Colors.teal;
                              break;
                            default:
                              statusText = status;
                              statusColor = Colors.grey;
                          }
                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.airport_shuttle,
                                color: Colors.red,
                              ),
                              title: Text(data['userName'] ?? ''),
                              subtitle: Text(statusText),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.driverTrip,
                                arguments: {
                                  'bookingId': docs[i].id,
                                  'ambulanceId': _ambulance!.id,
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _PendingRequestsSection extends StatefulWidget {
  final AmbulanceModel ambulance;

  const _PendingRequestsSection({required this.ambulance});

  @override
  State<_PendingRequestsSection> createState() =>
      _PendingRequestsSectionState();
}

class _PendingRequestsSectionState extends State<_PendingRequestsSection> {
  bool _busy = false;

  double _distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = 6371;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return c * (2 * asin(sqrt(a)));
  }

  Future<void> _accept(QueryDocumentSnapshot<Object?> doc) async {
    setState(() => _busy = true);
    final bp = context.read<BookingProvider>();
    final ok = await bp.acceptAmbulanceByDriver(
      bookingId: doc.id,
      ambulanceId: widget.ambulance.id!,
      driverName: widget.ambulance.driverName,
      driverPhone: widget.ambulance.driverPhone,
      plateNumber: widget.ambulance.plateNumber,
    );
    if (ok) {
      await FirebaseFirestore.instance
          .collection('ambulances')
          .doc(widget.ambulance.id)
          .update({'status': 'occupied'});
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pushNamed(
        context,
        AppRoutes.driverTrip,
        arguments: {'bookingId': doc.id, 'ambulanceId': widget.ambulance.id},
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل قبول الطلب')));
    }
  }

  Future<void> _reject(QueryDocumentSnapshot<Object?> doc) async {
    setState(() => _busy = true);
    final bp = context.read<BookingProvider>();
    await bp.rejectAmbulanceByDriver(
      bookingId: doc.id,
      ambulanceId: widget.ambulance.id!,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'طلبات الإسعاف الواردة:' : 'Incoming Ambulance Requests:',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final allDocs = snapshot.data?.docs ?? [];

            final driverLat = widget.ambulance.currentLat;
            final driverLng = widget.ambulance.currentLng;

            final requests = allDocs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              if (data['bookingType'] != 'ambulance') return false;
              final rejected =
                  data['rejectedAmbulanceIds'] as List<dynamic>? ?? [];
              return !rejected.contains(widget.ambulance.id);
            }).toList();

            requests.sort((a, b) {
              final da = a.data() as Map<String, dynamic>;
              final db = b.data() as Map<String, dynamic>;
              final distA = _distanceInKm(
                driverLat,
                driverLng,
                (da['userLat'] ?? 0).toDouble(),
                (da['userLng'] ?? 0).toDouble(),
              );
              final distB = _distanceInKm(
                driverLat,
                driverLng,
                (db['userLat'] ?? 0).toDouble(),
                (db['userLng'] ?? 0).toDouble(),
              );
              return distA.compareTo(distB);
            });

            if (requests.isEmpty) {
              return Center(
                child: Text(
                  isAr ? 'لا توجد طلبات إسعاف حالياً' : 'No ambulance requests',
                ),
              );
            }

            return Column(
              children: requests.take(5).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final distance = _distanceInKm(
                  driverLat,
                  driverLng,
                  (data['userLat'] ?? 0).toDouble(),
                  (data['userLng'] ?? 0).toDouble(),
                );
                final destName = isAr
                    ? (data['hospitalNameAr'] ?? data['hospitalName'])
                    : (data['hospitalName'] ?? data['hospitalNameAr']);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: AppColors.ambulanceRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${data['userName'] ?? ''} (${data['userPhone'] ?? ''})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (destName != null)
                          Text(
                            '${isAr ? "الوجهة" : "Destination"}: $destName',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        Text(
                          '${isAr ? "المسافة" : "Distance"}: ${distance < 1 ? "${(distance * 1000).round()} م" : "${distance.toStringAsFixed(1)} كم"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _busy ? null : () => _accept(doc),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(isAr ? 'قبول' : 'Accept'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy ? null : () => _reject(doc),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text(isAr ? 'رفض' : 'Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
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
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
