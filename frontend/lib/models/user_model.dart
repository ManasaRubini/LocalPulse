class UserModel {
  final String username;
  final String phone;
  final String address;
  final int karma;
  final int reportsCount;
  final int resolvedCount;
  final String badge;

  UserModel({
    required this.username,
    required this.phone,
    required this.address,
    this.karma = 50,
    this.reportsCount = 0,
    this.resolvedCount = 0,
    this.badge = "Active Citizen",
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json["username"] ?? "Citizen",
      phone: json["phone"] ?? "-",
      address: json["address"] ?? "-",
      karma: json["karma"] is int ? json["karma"] : int.tryParse(json["karma"]?.toString() ?? "50") ?? 50,
      reportsCount: json["reports_count"] is int ? json["reports_count"] : int.tryParse(json["reports_count"]?.toString() ?? "0") ?? 0,
      resolvedCount: json["resolved_count"] is int ? json["resolved_count"] : int.tryParse(json["resolved_count"]?.toString() ?? "0") ?? 0,
      badge: json["badge"] ?? "Active Citizen",
    );
  }

  String get tier {
    if (karma >= 100) return "Tier 3: Civic Champion";
    if (karma >= 50) return "Tier 2: Neighborhood Guardian";
    return "Tier 1: Community Member";
  }
}
