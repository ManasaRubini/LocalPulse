import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import 'location_picker_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  bool anonymous = false;
  String? selectedCategory;

  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  Position? currentPosition;

  double latitude = 0;
  double longitude = 0;

  String currentAddress = "Getting current location...";
  bool loadingLocation = true;

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    try {
      currentPosition =
          await ApiService.getCurrentLocation();

      latitude = currentPosition!.latitude;
      longitude = currentPosition!.longitude;

      List<Placemark> places =
          await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      Placemark place = places.first;

      currentAddress =
          "${place.street}, ${place.locality}, ${place.administrativeArea}";
    } catch (e) {
      currentAddress = "Unable to fetch location";
    }

    setState(() {
      loadingLocation = false;
    });
  }

  Future<void> pickFromGallery() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> pickFromCamera() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> changeLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: latitude,
          initialLongitude: longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        latitude = result["latitude"];
        longitude = result["longitude"];
        currentAddress = result["address"];
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
  Widget buildCategoryChip(
  String title,
  IconData icon,
) {
  final selected = selectedCategory == title;

  return GestureDetector(
    onTap: () {
      setState(() {
        selectedCategory = title;
      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xff7B61FF)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? const Color(0xff7B61FF)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Icon(
            icon,
            color: selected
                ? Colors.white
                : Colors.black87,
          ),

          const SizedBox(width: 8),

          Text(
            title,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Report New Issue",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [

          //==================================
          // TITLE CARD
          //==================================

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 12,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "Issue Title",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText:
                        "Enter issue title",
                    prefixIcon: const Icon(
                      Icons.report_problem,
                    ),
                    filled: true,
                    fillColor:
                        Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          //==================================
          // DESCRIPTION
          //==================================

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 12,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "Description",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller:
                      descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        "Describe the issue...",
                    filled: true,
                    fillColor:
                        Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          //==================================
          // CATEGORY
          //==================================
          Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.05),
        blurRadius: 12,
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Category",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),

      const SizedBox(height: 18),

      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [

          buildCategoryChip(
            "Road",
            Icons.directions_car,
          ),

          buildCategoryChip(
            "Water",
            Icons.water_drop,
          ),

          buildCategoryChip(
            "Electricity",
            Icons.bolt,
          ),

          buildCategoryChip(
            "Safety",
            Icons.security,
          ),

          buildCategoryChip(
            "Sanitation",
            Icons.delete,
          ),
        ],
      ),
    ],
  ),
),

const SizedBox(height: 20),

//==================================
// IMAGE
//==================================

Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.05),
        blurRadius: 12,
      )
    ],
  ),

  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Upload Photo",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),

      const SizedBox(height: 16),

      Row(
        children: [

          Expanded(
            child: ElevatedButton.icon(
              onPressed: pickFromGallery,
              icon: const Icon(Icons.photo),
              label: const Text("Gallery"),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xff7B61FF),
                foregroundColor: Colors.white,
                minimumSize:
                    const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: pickFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Camera"),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.orange,
                foregroundColor: Colors.white,
                minimumSize:
                    const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 18),

      if (selectedImage != null)

        ClipRRect(
          borderRadius:
              BorderRadius.circular(18),
          child: Image.file(
            selectedImage!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        )
      else

        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: const Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [

              Icon(
                Icons.image_outlined,
                size: 60,
                color: Colors.grey,
              ),

              SizedBox(height: 12),

              Text(
                "No image selected",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
    ],
  ),
),

const SizedBox(height: 20),

//==================================
// LOCATION
//==================================

Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.05),
        blurRadius: 12,
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Issue Location",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),

      const SizedBox(height: 16),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Text(
              loadingLocation
                  ? "Fetching current location..."
                  : currentAddress,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 18),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              loadingLocation ? null : changeLocation,
          icon: const Icon(Icons.edit_location_alt),
          label: const Text("Change Location"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff7B61FF),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 20),

//==================================
// ANONYMOUS
//==================================

Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.05),
        blurRadius: 12,
      )
    ],
  ),
  child: SwitchListTile(
    value: anonymous,
    activeColor: const Color(0xff7B61FF),
    contentPadding: EdgeInsets.zero,

    title: const Text(
      "Post Anonymously",
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    subtitle: const Text(
      "Your identity will remain hidden.",
    ),

    onChanged: (value) {
      setState(() {
        anonymous = value;
      });
    },
  ),
),

const SizedBox(height: 30),

//==================================
// SUBMIT BUTTON
//==================================

SizedBox(
  height: 58,
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.send),
    label: const Text(
      "Submit Report",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff7B61FF),
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    onPressed: () async {

      if (titleController.text.isEmpty ||
          descriptionController.text.isEmpty ||
          selectedCategory == null) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please fill all required fields",
            ),
          ),
        );

        return;
      }
      
      bool success = await ApiService.createIssue(
        title: titleController.text,
        description: descriptionController.text,
        category: selectedCategory!,
        location: currentAddress,
        latitude: latitude,
        longitude: longitude,
        anonymous: anonymous,
        userName:
            anonymous ? "Anonymous" : "Manass",
        imageFile: selectedImage,
      );

      if (!mounted) return;

      if (success) {

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
            title: const Row(
              children: [

                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),

                SizedBox(width: 10),

                Text("Success"),
              ],
            ),
            content: const Text(
              "Your issue has been submitted successfully.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog

                  Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Submission Failed",
            ),
          ),
        );

      }
    },
  ),
),

const SizedBox(height: 30),
        ],
      ),
    );
  }
}
