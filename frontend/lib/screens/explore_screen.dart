import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/emergency_sos_sheet.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialType;

  const ExploreScreen({super.key, this.initialType});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  LatLng currentLocation = const LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude);
  bool loading = true;
  String selectedType = "hospital";

  final List<Map<String, dynamic>> filters = [
    {"title": "Hospital", "type": "hospital", "icon": Icons.local_hospital_rounded, "color": AppColors.health},
    {"title": "Police", "type": "police", "icon": Icons.local_police_rounded, "color": const Color(0xFF3B5998)},
    {"title": "Fire", "type": "fire", "icon": Icons.local_fire_department_rounded, "color": AppColors.road},
    {"title": "Water", "type": "water", "icon": Icons.water_drop_rounded, "color": AppColors.water},
    {"title": "Waste", "type": "waste", "icon": Icons.delete_outline_rounded, "color": AppColors.garbage},
    {"title": "Issues", "type": "issues", "icon": Icons.report_problem_rounded, "color": AppColors.alert},
    {"title": "Events", "type": "events", "icon": Icons.event_rounded, "color": AppColors.primary},
  ];

  List<Marker> markers = [];
  List<dynamic> nearbyData = [];
  dynamic selectedItem;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      selectedType = widget.initialType!;
    }
    _initialize();
  }

  Future<void> _initialize() async {
    final pos = await ApiService.getCurrentLocation();
    if (mounted) {
      setState(() {
        currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      await _loadMarkers();
    }
  }

  Future<void> _openDirections(double lat, double lon) async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _searchPlace() async {
    final q = searchController.text.trim();
    if (q.isEmpty) return;

    final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1");
    try {
      final res = await http.get(url, headers: {"User-Agent": "LocalPulse/2.0"}).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          final dest = LatLng(double.parse(data[0]["lat"]), double.parse(data[0]["lon"]));
          mapController.move(dest, 15);
          setState(() {
            currentLocation = dest;
          });
          await _loadMarkers();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMarkers() async {
    setState(() {
      loading = true;
      nearbyData.clear();
      selectedItem = null;
      markers.clear();
    });

    try {
      if (selectedType == "issues") {
        final issues = await ApiService.getIssues();
        nearbyData = issues.map((i) => {
          "id": i.id,
          "title": i.title,
          "description": i.description,
          "lat": i.latitude,
          "lon": i.longitude,
          "category": i.category,
          "type": "issues",
        }).toList();
      } else if (selectedType == "events") {
        final events = await ApiService.getNearbyEvents();
        nearbyData = events.map((e) => {
          "id": e.id,
          "title": e.title,
          "description": e.description,
          "lat": e.latitude,
          "lon": e.longitude,
          "category": e.category,
          "type": "events",
        }).toList();
      } else {
        nearbyData = await ApiService.getNearbyServices(
          type: selectedType,
          lat: currentLocation.latitude,
          lon: currentLocation.longitude,
        );
      }

      for (final item in nearbyData) {
        final latVal = item["lat"] ?? item["latitude"];
        final lonVal = item["lon"] ?? item["longitude"];
        if (latVal == null || lonVal == null) continue;

        final double lat = double.tryParse(latVal.toString()) ?? 0;
        final double lon = double.tryParse(lonVal.toString()) ?? 0;
        if (lat == 0 || lon == 0) continue;

        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                mapController.move(LatLng(lat, lon), 15);
                setState(() {
                  selectedItem = item;
                });
              },
              child: _buildMarkerIcon(selectedType),
            ),
          ),
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Widget _buildMarkerIcon(String type) {
    Color color;
    IconData icon;

    switch (type) {
      case "hospital":
        color = AppColors.health;
        icon = Icons.local_hospital_rounded;
        break;
      case "police":
        color = const Color(0xFF3B5998);
        icon = Icons.local_police_rounded;
        break;
      case "fire":
        color = AppColors.road;
        icon = Icons.local_fire_department_rounded;
        break;
      case "water":
        color = AppColors.water;
        icon = Icons.water_drop_rounded;
        break;
      case "waste":
        color = AppColors.garbage;
        icon = Icons.delete_outline_rounded;
        break;
      case "issues":
        color = AppColors.alert;
        icon = Icons.report_problem_rounded;
        break;
      default:
        color = AppColors.primary;
        icon = Icons.event_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ==========================================
          // FLUTTER MAP
          // ==========================================
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.localpulse.app",
              ),
              MarkerLayer(
                markers: [
                  // User Location Pin
                  Marker(
                    point: currentLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: AppColors.primaryGlow,
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  ...markers,
                ],
              ),
            ],
          ),

          // ==========================================
          // TOP SEARCH & FILTER OVERLAY
          // ==========================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(30),
                    child: TextField(
                      controller: searchController,
                      onSubmitted: (_) => _searchPlace(),
                      decoration: InputDecoration(
                        hintText: "Search neighborhood, hospital, street...",
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: _searchPlace,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = filters[index];
                        final isSelected = item["type"] == selectedType;

                        return GestureDetector(
                          onTap: () async {
                            setState(() {
                              selectedType = item["type"];
                            });
                            await _loadMarkers();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item["icon"],
                                  size: 16,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item["title"],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
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

          // ==========================================
          // RIGHT FLOATING ACTION BUTTONS (SOS & GPS)
          // ==========================================
          Positioned(
            right: 16,
            bottom: selectedItem != null ? 220 : 100,
            child: Column(
              children: [
                // SOS Helpline Dial
                FloatingActionButton.small(
                  heroTag: "sos_explore",
                  backgroundColor: AppColors.alert,
                  onPressed: () => EmergencySOSSheet.show(context),
                  tooltip: "Emergency SOS",
                  child: const Icon(Icons.emergency_rounded, color: Colors.white),
                ),
                const SizedBox(height: 10),
                // Recenter GPS
                FloatingActionButton(
                  heroTag: "gps_recenter",
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    final pos = await ApiService.getCurrentLocation();
                    final dest = LatLng(pos.latitude, pos.longitude);
                    mapController.move(dest, 15);
                    setState(() {
                      currentLocation = dest;
                    });
                    await _loadMarkers();
                  },
                  child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // ==========================================
          // BOTTOM DETAIL PREVIEW CARD
          // ==========================================
          if (selectedItem != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 95,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildMarkerIcon(selectedType),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedItem["name"] ?? selectedItem["title"] ?? "Selected Location",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (selectedItem["distance_km"] != null)
                                  Text(
                                    "${selectedItem['distance_km']} km away",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => selectedItem = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            final lat = double.tryParse((selectedItem["lat"] ?? selectedItem["latitude"]).toString()) ?? 0;
                            final lon = double.tryParse((selectedItem["lon"] ?? selectedItem["longitude"]).toString()) ?? 0;
                            _openDirections(lat, lon);
                          },
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text("Get Turn-by-Turn Directions in Google Maps", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}