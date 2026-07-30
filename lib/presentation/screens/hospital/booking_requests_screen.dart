import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../../core/routes/app_routes.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.userModel?.hospitalId;
    if (hospitalId != null) {
      context.read<BookingProvider>().loadHospitalBookings(hospitalId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BookingProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات الحجز')),
      body: bp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bp.bookings.isEmpty
              ? const Center(child: Text('لا توجد طلبات'))
              : ListView.builder(
                  itemCount: bp.bookings.length,
                  itemBuilder: (ctx, i) {
                    final booking = bp.bookings[i];
                    Color statusColor;
                    switch (booking.status.name) {
                      case 'pending':
                        statusColor = Colors.orange;
                        break;
                      case 'accepted':
                      case 'inProgress':
                        statusColor = Colors.green;
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }
                    return Card(
                      child: ListTile(
                        title: Text(booking.userName),
                        subtitle: Text('${booking.departmentNameAr ?? booking.departmentName ?? ""} | ${booking.statusLabelAr}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios),
                          ],
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.bookingDetails,
                          arguments: booking.id,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
