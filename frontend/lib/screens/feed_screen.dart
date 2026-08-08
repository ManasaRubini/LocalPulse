import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue_model.dart';
import '../services/api_service.dart';
import '../widgets/issue_card.dart';
import '../widgets/emergency_sos_sheet.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class FeedScreen extends StatefulWidget {
  final String? initialCategoryFilter;

  const FeedScreen({super.key, this.initialCategoryFilter});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Issue>> issuesFuture;
  late Future<Map<String, dynamic>> statsFuture;

  final TextEditingController searchController = TextEditingController();
  String selectedCategory = "All";
  String selectedStatus = "All";
  String? currentUsername;

  final List<String> statusFilters = ["All", "Open", "In Progress", "Resolved"];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryFilter != null) {
      selectedCategory = widget.initialCategoryFilter!;
    }
    _loadUser();
    _fetchData();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUsername = prefs.getString("username") ?? "Citizen";
    });
  }

  void _fetchData() {
    setState(() {
      issuesFuture = ApiService.getIssues(user: currentUsername);
      statsFuture = ApiService.getStatsOverview();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "LocalPulse",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Emergency SOS Quick Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alert,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => EmergencySOSSheet.show(context),
              icon: const Icon(Icons.emergency_rounded, size: 16),
              label: const Text("SOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          IconButton(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: "Refresh Feed",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchData(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // ==========================================
            // LIVE COMMUNITY PULSE METRICS BANNER
            // ==========================================
            FutureBuilder<Map<String, dynamic>>(
              future: statsFuture,
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {
                  "active_issues": 12,
                  "resolved_rate_percent": 40.0,
                  "civic_health_index": "88/100"
                };

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppColors.primaryGlow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                              SizedBox(width: 6),
                              Text(
                                "Live Civic Pulse",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              "Active Wards",
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _pulseStatItem("${stats['active_issues']}", "Active Reports", Icons.pending_actions_rounded),
                          Container(height: 30, width: 1, color: Colors.white24),
                          _pulseStatItem("${stats['resolved_rate_percent']}%", "Resolved Rate", Icons.task_alt_rounded),
                          Container(height: 30, width: 1, color: Colors.white24),
                          _pulseStatItem("${stats['civic_health_index']}", "Civic Score", Icons.favorite_rounded),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // ==========================================
            // SEARCH BAR
            // ==========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.softShadow,
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    hintText: "Search issues by location, title or tag...",
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // ==========================================
            // CATEGORY FILTER CHIPS
            // ==========================================
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: AppCategories.list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = AppCategories.list[index];
                  final isSelected = cat == selectedCategory;

                  return ChoiceChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cat != "All") Icon(AppCategories.getIcon(cat), size: 15, color: isSelected ? Colors.white : AppColors.textSecondary),
                        if (cat != "All") const SizedBox(width: 6),
                        Text(cat),
                      ],
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = cat;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // ==========================================
            // STATUS FILTER PILLS
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: statusFilters.map((st) {
                  final isSelected = st == selectedStatus;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => selectedStatus = st),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.textPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.textPrimary : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          st,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // ==========================================
            // ISSUES FEED
            // ==========================================
            FutureBuilder<List<Issue>>(
              future: issuesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }

                List<Issue> issues = snapshot.data ?? [];

                // Category Filter
                if (selectedCategory != "All") {
                  issues = issues.where((i) => i.category.toLowerCase() == selectedCategory.toLowerCase()).toList();
                }

                // Status Filter
                if (selectedStatus != "All") {
                  issues = issues.where((i) => i.status.toLowerCase() == selectedStatus.toLowerCase()).toList();
                }

                // Search Filter
                final query = searchController.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  issues = issues.where((i) {
                    return i.title.toLowerCase().contains(query) ||
                        i.description.toLowerCase().contains(query) ||
                        i.location.toLowerCase().contains(query) ||
                        i.category.toLowerCase().contains(query);
                  }).toList();
                }

                if (issues.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(30),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          "No Issues Matching Filter",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Try switching category or search keywords.",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    return IssueCard(
                      issue: issues[index],
                      currentUser: currentUsername ?? "Citizen",
                      onStatusChanged: _fetchData,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulseStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}