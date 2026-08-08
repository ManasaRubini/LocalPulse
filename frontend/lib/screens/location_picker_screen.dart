import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const LocationPickerScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng selectedLocation;
  String address = "Tap anywhere on the map to place pin";
  bool isLocating = false;

  @override
  void initState() {
    super.initState();
    selectedLocation = LatLng(widget.initialLatitude, widget.initialLongitude);
    _getAddress();
  }

  Future<void> _getAddress() async {
    setState(() => isLocating = true);
    try {
      List<Placemark> places = await placemarkFromCoordinates(
        selectedLocation.latitude,
        selectedLocation.longitude,
      );

      if (places.isNotEmpty) {
        Placemark p = places.first;
        setState(() {
          address = "${p.street ?? ''}, ${p.locality ?? AppConfig.defaultCity}, ${p.administrativeArea ?? ''}".replaceAll(RegExp(r'^,\s*'), '');
        });
      }
    } catch (_) {
      setState(() {
        address = "Selected Pin Location (${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)})";
      });
    } finally {
      if (mounted) setState(() => isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Pick Incident Pin",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: selectedLocation,
                initialZoom: 15,
                onTap: (tapPosition, point) async {
                  setState(() {
                    selectedLocation = point;
                  });
                  await _getAddress();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.localpulse.app",
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.alert,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: AppColors.alert.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.alert, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Selected Incident Address",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isLocating ? "Fetching reverse geocoding address..." : address,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        "latitude": selectedLocation.latitude,
                        "longitude": selectedLocation.longitude,
                        "address": address,
                      });
                    },
                    child: const Text(
                      "Confirm Incident Location",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}