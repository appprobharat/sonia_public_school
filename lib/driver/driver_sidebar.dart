import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/driver/bus_information.dart';
import 'package:sonia_public_school/driver/route_detail.dart';
import 'package:sonia_public_school/driver/students.dart';
import 'package:flutter/material.dart';

class DriverSidebar extends StatelessWidget {
  const DriverSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xffF5F7FB),
      child: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 30),
                    ),
                  ),

                  const SizedBox(width: 15),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rajesh Kumar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          "Bus Driver",
                          style: TextStyle(color: Colors.white70),
                        ),

                        SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 16,
                            ),

                            SizedBox(width: 5),

                            Text(
                              "BUS-01",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  menu(Icons.dashboard, "Dashboard", () {}),

                  menu(
                    Icons.alt_route,
                    "Route Details",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RouteDetailsPage(),
                      ),
                    ),
                  ),

                  menu(
                    Icons.groups,
                    "Students",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentsPage()),
                    ),
                  ),

                  menu(
                    Icons.directions_bus,
                    "Bus Information",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BusInformationPage(),
                      ),
                    ),
                  ),

                  menu(Icons.history, "Trip History", () {}),

                  const Divider(height: 25),

                  menu(Icons.logout, "Logout", () {}, color: Colors.red),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget menu(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary.withOpacity(.10),
        child: Icon(
          icon,
          color: color == Colors.red ? Colors.red : AppColors.primary,
        ),
      ),

      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),

      trailing: const Icon(Icons.arrow_forward_ios, size: 15),

      onTap: onTap,
    );
  }
}
