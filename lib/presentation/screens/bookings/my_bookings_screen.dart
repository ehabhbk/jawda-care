import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userModel?.id;
      if (userId != null) {
        context.read<BookingProvider>().loadUserBookings(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isAr ? 'حجوزاتي' : 'My Bookings')),
      body: _buildContent(booking, isAr),
    );
  }

  Widget _buildContent(BookingProvider provider, bool isAr) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    final bookings = provider.bookings;

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(isAr ? 'لا توجد حجوزات' : 'No bookings', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.home),
              child: Text(isAr ? 'حجز الآن' : 'Book Now'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return _BookingCard(booking: b, isAr: isAr);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isAr;

  const _BookingCard({required this.booking, required this.isAr});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.pendingOrange;
      case 'accepted':
      case 'confirmed':
        return AppColors.success;
      case 'inProgress':
        return AppColors.info;
      case 'completed':
        return AppColors.textSecondary;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIcu = booking.bookingType.name == 'icu';
    final icon = isIcu ? Icons.bed : Icons.airport_shuttle;
    final color = isIcu ? AppColors.icuGreen : AppColors.ambulanceRed;
    final title = isIcu
        ? (isAr ? 'حجز سرير' : 'Bed Booking')
        : (isAr ? 'حجز إسعاف' : 'Ambulance Booking');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  isAr ? booking.statusLabelAr : booking.statusLabel,
                  style: TextStyle(color: _statusColor(booking.status.name), fontWeight: FontWeight.w600),
                ),
                if (booking.status == BookingStatus.accepted || booking.status == BookingStatus.inProgress)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.ambulanceTracking, arguments: booking.id),
                    child: Text(isAr ? 'تتبع' : 'Track', style: const TextStyle(color: Colors.teal)),
                  ),
              ],
            ),
            Text(
              '${booking.createdAt.year}-${booking.createdAt.month.toString().padLeft(2, '0')}-${booking.createdAt.day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.bookingDetails, arguments: booking.id),
      ),
    );
  }
}
