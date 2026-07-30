import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/ambulance_model.dart';
import '../../../core/routes/app_routes.dart';

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
        .where('driverEmail', isEqualTo: context.read<AuthProvider>().userModel?.email)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isNotEmpty) {
        setState(() {
          _ambulance = AmbulanceModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
        });
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
    await FirebaseFirestore.instance.collection('ambulances').doc(_ambulance!.id!).update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_ambulance != null ? 'سيارة ${_ambulance!.plateNumber}' : 'لوحة تحكم السائق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: _ambulance == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                          Text('رقم اللوحة: ${_ambulance!.plateNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('السائق: ${_ambulance!.driverName}'),
                          Text('الهاتف: ${_ambulance!.driverPhone}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('الحالة: '),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                      ? 'متاح'
                                      : _ambulance!.status == 'maintenance'
                                          ? 'صيانة'
                                          : 'مشغول',
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
                  const Text('تغيير الحالة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _ambulance!.status == 'available' ? null : () => _updateStatus('available'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('متاح'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _ambulance!.status == 'maintenance' ? null : () => _updateStatus('maintenance'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('صيانة'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('الطلبات المتاحة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('status', isEqualTo: 'accepted')
                          .where('ambulanceId', isNull: true)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('لا توجد طلبات متاحة'));
                        }
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.local_hospital, color: Colors.teal),
                                title: Text(data['userName'] ?? ''),
                                subtitle: Text(data['hospitalNameAr'] ?? data['hospitalName'] ?? ''),
                                trailing: const Icon(Icons.map),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.driverTrip,
                                  arguments: {'bookingId': docs[i].id, 'ambulanceId': _ambulance!.id},
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
            ),
    );
  }
}
