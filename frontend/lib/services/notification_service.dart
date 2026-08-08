import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class NotificationService {
  static void showCivicAlert(BuildContext context, {required String title, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(message, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
