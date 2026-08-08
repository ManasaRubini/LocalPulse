import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final String currentUser;

  const EventCard({
    super.key,
    required this.event,
    this.currentUser = "Citizen",
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late bool isAttending;
  late int attendeesCount;

  @override
  void initState() {
    super.initState();
    isAttending = widget.event.isAttending;
    attendeesCount = widget.event.attendeesCount;
  }

  Future<void> _handleRSVP() async {
    setState(() {
      if (isAttending) {
        isAttending = false;
        attendeesCount = (attendeesCount - 1).clamp(0, 9999);
      } else {
        isAttending = true;
        attendeesCount += 1;
      }
    });

    await ApiService.toggleEventRSVP(widget.event.id, widget.currentUser);
  }

  Future<void> _openDirections() async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${widget.event.latitude},${widget.event.longitude}",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Pill & Location Distance
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(event.categoryIcon, color: event.categoryColor, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        event.category,
                        style: TextStyle(
                          color: event.categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      "$attendeesCount Attending",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Title & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              event.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              event.description,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),

          // Event Timing & Venue Row
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.startTime,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.road),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.locationName,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: RSVP & Directions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primaryLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _openDirections,
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: const Text("Directions", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAttending ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _handleRSVP,
                    icon: Icon(isAttending ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 18),
                    label: Text(
                      isAttending ? "Going" : "RSVP",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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