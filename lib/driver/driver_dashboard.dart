// Premium Driver Dashboard (Starter Template)
// Replace dummy data with your APIs later.

import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/driver/driver_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please turn on GPS to continue")),
      );

      await Geolocator.openLocationSettings();
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // User denied
    if (permission == LocationPermission.denied) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission is required")),
      );
      return;
    }

    // Permanently denied
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Location Permission"),
          content: const Text(
            "Please allow location permission from app settings.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );

      return;
    }

    // Permission granted
    _getDriverLocation();
  }

  Future<void> _getDriverLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print("Driver Latitude : ${position.latitude}");
      print("Driver Longitude: ${position.longitude}");

      // Later API call:
      // await updateDriverLocation(
      //   position.latitude,
      //   position.longitude,
      // );
    } catch (e) {
      print("Location Error: $e");
    }
  }

  bool tripStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FC),
      drawer: const DriverSidebar(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff2563EB),
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(.82),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.12),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Rajesh Kumar",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            const Icon(
                              Icons.directions_bus_rounded,
                              color: Colors.white70,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "BUS-01 • Patna → School",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.9),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                        SizedBox(width: 5),
                        Text(
                          "ONLINE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(child: _StatusCard(Icons.gps_fixed, "GPS", "ON")),
                SizedBox(width: 8),

                Expanded(child: _StatusCard(Icons.speed, "Speed", "38")),
                SizedBox(width: 8),

                Expanded(child: _StatusCard(Icons.people, "Students", "42")),
                SizedBox(width: 8),

                Expanded(child: _StatusCard(Icons.route, "Route", "12")),
              ],
            ),
            const SizedBox(height: 20),
            const CurrentTripCard(),
            const SizedBox(height: 16),

            const TodayTimingCard(),
            const SizedBox(height: 16),

            const StudentPickupCard(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tripStarted
                      ? Colors.red
                      : const Color(0xff2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    tripStarted = !tripStarted;
                  });
                },
                icon: Icon(
                  tripStarted ? Icons.stop_circle : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                label: Text(
                  tripStarted ? "END TRIP" : "START TRIP",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),

            const _SummaryCard(),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatusCard(this.icon, this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(.10),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Trips"), Text("2")],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Distance"), Text("38 km")],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Last Sync"), Text("10:42 AM")],
            ),
          ],
        ),
      ),
    );
  }
}

class CurrentTripCard extends StatelessWidget {
  const CurrentTripCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_bus, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                "Current Trip",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _tripRow(Icons.route, "Route", "Patna → School"),
          _tripRow(Icons.location_on, "Next Stop", "Kankarbagh"),
          _tripRow(Icons.access_time, "ETA", "08:35 AM"),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.green, size: 10),
                SizedBox(width: 6),
                Text(
                  "Running",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class TodayTimingCard extends StatelessWidget {
  const TodayTimingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: const [
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                "Today's Timing",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 14),

          _TimingRow("Start Time", "07:20 AM"),
          Divider(),
          _TimingRow("Current Time", "08:05 AM"),
          Divider(),
          _TimingRow("Expected End", "09:10 AM"),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  final String title;
  final String value;

  const _TimingRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class StudentPickupCard extends StatelessWidget {
  const StudentPickupCard({super.key});

  @override
  Widget build(BuildContext context) {
    const picked = 32;
    const total = 42;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                "Today's Pickup",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),

          LinearProgressIndicator(
            value: picked / total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: Colors.grey.shade200,
            color: AppColors.primary,
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _PickupItem("Picked", "32", Colors.green),
              _PickupItem("Remaining", "10", Colors.orange),
              _PickupItem("Total", "42", AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickupItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _PickupItem(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(title),
      ],
    );
  }
}
