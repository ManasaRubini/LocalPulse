import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const LocationPickerScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState
    extends State<LocationPickerScreen> {

  late LatLng selectedLocation;

  String address = "Tap anywhere on the map";

  @override
  void initState() {
    super.initState();

    selectedLocation = LatLng(
      widget.initialLatitude,
      widget.initialLongitude,
    );

    _getAddress();
  }

  Future<void> _getAddress() async {
    try {
      List<Placemark> places =
          await placemarkFromCoordinates(
        selectedLocation.latitude,
        selectedLocation.longitude,
      );

      Placemark p = places.first;

      setState(() {
        address =
            "${p.street}, ${p.locality}, ${p.administrativeArea}";
      });
    } catch (_) {
      setState(() {
        address = "Unknown Location";
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
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
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName:
                      "com.localpulse.app",
                ),

                MarkerLayer(
                  markers: [

                    Marker(
                      point: selectedLocation,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 45,
                      ),
                    ),

                  ],
                ),

              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(15),

            child: Column(
              children: [

                Row(
                  children: const [

                    Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),

                    SizedBox(width: 8),

                    Text(
                      "Selected Location",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 10),

                Text(address),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(

                    onPressed: () {

                      Navigator.pop(context, {

                        "latitude":
                            selectedLocation.latitude,

                        "longitude":
                            selectedLocation.longitude,

                        "address":
                            address,

                      });

                    },

                    child: const Text("Save Location"),
                  ),
                )

              ],
            ),
          )
        ],
      ),
    );
  }
}