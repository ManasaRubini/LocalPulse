class PulseAIResponse {
  final String text;
  final String? actionType; // 'filter_category', 'open_emergency', 'open_report', 'open_events', 'open_explore'
  final String? payload;

  PulseAIResponse({
    required this.text,
    this.actionType,
    this.payload,
  });
}

class PulseAIService {
  static PulseAIResponse processQuery(String query) {
    final q = query.toLowerCase().trim();

    // 1. Emergency & Helplines
    if (q.contains("emergency") || q.contains("police") || q.contains("ambulance") || q.contains("fire") || q.contains("sos") || q.contains("help")) {
      return PulseAIResponse(
        text: "🚨 Opening City Emergency Helplines. You can one-tap dial Police (100), Ambulance (108), or Fire (101) directly.",
        actionType: "open_emergency",
      );
    }

    // 2. Hospital & Medical on Map
    if (q.contains("hospital") || q.contains("medical") || q.contains("doctor") || q.contains("clinic")) {
      return PulseAIResponse(
        text: "🏥 Navigating to Explore Map for nearest Hospitals and 24/7 Medical Care.",
        actionType: "open_explore",
        payload: "hospital",
      );
    }

    // 3. Police Stations on Map
    if (q.contains("station") || q.contains("cop") || q.contains("patrol")) {
      return PulseAIResponse(
        text: "🚓 Showing local Police Stations and Commissionerate on the Explore map.",
        actionType: "open_explore",
        payload: "police",
      );
    }

    // 4. Water Pipeline & Drainage
    if (q.contains("water") || q.contains("leak") || q.contains("pipe") || q.contains("drain")) {
      return PulseAIResponse(
        text: "💧 Filtering feed for Water & Pipeline issues. Twad Board is currently repairing leaks in RS Puram.",
        actionType: "filter_category",
        payload: "Water",
      );
    }

    // 5. Road & Potholes
    if (q.contains("road") || q.contains("pothole") || q.contains("traffic") || q.contains("footpath") || q.contains("street")) {
      return PulseAIResponse(
        text: "🚧 Showing Road & Infrastructure hazards near Gandhipuram and Peelamedu.",
        actionType: "filter_category",
        payload: "Road",
      );
    }

    // 6. Garbage & Sanitation
    if (q.contains("garbage") || q.contains("waste") || q.contains("clean") || q.contains("dustbin") || q.contains("trash")) {
      return PulseAIResponse(
        text: "🗑️ Filtering for Waste Management & Sanitation reports across your ward.",
        actionType: "filter_category",
        payload: "Garbage",
      );
    }

    // 7. Electricity & Streetlights
    if (q.contains("light") || q.contains("power") || q.contains("electricity") || q.contains("blackout") || q.contains("wire")) {
      return PulseAIResponse(
        text: "⚡ Showing Electricity & Streetlight outages near your location.",
        actionType: "filter_category",
        payload: "Electricity",
      );
    }

    // 8. Community Drives & Events
    if (q.contains("event") || q.contains("camp") || q.contains("plantation") || q.contains("drive") || q.contains("meetup") || q.contains("tree") || q.contains("blood")) {
      return PulseAIResponse(
        text: "📅 Opening Community Drives. Blood Donation camp at CMC and 1000 Trees Plantation drive are happening this week!",
        actionType: "open_events",
      );
    }

    // 9. Reporting New Incidents
    if (q.contains("report") || q.contains("submit") || q.contains("new issue") || q.contains("file")) {
      return PulseAIResponse(
        text: "📝 Launching the Civic Incident Report form. You can snap a photo proof and pinpoint the GPS location.",
        actionType: "open_report",
      );
    }

    // Default friendly AI overview
    return PulseAIResponse(
      text: "👋 LocalPulse AI is active. Current civic resolution rate in Coimbatore is 88%. Try asking: 'Show water leaks', 'Nearest hospital', or 'Emergency police'.",
    );
  }
}
