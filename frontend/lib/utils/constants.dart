import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppConfig {
  // Primary backend URL (Render deployment or local server)
  // For local development on Android emulator use 'http://10.0.2.2:8000'
  // For iOS emulator or desktop use 'http://127.0.0.1:8000'
  static const String baseUrl = "https://my-backend-4hfj.onrender.com";

  // =========================================================
  // GOOGLE GEMINI API KEY CONFIGURATION
  // Paste your Google Gemini API Key below (e.g. "AIzaSy...")
  // =========================================================
  static const String geminiApiKey = "";

  // Default Map Coordinates (Coimbatore City Center)
  static const double defaultLatitude = 11.0168;
  static const double defaultLongitude = 76.9558;
  static const String defaultCity = "Coimbatore";
}

class AppCategories {
  static const List<String> list = [
    "All",
    "Road",
    "Water",
    "Garbage",
    "Electricity",
    "Health",
    "Safety",
    "Others",
  ];

  static Color getColor(String category) {
    switch (category.toLowerCase()) {
      case "road":
        return AppColors.road;
      case "water":
        return AppColors.water;
      case "garbage":
        return AppColors.garbage;
      case "electricity":
        return AppColors.electricity;
      case "health":
        return AppColors.health;
      case "safety":
        return AppColors.safety;
      default:
        return AppColors.primary;
    }
  }

  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case "road":
        return Icons.directions_car_rounded;
      case "water":
        return Icons.water_drop_rounded;
      case "garbage":
        return Icons.delete_outline_rounded;
      case "electricity":
        return Icons.bolt_rounded;
      case "health":
        return Icons.local_hospital_rounded;
      case "safety":
        return Icons.shield_outlined;
      default:
        return Icons.report_problem_rounded;
    }
  }
}

class AppPriorities {
  static const String critical = "Critical";
  static const String high = "High";
  static const String medium = "Medium";
  static const String low = "Low";

  static Color getColor(String priority) {
    switch (priority.toLowerCase()) {
      case "critical":
        return AppColors.alert;
      case "high":
        return AppColors.road;
      case "medium":
        return AppColors.warning;
      case "low":
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

class AppStatus {
  static const String open = "Open";
  static const String inProgress = "In Progress";
  static const String resolved = "Resolved";

  static Color getColor(String status) {
    switch (status.toLowerCase()) {
      case "resolved":
        return AppColors.success;
      case "in progress":
        return AppColors.warning;
      case "open":
      default:
        return AppColors.alert;
    }
  }
}
