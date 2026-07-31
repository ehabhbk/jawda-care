import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'data/services/notification_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/icu_provider.dart';
import 'presentation/providers/ambulance_provider.dart';
import 'presentation/providers/booking_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/admin_provider.dart';
import 'presentation/providers/department_provider.dart';
import 'presentation/providers/bed_provider.dart';
import 'presentation/providers/trip_provider.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IcuProvider()),
        ChangeNotifierProvider(create: (_) => AmbulanceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => DepartmentProvider()),
        ChangeNotifierProvider(create: (_) => BedProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
      ],
      child: const JawdaCareApp(),
    ),
  );
}
