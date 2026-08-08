import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'explore_screen.dart';
import 'report_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import '../widgets/voice_assistant_modal.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  String? feedCategoryFilter;

  String? exploreSubType;

  @override
  void initState() {
    super.initState();
    _initPages();
  }

  void _initPages() {
    pages = [
      FeedScreen(initialCategoryFilter: feedCategoryFilter),
      ExploreScreen(initialType: exploreSubType),
      const ReportScreen(),
      const EventsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onFilterCategory(String category) {
    setState(() {
      feedCategoryFilter = category;
      currentIndex = 0;
      _initPages();
    });
  }

  void _onNavigateTab(int index, {String? subType}) {
    setState(() {
      if (index == 1 && subType != null) {
        exploreSubType = subType;
        _initPages();
      }
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      // Central PulseAI Voice Assistant Mic Button
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: AppColors.primaryGlow,
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: Colors.transparent,
          onPressed: () {
            VoiceAssistantModal.show(
              context,
              onFilterCategory: _onFilterCategory,
              onNavigateTab: _onNavigateTab,
            );
          },
          tooltip: "PulseAI Voice Assistant",
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, "Feed", 0),
            _navItem(Icons.explore_rounded, "Explore", 1),
            _navItem(Icons.add_circle_outline_rounded, "Report", 2),
            _navItem(Icons.event_note_rounded, "Events", 3),
            _navItem(Icons.person_rounded, "Profile", 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String text, int index) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}