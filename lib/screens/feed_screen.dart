import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<dynamic>> issuesFuture;

  final Map<int, Future<List<dynamic>>> commentsCache = {};
  final Set<int> likedPosts = {};

  final TextEditingController searchController = TextEditingController();

  String selectedCategory = "All";

  final List<String> categories = [
    "All",
    "Water",
    "Road",
    "Garbage",
    "Electricity",
    "Health",
    "Others",
  ];

  @override
  void initState() {
    super.initState();
    issuesFuture = ApiService.getIssues();
  }

  Future<void> refreshFeed() async {
    setState(() {
      issuesFuture = ApiService.getIssues();
    });
  }

  Future<List<dynamic>> loadComments(int issueId) {
    commentsCache[issueId] ??= ApiService.getComments(issueId);
    return commentsCache[issueId]!;
  }

  Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case "water":
        return Colors.blue;
      case "road":
        return Colors.orange;
      case "garbage":
        return Colors.green;
      case "electricity":
        return Colors.amber;
      case "health":
        return Colors.red;
      default:
        return Colors.deepPurple;
    }
  }

  IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case "water":
        return Icons.water_drop;
      case "road":
        return Icons.route;
      case "garbage":
        return Icons.delete;
      case "electricity":
        return Icons.flash_on;
      case "health":
        return Icons.local_hospital;
      default:
        return Icons.report_problem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Community Feed",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: refreshFeed,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black87,
            ),
          ),
        ],
      ),

      body: Column(
        children: [

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black.withOpacity(.05),
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                  hintText: "Search issues...",
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          /// CATEGORY FILTER
          SizedBox(
            height: 48,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final selected = cat == selectedCategory;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(cat),
                    selectedColor: const Color(0xff7B61FF),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          /// FEED
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshFeed,
              child: FutureBuilder<List<dynamic>>(
                future: issuesFuture,
                builder: (context, snapshot) {

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Issues Found",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  List<dynamic> issues = snapshot.data!;

                  /// SEARCH FILTER
                  if (searchController.text.isNotEmpty) {
                    issues = issues.where((issue) {
                      final q = searchController.text.toLowerCase();

                      return issue["title"]
                              .toString()
                              .toLowerCase()
                              .contains(q) ||
                          issue["description"]
                              .toString()
                              .toLowerCase()
                              .contains(q) ||
                          issue["location"]
                              .toString()
                              .toLowerCase()
                              .contains(q);
                    }).toList();
                  }

                  /// CATEGORY FILTER
                  if (selectedCategory != "All") {
                    issues = issues.where((issue) {
                      return issue["category"] ==
                          selectedCategory;
                    }).toList();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: issues.length,
                    itemBuilder: (context, index) {

                      final issue = issues[index];

                      return buildIssueCard(issue);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget buildIssueCard(dynamic issue) {
  final int id = issue["id"];

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.06),
          blurRadius: 16,
          offset: const Offset(0, 8),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ================= HEADER =================
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [

              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xff7B61FF),
                child: Text(
                  (issue["user_name"] ?? "U")
                      .toString()
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      issue["anonymous"] == true
                          ? "Anonymous"
                          : issue["user_name"] ?? "User",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 15,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            issue["location"] ?? "",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: issue["status"] == "Open"
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  issue["status"],
                  style: TextStyle(
                    color: issue["status"] == "Open"
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),

        // ================= IMAGE =================

        if ((issue["image_url"] ?? "").toString().isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              child: Image.network(
                issue["image_url"],
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // ================= TITLE =================

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            issue["title"] ?? "",
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ================= DESCRIPTION =================

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            issue["description"] ?? "",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ================= CATEGORY =================

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Wrap(
            spacing: 10,
            children: [

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: categoryColor(issue["category"])
                      .withOpacity(.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Icon(
                      categoryIcon(issue["category"]),
                      color: categoryColor(issue["category"]),
                      size: 18,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      issue["category"],
                      style: TextStyle(
                        color: categoryColor(issue["category"]),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Divider(height: 1),

        // ================= ACTION BAR =================

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [

              // LIKE

              TextButton.icon(
                onPressed: () async {

                  if (likedPosts.contains(id)) return;

                  await ApiService.upvoteIssue(id);

                  setState(() {
                    likedPosts.add(id);
                  });

                  refreshFeed();
                },
                icon: Icon(
                  likedPosts.contains(id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: likedPosts.contains(id)
                      ? Colors.red
                      : Colors.grey,
                ),
                label: Text(
                  "${issue["upvotes"]}",
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ),

              // COMMENT

              TextButton.icon(
                onPressed: () {
                  showCommentBottomSheet(
                    context,
                    id,
                  );
                },
                icon: const Icon(
                  Icons.mode_comment_outlined,
                  color: Colors.grey,
                ),
                label: const Text(
                  "Comment",
                  style: TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ),

              // SHARE

              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content:
                          Text("Share coming soon"),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.share_outlined,
                  color: Colors.grey,
                ),
                label: const Text(
                  "Share",
                  style: TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
void showCommentBottomSheet(BuildContext context, int issueId) {
  final TextEditingController controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        minChildSize: .55,
        maxChildSize: .95,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [

                const SizedBox(height: 12),

                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Comments",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Divider(),

                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: loadComments(issueId),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final comments = snapshot.data!;

                      if (comments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: const [

                              Icon(
                                Icons.chat_bubble_outline,
                                size: 70,
                                color: Colors.grey,
                              ),

                              SizedBox(height: 16),

                              Text(
                                "No comments yet",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {

                          final c = comments[index];

                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: 14),

                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      Colors.deepPurple.shade100,

                                  child: Text(
                                    (c["user_name"] ?? "U")
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(14),

                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xffF5F7FB),
                                      borderRadius:
                                          BorderRadius.circular(18),
                                    ),

                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [

                                        Text(
                                          c["user_name"],
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          c["comment"],
                                          style:
                                              const TextStyle(
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
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

                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(.05),
                        )
                      ],
                    ),

                    child: Row(
                      children: [

                        const CircleAvatar(
                          backgroundColor: Color(0xff7B61FF),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: "Write a comment...",
                              filled: true,
                              fillColor:
                                  const Color(0xffF5F7FB),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff7B61FF),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                            onPressed: () async {

                              if (controller.text.trim().isEmpty) {
                                return;
                              }

                              await ApiService.addComment(
                                issueId: issueId,
                                comment: controller.text.trim(),
                              );

                              controller.clear();

                              commentsCache.remove(issueId);

                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
}