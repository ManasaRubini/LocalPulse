import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue_model.dart';
import '../services/api_service.dart';
import '../widgets/issue_card.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final bool _isLoading = false;
  String? username;

  Map<String, dynamic> _profile = {
    "username": "Citizen",
    "phone": "+91 98765 43210",
    "address": "Gandhipuram Ward 12, Coimbatore",
    "karma": 65,
    "reports_count": 0,
    "resolved_count": 0,
    "badge": "Active Citizen 🌱"
  };

  List<Issue> _myReports = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString("username");

    if (storedUser == null || storedUser.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final defaultPhones = {
      "manass": "+91 98765 43210",
      "lavanya": "+91 98432 10987",
      "keerthi": "+91 97654 32109"
    };
    final defaultAddresses = {
      "manass": "Gandhipuram Ward 12, Coimbatore",
      "lavanya": "RS Puram West, Coimbatore",
      "keerthi": "Peelamedu Ward 8, Coimbatore"
    };

    final phone = prefs.getString("phone") ?? defaultPhones[storedUser.toLowerCase()] ?? "+91 98765 43210";
    final address = prefs.getString("address") ?? defaultAddresses[storedUser.toLowerCase()] ?? "Gandhipuram Ward 12, Coimbatore";
    final karma = prefs.getInt("karma") ?? 65;

    setState(() {
      username = storedUser;
      _profile = {
        "username": storedUser,
        "phone": phone,
        "address": address,
        "karma": karma,
        "reports_count": 0,
        "resolved_count": 0,
        "badge": karma >= 80 ? "Civic Champion 🏆" : (karma >= 40 ? "Neighborhood Guardian 🛡️" : "Active Citizen 🌱")
      };
    });

    await _loadData();
  }

  Future<void> _loadData() async {
    if (username == null) return;

    try {
      final res = await http
          .get(Uri.parse('${AppConfig.baseUrl}/profile/$username'))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data["username"] != null && data["error"] == null) {
          setState(() {
            _profile = data;
          });

          final prefs = await SharedPreferences.getInstance();
          if (data["phone"] != null) await prefs.setString("phone", data["phone"].toString());
          if (data["address"] != null) await prefs.setString("address", data["address"].toString());
          if (data["karma"] != null) {
            await prefs.setInt("karma", int.tryParse(data["karma"].toString()) ?? 65);
          }
        }
      }
    } catch (_) {}

    try {
      final allIssues = await ApiService.getIssues(user: username);
      setState(() {
        _myReports = allIssues.where((i) => i.userName.trim().toLowerCase() == username!.trim().toLowerCase()).toList();
      });
    } catch (_) {}
  }

  void _showEditProfileSheet() {
    final phoneCtrl = TextEditingController(text: _profile["phone"] ?? "");
    final addressCtrl = TextEditingController(text: _profile["address"] ?? "");
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 26,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text("Edit Citizen Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Contact Phone",
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: "Ward / Neighborhood Address",
                  prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setSheetState(() => isSaving = true);
                          final newPhone = phoneCtrl.text.trim();
                          final newAddress = addressCtrl.text.trim();

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString("phone", newPhone);
                          await prefs.setString("address", newAddress);

                          try {
                            await http.put(
                              Uri.parse('${AppConfig.baseUrl}/profile/$username'),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"phone": newPhone, "address": newAddress}),
                            ).timeout(const Duration(seconds: 4));
                          } catch (_) {}

                          setState(() {
                            _profile["phone"] = newPhone;
                            _profile["address"] = newAddress;
                          });

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✨ Profile details updated successfully!"), backgroundColor: AppColors.success),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final karma = _profile["karma"] ?? 65;
    final String tier = karma >= 80 ? "Civic Champion 🏆" : (karma >= 40 ? "Neighborhood Guardian 🛡️" : "Community Volunteer 🌱");
    final String displayName = _profile["username"] ?? username ?? "Citizen";
    final String displayPhone = (_profile["phone"] != null && _profile["phone"].toString().isNotEmpty) ? _profile["phone"].toString() : "+91 98765 43210";
    final String displayAddress = (_profile["address"] != null && _profile["address"].toString().isNotEmpty) ? _profile["address"].toString() : "Gandhipuram Ward 12, Coimbatore";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Citizen Profile",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            tooltip: "Edit Profile",
            onPressed: _showEditProfileSheet,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.alert),
            tooltip: "Logout",
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text("Log Out"),
                  content: const Text("Are you sure you want to end your session?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.alert, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // ==========================================
                    // PROFILE HEADER CARD WITH VERIFIED DETAILS
                    // ==========================================
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    displayName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        tier,
                                        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 11.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                                  foregroundColor: AppColors.primary,
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                onPressed: _showEditProfileSheet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(height: 1),
                          const SizedBox(height: 14),

                          // Contact Phone Row
                          _infoRow(
                            Icons.phone_android_rounded,
                            "Contact Phone",
                            displayPhone,
                          ),
                          const SizedBox(height: 10),

                          // Ward & Location Row
                          _infoRow(
                            Icons.location_city_rounded,
                            "Ward / Neighborhood",
                            displayAddress,
                          ),
                        ],
                      ),
                    ),

                    // ==========================================
                    // KARMA & STATS OVERVIEW ROW
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _statCard("${_profile['karma'] ?? 65}", "Civic Karma", Icons.stars_rounded, Colors.amber),
                          const SizedBox(width: 10),
                          _statCard("${_myReports.length}", "My Reports", Icons.article_rounded, AppColors.primary),
                          const SizedBox(width: 10),
                          _statCard("${_profile['resolved_count'] ?? 0}", "Resolved", Icons.verified_rounded, AppColors.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ==========================================
                    // TAB BAR: MY REPORTS VS CIVIC IMPACT
                    // ==========================================
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: "My Civic Reports"),
                          Tab(text: "Civic Impact"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ==========================================
                    // TAB CONTENT: REPORT LIST OR IMPACT METRICS
                    // ==========================================
                    _myReports.isEmpty
                        ? Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.post_add_rounded, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                const Text("No Reports Submitted Yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  "Your reported potholes, water leaks, and street lights will show up here.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _myReports.length,
                            itemBuilder: (context, index) {
                              return IssueCard(
                                issue: _myReports[index],
                                currentUser: displayName,
                                onStatusChanged: _loadData,
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(
                value,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}