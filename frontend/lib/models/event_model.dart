import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_colors.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final String category;
  final String locationName;
  final double latitude;
  final double longitude;
  final String startTime;
  final int attendeesCount;
  final bool isAttending;
  final double distanceKm;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    this.attendeesCount = 12,
    this.isAttending = false,
    this.distanceKm = 0.0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json["id"] is int ? json["id"] : int.tryParse(json["id"].toString()) ?? 0,
      title: json["title"] ?? "Community Event",
      description: json["description"] ?? "",
      category: json["category"] ?? "Community",
      locationName: json["location_name"] ?? AppConfig.defaultCity,
      latitude: (json["latitude"] as num?)?.toDouble() ?? AppConfig.defaultLatitude,
      longitude: (json["longitude"] as num?)?.toDouble() ?? AppConfig.defaultLongitude,
      startTime: json["start_time"] ?? "Upcoming",
      attendeesCount: json["attendees_count"] is int 
          ? json["attendees_count"] 
          : int.tryParse(json["attendees_count"]?.toString() ?? "12") ?? 12,
      isAttending: json["is_attending"] == true,
      distanceKm: (json["distance_km"] as num?)?.toDouble() ?? 0.0,
    );
  }

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case "health":
        return AppColors.health;
      case "environment":
        return AppColors.garbage;
      case "education":
        return AppColors.info;
      case "safety":
        return AppColors.safety;
      case "business":
        return AppColors.electricity;
      default:
        return AppColors.primary;
    }
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case "health":
        return Icons.medical_services_outlined;
      case "environment":
        return Icons.eco_outlined;
      case "education":
        return Icons.school_outlined;
      case "safety":
        return Icons.security_outlined;
      case "business":
        return Icons.business_center_outlined;
      default:
        return Icons.groups_outlined;
    }
  }
}