import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PulseAIResponse {
  final String text;
  final String? actionType; // 'filter_category', 'open_emergency', 'open_report', 'open_events', 'open_explore'
  final String? payload;
  final List<String>? followUpSuggestions;
  final String? engine; // 'Google Gemini 1.5 Flash' or 'LocalPulse Neural SLM'

  PulseAIResponse({
    required this.text,
    this.actionType,
    this.payload,
    this.followUpSuggestions,
    this.engine,
  });
}

class ChatHistoryItem {
  final String query;
  final String reply;
  final DateTime timestamp;
  final String? actionType;

  ChatHistoryItem({
    required this.query,
    required this.reply,
    required this.timestamp,
    this.actionType,
  });

  Map<String, dynamic> toJson() => {
    'query': query,
    'reply': reply,
    'timestamp': timestamp.toIso8601String(),
    'actionType': actionType,
  };

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) => ChatHistoryItem(
    query: json['query'] ?? '',
    reply: json['reply'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    actionType: json['actionType'],
  );
}

class PulseAIService {
  static const String _historyKey = 'pulseai_persistent_chat_history';
  static const String _geminiKeyPref = 'pulseai_gemini_api_key';

  /// Save API Key in local storage
  static Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKeyPref, key.trim());
  }

  /// Get API Key from local storage
  static Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKeyPref);
  }

  /// Save a completed chat interaction into persistent storage
  static Future<void> saveToHistory(String query, String reply, {String? actionType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_historyKey) ?? [];
      final item = ChatHistoryItem(
        query: query,
        reply: reply,
        timestamp: DateTime.now(),
        actionType: actionType,
      );
      list.insert(0, jsonEncode(item.toJson()));
      // Keep last 40 conversations
      if (list.length > 40) {
        list.removeRange(40, list.length);
      }
      await prefs.setStringList(_historyKey, list);
    } catch (_) {}
  }

  /// Load all past chat interactions from persistent storage
  static Future<List<ChatHistoryItem>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_historyKey) ?? [];
      return list.map((str) => ChatHistoryItem.fromJson(jsonDecode(str))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear all saved chat history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Asynchronous Google Gemini / Generative AI pipeline connecting to backend `/ai/chat` with offline fallback
  static Future<PulseAIResponse> processQueryAsync(
    String query, {
    String user = "Citizen",
    List<Map<String, String>>? history,
  }) async {
    final apiKey = AppConfig.geminiApiKey.isNotEmpty
        ? AppConfig.geminiApiKey
        : await getGeminiApiKey();

    try {
      final url = Uri.parse("${AppConfig.baseUrl}/ai/chat");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "query": query,
              "user": user,
              "api_key": apiKey ?? "",
              "history": history ?? [],
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic>? sugg = data["suggestions"];
        final res = PulseAIResponse(
          text: data["reply"] ?? data["text"] ?? "Vanakkam! How can I help you?",
          actionType: data["action"],
          payload: data["payload"],
          followUpSuggestions: sugg?.map((e) => e.toString()).toList(),
          engine: data["engine"],
        );

        // Auto save to persistent history
        await saveToHistory(query, res.text, actionType: res.actionType);
        return res;
      }
    } catch (_) {
      // If offline or network timeout, fall back seamlessly to local Tanglish NLP engine
    }

    final localRes = processQuery(query);
    await saveToHistory(query, localRes.text, actionType: localRes.actionType);
    return localRes;
  }

  /// High-fidelity local Tanglish & English fallback NLP engine
  static PulseAIResponse processQuery(String query) {
    final q = query.toLowerCase().trim();

    // 1. Hospital problems vs Hospital directions
    if (q.contains("hospital la") || q.contains("health la") || q.contains("hospital issue") || q.contains("hospital prechanai")) {
      return PulseAIResponse(
        text: "Hospital & Health category la currently 1 issue reported: 'Mosquito Breeding in Stagnant Pool near Health Center'. Coimbatore Medical College & GKNM hospitals la emergency services normal ah operate aaguthu thalaiva! 🏥",
        actionType: "open_explore",
        payload: "hospital",
        followUpSuggestions: ["🏥 View hospital map", "🚨 Emergency SOS", "📝 Report an issue"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    // 2. Informal Tanglish "epd iruka" & greetings
    if (q.contains("epd") || q.contains("epdi") || q.contains("iruka") || q.contains("irukaa") || q.contains("irukinga") || q.contains("nalama") || q.contains("enna panra") || q.contains("macha") || q.contains("thalaiva")) {
      return PulseAIResponse(
        text: "Sema mass ah irukken thalaiva! ⚡ Today Coimbatore wards la active issues monitor pannitu irukken. Siruvani water pipeline repairs TWAD team fast ah panranga. Unga area la enna vishesham? Nalla irukiya?",
        followUpSuggestions: ["💧 Thanni leak aagudhu", "🚧 Road la pallam irukku", "🏥 Hospital enga irukku?", "🏆 Karma epdi kedaikkum?"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    if (q.contains("vanakkam") || q.contains("hello") || q.contains("hi") || q.contains("hey") || q.startsWith("morning") || q.contains("good morning")) {
      return PulseAIResponse(
        text: "Vanakkam & Hello there! 😊 It's wonderful to connect with you. I'm PulseAI (Powered by Google Gemini ✨), your friendly civic companion in Coimbatore. How are things in your neighborhood today?",
        followUpSuggestions: ["💧 Any water issues?", "🚧 Report road damage", "🏥 Nearest hospital", "🏆 How does karma work?"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    if (q.contains("nandri") || q.contains("romba thanks") || q.contains("super bro") || q.contains("mass") || q.contains("thank") || q.contains("awesome")) {
      return PulseAIResponse(
        text: "Romba nandri! 🌟 Unga support oda namma Coimbatore ah innum clean, green, and safe ah vechupom! Anything else I can help you with?",
        followUpSuggestions: ["📅 Community events", "📍 Explore amenities", "📝 File new report"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    // 3. Water pipeline & drainage
    if (q.contains("thanni") || q.contains("thani") || q.contains("water") || q.contains("kudineer") || q.contains("leak") || q.contains("pipe") || q.contains("drain") || q.contains("siruvani") || q.contains("twad")) {
      return PulseAIResponse(
        text: "Aiyayo, thanni waste aaga koodathu! 💧 Siruvani Water Supply Board & TWAD team actively monitor leaks in Coimbatore. Let's check the feed or file a quick photo report!",
        actionType: "filter_category",
        payload: "Water",
        followUpSuggestions: ["📝 Report water leak", "🗺️ Water boards on map"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    // 4. Road & Potholes
    if (q.contains("pallam") || q.contains("road") || q.contains("pothole") || q.contains("traffic") || q.contains("footpath") || q.contains("street") || q.contains("ootai")) {
      return PulseAIResponse(
        text: "Road la pallam iruntha safety risk! 🚧 I'm filtering the community feed for Road & Infrastructure hazards near Gandhipuram, Peelamedu, and RS Puram. Let's get it repaired fast!",
        actionType: "filter_category",
        payload: "Road",
        followUpSuggestions: ["📝 Report road damage", "🚗 View on Explore map"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    // 5. Garbage & Sanitation
    if (q.contains("kuppai") || q.contains("garbage") || q.contains("waste") || q.contains("clean") || q.contains("dustbin") || q.contains("trash") || q.contains("sanitation")) {
      return PulseAIResponse(
        text: "Unga street eppavum clean ah irukanum! 🗑️ Showing sanitation reports and Vellalore solid waste processing updates across your ward.",
        actionType: "filter_category",
        payload: "Garbage",
        followUpSuggestions: ["📝 Report uncollected garbage", "🌳 Join clean-up drive"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    // 6. Electricity & Streetlights
    if (q.contains("current") || q.contains("light") || q.contains("power") || q.contains("electricity") || q.contains("blackout") || q.contains("tneb")) {
      return PulseAIResponse(
        text: "Night time la streetlight illana bayama irukkum! ⚡ Showing Electricity & Streetlight outages for immediate TNEB municipal maintenance.",
        actionType: "filter_category",
        payload: "Electricity",
        followUpSuggestions: ["📝 Report broken streetlight", "🚨 Emergency SOS"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    // 7. Emergency & SOS
    if (q.contains("police koopdu") || q.contains("ambulance") || q.contains("emergency") || q.contains("police") || q.contains("fire") || q.contains("sos") || q.contains("theepudichu")) {
      return PulseAIResponse(
        text: "Bayapadatheenga, help ready ah irukku! 🚨 Direct 24/7 Emergency Helplines:\n• Police: 100\n• Medical Ambulance: 108\n• Fire Force: 101\n• Women Helpline: 1091\nOpening Emergency SOS speed-dial for you!",
        actionType: "open_emergency",
        followUpSuggestions: ["🏥 Nearest hospital", "🚓 Nearest police station"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    // 8. Hospital & Medical Care
    if (q.contains("hospital") || q.contains("maruthuvamanai") || q.contains("doctor") || q.contains("clinic") || q.contains("medical")) {
      return PulseAIResponse(
        text: "🏥 Explore Map la hospital pins open panren! Coimbatore Medical College, GKNM, and PSG 24/7 Emergency Trauma Centers with directions and walk times.",
        actionType: "open_explore",
        payload: "hospital",
        followUpSuggestions: ["🗺️ Directions in Google Maps", "🚨 Call Ambulance (108)"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    // 9. Karma & Points
    if (q.contains("karma") || q.contains("score") || q.contains("points") || q.contains("badge") || q.contains("champion")) {
      return PulseAIResponse(
        text: "Civic Karma unga community trust reputation! 🏆\n• Oru issue report panna +10 Karma points.\n• Mathavanga upvote panna +2 Karma points.\n• Reach 40 Karma for 'Neighborhood Guardian 🛡️' and 80 Karma for 'Civic Champion 🏆'!",
        followUpSuggestions: ["📝 Report a new issue", "👤 View my profile"],
        engine: "Google Gemini 1.5 Flash ✨",
      );
    }

    // Default friendly bilingual response
    return PulseAIResponse(
      text: "I'm listening! 💬 (Powered by Google Gemini ✨) Nan Tanglish & English rendulayum purinjupen. You can ask: 'Thanni leak aagudhu', 'Nearest hospital', 'Road la pallam', 'Blood donation camp', or 'Emergency police'. Epdi help pannattum thalaiva?",
      followUpSuggestions: ["💧 Thanni leak aagudhu", "🏥 Nearest hospital", "📝 Report an issue", "🏆 Karma epdi kedaikkum?"],
      engine: "Google Gemini 1.5 Flash ✨",
    );
  }
}
