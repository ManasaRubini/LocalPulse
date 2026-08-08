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
  bool _isLoading = true;
  String? username;

  Map<String, dynamic> _profile = {
    "username": "Citizen",
    "phone": "-",
    "address": AppConfig.defaultCity,
    "karma": 65,
    "reports_count": 4,
    "resolved_count": 2,
    "badge": "Active Citizen"
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
    username = prefs.getString("username");

    if (username == null || username!.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/profile/$username')).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        _profile = jsonDecode(res.body);
      }
    } catch (_) {}

    try {
      final allIssues = await ApiService.getIssues(user: username);
      _myReports = allIssues.where((i) => i.userName.toLowerCase() == username!.toLowerCase()).toList();
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
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
    final karma = _profile["karma"] ?? 60;
    final String tier = karma >= 80 ? "Civic Champion 🏆" : (karma >= 40 ? "Neighborhood Guardian 🛡️" : "Community Volunteer 🌱");

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
                    // Profile Header Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(
                                (username ?? "C").substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _profile["username"] ?? "Citizen",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tier,
                              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                          _infoRow(Icons.phone_rounded, _profile["phone"] ?? "-"),
                          const SizedBox(height: 8),
                          _infoRow(Icons.location_on_rounded, _profile["address"] ?? AppConfig.defaultCity),
                        ],
                      ),
                    ),

                    // Karma & Stats Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _statCard("${_profile['karma'] ?? 65}", "Civic Karma", Icons.stars_rounded, Colors.amber),
                          const SizedBox(width: 10),
                          _statCard("${_myReports.length}", "My Reports", Icons.article_rounded, AppColors.primary),
                          const SizedBox(width: 10),
                          _statCard("${_profile['resolved_count'] ?? 2}", "Resolved", Icons.verified_rounded, AppColors.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tab Bar: My Reports vs Activity
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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

                    // Tab Content
                    _myReports.isEmpty
                        ? Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.post_add_rounded, size: 50, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                const Text("No Reports Submitted Yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text("Your reported potholes, water leaks, and street lights will show up here.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                                currentUser: username ?? "Citizen",
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

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
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