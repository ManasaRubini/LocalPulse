import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CommentTile extends StatelessWidget {
  final String author;
  final String comment;
  final String? timeAgo;

  const CommentTile({
    super.key,
    required this.author,
    required this.comment,
    this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              author.isNotEmpty ? author[0].toUpperCase() : "C",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (timeAgo != null)
                      Text(
                        timeAgo!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: const TextStyle(fontSize: 13.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
