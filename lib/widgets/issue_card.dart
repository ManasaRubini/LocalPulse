import 'package:flutter/material.dart';

class IssueCard extends StatefulWidget {
  const IssueCard({super.key});

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard> {

  int likes = 24;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Water Leakage Near Bus Stand",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Water is leaking continuously for two days.",
            ),

            const SizedBox(height: 10),

            Row(
              children: [

                IconButton(
                  onPressed: () {
                    setState(() {
                      likes++;
                    });
                  },
                  icon: const Icon(Icons.thumb_up),
                ),

                Text("$likes"),

                const SizedBox(width: 20),

                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.comment),
                ),

                const Text("12 Comments"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}