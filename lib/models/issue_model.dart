class Issue {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String location;
  final int upvotes;
  final bool anonymous;

  final double latitude;
  final double longitude;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.location,
    required this.upvotes,
    required this.anonymous,
    required this.latitude,
    required this.longitude,
  });
}