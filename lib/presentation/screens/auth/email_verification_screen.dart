import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _resent = false;

  Future<void> _checkVerification() async {
    _isChecking = true;
    setState(() {});

    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerified();

    if (!mounted) return;

    if (verified) {
      await auth.loadUserData(auth.firebaseUser!.uid);
      if (!mounted) return;
      final role = auth.userModel?.role;
      String route;
      switch (role) {
        case 'admin':
          route = AppRoutes.adminDashboard;
          break;
        case 'hospital':
          route = AppRoutes.hospitalDashboard;
          break;
        case 'driver':
          route = AppRoutes.driverDashboard;
          break;
        default:
          route = AppRoutes.home;
      }
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      _isChecking = false;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'البريد الإلكتروني لم يتم التحقق منه بعد. يرجى التحقق من بريدك الوارد.'
                : 'Email not verified yet. Please check your inbox.',
          ),
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    await context.read<AuthProvider>().resendVerificationEmail();
    _resent = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_outlined, size: 50, color: AppColors.warning),
              ),
              const SizedBox(height: 32),
              Text(
                isAr ? 'تحقق من بريدك الإلكتروني' : 'Verify Your Email',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                isAr
                    ? 'تم إرسال رابط التحقق إلى بريدك الإلكتروني. يرجى النقر على الرابط لتفعيل حسابك.'
                    : 'A verification link has been sent to your email. Click the link to activate your account.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? 'لم تصلك الرسالة؟ تحقق من مجلد البريد المزعج.' : "Didn't receive it? Check your spam folder.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: isAr ? 'تم التحقق - ادخل الآن' : "I've Verified - Continue",
                isLoading: _isChecking,
                onPressed: _checkVerification,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: _resent
                    ? (isAr ? 'تم إعادة الإرسال ✓' : 'Resent ✓')
                    : (isAr ? 'إعادة إرسال البريد' : 'Resend Email'),
                isOutlined: true,
                onPressed: _resent ? null : _resendEmail,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  context.read<AuthProvider>().signOut();
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                },
                child: Text(
                  isAr ? 'استخدام حساب آخر' : 'Use a different account',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
