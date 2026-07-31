import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final ValueChanged<LatLng> onChanged;
  final double height;

  const LocationPicker({
    super.key,
    this.initialLocation,
    required this.onChanged,
    this.height = 250,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _setLocation(LatLng pos) {
    setState(() => _selected = pos);
    widget.onChanged(pos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر موقع المستشفى على الخريطة', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selected ?? const LatLng(24.7136, 46.6753),
                zoom: 10,
              ),
              onMapCreated: (ctrl) => _mapController = ctrl,
              onTap: _setLocation,
              markers: _selected != null
                  ? {Marker(markerId: const MarkerId('location'), position: _selected!)}
                  : {},
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'الإحداثيات: ${_selected!.latitude.toStringAsFixed(4)}, ${_selected!.longitude.toStringAsFixed(4)}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
