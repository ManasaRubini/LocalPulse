import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../utils/app_colors.dart';

class NearbyEventsStrip extends StatelessWidget {
  final List<Event> events;
  final Function(Event event)? onEventTap;

  const NearbyEventsStrip({
    super.key,
    required this.events,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Upcoming Neighborhood Drives",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final e = events[index];
              return InkWell(
                onTap: () => onEventTap?.call(e),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(e.categoryIcon, size: 16, color: e.categoryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        e.locationName,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(e.startTime, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
