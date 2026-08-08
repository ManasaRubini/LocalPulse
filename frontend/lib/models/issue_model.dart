import 'package:flutter/material.dart';
import '../utils/constants.dart';

class Issue {
  final int id;
  final String userName;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String location;
  final double latitude;
  final double longitude;
  final bool anonymous;
  final int upvotes;
  final String status;
  final String priority;
  final String resolutionNote;
  final String createdAt;
  final bool hasUpvoted;

  Issue({
    required this.id,
    required this.userName,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.anonymous,
    required this.upvotes,
    required this.status,
    required this.priority,
    required this.resolutionNote,
    required this.createdAt,
    this.hasUpvoted = false,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json["id"] is int ? json["id"] : int.tryParse(json["id"].toString()) ?? 0,
      userName: json["user_name"] ?? "Citizen",
      title: json["title"] ?? "Civic Concern",
      description: json["description"] ?? "",
      imageUrl: json["image_url"] ?? "",
      category: json["category"] ?? "General",
      location: json["location"] ?? AppConfig.defaultCity,
      latitude: (json["latitude"] as num?)?.toDouble() ?? AppConfig.defaultLatitude,
      longitude: (json["longitude"] as num?)?.toDouble() ?? AppConfig.defaultLongitude,
      anonymous: json["anonymous"] == true || json["anonymous"] == 1,
      upvotes: json["upvotes"] is int ? json["upvotes"] : int.tryParse(json["upvotes"].toString()) ?? 0,
      status: json["status"] ?? "Open",
      priority: json["priority"] ?? "Medium",
      resolutionNote: json["resolution_note"] ?? "",
      createdAt: json["created_at"] ?? "",
      hasUpvoted: json["has_upvoted"] == true,
    );
  }

  bool get isResolved => status.toLowerCase() == "resolved";
  bool get isInProgress => status.toLowerCase() == "in progress";
  bool get isOpen => status.toLowerCase() == "open";
  bool get isCritical => priority.toLowerCase() == "critical";

  Color get categoryColor => AppCategories.getColor(category);
  IconData get categoryIcon => AppCategories.getIcon(category);
  Color get priorityColor => AppPriorities.getColor(priority);
  Color get statusColor => AppStatus.getColor(status);

  String get displayName => anonymous ? "Anonymous Citizen" : userName;
}