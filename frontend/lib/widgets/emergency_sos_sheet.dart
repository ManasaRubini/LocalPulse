import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';

class EmergencySOSSheet extends StatelessWidget {
  const EmergencySOSSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EmergencySOSSheet(),
    );
  }

  Future<void> _makeCall(BuildContext context, String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Calling $phone...")),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Emergency Helpline: $phone")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyContacts = [
      {
        "name": "Police Control Room",
        "category": "Immediate Police Response",
        "phone": "100",
        "icon": Icons.local_police_rounded,
        "color": const Color(0xFF3B5998),
      },
      {
        "name": "Ambulance / Emergency Medical",
        "category": "Paramedic & Trauma Transport",
        "phone": "108",
        "icon": Icons.local_hospital_rounded,
        "color": AppColors.alert,
      },
      {
        "name": "Fire & Rescue Force",
        "category": "Fire & Hazard Extraction",
        "phone": "101",
        "icon": Icons.local_fire_department_rounded,
        "color": AppColors.road,
      },
      {
        "name": "Women's Safety Helpline",
        "category": "24/7 Citizen Security",
        "phone": "1091",
        "icon": Icons.security_rounded,
        "color": AppColors.primary,
      },
      {
        "name": "Municipal Corporation Grievance",
        "category": "Civic Works & Water Control",
        "phone": "0422-2302323",
        "icon": Icons.location_city_rounded,
        "color": AppColors.info,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.alert.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded, color: AppColors.alert, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Emergency SOS Helplines",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "One-tap direct dialing for urgent crisis support",
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emergencyContacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = emergencyContacts[index];
              final Color itemColor = item["color"] as Color;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item["icon"] as IconData, color: itemColor, size: 24),
                  ),
                  title: Text(
                    item["name"] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    item["category"] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: itemColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () => _makeCall(context, item["phone"] as String),
                    icon: const Icon(Icons.call, size: 16),
                    label: Text(
                      item["phone"] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
