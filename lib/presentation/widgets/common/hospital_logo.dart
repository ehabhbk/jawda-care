import 'dart:convert';
import 'package:flutter/material.dart';

class HospitalLogo extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? name;

  const HospitalLogo({super.key, this.imageUrl, this.radius = 24, this.name});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: ClipOval(
          child: url.startsWith('data:')
              ? Image.memory(
                  base64Decode(url.substring(url.indexOf(',') + 1)),
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackIcon(),
                )
              : Image.network(
                  url,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackIcon(),
                ),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.teal.withValues(alpha: 0.12),
      child: Icon(Icons.local_hospital, size: radius, color: Colors.teal),
    );
  }
}
