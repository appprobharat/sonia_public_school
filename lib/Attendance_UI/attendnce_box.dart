import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class AttendanceCard extends StatelessWidget {
  final String title;
  final String place;
  final String status;
  final IconData icon;

  const AttendanceCard({
    Key? key,
    this.title = "Today's Attendance",
    this.place = "School",
    this.status = "Present",
    this.icon = Icons.apartment,
  }) : super(key: key);

  String getFormattedStatus() {
    String s = status.toLowerCase().trim();

    if (s == "not_mark") {
      return "Not Mark";
    }

    return status;
  }

  Color getStatusColor(String s) {
    switch (status.toLowerCase()) {
      case "present":
        return Colors.green;
      case "absent":
        return Colors.red;
      case "not marked":
        return Colors.grey;
      case "Halfday":
        return Colors.blue;
      case "leave":
        return Colors.yellow;
      case "holiday":
        return Colors.black;
      default:
        return Colors.grey;
      // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    String finalStatus = getFormattedStatus();
    Color statusColor = getStatusColor(finalStatus);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  place,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    finalStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
