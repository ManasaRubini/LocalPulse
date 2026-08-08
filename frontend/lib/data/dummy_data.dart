import '../models/issue_model.dart';
import '../models/event_model.dart';

class DummyData {
  static final List<Issue> sampleIssues = [
    Issue(
      id: 1,
      userName: "Manass",
      title: "Major Pothole Near Gandhipuram Bus Stand",
      description: "Huge 2ft pothole causing frequent bike skids and evening traffic jams.",
      imageUrl: "",
      category: "Road",
      location: "Gandhipuram, Coimbatore",
      latitude: 11.0168,
      longitude: 76.9558,
      anonymous: false,
      upvotes: 58,
      status: "In Progress",
      priority: "Critical",
      resolutionNote: "Municipal road repair team notified. Work scheduled.",
      createdAt: "2026-08-01 10:00",
    ),
    Issue(
      id: 2,
      userName: "Lavanya",
      title: "Main Street Light Blackout",
      description: "Entire cross street lights have failed for three consecutive nights. Safety risk for pedestrians.",
      imageUrl: "",
      category: "Electricity",
      location: "Peelamedu, Coimbatore",
      latitude: 11.0281,
      longitude: 76.9890,
      anonymous: false,
      upvotes: 38,
      status: "Open",
      priority: "High",
      resolutionNote: "",
      createdAt: "2026-08-02 18:30",
    ),
  ];

  static final List<Event> sampleEvents = [
    Event(
      id: 1,
      title: "Mega Blood Donation & Health Camp",
      description: "Join local doctors for voluntary blood donation and free vital health checkups.",
      category: "Health",
      locationName: "Coimbatore Medical College",
      latitude: 11.0168,
      longitude: 76.9558,
      startTime: "2026-08-15 09:00 AM",
      attendeesCount: 45,
    ),
  ];
}
