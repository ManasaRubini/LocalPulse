import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'location_picker_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  
  String selectedCategory = "Road";
  String selectedPriority = "Medium";
  bool anonymous = false;
  bool isSubmitting = false;

  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  double latitude = AppConfig.defaultLatitude;
  double longitude = AppConfig.defaultLongitude;
  String currentAddress = "Fetching GPS location...";
  bool loadingLocation = true;
  String? currentUsername;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadLocation();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUsername = prefs.getString("username") ?? "Citizen";
    });
  }

  Future<void> _loadLocation() async {
    try {
      final pos = await ApiService.getCurrentLocation();
      latitude = pos.latitude;
      longitude = pos.longitude;

      final places = await placemarkFromCoordinates(latitude, longitude);
      if (places.isNotEmpty) {
        final place = places.first;
        currentAddress = "${place.street ?? ''}, ${place.locality ?? AppConfig.defaultCity}, ${place.administrativeArea ?? ''}";
      }
    } catch (_) {
      currentAddress = "Gandhipuram, Coimbatore";
    }

    if (mounted) {
      setState(() {
        loadingLocation = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _changeLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: latitude,
          initialLongitude: longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        latitude = result["latitude"];
        longitude = result["longitude"];
        currentAddress = result["address"] ?? currentAddress;
      });
    }
  }

  Future<void> _submitReport() async {
    if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please provide both an issue title and description"),
          backgroundColor: AppColors.alert,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final success = await ApiService.createIssue(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      category: selectedCategory,
      location: currentAddress,
      latitude: latitude,
      longitude: longitude,
      anonymous: anonymous,
      userName: anonymous ? "Anonymous" : (currentUsername ?? "Citizen"),
      priority: selectedPriority,
      imageFile: selectedImage,
    );

    if (!mounted) return;
    setState(() {
      isSubmitting = false;
    });

    if (success) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text("Report Submitted"),
            ],
          ),
          content: const Text("Your civic issue has been broadcasted to local authorities and the neighborhood feed."),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                titleController.clear();
                descriptionController.clear();
                setState(() {
                  selectedImage = null;
                });
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
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
          "Report Civic Issue",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ==========================================
          // TITLE & DETAILS CARD
          // ==========================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Issue Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: "e.g. Broken water pipe / Pothole near junction",
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.report_problem_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Describe the hazard, affected landmarks, and severity...",
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // CATEGORY & PRIORITY SELECTOR
          // ==========================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Civic Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppCategories.list.where((c) => c != "All").map((cat) {
                    final isSelected = cat == selectedCategory;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppCategories.getIcon(cat), size: 16, color: isSelected ? Colors.white : AppColors.textPrimary),
                          const SizedBox(width: 6),
                          Text(cat),
                        ],
                      ),
                      selectedColor: AppCategories.getColor(cat),
                      backgroundColor: AppColors.background,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                      onSelected: (_) => setState(() => selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text("Urgency & Priority", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  children: [AppPriorities.critical, AppPriorities.high, AppPriorities.medium, AppPriorities.low].map((p) {
                    final isSelected = p == selectedPriority;
                    final color = AppPriorities.getColor(p);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => setState(() => selectedPriority = p),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? color : AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // PHOTO UPLOAD
          // ==========================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Attach Photo Proof", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primaryLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text("Gallery", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text("Camera", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: 14),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          selectedImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => selectedImage = null),
                        icon: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 14,
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // LOCATION PINPOINT
          // ==========================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Incident Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.alertLight, shape: BoxShape.circle),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.alert, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loadingLocation ? "Detecting GPS location..." : currentAddress,
                        style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primaryLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _changeLocation,
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                    label: const Text("Adjust Pin on Map", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // ANONYMOUS PRIVACY TOGGLE
          // ==========================================
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.softShadow,
            ),
            child: SwitchListTile(
              activeTrackColor: AppColors.primary,
              value: anonymous,
              onChanged: (val) => setState(() => anonymous = val),
              title: const Text("Post Anonymously", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Hide your username from public view", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 24),

          // ==========================================
          // SUBMIT BUTTON
          // ==========================================
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: isSubmitting ? null : _submitReport,
              icon: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(
                isSubmitting ? "Submitting..." : "Submit Civic Report",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
