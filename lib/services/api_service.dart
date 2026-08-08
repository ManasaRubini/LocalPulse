
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/event_model.dart';

class ApiService {
  static const String baseUrl = "https://my-backend-4hfj.onrender.com";

  // ==========================
  // GET ISSUES
  // ==========================
  static Future<List<dynamic>> getIssues() async {
    final response = await http.get(
      Uri.parse('$baseUrl/issues/all'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load issues");
  }

  // ==========================
  // CREATE ISSUE
  // ==========================
  static Future<bool> createIssue({
  required String title,
  required String description,
  required String category,
  required String location,
  required double latitude,
  required double longitude,
  required bool anonymous,
  required String userName,
  File? imageFile,
}) async {


  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/issues/create'),
  );

  request.fields['title'] = title;
  request.fields['description'] = description;
  request.fields['category'] = category;
  request.fields['location'] = location;
  request.fields['anonymous'] = anonymous.toString();
  request.fields['user_name'] = userName;

  request.fields['latitude'] =
    latitude.toString();

  request.fields['longitude'] =
      longitude.toString();
  if (imageFile != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );
  }

  final response = await request.send();

  return response.statusCode == 200;
}

  // ==========================
  // UPVOTE ISSUE
  // ==========================
  static Future<void> upvoteIssue(int issueId) async {
    await http.put(
      Uri.parse('$baseUrl/issues/upvote/$issueId'),
    );
  }

  // ==========================
  // GET COMMENTS
  // ==========================
  static Future<List<dynamic>> getComments(
    int issueId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/comments/$issueId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  // ==========================
  // ADD COMMENT
  // ==========================
  static Future<void> addComment({
    required int issueId,
    required String comment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/comments/add'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "issue_id": issueId,
        "user_name": "Anonymous",
        "comment": comment,
      }),
    );

    print(response.statusCode);
    print(response.body);
  }

  // ==========================
  // GET NEARBY EVENTS
  // ==========================
  static Future<List<Event>> getNearbyEvents() async {
  final response = await http.get(
    Uri.parse('$baseUrl/events/nearby'),
  );

  print(response.body); // <-- Add this

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);

    return data.map((e) => Event.fromJson(e)).toList();
  }

  throw Exception("Failed to load events");
}
  // ==========================
  // GET EVENT DETAILS
  // ==========================
  static Future<Map<String, dynamic>> getEventDetails(
    int eventId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$eventId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load event details");
  }

  // ==========================
  // CREATE EVENT
  // ==========================
  static Future<bool> createEvent({
    required String title,
    required String description,
    required String category,
    required String locationName,
    required double latitude,
    required double longitude,
    required String startTime,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/create'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "title": title,
        "description": description,
        "category": category,
        "location_name": locationName,
        "latitude": latitude,
        "longitude": longitude,
        "start_time": startTime,
      }),
    );

    return response.statusCode == 200;
  }
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services disabled');
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    return await Geolocator.getCurrentPosition();
  }
  // ==========================
// GET NEARBY SERVICES (NEW)
// ==========================
static Future<List<dynamic>> getNearbyServices({
  required String type,
  required double lat,
  required double lon,
}) async {
  final response = await http.get(
    Uri.parse(
      '$baseUrl/nearby?type=$type&lat=$lat&lon=$lon',
    ),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception("Failed to load nearby services");
}
}
