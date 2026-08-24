import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class BusInformationPage extends StatelessWidget {
  const BusInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Bus Information",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            /// Header
            BusHeaderCard(),

            SizedBox(height: 18),

            /// Vehicle Details
            VehicleInfoCard(),

            SizedBox(height: 18),

            const SizedBox(height: 18),

            const StaffInfoCard(),

            const SizedBox(height: 18),

            const RouteInformationCard(),

            const SizedBox(height: 18),

            const BusStatisticsCard(),
          ],
        ),
      ),
    );
  }
}

class BusHeaderCard extends StatelessWidget {
  const BusHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(.82)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BUS-01",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      "Patna ➜ SONIA Public School",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  color: Colors.green.withOpacity(.18),
                  borderRadius: BorderRadius.circular(20),
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

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: _TopInfo(Icons.people, "52", "Capacity")),

              Expanded(child: _TopInfo(Icons.route, "18 KM", "Distance")),

              Expanded(child: _TopInfo(Icons.access_time, "35 Min", "ETA")),
            ],
          ),
        ],
      ),
    );
  }
}

class VehicleInfoCard extends StatelessWidget {
  const VehicleInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.directions_bus, color: AppColors.primary),

              SizedBox(width: 8),

              Text(
                "Vehicle Information",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Row(
            children: [
              Expanded(child: InfoTile("Registration", "BR01AB1234")),

              SizedBox(width: 12),

              Expanded(child: InfoTile("Model", "Tata Starbus")),
            ],
          ),

          const SizedBox(height: 12),

          const Row(
            children: [
              Expanded(child: InfoTile("Capacity", "52 Students")),

              SizedBox(width: 12),

              Expanded(child: InfoTile("Color", "Yellow")),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;

  const _TopInfo(this.icon, this.value, this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const InfoTile(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class StaffInfoCard extends StatelessWidget {
  const StaffInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.people_alt_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                "Driver & Helper",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const StaffTile(
            icon: Icons.person,
            title: "Driver",
            name: "Rajesh Kumar",
            phone: "9876543210",
          ),

          const Divider(height: 24),

          const StaffTile(
            icon: Icons.person_outline,
            title: "Helper",
            name: "Ramesh Kumar",
            phone: "9876543211",
          ),
        ],
      ),
    );
  }
}

class StaffTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String name;
  final String phone;

  const StaffTile({
    super.key,
    required this.icon,
    required this.title,
    required this.name,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withOpacity(.12),
          child: Icon(icon, color: AppColors.primary),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),

              const SizedBox(height: 2),

              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                phone,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.call, color: Colors.green),
        ),
      ],
    );
  }
}

class RouteInformationCard extends StatelessWidget {
  const RouteInformationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.route, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                "Today's Route",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Row(
            children: [
              Expanded(child: InfoTile("Start", "07:30 AM")),

              SizedBox(width: 12),

              Expanded(child: InfoTile("End", "03:30 PM")),
            ],
          ),

          const SizedBox(height: 12),

          const Row(
            children: [
              Expanded(child: InfoTile("Distance", "18 KM")),

              SizedBox(width: 12),

              Expanded(child: InfoTile("Stops", "12")),
            ],
          ),
        ],
      ),
    );
  }
}

class BusStatisticsCard extends StatelessWidget {
  const BusStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                "Bus Statistics",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Row(
            children: [
              Expanded(child: _StatItem("52", "Capacity")),

              Expanded(child: _StatItem("38", "Occupied")),

              Expanded(child: _StatItem("14", "Available")),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.73,
              minHeight: 6,
              backgroundColor: Color(0xffE5E7EB),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String title;

  const _StatItem(this.value, this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 3),

        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
