import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

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
  /// Asynchronous Generative AI pipeline connecting to backend `/ai/chat` with offline fallback
  static Future<PulseAIResponse> processQueryAsync(
    String query, {
    String user = "Citizen",
    List<Map<String, String>>? history,
  }) async {
    try {
      final url = Uri.parse("${AppConfig.baseUrl}/ai/chat");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "query": query,
              "user": user,
              "history": history ?? [],
            }),
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic>? sugg = data["suggestions"];
        return PulseAIResponse(
          text: data["reply"] ?? data["text"] ?? "Vanakkam! How can I help you?",
          actionType: data["action"],
          payload: data["payload"],
          followUpSuggestions: sugg?.map((e) => e.toString()).toList(),
        );
      }
    } catch (_) {
      // If offline or network timeout, fall back seamlessly to local Tanglish NLP engine
    }

    return processQuery(query);
  }

  /// High-fidelity local Tanglish & English fallback NLP engine
  static PulseAIResponse processQuery(String query) {
    final q = query.toLowerCase().trim();

    // 1. Informal Tanglish "epd iruka" & greetings
    if (q.contains("epd") || q.contains("epdi") || q.contains("iruka") || q.contains("irukaa") || q.contains("irukinga") || q.contains("nalama") || q.contains("enna panra") || q.contains("macha") || q.contains("thalaiva")) {
      return PulseAIResponse(
        text: "Sema mass ah irukken thalaiva! ⚡ Today Coimbatore wards la active issues monitor pannitu irukken. Siruvani water pipeline repairs TWAD team fast ah panranga. Unga area la enna vishesham? Nalla irukiya?",
        followUpSuggestions: ["💧 Thanni leak aagudhu", "🚧 Road la pallam irukku", "🏥 Hospital enga irukku?", "🏆 Karma epdi kedaikkum?"],
      );
    }

    if (q.contains("vanakkam") || q.contains("hello") || q.contains("hi") || q.contains("hey") || q.startsWith("morning") || q.contains("good morning")) {
      return PulseAIResponse(
        text: "Vanakkam & Hello there! 😊 It's wonderful to connect with you. I'm PulseAI, your friendly civic companion in Coimbatore. How are things in your neighborhood today?",
        followUpSuggestions: ["💧 Any water issues?", "🚧 Report road damage", "🏥 Nearest hospital", "🏆 How does karma work?"],
      );
    }

    if (q.contains("nandri") || q.contains("romba thanks") || q.contains("super bro") || q.contains("mass") || q.contains("thank") || q.contains("awesome")) {
      return PulseAIResponse(
        text: "Romba nandri! 🌟 Unga support oda namma Coimbatore ah innum clean, green, and safe ah vechupom! Anything else I can help you with?",
        followUpSuggestions: ["📅 Community events", "📍 Explore amenities", "📝 File new report"],
      );
    }

    // 2. Water pipeline & drainage
    if (q.contains("thanni") || q.contains("thani") || q.contains("water") || q.contains("kudineer") || q.contains("leak") || q.contains("pipe") || q.contains("drain") || q.contains("siruvani") || q.contains("twad")) {
      return PulseAIResponse(
        text: "Aiyayo, thanni waste aaga koodathu! 💧 Siruvani Water Supply Board & TWAD team actively monitor leaks in Coimbatore. Let's check the feed or file a quick photo report!",
        actionType: "filter_category",
        payload: "Water",
        followUpSuggestions: ["📝 Report water leak", "🗺️ Water boards on map"],
      );
    }

    // 3. Road & Potholes
    if (q.contains("pallam") || q.contains("road") || q.contains("pothole") || q.contains("traffic") || q.contains("footpath") || q.contains("street") || q.contains("ootai")) {
      return PulseAIResponse(
        text: "Road la pallam iruntha safety risk! 🚧 I'm filtering the community feed for Road & Infrastructure hazards near Gandhipuram, Peelamedu, and RS Puram. Let's get it repaired fast!",
        actionType: "filter_category",
        payload: "Road",
        followUpSuggestions: ["📝 Report road damage", "🚗 View on Explore map"],
      );
    }

    // 4. Garbage & Sanitation
    if (q.contains("kuppai") || q.contains("garbage") || q.contains("waste") || q.contains("clean") || q.contains("dustbin") || q.contains("trash") || q.contains("sanitation")) {
      return PulseAIResponse(
        text: "Unga street eppavum clean ah irukanum! 🗑️ Showing sanitation reports and Vellalore solid waste processing updates across your ward.",
        actionType: "filter_category",
        payload: "Garbage",
        followUpSuggestions: ["📝 Report uncollected garbage", "🌳 Join clean-up drive"],
      );
    }

    // 5. Electricity & Streetlights
    if (q.contains("current") || q.contains("light") || q.contains("power") || q.contains("electricity") || q.contains("blackout") || q.contains("tneb")) {
      return PulseAIResponse(
        text: "Night time la streetlight illana bayama irukkum! ⚡ Showing Electricity & Streetlight outages for immediate TNEB municipal maintenance.",
        actionType: "filter_category",
        payload: "Electricity",
        followUpSuggestions: ["📝 Report broken streetlight", "🚨 Emergency SOS"],
      );
    }

    // 6. Emergency & SOS
    if (q.contains("police koopdu") || q.contains("ambulance") || q.contains("emergency") || q.contains("police") || q.contains("fire") || q.contains("sos") || q.contains("theepudichu")) {
      return PulseAIResponse(
        text: "Bayapadatheenga, help ready ah irukku! 🚨 Direct 24/7 Emergency Helplines:\n• Police: 100\n• Medical Ambulance: 108\n• Fire Force: 101\n• Women Helpline: 1091\nOpening Emergency SOS speed-dial for you!",
        actionType: "open_emergency",
        followUpSuggestions: ["🏥 Nearest hospital", "🚓 Nearest police station"],
      );
    }

    // 7. Hospital & Medical Care
    if (q.contains("hospital") || q.contains("maruthuvamanai") || q.contains("doctor") || q.contains("clinic") || q.contains("medical")) {
      return PulseAIResponse(
        text: "🏥 Explore Map la hospital pins open panren! Coimbatore Medical College, GKNM, and PSG 24/7 Emergency Trauma Centers with directions and walk times.",
        actionType: "open_explore",
        payload: "hospital",
        followUpSuggestions: ["🗺️ Directions in Google Maps", "🚨 Call Ambulance (108)"],
      );
    }

    // 8. Karma & Points
    if (q.contains("karma") || q.contains("score") || q.contains("points") || q.contains("badge") || q.contains("champion")) {
      return PulseAIResponse(
        text: "Civic Karma unga community trust reputation! 🏆\n• Oru issue report panna +10 Karma points.\n• Mathavanga upvote panna +2 Karma points.\n• Reach 40 Karma for 'Neighborhood Guardian 🛡️' and 80 Karma for 'Civic Champion 🏆'!",
        followUpSuggestions: ["📝 Report a new issue", "👤 View my profile"],
      );
    }

    // Default friendly bilingual response
    return PulseAIResponse(
      text: "I'm listening! 💬 Nan Tanglish & English rendulayum purinjupen. You can ask: 'Thanni leak aagudhu', 'Nearest hospital', 'Road la pallam', 'Blood donation camp', or 'Emergency police'. Epdi help pannattum thalaiva?",
      followUpSuggestions: ["💧 Thanni leak aagudhu", "🏥 Nearest hospital", "📝 Report an issue", "🏆 Karma epdi kedaikkum?"],
    );
  }
}
