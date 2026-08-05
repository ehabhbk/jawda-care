import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/constants/app_colors.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/localization.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/email_verification_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/auth/about_us_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/icu/icu_list_screen.dart';
import 'presentation/screens/icu/icu_booking_screen.dart';
import 'presentation/screens/ambulance/ambulance_booking_screen.dart';
import 'presentation/screens/ambulance/ambulance_tracking_screen.dart';
import 'presentation/screens/bookings/my_bookings_screen.dart';
import 'presentation/screens/bookings/booking_details_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/edit_profile_screen.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';
import 'presentation/screens/admin/hospitals_management_screen.dart';
import 'presentation/screens/admin/ambulances_management_screen.dart';
import 'presentation/screens/admin/admins_management_screen.dart';
import 'presentation/screens/admin/add_hospital_screen.dart';
import 'presentation/screens/admin/add_ambulance_screen.dart';
import 'presentation/screens/admin/add_admin_screen.dart';
import 'presentation/screens/hospital/hospital_dashboard_screen.dart';
import 'presentation/screens/hospital/manage_departments_screen.dart';
import 'presentation/screens/hospital/manage_beds_screen.dart';
import 'presentation/screens/hospital/booking_requests_screen.dart';
import 'presentation/screens/hospital/patients_management_screen.dart';
import 'presentation/screens/driver/driver_dashboard_screen.dart';
import 'presentation/screens/driver/driver_trip_screen.dart';

class JawdaCareApp extends StatefulWidget {
  const JawdaCareApp({super.key});

  @override
  State<JawdaCareApp> createState() => _JawdaCareAppState();
}

class _JawdaCareAppState extends State<JawdaCareApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().checkSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp(
      title: 'Jawda Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        AppColors.brightness = Theme.of(context).brightness;
        return child!;
      },
      locale: lang.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: [
        AppLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale?.languageCode) {
            return supported;
          }
        }
        return supportedLocales.first;
      },
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SplashScreen(),
            );
          case AppRoutes.login:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const LoginScreen(),
            );
          case AppRoutes.register:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const RegisterScreen(),
            );
          case AppRoutes.emailVerification:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const EmailVerificationScreen(),
            );
          case AppRoutes.forgotPassword:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ForgotPasswordScreen(),
            );
          case AppRoutes.aboutUs:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AboutUsScreen(),
            );
          case AppRoutes.home:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HomeScreen(),
            );
          case AppRoutes.icuList:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const IcuListScreen(),
            );
          case AppRoutes.icuBooking:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const IcuBookingScreen(),
            );
          case AppRoutes.ambulanceBooking:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AmbulanceBookingScreen(),
            );
          case AppRoutes.ambulanceTracking:
            final bookingId = args as String;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => AmbulanceTrackingScreen(bookingId: bookingId),
            );
          case AppRoutes.myBookings:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const MyBookingsScreen(),
            );
          case AppRoutes.bookingDetails:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const BookingDetailsScreen(),
            );
          case AppRoutes.profile:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ProfileScreen(),
            );
          case AppRoutes.editProfile:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const EditProfileScreen(),
            );
          case AppRoutes.adminDashboard:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AdminDashboardScreen(),
            );
          case AppRoutes.hospitalsManagement:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HospitalsManagementScreen(),
            );
          case AppRoutes.ambulancesManagement:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AmbulancesManagementScreen(),
            );
          case AppRoutes.adminsManagement:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AdminsManagementScreen(),
            );
          case AppRoutes.addHospital:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AddHospitalScreen(),
            );
          case AppRoutes.addAmbulance:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AddAmbulanceScreen(),
            );
          case AppRoutes.addAdmin:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AddAdminScreen(),
            );
          case AppRoutes.hospitalDashboard:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HospitalDashboardScreen(),
            );
          case AppRoutes.manageDepartments:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ManageDepartmentsScreen(),
            );
          case AppRoutes.manageBeds:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ManageBedsScreen(),
            );
          case AppRoutes.bookingRequests:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const BookingRequestsScreen(),
            );
          case AppRoutes.managePatients:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const PatientsManagementScreen(),
            );
          case AppRoutes.driverDashboard:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const DriverDashboardScreen(),
            );
          case AppRoutes.driverTrip:
            final tripArgs = args as Map<String, dynamic>;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => DriverTripScreen(
                bookingId: tripArgs['bookingId'],
                ambulanceId: tripArgs['ambulanceId'],
              ),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SplashScreen(),
            );
        }
      },
    );
  }
}
