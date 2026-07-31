import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> ensureLocationEnabled(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!context.mounted) return false;
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      final shouldOpen = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'تشغيل الموقع' : 'Enable Location'),
          content: Text(
            isAr
                ? 'يجب تشغيل خدمة تحديد الموقع (GPS) لتتمكن من استخدام هذه الميزة.'
                : 'You must enable GPS (location services) to use this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isAr ? 'فتح الإعدادات' : 'Open Settings'),
            ),
          ],
        ),
      );
      if (shouldOpen != true) return false;
      await Geolocator.openLocationSettings();
      await Future.delayed(const Duration(seconds: 1));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    if (!context.mounted) return false;
    return ensurePermission(context);
  }

  static Future<bool> ensurePermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'إذن الموقع' : 'Location Permission'),
          content: Text(
            isAr
                ? 'تم رفض إذن الوصول إلى الموقع بشكل دائم. يرجى السماح بالوصول إلى الموقع من الإعدادات.'
                : 'Location permission was permanently denied. Please allow location access from settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isAr ? 'فتح الإعدادات' : 'Open Settings'),
            ),
          ],
        ),
      );
      if (shouldOpen != true) return false;
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  static Future<Position?> getPosition(BuildContext context) async {
    try {
      final ok = await ensureLocationEnabled(context);
      if (!ok) return null;
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 20));
      } on TimeoutException {
        try {
          return await Geolocator.getLastKnownPosition();
        } catch (_) {
          return null;
        }
      }
    } catch (_) {
      return null;
    }
  }
}
