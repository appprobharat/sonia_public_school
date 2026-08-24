import 'dart:convert';
import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GeoAttendanceTeacher extends StatefulWidget {
  const GeoAttendanceTeacher({super.key});

  @override
  State<GeoAttendanceTeacher> createState() => _GeoAttendanceTeacherState();
}

class _GeoAttendanceTeacherState extends State<GeoAttendanceTeacher> {
  Position? position;

  bool isLoading = false;
  bool loadingLocation = true;

  double distance = 0;
  bool isInside = false;

  double schoolLat = 0;
  double schoolLng = 0;
  double radius = 0;

  String attendanceStatus = "not-marked";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkPermission();
      getLocation();
      fetchSchoolLocation();
    });
  }

  /// GET SCHOOL LOCATION FROM API
  Future<void> fetchSchoolLocation() async {
    try {
      final response = await ApiService.post(context, "/teacher/get-location");

      if (response == null) {
        setState(() => loadingLocation = false);
        return;
      }

      final data = jsonDecode(response.body);

      attendanceStatus = data["status"];

      schoolLat = double.parse(data["school"]["Latitude"]);
      schoolLng = double.parse(data["school"]["Longitude"]);
      radius = double.parse(data["school"]["Radius"].toString());

      debugPrint("School Lat: $schoolLat");
      debugPrint("School Lng: $schoolLng");
      debugPrint("Radius: $radius");

      await getLocation();
    } catch (e) {
      debugPrint("Location API error: $e");
      setState(() => loadingLocation = false);
    }
  }

  /// LOCATION PERMISSION
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location service")),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission permanently denied")),
      );
      return false;
    }

    return true;
  }

  /// GET CURRENT LOCATION
  Future<void> getLocation() async {
    bool hasPermission = await checkPermission();

    if (!hasPermission) {
      setState(() => loadingLocation = false);
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    /// fake gps detection
    if (pos.isMocked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fake GPS detected")));
      setState(() => loadingLocation = false);
      return;
    }

    /// accuracy check
    if (pos.accuracy > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Low GPS accuracy, move outside")),
      );
    }

    double d = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      schoolLat,
      schoolLng,
    );

    debugPrint("Teacher Lat: ${pos.latitude}");
    debugPrint("Teacher Lng: ${pos.longitude}");
    debugPrint("Distance: $d");

    setState(() {
      position = pos;
      distance = d;
      isInside = d <= radius;
      loadingLocation = false;
    });
  }

  /// MARK ATTENDANCE
  Future<void> markAttendance() async {
    if (attendanceStatus == "marked") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance already marked")),
      );
      return;
    }

    if (!isInside) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are outside school campus")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        context,
        "/teacher/mark-attendance",
        body: {
          "latitude": position!.latitude,
          "longitude": position!.longitude,
          "distance": distance,
        },
      );

      if (response != null) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Attendance marked")),
          );

          setState(() {
            attendanceStatus = "marked";
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Attendance failed")),
          );
        }
      }
    } catch (e) {
      debugPrint("Attendance error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }

    setState(() => isLoading = false);
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Attendance"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                loadingLocation = true;
              });
              await getLocation();
            },
          ),
        ],
      ),

      body: loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await getLocation();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  /// STATUS BANNER
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isInside
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isInside ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isInside ? Icons.verified : Icons.location_off,
                          size: 42,
                          color: isInside ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isInside
                              ? "You are inside school campus"
                              : "You are outside school radius",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isInside ? Colors.green : Colors.red,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (!isInside)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              "Move closer to school and refresh location",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  if (attendanceStatus == "marked")
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Attendance is already marked for today.",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 18),

                  /// LOCATION DETAILS CARD
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.my_location, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                "Your Current Location",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "${position?.latitude.toStringAsFixed(5)}, ${position?.longitude.toStringAsFixed(5)}",
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 14),

                          const Divider(),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.social_distance, size: 18),
                                  SizedBox(width: 6),
                                  Text("Distance from School"),
                                ],
                              ),

                              Text(
                                "${distance.toStringAsFixed(2)} m",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// RADIUS ROW
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.circle_outlined, size: 18),
                                  SizedBox(width: 6),
                                  Text("Allowed Radius"),
                                ],
                              ),

                              Text(
                                "$radius m",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            "Pull down or press refresh icon to update location",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// ATTENDANCE BUTTON
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed:
                          (!isInside ||
                              isLoading ||
                              attendanceStatus == "marked")
                          ? null
                          : markAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              attendanceStatus == "marked"
                                  ? "ATTENDANCE MARKED"
                                  : "MARK ATTENDANCE",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }
}
