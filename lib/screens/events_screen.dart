import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/api_service.dart';
import '../widgets/event_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<Event>> eventsFuture;

@override
void initState() {
  super.initState();
  _loadEvents();
}

void _loadEvents() {
  eventsFuture = ApiService.getNearbyEvents();
}

Future<void> _refresh() async {
  setState(() {
    _loadEvents();
  });
}

  Future<void> _showCreateEventDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final locationController = TextEditingController();
    final startTimeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            "Create Event",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(titleController, "Title"),
                _field(descriptionController, "Description"),
                _field(categoryController, "Category"),
                _field(locationController, "Location"),
                _field(
                  startTimeController,
                  "Start Time",
                  hint: "2026-06-25 10:00",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff7B61FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await ApiService.createEvent(
                    title: titleController.text,
                    description: descriptionController.text,
                    category: categoryController.text,
                    locationName: locationController.text,
                    latitude: 11.1939,
                    longitude: 77.2674,
                    startTime: startTimeController.text,
                  );

                  if (!mounted) return;

                  Navigator.pop(context);
                  _refresh();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Event created successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xffF5F7FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      /// APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Nearby Events",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
      ),

      /// 🔥 FIXED FLOATING ACTION BUTTON (moved above mic assistant)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 85, // 👈 THIS is the key fix
        ),
        child: Container(
          height: 62,
          width: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xff7B61FF),
                Color(0xff9C7CFF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: _showCreateEventDialog,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Event>>(
          future: eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 70, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "No nearby events",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 10),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return EventCard(event: events[index]);
              },
            );
          },
        ),
      ),
    );
  }
}