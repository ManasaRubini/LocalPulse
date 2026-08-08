class PulseAIResponse {
  final String text;
  final String? actionType; // 'filter_category', 'open_emergency', 'open_report', 'open_events'
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

    if (q.contains("emergency") || q.contains("police") || q.contains("ambulance") || q.contains("fire") || q.contains("sos")) {
      return PulseAIResponse(
        text: "Opening City Emergency Helplines. You can call Police (100), Ambulance (108), or Fire (101) directly.",
        actionType: "open_emergency",
      );
    }

    if (q.contains("water") || q.contains("leak") || q.contains("pipe")) {
      return PulseAIResponse(
        text: "Filtering feed for Water & Pipeline issues. RS Puram has an active pipeline restoration underway.",
        actionType: "filter_category",
        payload: "Water",
      );
    }

    if (q.contains("road") || q.contains("pothole") || q.contains("traffic") || q.contains("footpath")) {
      return PulseAIResponse(
        text: "Filtering feed for Road and Infrastructure issues.",
        actionType: "filter_category",
        payload: "Road",
      );
    }

    if (q.contains("garbage") || q.contains("waste") || q.contains("clean") || q.contains("dustbin")) {
      return PulseAIResponse(
        text: "Showing Sanitation & Waste Management reports near you.",
        actionType: "filter_category",
        payload: "Garbage",
      );
    }

    if (q.contains("event") || q.contains("camp") || q.contains("plantation") || q.contains("drive") || q.contains("meetup")) {
      return PulseAIResponse(
        text: "Navigating to Community Events. There is a Blood Donation Camp and Tree Plantation drive coming up this week.",
        actionType: "open_events",
      );
    }

    if (q.contains("report") || q.contains("submit") || q.contains("new issue")) {
      return PulseAIResponse(
        text: "Opening the Issue Report form. You can attach a photo and pinpoint GPS location.",
        actionType: "open_report",
      );
    }

    if (q.contains("hospital") || q.contains("medical") || q.contains("doctor")) {
      return PulseAIResponse(
        text: "Showing nearby Hospitals & Medical Emergency facilities on the Explore map.",
        actionType: "open_explore_hospital",
      );
    }

    return PulseAIResponse(
      text: "LocalPulse AI is monitoring Coimbatore civic reports. 88% civic resolution rate this month. How can I assist you?",
    );
  }
}
