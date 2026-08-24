import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

enum StopStatus { completed, current, pending }

class RouteDetailsPage extends StatelessWidget {
  const RouteDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Route Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            /// Header
            RouteHeaderCard(),

            SizedBox(height: 18),

            /// Current Stop
            CurrentStopCard(),

            SizedBox(height: 18),

            /// Route Information
            RouteInfoRow(),

            SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Route Timeline",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 14),

            const RouteTimeline(),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class RouteTimeline extends StatelessWidget {
  const RouteTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),
      child: const Column(
        children: [
          RouteStopTile(
            stopName: "Patna Junction",
            time: "07:35 AM",
            status: StopStatus.completed,
          ),

          RouteStopTile(
            stopName: "Kankarbagh",
            time: "07:55 AM",
            status: StopStatus.completed,
          ),

          RouteStopTile(
            stopName: "Rajendra Nagar",
            time: "08:20 AM",
            status: StopStatus.current,
          ),

          RouteStopTile(
            stopName: "Boring Road",
            time: "08:40 AM",
            status: StopStatus.pending,
          ),

          RouteStopTile(
            stopName: "SONIA Public School",
            time: "09:00 AM",
            status: StopStatus.pending,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class RouteStopTile extends StatelessWidget {
  final String stopName;
  final String time;
  final StopStatus status;
  final bool isLast;

  const RouteStopTile({
    super.key,
    required this.stopName,
    required this.time,
    required this.status,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case StopStatus.completed:
        color = Colors.green;
        icon = Icons.check;
        label = "Completed";
        break;

      case StopStatus.current:
        color = AppColors.primary;
        icon = Icons.navigation;
        label = "Current Stop";
        break;

      case StopStatus.pending:
        color = Colors.grey;
        icon = Icons.location_on;
        label = "Pending";
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white, size: 15),
                ),

                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Text(
              time,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteHeaderCard extends StatelessWidget {
  const RouteHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Morning Route",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "BUS-01",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withOpacity(.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                    SizedBox(width: 5),
                    Text(
                      "ACTIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Patna ➜ SONIA Public School",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: .35,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _HeaderChip(Icons.route, "18 KM")),
              const SizedBox(width: 10),
              Expanded(child: _HeaderChip(Icons.access_time, "35 Min")),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CurrentStopCard extends StatelessWidget {
  const CurrentStopCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Current Stop",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),

                SizedBox(height: 2),

                Text(
                  "Kankarbagh",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),

                SizedBox(height: 3),

                Text(
                  "Next • Rajendra Nagar",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("ETA", style: TextStyle(fontSize: 10, color: Colors.grey)),
                SizedBox(height: 2),
                Text(
                  "08:25",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RouteInfoRow extends StatelessWidget {
  const RouteInfoRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: RouteInfoCard(Icons.location_on, "Patna")),

        SizedBox(width: 8),

        Expanded(child: RouteInfoCard(Icons.school, "School")),

        SizedBox(width: 8),

        Expanded(child: RouteInfoCard(Icons.route, "18 km")),

        SizedBox(width: 8),

        Expanded(child: RouteInfoCard(Icons.access_time, "35m")),
      ],
    );
  }
}

class RouteInfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const RouteInfoCard(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),

          const SizedBox(height: 8),

          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
