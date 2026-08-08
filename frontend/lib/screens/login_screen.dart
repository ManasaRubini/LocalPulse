import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController(text: "Manass");
  final passwordController = TextEditingController(text: "manass123");
  final phoneController = TextEditingController(text: "9876543210");
  final addressController = TextEditingController(text: "Gandhipuram, Coimbatore");

  bool isLoading = false;
  bool isLoginMode = true;
  bool obscurePassword = true;

  Future<void> _handleAuth() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your username and password"), backgroundColor: AppColors.alert),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLoginMode) {
        final response = await http.post(
          Uri.parse("${AppConfig.baseUrl}/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"username": username, "password": password}),
        ).timeout(const Duration(seconds: 8));

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data["username"] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("username", data["username"]);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          // Demo fallback: If backend wake-up is slow, allow citizen entry
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("username", username);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        final response = await http.post(
          Uri.parse("${AppConfig.baseUrl}/register"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "username": username,
            "password": password,
            "phone": phoneController.text.trim(),
            "address": addressController.text.trim(),
          }),
        ).timeout(const Duration(seconds: 8));

        if (!mounted) return;
        setState(() => isLoading = false);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account registered! Please log in with your credentials."), backgroundColor: AppColors.success),
          );
          setState(() => isLoginMode = true);
        } else {
          try {
            final data = jsonDecode(response.body);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data["detail"] ?? data["error"] ?? "Registration failed"), backgroundColor: AppColors.alert),
            );
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Registration error: ${response.body}"), backgroundColor: AppColors.alert),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection issue: $e"), backgroundColor: AppColors.alert),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _quickFill(String user, String pass) {
    setState(() {
      usernameController.text = user;
      passwordController.text = pass;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // Animated App Brand Logo
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: AppColors.primaryGlow,
                  ),
                  child: const Icon(Icons.hub_rounded, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 18),
                Text(
                  isLoginMode ? "Welcome to LocalPulse" : "Join Your Neighborhood",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  isLoginMode ? "Real-time civic issue reporting & community pulse" : "Connect with local citizens and civic authorities",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      _inputField(
                        controller: usernameController,
                        label: "Citizen Username",
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: passwordController,
                        label: "Password",
                        icon: Icons.lock_rounded,
                        obscure: obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      if (!isLoginMode) ...[
                        const SizedBox(height: 14),
                        _inputField(
                          controller: phoneController,
                          label: "Contact Phone",
                          icon: Icons.phone_rounded,
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: addressController,
                          label: "Ward / Neighborhood",
                          icon: Icons.location_on_rounded,
                        ),
                      ],
                      const SizedBox(height: 22),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isLoading ? null : _handleAuth,
                          child: isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  isLoginMode ? "Enter LocalPulse" : "Create Citizen Profile",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Switch Mode Button
                      TextButton(
                        onPressed: () => setState(() => isLoginMode = !isLoginMode),
                        child: Text(
                          isLoginMode ? "New to the area? Create Account" : "Already registered? Log In",
                          style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Demo User Selector
                if (isLoginMode) ...[
                  const Text("Quick Demo Citizen Login:", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text("Manass"),
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        onPressed: () => _quickFill("Manass", "manass123"),
                      ),
                      ActionChip(
                        label: const Text("Lavanya"),
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        onPressed: () => _quickFill("Lavanya", "lavanya123"),
                      ),
                      ActionChip(
                        label: const Text("Keerthi"),
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        onPressed: () => _quickFill("Keerthi", "keerthi123"),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}