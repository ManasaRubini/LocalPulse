class PulseAIResponse {
  final String text;
  final String? actionType; // 'filter_category', 'open_emergency', 'open_report', 'open_events', 'open_explore'
  final String? payload;
  final List<String>? followUpSuggestions;

  PulseAIResponse({
    required this.text,
    this.actionType,
    this.payload,
    this.followUpSuggestions,
  });
}

class PulseAIService {
  static PulseAIResponse processQuery(String query) {
    final q = query.toLowerCase().trim();

    // 1. Friendly Greetings & Small Talk
    if (q.contains("hello") || q.contains("hi") || q.contains("hey") || q.startsWith("morning") || q.contains("good morning") || q.contains("good evening") || q.contains("vanakkam")) {
      return PulseAIResponse(
        text: "Vanakkam & Hello there! 😊 It's wonderful to connect with you. I'm PulseAI, your friendly neighborhood civic buddy in Coimbatore. How are things in your area today?",
        followUpSuggestions: ["💧 Any water issues?", "🚧 Report road damage", "🏥 Nearest hospital", "🏆 How does karma work?"],
      );
    }

    if (q.contains("how are you") || q.contains("how r u") || q.contains("how do you do") || q.contains("whats up")) {
      return PulseAIResponse(
        text: "I'm doing fantastic, thank you for asking! ⚡ I've been monitoring ward reports across Gandhipuram, RS Puram, and Peelamedu. 88% resolution rate this month! How can I make your day easier?",
        followUpSuggestions: ["📢 Check live feed", "🌳 Upcoming events", "🚑 Emergency helplines"],
      );
    }

    if (q.contains("who are you") || q.contains("what can you do") || q.contains("your name") || q.contains("help me")) {
      return PulseAIResponse(
        text: "I'm PulseAI! 🤖 Think of me as your personal civic co-pilot. I can help you report road potholes or water leaks, locate nearby 24/7 hospitals and police stations, guide you to blood donation events, or explain your Civic Karma score. Just ask me anything!",
        followUpSuggestions: ["📝 Report an issue", "🗺️ Explore map", "🏆 Check my karma"],
      );
    }

    if (q.contains("thank") || q.contains("thx") || q.contains("awesome") || q.contains("great") || q.contains("good job") || q.contains("nice")) {
      return PulseAIResponse(
        text: "You're so welcome! 🌟 Active citizens like you make Coimbatore cleaner, safer, and better every day. I'm always right here if you need anything else!",
        followUpSuggestions: ["📅 Explore community drives", "📍 Find nearby amenities"],
      );
    }

    // 2. Karma & Community Reputation
    if (q.contains("karma") || q.contains("score") || q.contains("points") || q.contains("badge") || q.contains("rank") || q.contains("champion")) {
      return PulseAIResponse(
        text: "Civic Karma is your community trust reputation! 🏆\n• You earn +10 Karma every time you submit a civic report.\n• You earn +2 Karma when neighbors upvote your submission.\n• Reach 40 Karma for 'Neighborhood Guardian 🛡️' and 80 Karma for 'Civic Champion 🏆'!",
        followUpSuggestions: ["📝 Report a new issue", "👤 View my profile"],
      );
    }

    // 3. Emergency & SOS Helplines
    if (q.contains("emergency") || q.contains("police") || q.contains("ambulance") || q.contains("fire") || q.contains("sos") || q.contains("danger") || q.contains("accident")) {
      return PulseAIResponse(
        text: "Stay calm, help is always one tap away! 🚨 Direct 24/7 emergency helplines:\n• Police: 100\n• Medical Ambulance: 108\n• Fire & Rescue: 101\n• Women Helpline: 1091\nLaunching the Emergency SOS speed-dial for you!",
        actionType: "open_emergency",
        followUpSuggestions: ["🏥 Nearest hospital", "🚓 Nearest police station"],
      );
    }

    // 4. Hospitals & Medical on Map
    if (q.contains("hospital") || q.contains("medical") || q.contains("doctor") || q.contains("clinic") || q.contains("health center") || q.contains("pharmacy")) {
      return PulseAIResponse(
        text: "🏥 Navigating to the Explore map! Pinpointing Coimbatore Medical College, GKNM Hospital, and PSG 24/7 Emergency Trauma Centers with walking and driving times.",
        actionType: "open_explore",
        payload: "hospital",
        followUpSuggestions: ["🗺️ Get directions in Google Maps", "🚨 Emergency SOS"],
      );
    }

    // 5. Police Stations on Map
    if (q.contains("police station") || q.contains("cop") || q.contains("patrol") || q.contains("commissioner") || q.contains("station")) {
      return PulseAIResponse(
        text: "🚓 Showing local Police Stations including RS Puram B2, Gandhipuram Law & Order, and the City Commissionerate on the Explore map.",
        actionType: "open_explore",
        payload: "police",
        followUpSuggestions: ["🗺️ Open in Google Maps", "🚨 Call Police (100)"],
      );
    }

    // 6. Water Pipeline & Drainage
    if (q.contains("water") || q.contains("leak") || q.contains("pipe") || q.contains("drain") || q.contains("siruvani") || q.contains("twad")) {
      return PulseAIResponse(
        text: "Water is precious to all of us! 💧 The Siruvani Water Supply Board and TWAD team are actively resolving leaks in RS Puram. Filtering the feed to show all water maintenance updates!",
        actionType: "filter_category",
        payload: "Water",
        followUpSuggestions: ["📝 Report a water leak", "🗺️ Water utilities on map"],
      );
    }

    // 7. Road, Potholes & Traffic
    if (q.contains("road") || q.contains("pothole") || q.contains("traffic") || q.contains("footpath") || q.contains("street") || q.contains("accident hazard")) {
      return PulseAIResponse(
        text: "Road potholes are a major priority before the monsoon! 🚧 I'm filtering the community feed for Road & Infrastructure hazards near Gandhipuram and Peelamedu.",
        actionType: "filter_category",
        payload: "Road",
        followUpSuggestions: ["📝 Report road damage", "🚗 View on Explore map"],
      );
    }

    // 8. Garbage & Sanitation
    if (q.contains("garbage") || q.contains("waste") || q.contains("clean") || q.contains("dustbin") || q.contains("trash") || q.contains("smell") || q.contains("sanitation")) {
      return PulseAIResponse(
        text: "A clean neighborhood is a healthy neighborhood! 🗑️ Showing sanitation reports and Vellalore solid waste processing updates near your ward.",
        actionType: "filter_category",
        payload: "Garbage",
        followUpSuggestions: ["📝 Report uncollected garbage", "🌳 Join clean-up drive"],
      );
    }

    // 9. Electricity & Power Outages
    if (q.contains("light") || q.contains("power") || q.contains("electricity") || q.contains("blackout") || q.contains("wire") || q.contains("transformer") || q.contains("tneb")) {
      return PulseAIResponse(
        text: "Dark streets and power outages can be unsafe at night. ⚡ Showing Electricity & Streetlight reports for quick TNEB maintenance.",
        actionType: "filter_category",
        payload: "Electricity",
        followUpSuggestions: ["📝 Report broken streetlight", "🚨 Emergency SOS"],
      );
    }

    // 10. Community Events & Volunteering
    if (q.contains("event") || q.contains("camp") || q.contains("plantation") || q.contains("drive") || q.contains("meetup") || q.contains("volunteer") || q.contains("tree") || q.contains("blood")) {
      return PulseAIResponse(
        text: "Giving back makes our community stronger! 📅 Opening the Civic Events tab. You can RSVP for the Mega Blood Donation Camp at CMC or the 1000 Trees Plantation Drive at VOC Park!",
        actionType: "open_events",
        followUpSuggestions: ["🌳 Host a new drive", "👥 Check attendees"],
      );
    }

    // 11. Reporting a New Incident
    if (q.contains("report") || q.contains("submit") || q.contains("new issue") || q.contains("file") || q.contains("complaint") || q.contains("photo")) {
      return PulseAIResponse(
        text: "I'll help you get that reported right away! 📝 Opening the Incident Report form where you can snap a photo proof, choose priority, and auto-detect your GPS pin.",
        actionType: "open_report",
        followUpSuggestions: ["📷 Attach photo proof", "📍 Adjust pin on map"],
      );
    }

    // Default friendly conversational response with helpful guidance
    return PulseAIResponse(
      text: "I'm listening! 💬 You can ask me anything about your city: 'Show water leaks', 'Find nearest hospital', 'Report a pothole', 'Upcoming events', or 'Emergency police'. How can I help you today?",
      followUpSuggestions: ["💧 Water leaks", "🏥 Nearest hospital", "📝 Report an issue", "🏆 How does karma work?"],
    );
  }
}
