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

    // ==========================================
    // 1. TANGLISH & TAMIL GREETINGS / SMALL TALK
    // ==========================================
    if (q.contains("vanakkam") || q.contains("eppadi irukinga") || q.contains("epdi irukinga") || q.contains("nalama") || q.contains("saptacha") || q.contains("macha") || q.contains("thalaiva")) {
      return PulseAIResponse(
        text: "Vanakkam thalaiva! 😊 Romba nalla irukken! I am PulseAI, unga Coimbatore neighborhood buddy. Unga area la enna vishayam? Road, water, illana streetlight issues ethavathu report pannanuma?",
        followUpSuggestions: ["💧 Thanni leak aagudhu", "🚧 Road la pallam irukku", "🏥 Hospital enga irukku?", "🏆 Karma epdi kedaikkum?"],
      );
    }

    if (q.contains("nandri") || q.contains("romba thanks") || q.contains("super bro") || q.contains("mass") || q.contains("kalakkuringa") || q.contains("sema")) {
      return PulseAIResponse(
        text: "Romba nandri! 🌟 Unga support oda namma Coimbatore ah innum clean and safe ah vechupom. Vera ethavathu help thevaiya thalaiva?",
        followUpSuggestions: ["📅 Events parkanum", "📝 Complaint podanum", "🗺️ Explore map"],
      );
    }

    // ==========================================
    // 2. ENGLISH GREETINGS & SMALL TALK
    // ==========================================
    if (q.contains("hello") || q.contains("hi") || q.contains("hey") || q.startsWith("morning") || q.contains("good morning") || q.contains("good evening")) {
      return PulseAIResponse(
        text: "Vanakkam & Hello there! 😊 It's wonderful to connect with you. I'm PulseAI, your friendly civic companion in Coimbatore. How are things in your neighborhood today?",
        followUpSuggestions: ["💧 Any water issues?", "🚧 Report road damage", "🏥 Nearest hospital", "🏆 How does karma work?"],
      );
    }

    if (q.contains("how are you") || q.contains("how r u") || q.contains("how do you do") || q.contains("whats up")) {
      return PulseAIResponse(
        text: "I'm doing fantastic, thank you for asking! ⚡ I've been monitoring ward reports across Gandhipuram, RS Puram, and Peelamedu. 88% resolution rate this month! How can I help you today?",
        followUpSuggestions: ["📢 Check live feed", "🌳 Upcoming events", "🚑 Emergency helplines"],
      );
    }

    if (q.contains("who are you") || q.contains("what can you do") || q.contains("your name") || q.contains("help me") || q.contains("ne yar") || q.contains("nee yaaru")) {
      return PulseAIResponse(
        text: "I'm PulseAI! 🤖 Think of me as your personal civic co-pilot (bilingual in English & Tanglish). I can help you report road potholes or water leaks, locate nearby 24/7 hospitals and police stations, guide you to blood donation events, or explain your Civic Karma score. Just speak or type anytime!",
        followUpSuggestions: ["📝 Report an issue", "🗺️ Explore map", "🏆 Check my karma"],
      );
    }

    if (q.contains("thank") || q.contains("thx") || q.contains("awesome") || q.contains("great") || q.contains("good job") || q.contains("nice")) {
      return PulseAIResponse(
        text: "You're so welcome! 🌟 Active citizens like you make Coimbatore cleaner, safer, and better every day. I'm always right here if you need anything else!",
        followUpSuggestions: ["📅 Explore community drives", "📍 Find nearby amenities"],
      );
    }

    // ==========================================
    // 3. TANGLISH & ENGLISH WATER ISSUES
    // ==========================================
    if (q.contains("thanni") || q.contains("thani") || q.contains("kudineer") || q.contains("water") || q.contains("leak") || q.contains("pipe") || q.contains("drain") || q.contains("saakadai") || q.contains("siruvani") || q.contains("twad")) {
      return PulseAIResponse(
        text: "Aiyayo, thanni waste aaga koodathu! 💧 Siruvani Water Supply Board & TWAD team actively monitor leaks in Coimbatore. Feed ah filter panni water issues kaatren, illana photo eduthu pudhu report submit pannunga!",
        actionType: "filter_category",
        payload: "Water",
        followUpSuggestions: ["📝 Report water leak", "🗺️ Water boards on map"],
      );
    }

    // ==========================================
    // 4. TANGLISH & ENGLISH ROAD & POTHOLES
    // ==========================================
    if (q.contains("pallam") || q.contains("road seri illa") || q.contains("thar road") || q.contains("vandi poga mudiyala") || q.contains("road") || q.contains("pothole") || q.contains("traffic") || q.contains("footpath") || q.contains("street") || q.contains("ootai")) {
      return PulseAIResponse(
        text: "Road la pallam iruntha safety risk! 🚧 Road & Infrastructure hazards near Gandhipuram and Peelamedu feed la filter panren. Let's get it repaired fast!",
        actionType: "filter_category",
        payload: "Road",
        followUpSuggestions: ["📝 Report road damage", "🚗 View on Explore map"],
      );
    }

    // ==========================================
    // 5. TANGLISH & ENGLISH GARBAGE & SANITATION
    // ==========================================
    if (q.contains("kuppai") || q.contains("naatham") || q.contains("clean panala") || q.contains("garbage") || q.contains("waste") || q.contains("clean") || q.contains("dustbin") || q.contains("trash") || q.contains("sanitation")) {
      return PulseAIResponse(
        text: "Unga street eppavum clean ah irukanum! 🗑️ Showing sanitation reports and Vellalore solid waste processing updates across your ward.",
        actionType: "filter_category",
        payload: "Garbage",
        followUpSuggestions: ["📝 Report uncollected garbage", "🌳 Join clean-up drive"],
      );
    }

    // ==========================================
    // 6. TANGLISH & ENGLISH ELECTRICITY / POWER
    // ==========================================
    if (q.contains("current poiduchu") || q.contains("light eriyala") || q.contains("kambam") || q.contains("power cut") || q.contains("dark ah irukku") || q.contains("light") || q.contains("power") || q.contains("electricity") || q.contains("blackout") || q.contains("wire") || q.contains("tneb")) {
      return PulseAIResponse(
        text: "Night time la streetlight illana bayama irukkum! ⚡ Showing Electricity & Streetlight outages for immediate TNEB municipal maintenance.",
        actionType: "filter_category",
        payload: "Electricity",
        followUpSuggestions: ["📝 Report broken streetlight", "🚨 Emergency SOS"],
      );
    }

    // ==========================================
    // 7. TANGLISH & ENGLISH EMERGENCY & SOS
    // ==========================================
    if (q.contains("police koopdu") || q.contains("ambulance venum") || q.contains("theepudichu") || q.contains("emergency") || q.contains("police") || q.contains("ambulance") || q.contains("fire") || q.contains("sos") || q.contains("danger") || q.contains("accident") || q.contains("help venum")) {
      return PulseAIResponse(
        text: "Bayapadatheenga, help ready ah irukku! 🚨 24/7 Emergency Helplines:\n• Police: 100\n• Medical Ambulance: 108\n• Fire & Rescue: 101\n• Women Helpline: 1091\nOpening the Emergency SOS speed-dial for you!",
        actionType: "open_emergency",
        followUpSuggestions: ["🏥 Nearest hospital", "🚓 Nearest police station"],
      );
    }

    // ==========================================
    // 8. TANGLISH & ENGLISH HOSPITALS ON MAP
    // ==========================================
    if (q.contains("hospital enga") || q.contains("maruthuvamanai") || q.contains("doctor theva") || q.contains("aduthula hospital") || q.contains("hospital") || q.contains("medical") || q.contains("doctor") || q.contains("clinic") || q.contains("health center") || q.contains("pharmacy")) {
      return PulseAIResponse(
        text: "🏥 Explore Map la hospital pins open panren! Coimbatore Medical College, GKNM, and PSG 24/7 Emergency Trauma Centers with directions and walk times.",
        actionType: "open_explore",
        payload: "hospital",
        followUpSuggestions: ["🗺️ Directions in Google Maps", "🚨 Call Ambulance (108)"],
      );
    }

    // ==========================================
    // 9. TANGLISH & ENGLISH POLICE STATIONS ON MAP
    // ==========================================
    if (q.contains("police station enga") || q.contains("kaaval nilayam") || q.contains("station enga") || q.contains("police station") || q.contains("cop") || q.contains("patrol") || q.contains("commissioner") || q.contains("station")) {
      return PulseAIResponse(
        text: "🚓 Showing local Police Stations including RS Puram B2, Gandhipuram Law & Order, and City Commissionerate on the Explore map.",
        actionType: "open_explore",
        payload: "police",
        followUpSuggestions: ["🗺️ Open in Google Maps", "🚨 Call Police (100)"],
      );
    }

    // ==========================================
    // 10. TANGLISH & ENGLISH COMMUNITY EVENTS & DRIVES
    // ==========================================
    if (q.contains("maram nadanum") || q.contains("blood donation") || q.contains("ratham thaanam") || q.contains("event irukka") || q.contains("event") || q.contains("camp") || q.contains("plantation") || q.contains("drive") || q.contains("meetup") || q.contains("volunteer") || q.contains("tree") || q.contains("blood")) {
      return PulseAIResponse(
        text: "Romba nalla vishayam! 📅 Opening the Civic Events tab. You can RSVP for the Mega Blood Donation Camp at CMC or the 1000 Trees Plantation Drive at VOC Park!",
        actionType: "open_events",
        followUpSuggestions: ["🌳 Host a new drive", "👥 Check attendees"],
      );
    }

    // ==========================================
    // 11. TANGLISH & ENGLISH REPORTING
    // ==========================================
    if (q.contains("complaint pannanum") || q.contains("report podanum") || q.contains("photo upload") || q.contains("issue register") || q.contains("report") || q.contains("submit") || q.contains("new issue") || q.contains("file") || q.contains("complaint") || q.contains("photo")) {
      return PulseAIResponse(
        text: "Kandippa! 📝 Opening the Incident Report form. You can attach photo proof, auto-detect GPS pin, choose priority, and earn +10 Civic Karma points!",
        actionType: "open_report",
        followUpSuggestions: ["📷 Attach photo proof", "📍 Adjust pin on map"],
      );
    }

    // ==========================================
    // 12. TANGLISH & ENGLISH KARMA / POINTS
    // ==========================================
    if (q.contains("karma na enna") || q.contains("points epdi varum") || q.contains("badge epdi") || q.contains("karma") || q.contains("score") || q.contains("points") || q.contains("badge") || q.contains("rank") || q.contains("champion")) {
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
