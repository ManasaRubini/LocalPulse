import 'package:flutter/material.dart';

import 'feed_screen.dart';
import 'explore_screen.dart';
import 'report_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final List<Widget> pages = const [
  FeedScreen(),
  ExploreScreen(),
  ReportScreen(),
  EventsScreen(),
  ProfileScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],

      floatingActionButton: Container(
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color(0xff7B61FF),
              Color(0xff9C7CFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            )
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: Colors.transparent,
          onPressed: () {},
          child: Icon(Icons.mic, color: Colors.white, size: 30),
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              color: Colors.black12,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home, "Feed", 0),
            navItem(Icons.explore, "Explore", 1),
            navItem(Icons.add_circle_outline, "Report", 2),
            navItem(Icons.calendar_month, "Events", 3),
            navItem(Icons.person, "Profile", 4),
          ],
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String text, int i) {
    bool selected = index == i;

    return GestureDetector(
      onTap: () => setState(() => index = i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected
                ? Color(0xff7B61FF)
                : Colors.grey,
          ),
          SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: selected
                  ? Color(0xff7B61FF)
                  : Colors.grey,
            ),
          )
        ],
      ),
    );
  }
}