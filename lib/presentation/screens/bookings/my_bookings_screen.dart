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

  Future<void> _cancelBooking(BookingModel booking) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'إلغاء الحجز' : 'Cancel Booking'),
        content: Text(isAr ? 'هل أنت متأكد من إلغاء هذا الحجز؟' : 'Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'رجوع' : 'Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && booking.id != null) {
      await context.read<BookingProvider>().cancelBooking(bookingId: booking.id!);
    }
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
        return _BookingCard(
          booking: b,
          isAr: isAr,
          onCancel: (b.status == BookingStatus.pending || b.status == BookingStatus.accepted || b.status == BookingStatus.inProgress)
              ? () => _cancelBooking(b)
              : null,
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isAr;
  final VoidCallback? onCancel;

  const _BookingCard({required this.booking, required this.isAr, this.onCancel});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.pendingOrange;
      case 'accepted':
      case 'confirmed':
        return AppColors.success;
      case 'inProgress':
      case 'headingToPatient':
      case 'pickedUp':
      case 'arrived':
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

    final isActive = booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.accepted ||
        booking.status == BookingStatus.inProgress ||
        booking.status == BookingStatus.headingToPatient ||
        booking.status == BookingStatus.pickedUp;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        isAr ? booking.statusLabelAr : booking.statusLabel,
                        style: TextStyle(color: _statusColor(booking.status.name), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (isIcu && isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(isAr ? 'قيد التنفيذ' : 'Active', style: const TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(booking.userName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(booking.userPhone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${booking.createdAt.year}-${booking.createdAt.month.toString().padLeft(2, '0')}-${booking.createdAt.day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (booking.hospitalName != null || booking.hospitalNameAr != null) ...[
              const SizedBox(height: 2),
              Text(isAr ? booking.hospitalNameAr ?? '' : booking.hospitalName ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!isIcu && (booking.status == BookingStatus.accepted || booking.status == BookingStatus.headingToPatient || booking.status == BookingStatus.pickedUp))
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map, size: 16),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.ambulanceTracking, arguments: booking.id),
                        label: Text(isAr ? 'تتبع' : 'Track', style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
                      ),
                    ),
                  if (isIcu && booking.id != null && booking.status == BookingStatus.pending)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel, size: 16),
                        onPressed: onCancel,
                        label: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                  if (!isIcu && onCancel != null)
                    const SizedBox(width: 8),
                  if (!isIcu && onCancel != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel, size: 16),
                        onPressed: onCancel,
                        label: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.bookingDetails, arguments: booking.id),
                    child: Text(isAr ? 'التفاصيل' : 'Details', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
            if (!isActive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.bookingDetails, arguments: booking.id),
                  child: Text(isAr ? 'عرض التفاصيل' : 'View Details'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
