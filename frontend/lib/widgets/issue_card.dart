import 'package:flutter/material.dart';
import '../models/issue_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class IssueCard extends StatefulWidget {
  final Issue issue;
  final String currentUser;
  final VoidCallback? onStatusChanged;

  const IssueCard({
    super.key,
    required this.issue,
    this.currentUser = "Citizen",
    this.onStatusChanged,
  });

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard> with SingleTickerProviderStateMixin {
  late bool hasUpvoted;
  late int upvotesCount;
  late String currentStatus;
  bool isUpvoting = false;

  @override
  void initState() {
    super.initState();
    hasUpvoted = widget.issue.hasUpvoted;
    upvotesCount = widget.issue.upvotes;
    currentStatus = widget.issue.status;
  }

  Future<void> _handleUpvote() async {
    if (isUpvoting) return;
    setState(() {
      isUpvoting = true;
      if (hasUpvoted) {
        hasUpvoted = false;
        upvotesCount = (upvotesCount - 1).clamp(0, 9999);
      } else {
        hasUpvoted = true;
        upvotesCount += 1;
      }
    });

    await ApiService.toggleUpvote(widget.issue.id, widget.currentUser);
    setState(() {
      isUpvoting = false;
    });
  }

  void _showStatusUpdateDialog(BuildContext context) {
    String selectedStatus = currentStatus;
    final TextEditingController noteCtrl = TextEditingController(text: widget.issue.resolutionNote);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text("Update Issue Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Lifecycle State:", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ["Open", "In Progress", "Resolved"].map((st) {
                    final isSel = st == selectedStatus;
                    return ChoiceChip(
                      selected: isSel,
                      label: Text(st),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setDialogState(() => selectedStatus = st),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text("Resolution Remarks:", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "e.g. TWAD Board replaced pipeline valve.",
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await ApiService.updateIssueStatus(
                    widget.issue.id,
                    selectedStatus,
                    resolutionNote: noteCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {
                      currentStatus = selectedStatus;
                    });
                    widget.onStatusChanged?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Issue status updated to $selectedStatus!"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImageZoom(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(40),
                  child: const Text("Image preview unavailable", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentSheet(BuildContext context) {
    final TextEditingController commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Community Discussion",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: ApiService.getComments(widget.issue.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final comments = snapshot.data!;
                      if (comments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 52, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text("No comments yet. Be the first to share an update!", style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          final String author = c["user_name"] ?? "Citizen";
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
                                      Text(
                                        author,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        c["comment"] ?? "",
                                        style: const TextStyle(fontSize: 14, height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          decoration: InputDecoration(
                            hintText: "Add your civic update...",
                            hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: () async {
                            final text = commentCtrl.text.trim();
                            if (text.isEmpty) return;
                            commentCtrl.clear();
                            await ApiService.addComment(
                              issueId: widget.issue.id,
                              userName: widget.currentUser,
                              comment: text,
                            );
                            setModalState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Location & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: issue.categoryColor.withValues(alpha: 0.15),
                  child: Icon(issue.categoryIcon, color: issue.categoryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            issue.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          if (issue.anonymous)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text("Anonymous", style: TextStyle(fontSize: 10, color: Colors.black54)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              issue.location,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: issue.priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record, size: 10, color: issue.priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        issue.priority,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: issue.priorityColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Attached Image
          if (issue.imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _showImageZoom(context, issue.imageUrl),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    issue.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 40),
                    ),
                  ),
                ),
              ),
            ),

          // Title & Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              issue.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              issue.description,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Resolution Remarks (if resolved or in progress)
          if (issue.resolutionNote.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue.resolutionNote,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF007A5E), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Action Bar: Category tag, Status indicator (tap to change), Upvote button & Comments
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                // Category Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: issue.categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issue.category,
                    style: TextStyle(color: issue.categoryColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),

                // Interactive Status Pill (Tap to update state)
                InkWell(
                  onTap: () => _showStatusUpdateDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: issue.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentStatus,
                          style: TextStyle(color: issue.statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.edit_outlined, size: 12, color: issue.statusColor),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Upvote Button
                InkWell(
                  onTap: _handleUpvote,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasUpvoted ? AppColors.alertLight : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasUpvoted ? Icons.favorite : Icons.favorite_border_rounded,
                          color: hasUpvoted ? AppColors.alert : Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$upvotesCount",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: hasUpvoted ? AppColors.alert : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Comment Button
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined, size: 20, color: AppColors.textSecondary),
                  onPressed: () => _showCommentSheet(context),
                  tooltip: "Comments",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}