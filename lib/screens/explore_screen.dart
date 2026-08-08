import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:url_launcher/url_launcher.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {

  // ===========================
  // Backend URL
  // ===========================

  static const String baseUrl =
      "https://my-backend-4hfj.onrender.com";

  // ===========================
  // Controllers
  // ===========================

  final MapController mapController = MapController();

  final TextEditingController searchController =
      TextEditingController();

  // ===========================
  // Current Location
  // ===========================

  LatLng currentLocation =
      const LatLng(11.0168, 76.9558);

  bool loading = true;

  // ===========================
  // Filters
  // ===========================

  String selectedType = "hospital";

  final List<Map<String, dynamic>> filters = [

    {
      "title": "Hospital",
      "type": "hospital",
      "icon": Icons.local_hospital,
    },

    {
      "title": "Police",
      "type": "police",
      "icon": Icons.local_police,
    },

    {
      "title": "Fire",
      "type": "fire",
      "icon": Icons.local_fire_department,
    },

    {
      "title": "Water",
      "type": "water",
      "icon": Icons.water_drop,
    },

    {
      "title": "Waste",
      "type": "waste",
      "icon": Icons.delete,
    },

    {
      "title": "Issues",
      "type": "issues",
      "icon": Icons.report,
    },

    {
      "title": "Events",
      "type": "events",
      "icon": Icons.event,
    },
  ];

  // ===========================
  // Marker Data
  // ===========================

  List<Marker> markers = [];

  List<dynamic> nearbyData = [];

  dynamic selectedItem;

  // ===========================
  // INIT
  // ===========================

  @override
  void initState() {
    super.initState();

    initialize();
  }
  Future<void> openDirections(
    double lat,
    double lon,
    ) async {

  final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lon");

  if (await canLaunchUrl(url)) {

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }
}
  Future<void> initialize() async {

    await getCurrentLocation();

    await loadMarkers();
  }

  // ===========================
  // LOCATION
  // ===========================

  Future<void> getCurrentLocation() async {

    bool enabled =
        await Geolocator.isLocationServiceEnabled();

    if (!enabled) {

      setState(() {
        loading = false;
      });

      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {

      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {

      setState(() {
        loading = false;
      });

      return;
    }

    Position position =
        await Geolocator.getCurrentPosition();

    currentLocation = LatLng(
      position.latitude,
      position.longitude,
    );
  }

  // ===========================
  // SEARCH
  // ===========================

  Future<void> searchLocation() async {

    if (searchController.text.isEmpty) return;

    final response = await http.get(

      Uri.parse(
        "$baseUrl/search?q=${searchController.text}",
      ),
    );

    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);

    if (data["lat"] == 0) return;

    final LatLng destination = LatLng(

      data["lat"],

      data["lon"],
    );

    mapController.move(destination, 15);

    setState(() {
      currentLocation = destination;
    });

    await loadMarkers();
  }

  // ===========================
  // LOAD MARKERS
  // (Implemented in Part 3)
  // ===========================

  Future<void> loadMarkers() async {
        setState(() {
        loading = true;
        nearbyData.clear();
        selectedItem = null;
      });
      markers.clear();

  try {
    late String url;

    if (selectedType == "issues") {
      url =
          "$baseUrl/issues/nearby?lat=${currentLocation.latitude}"
          "&lng=${currentLocation.longitude}"
          "&radius_km=5";
    } else if (selectedType == "events") {
      url =
          "$baseUrl/events/nearby?lat=${currentLocation.latitude}"
          "&lng=${currentLocation.longitude}"
          "&radius_km=5";
    } else {
      url =
          "$baseUrl/nearby?type=$selectedType"
          "&lat=${currentLocation.latitude}"
          "&lon=${currentLocation.longitude}";
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      nearbyData = jsonDecode(response.body);

for (final item in nearbyData) {
  final latValue = item["lat"] ?? item["latitude"];
  final lonValue = item["lon"] ?? item["longitude"];

  if (latValue == null || lonValue == null) continue;

  final double lat = double.tryParse(latValue.toString()) ?? 0;
  final double lon = double.tryParse(lonValue.toString()) ?? 0;

  if (lat == 0 || lon == 0) continue;  markers.add(
          Marker(
            point: LatLng(lat, lon),

            width: 60,
            height: 60,

            child: GestureDetector(
             onTap: () {
                mapController.move(LatLng(lat, lon), 16);

                setState(() {
                  selectedItem = item;
                });
              },

              child: _buildMarkerIcon(item),
            ),
          ),
        );
        
      }
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  setState(() {
    loading = false;
  });
  setState(() {
  markers = List.from(markers);
});
}
Widget _buildMarkerIcon(dynamic item) {

  String type = selectedType;

  Color color;
  IconData icon;

  switch (type) {

    case "hospital":
      color = Colors.red;
      icon = Icons.local_hospital;
      break;

    case "police":
      color = Colors.blue;
      icon = Icons.local_police;
      break;

    case "fire":
      color = Colors.orange;
      icon = Icons.local_fire_department;
      break;

    case "water":
      color = Colors.lightBlue;
      icon = Icons.water_drop;
      break;

    case "waste":
      color = Colors.brown;
      icon = Icons.delete;
      break;

    case "issues":
      color = Colors.deepPurple;
      icon = Icons.report;
      break;

    default:
      color = Colors.green;
      icon = Icons.location_on;
  }

  return Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 10,
        )
      ],
    ),
    child: Icon(
      icon,
      color: Colors.white,
      size: 26,
    ),
  );
}
Widget statItem(
    IconData icon,
    String value,
    String title,
    Color color,
    ) {

  return Column(
    children: [

      Icon(icon, color: color),

      const SizedBox(height: 6),

      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
        ),
      )
    ],
  );
}
Widget buildMarkerIcon() {

  Color color;

  IconData icon;

  switch (selectedType) {

    case "hospital":
      color = Colors.red;
      icon = Icons.local_hospital;
      break;

    case "police":
      color = Colors.blue;
      icon = Icons.local_police;
      break;

    case "fire":
      color = Colors.orange;
      icon = Icons.local_fire_department;
      break;

    case "water":
      color = Colors.lightBlue;
      icon = Icons.water_drop;
      break;

    case "waste":
      color = Colors.brown;
      icon = Icons.delete;
      break;

    case "issues":
      color = Colors.deepPurple;
      icon = Icons.report;
      break;

    default:
      color = Colors.green;
      icon = Icons.event;
  }

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: .7, end: 1),
    duration: const Duration(milliseconds: 300),

    builder: (_, scale, child) {

      return Transform.scale(
        scale: scale,
        child: child,
      );
    },

    child: Container(

      decoration: BoxDecoration(

        color: color,

        shape: BoxShape.circle,

        boxShadow: [

          BoxShadow(

            color: color.withOpacity(.45),

            blurRadius: 14,
          )
        ],
      ),

      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    ),
  );
}

  // ===========================
  // Build
  // (Part 2)
  // ===========================

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xffF6F7FB),

    body: Stack(
      children: [

        // ==========================
        // MAP
        // ==========================

        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentLocation,
            initialZoom: 14,
          ),

          children: [

            TileLayer(
              urlTemplate:
                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "com.example.frontend",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLocation,
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.my_location,
                    size: 34,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 45,
                size: const Size(40, 40),
                markers: markers,

                builder: (context, clusterMarkers) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xff7B61FF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        clusterMarkers.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // ==========================
        // SEARCH BAR
        // ==========================

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(30),

                  child: TextField(
                    controller: searchController,

                    onSubmitted: (_) {
                      searchLocation();
                    },

                    decoration: InputDecoration(

                      hintText: "Search place...",

                      prefixIcon:
                          const Icon(Icons.search),

                      suffixIcon: IconButton(

                        icon: const Icon(
                            Icons.arrow_forward),

                        onPressed: searchLocation,
                      ),

                      filled: true,

                      fillColor: Colors.white,

                      border: OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(30),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ======================
                // FILTER CHIPS
                // ======================

                SizedBox(
                  height: 45,

                  child: ListView.builder(

                    scrollDirection: Axis.horizontal,

                    itemCount: filters.length,

                    itemBuilder: (context, index) {

                      final item = filters[index];

                      final bool selected =
                          item["type"] == selectedType;

                      return Padding(
                        padding:
                            const EdgeInsets.only(right: 10),

                        child: GestureDetector(

                          onTap: () async {

                            setState(() {
                              selectedType =
                                  item["type"];
                            });

                            await loadMarkers();

                            mapController.move(
                              currentLocation,
                              15,
                            );
                          },

                          child: AnimatedContainer(

                            duration:
                                const Duration(milliseconds: 250),

                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 18,
                            ),

                            decoration: BoxDecoration(

                              color: selected
                                  ? const Color(0xff7B61FF)
                                  : Colors.white,

                              borderRadius:
                                  BorderRadius.circular(25),

                              boxShadow: [

                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(.06),

                                  blurRadius: 8,
                                )
                              ],
                            ),

                            child: Row(

                              children: [

                                Icon(
                                  item["icon"],

                                  size: 20,

                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
                                ),

                                const SizedBox(width: 8),

                                Text(

                                  item["title"],

                                  style: TextStyle(

                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,

                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // ==========================
        // MY LOCATION BUTTON
        // ==========================

        Positioned(
          right: 18,
          bottom: 170,

          child: FloatingActionButton(

            heroTag: "location",

            backgroundColor: Colors.white,

            onPressed: () async {

              await getCurrentLocation();

              mapController.move(
                currentLocation,
                15,
              );

              await loadMarkers();
            },

            child: const Icon(
              Icons.my_location,
              color: Color(0xff7B61FF),
            ),
          ),
        ),

        // ==========================
        // DETAILS CARD
        // ==========================

        if (selectedItem != null)

          Positioned(

            left: 15,
            right: 15,
            bottom: 20,

            child: Material(

              elevation: 10,

              borderRadius:
                  BorderRadius.circular(24),

              child: Container(

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(24),
                ),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                Text(
                  selectedItem["name"] ?? selectedItem["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                    if (selectedItem["location"] != null)

                      Text(
                        selectedItem["location"],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),

                    if (selectedItem["distance_km"] != null)

                      Padding(

                        padding:
                            const EdgeInsets.only(top: 6),

                        child: Text(
                          "${selectedItem["distance_km"]} km away",
                          style: const TextStyle(
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    SizedBox(

                      width: double.infinity,

                      child: ElevatedButton(

                        style: ElevatedButton.styleFrom(

                          backgroundColor:
                              const Color(0xff7B61FF),

                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),

                        onPressed: () {

                          final lat = selectedItem["lat"];
                          final lon = selectedItem["lon"];
                          openDirections(
                            lat.toDouble(),
                            lon.toDouble(),
                          );
                        },

                        child: const Text("Navigate"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
  top: 190,
  left: 16,
  right: 16,
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.95),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          blurRadius: 12,
          color: Colors.black.withOpacity(.08),
        )
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [

        statItem(
          Icons.place,
          markers.length.toString(),
          "Places",
          Colors.deepPurple,
        ),

        statItem(
          Icons.location_on,
          "${currentLocation.latitude.toStringAsFixed(3)}",
          "Latitude",
          Colors.blue,
        ),

        statItem(
          Icons.explore,
          selectedType.toUpperCase(),
          "Filter",
          Colors.green,
        ),
      ],
    ),
  ),
),
        // ==========================
        // LOADING
        // ==========================
        if (!loading && markers.isEmpty && nearbyData.isEmpty)
  Center(
    child: Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
          )
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off,
            size: 60,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            "No nearby locations found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Try another search or select a different category.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ),
        if (loading)

          Container(

            color: Colors.white.withOpacity(.8),

            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          
      ],
      
    ),
  );
}
}