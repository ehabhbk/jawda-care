import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/services/location_service.dart';

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
  bool _gettingCurrent = false;

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

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingCurrent = true);
    final pos = await LocationService.getPosition(context);
    if (!mounted) return;
    setState(() => _gettingCurrent = false);
    if (pos == null) return;
    _setLocation(LatLng(pos.latitude, pos.longitude));
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر موقع المستشفى على الخريطة',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selected ?? const LatLng(30.0444, 31.2357),
                zoom: 6,
              ),
              onMapCreated: (ctrl) => _mapController = ctrl,
              onTap: _setLocation,
              markers: _selected != null
                  ? {
                      Marker(
                        markerId: const MarkerId('location'),
                        position: _selected!,
                        infoWindow: const InfoWindow(title: 'موقع المستشفى'),
                      ),
                    }
                  : {},
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _gettingCurrent ? null : _useCurrentLocation,
                icon: _gettingCurrent
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _gettingCurrent
                      ? 'جار تحديد موقعك...'
                      : 'استخدام موقعي الحالي',
                ),
              ),
            ),
          ],
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
