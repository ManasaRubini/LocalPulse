class Event {
  final int id;
  final String title;
  final String description;
  final String category;
  final String locationName;
  final double latitude;
  final double longitude;
  final String startTime;
  final double distanceKm;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.distanceKm,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json["id"],
      title: json["title"],
      description: json["description"] ?? "",
      category: json["category"],
      locationName: json["location_name"],
      latitude: (json["latitude"] as num).toDouble(),
      longitude: (json["longitude"] as num).toDouble(),
      startTime: json["start_time"],
      distanceKm: (json["distance_km"] ?? 0).toDouble(),
    );
  }
}