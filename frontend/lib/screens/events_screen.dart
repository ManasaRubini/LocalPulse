import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../widgets/event_card.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<Event>> eventsFuture;
  String selectedCategory = "All";
  String? currentUsername;

  final List<String> eventCategories = ["All", "Health", "Environment", "Safety", "Education", "Community"];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchEvents();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUsername = prefs.getString("username") ?? "Citizen";
    });
  }

  void _fetchEvents() {
    setState(() {
      eventsFuture = ApiService.getNearbyEvents(user: currentUsername);
    });
  }

  Future<void> _showCreateEventDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final timeController = TextEditingController(text: "2026-08-25 09:00 AM");
    String category = "Community";

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.event_available_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text("Host Community Drive", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(titleController, "Event Title", "e.g. Neighborhood Cleanliness Walk"),
                  const SizedBox(height: 10),
                  _dialogField(descriptionController, "Description", "Explain the cause and requirements", maxLines: 3),
                  const SizedBox(height: 10),
                  _dialogField(locationController, "Venue / Landmark", "e.g. VOC Park Grounds"),
                  const SizedBox(height: 10),
                  _dialogField(timeController, "Date & Time", "e.g. 2026-08-25 09:00 AM"),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: "Category",
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: eventCategories.where((c) => c != "All").map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => category = val ?? "Community"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;
                  await ApiService.createEvent(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    category: category,
                    locationName: locationController.text.trim().isNotEmpty ? locationController.text.trim() : AppConfig.defaultCity,
                    latitude: AppConfig.defaultLatitude,
                    longitude: AppConfig.defaultLongitude,
                    startTime: timeController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _fetchEvents();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Event published to neighborhood calendar!"), backgroundColor: AppColors.success),
                    );
                  }
                },
                child: const Text("Publish"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
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
          "Civic Events & Drives",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            onPressed: _fetchEvents,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          onPressed: _showCreateEventDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text("Host Drive", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchEvents(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const SizedBox(height: 12),
            // Category Filter Chips
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: eventCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = eventCategories[index];
                  final isSelected = cat == selectedCategory;

                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(cat),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    onSelected: (_) => setState(() => selectedCategory = cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Events List
            FutureBuilder<List<Event>>(
              future: eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }

                List<Event> events = snapshot.data ?? [];
                if (selectedCategory != "All") {
                  events = events.where((e) => e.category.toLowerCase() == selectedCategory.toLowerCase()).toList();
                }

                if (events.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(30),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 52, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text("No Upcoming Events in this Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text("Be the first to host a tree plantation or blood donation camp!", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return EventCard(
                      event: events[index],
                      currentUser: currentUsername ?? "Citizen",
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}