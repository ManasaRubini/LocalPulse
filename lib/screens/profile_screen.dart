import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String baseUrl = "https://my-backend-4hfj.onrender.com";

  bool _isLoading = true;

  String? username;

  Map<String, dynamic> _profile = {
    "username": "-",
    "phone": "-",
    "address": "-"
  };

  List<dynamic> _myReports = [];

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  // ================= INIT =================
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

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadProfile(),
      _loadMyPosts(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            _profile = data;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMyPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/issues/all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            _myReports = (data as List)
                .where((issue) => issue["user_name"] == username)
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadData,
          )
        ],
      ),

      // ---------------- BODY ----------------
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      // ================= PROFILE HEADER =================
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Column(
                          children: [

                            // Avatar with gradient ring
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xff7B61FF),
                                    Color(0xff9C7CFF),
                                  ],
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 42,
                                  color: Color(0xff7B61FF),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              _profile["username"] ?? "-",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Community Reporter",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),

                            const SizedBox(height: 14),

                            Divider(color: Colors.grey.shade200),

                            const SizedBox(height: 10),

                            _info(Icons.phone, _profile["phone"] ?? "-"),
                            const SizedBox(height: 8),
                            _info(Icons.location_on, _profile["address"] ?? "-"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ================= STATS CARD =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statBox(
                            "Posts",
                            _myReports.length.toString(),
                            Icons.article,
                          ),
                          _statBox(
                            "Active",
                            "1",
                            Icons.verified,
                          ),
                          _statBox(
                            "Rank",
                            "Top",
                            Icons.emoji_events,
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // ================= POSTS HEADER =================
                      Row(
                        children: const [
                          Text(
                            "My Posts",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ================= POSTS LIST =================
                      _myReports.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.post_add,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "No posts yet",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _myReports.length,
                              itemBuilder: (context, index) {
                                final post = _myReports[index];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xff7B61FF)
                                            .withOpacity(.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.article,
                                        color: Color(0xff7B61FF),
                                      ),
                                    ),
                                    title: Text(
                                      post["title"] ?? "",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        post["description"] ?? "",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ================= HELPERS =================
  Widget _info(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xff7B61FF)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}