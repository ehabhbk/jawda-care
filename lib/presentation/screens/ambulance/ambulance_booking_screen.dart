import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common/custom_button.dart';

class AmbulanceBookingScreen extends StatefulWidget {
  const AmbulanceBookingScreen({super.key});

  @override
  State<AmbulanceBookingScreen> createState() => _AmbulanceBookingScreenState();
}

class _AmbulanceBookingScreenState extends State<AmbulanceBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _requestAmbulance() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    double? lat;
    double? lng;
    try {
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    final bookingModel = BookingModel(
      userId: auth.userModel!.id!,
      userName: auth.userModel!.name,
      userPhone: auth.userModel!.phone,
      userLat: lat,
      userLng: lng,
      bookingType: BookingType.ambulance,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final bookingId = await booking.createBookingFromModel(bookingModel);

    if (bookingId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'تم طلب الإسعاف بنجاح!' : 'Ambulance requested successfully!')),
      );
      Navigator.of(context).pushReplacementNamed(AppRoutes.ambulanceTracking, arguments: bookingId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.ambulanceRed,
        title: Text(isAr ? 'حجز إسعاف' : 'Ambulance Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.ambulanceRed, Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency, size: 40, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'طلب إسعاف طارئ' : 'Emergency Ambulance',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr ? 'سيتم إرسال أقرب إسعاف إلى موقعك' : 'Nearest ambulance will be sent to your location',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isAr ? 'حالة المريض، متطلبات خاصة...' : 'Patient condition, special needs...',
                  prefixIcon: const Icon(Icons.note_add),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: isAr ? 'طلب الإسعاف' : 'Request Ambulance',
                backgroundColor: AppColors.ambulanceRed,
                isLoading: booking.isLoading,
                onPressed: _requestAmbulance,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone, color: AppColors.ambulanceRed),
                label: Text(
                  isAr ? 'اتصال طوارئ 997' : 'Emergency Call 997',
                  style: const TextStyle(color: AppColors.ambulanceRed),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.ambulanceRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
