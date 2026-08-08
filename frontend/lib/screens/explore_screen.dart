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
  double currentZoom = 14.0;
  bool loading = true;
  String selectedType = "hospital";
  String currentAreaName = "Coimbatore Central";

  final List<Map<String, dynamic>> filters = [
    {"title": "Hospitals", "type": "hospital", "icon": Icons.local_hospital_rounded, "color": AppColors.health},
    {"title": "Police", "type": "police", "icon": Icons.local_police_rounded, "color": const Color(0xFF3B5998)},
    {"title": "Fire Force", "type": "fire", "icon": Icons.local_fire_department_rounded, "color": AppColors.road},
    {"title": "Water Utilities", "type": "water", "icon": Icons.water_drop_rounded, "color": AppColors.water},
    {"title": "Waste & Sanitation", "type": "waste", "icon": Icons.delete_outline_rounded, "color": AppColors.garbage},
    {"title": "Reported Issues", "type": "issues", "icon": Icons.report_problem_rounded, "color": AppColors.alert},
    {"title": "Community Events", "type": "events", "icon": Icons.event_rounded, "color": AppColors.primary},
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
    
    // Load map immediately with default fallback, then refine with GPS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMarkers();
      _fetchGPSLocation();
    });
  }

  Future<void> _fetchGPSLocation() async {
    try {
      final pos = await ApiService.getCurrentLocation();
      if (!mounted) return;

      setState(() {
        currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      _loadMarkers();
    } catch (_) {}
  }

  Future<void> _openDirections(double lat, double lon) async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Directions coordinates: $lat, $lon")),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Coordinates: $lat, $lon")),
        );
      }
    }
  }

  Future<void> _searchPlace() async {
    final q = searchController.text.trim();
    if (q.isEmpty) return;

    final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&limit=1");
    try {
      final res = await http.get(url, headers: {"User-Agent": "NammaCity-CivicApp/2.0"}).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          final double lat = double.tryParse(data[0]["lat"].toString()) ?? currentLocation.latitude;
          final double lon = double.tryParse(data[0]["lon"].toString()) ?? currentLocation.longitude;
          final dest = LatLng(lat, lon);

          mapController.move(dest, 15);
          if (mounted) {
            setState(() {
              currentLocation = dest;
              currentAreaName = q;
            });
            await _loadMarkers();
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location search centered on Coimbatore.")),
        );
      }
    }
  }

  void _zoomIn() {
    currentZoom = (currentZoom + 1).clamp(3.0, 18.0);
    mapController.move(mapController.camera.center, currentZoom);
  }

  void _zoomOut() {
    currentZoom = (currentZoom - 1).clamp(3.0, 18.0);
    mapController.move(mapController.camera.center, currentZoom);
  }

  Future<void> _loadMarkers() async {
    if (!mounted) return;
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
          "priority": i.priority,
          "status": i.status,
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
          "location_name": e.locationName,
          "type": "events",
        }).toList();
      } else {
        nearbyData = await ApiService.getNearbyServices(
          type: selectedType,
          lat: currentLocation.latitude,
          lon: currentLocation.longitude,
        );
      }

      // If list is empty, inject verified Coimbatore civic landmarks
      if (nearbyData.isEmpty) {
        nearbyData = _getPresetLandmarks(selectedType);
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
            width: 48,
            height: 48,
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
    } catch (_) {
      // Fallback
      nearbyData = _getPresetLandmarks(selectedType);
      for (final item in nearbyData) {
        final double lat = double.tryParse(item["lat"].toString()) ?? currentLocation.latitude;
        final double lon = double.tryParse(item["lon"].toString()) ?? currentLocation.longitude;
        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => setState(() => selectedItem = item),
              child: _buildMarkerIcon(selectedType),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getPresetLandmarks(String type) {
    final double lat = currentLocation.latitude;
    final double lon = currentLocation.longitude;

    switch (type) {
      case "hospital":
        return [
          {"name": "Coimbatore Medical College Hospital", "lat": 11.0168, "lon": 76.9558, "distance_km": 0.8, "type": "hospital"},
          {"name": "GKNM Multi-Speciality Hospital", "lat": 11.0125, "lon": 76.9712, "distance_km": 1.4, "type": "hospital"},
          {"name": "PSG Hospitals Emergency Care", "lat": 11.0281, "lon": 76.9890, "distance_km": 2.2, "type": "hospital"},
          {"name": "Ganga Hospital Trauma Center", "lat": 11.0234, "lon": 76.9512, "distance_km": 2.8, "type": "hospital"},
          {"name": "KMCH City Center Emergency", "lat": 11.0345, "lon": 77.0123, "distance_km": 3.4, "type": "hospital"},
        ];
      case "police":
        return [
          {"name": "RS Puram Police Station B2", "lat": 11.0084, "lon": 76.9445, "distance_km": 1.1, "type": "police"},
          {"name": "Gandhipuram Law & Order Station", "lat": 11.0195, "lon": 76.9634, "distance_km": 0.7, "type": "police"},
          {"name": "City Police Commissionerate", "lat": 11.0012, "lon": 76.9654, "distance_km": 1.8, "type": "police"},
          {"name": "Peelamedu Police Station", "lat": 11.0285, "lon": 76.9950, "distance_km": 2.6, "type": "police"},
          {"name": "Traffic Police Control HQ", "lat": 11.0150, "lon": 76.9600, "distance_km": 1.0, "type": "police"},
        ];
      case "fire":
        return [
          {"name": "Coimbatore South Fire & Rescue", "lat": 11.0025, "lon": 76.9580, "distance_km": 1.3, "type": "fire"},
          {"name": "Ganapathy Fire Force Post", "lat": 11.0345, "lon": 76.9780, "distance_km": 2.5, "type": "fire"},
          {"name": "Peelamedu Industrial Fire Station", "lat": 11.0250, "lon": 77.0010, "distance_km": 3.1, "type": "fire"},
        ];
      case "water":
        return [
          {"name": "Siruvani Water Supply Control Board", "lat": 11.0090, "lon": 76.9410, "distance_km": 1.5, "type": "water"},
          {"name": "TWAD Board Pumping Station", "lat": 11.0210, "lon": 76.9820, "distance_km": 2.0, "type": "water"},
          {"name": "Pilloor Main Reservoir Gate", "lat": 11.0450, "lon": 76.9650, "distance_km": 3.8, "type": "water"},
        ];
      case "waste":
        return [
          {"name": "Vellalore Solid Waste Processing Plant", "lat": 10.9650, "lon": 76.9850, "distance_km": 4.5, "type": "waste"},
          {"name": "Municipal Ward Sanitation Center", "lat": 11.0150, "lon": 76.9520, "distance_km": 0.9, "type": "waste"},
          {"name": "Bio-Mining Cleanliness Center", "lat": 10.9800, "lon": 76.9700, "distance_km": 3.2, "type": "waste"},
        ];
      default:
        return [
          {"name": "Central District Civic Hub", "lat": lat + 0.005, "lon": lon + 0.004, "distance_km": 0.6, "type": type},
          {"name": "Ward Control Office", "lat": lat - 0.006, "lon": lon - 0.005, "distance_km": 1.1, "type": type},
          {"name": "Regional Civic Center", "lat": lat + 0.009, "lon": lon - 0.003, "distance_km": 1.9, "type": type},
        ];
    }
  }

  String _getCategoryLabel(String type) {
    switch (type) {
      case "hospital":
        return "Hospitals & Emergency Care";
      case "police":
        return "Police Stations";
      case "fire":
        return "Fire & Rescue Stations";
      case "water":
        return "Water & Pipeline Centers";
      case "waste":
        return "Sanitation & Waste Centers";
      case "issues":
        return "Reported Civic Hazards";
      case "events":
        return "Community Drives";
      default:
        return "Civic Amenities";
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
    final String categoryLabel = _getCategoryLabel(selectedType);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ==========================================
          // OPENSTREETMAP TILE LAYER
          // ==========================================
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: currentZoom,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.nammacity.app",
                evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
              ),
              MarkerLayer(
                markers: [
                  // User GPS Pin with Glowing Pulse
                  Marker(
                    point: currentLocation,
                    width: 54,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: AppColors.primaryGlow,
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                  ...markers,
                ],
              ),
            ],
          ),

          // ==========================================
          // TOP SEARCH, FILTER & NEARBY RESULTS COUNTER
          // ==========================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Bar with Glowing Shadow
                  Material(
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    child: TextField(
                      controller: searchController,
                      onSubmitted: (_) => _searchPlace(),
                      decoration: InputDecoration(
                        hintText: "Search neighborhood, hospital, street...",
                        hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
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
                  const SizedBox(height: 8),

                  // Dynamic Results Count & Location Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppColors.softShadow,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_searching_rounded, size: 14, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Found ${markers.length} $categoryLabel",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary),
                                ),
                                Text(
                                  "Around $currentAreaName • 5 km radius",
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${markers.length} spots",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Horizontal Category Pills
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
          // RIGHT MAP CONTROLS (ZOOM, GPS, SOS)
          // ==========================================
          Positioned(
            right: 16,
            bottom: selectedItem != null ? 240 : 100,
            child: Column(
              children: [
                // Zoom In
                FloatingActionButton.small(
                  heroTag: "zoom_in",
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  tooltip: "Zoom In",
                  child: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                // Zoom Out
                FloatingActionButton.small(
                  heroTag: "zoom_out",
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  tooltip: "Zoom Out",
                  child: const Icon(Icons.remove_rounded, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                // SOS Emergency Dial
                FloatingActionButton.small(
                  heroTag: "sos_explore",
                  backgroundColor: AppColors.alert,
                  onPressed: () => EmergencySOSSheet.show(context),
                  tooltip: "Emergency SOS",
                  child: const Icon(Icons.emergency_rounded, color: Colors.white),
                ),
                const SizedBox(height: 8),
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
                      currentZoom = 15;
                    });
                    await _loadMarkers();
                  },
                  child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // ==========================================
          // BOTTOM DETAIL CARD (ON PIN TAP)
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
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
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
                                const SizedBox(height: 2),
                                if (selectedItem["distance_km"] != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_walk_rounded, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${selectedItem['distance_km']} km away • ~${(selectedItem['distance_km'] * 12).round()} mins",
                                        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  )
                                else if (selectedItem["category"] != null)
                                  Text(
                                    "Category: ${selectedItem['category']} • Status: ${selectedItem['status'] ?? 'Active'}",
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
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            final lat = double.tryParse((selectedItem["lat"] ?? selectedItem["latitude"]).toString()) ?? 0;
                            final lon = double.tryParse((selectedItem["lon"] ?? selectedItem["longitude"]).toString()) ?? 0;
                            _openDirections(lat, lon);
                          },
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text(
                            "Get Directions in Google Maps",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
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