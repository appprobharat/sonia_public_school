import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ParentBusTrackingPage extends StatefulWidget {
  const ParentBusTrackingPage({super.key});

  @override
  State<ParentBusTrackingPage> createState() => _ParentBusTrackingPageState();
}

class _ParentBusTrackingPageState extends State<ParentBusTrackingPage> {
  final MapController mapController = MapController();

  LatLng busLocation = const LatLng(28.4089, 77.3178);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// GOOGLE MAP
          FlutterMap(
            mapController: mapController,
            options: MapOptions(initialCenter: busLocation, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.soniapublicschool.apppro",
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: busLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// TOP CHILD CARD
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  ),

                  const SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Rahul Kumar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        "Class 5 - Section A",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Bus 12",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// BOTTOM BUS INFO PANEL
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),

              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      busInfo(Icons.directions_bus, "Bus No", "BUS 12"),

                      busInfo(Icons.person, "Driver", "Ramesh"),

                      busInfo(Icons.speed, "Speed", "35 km/h"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.location_on),
                          label: const Text("Track Live"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call),
                          label: const Text("Call Driver"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          /// REFRESH BUTTON
          Positioned(
            bottom: 150,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }

  Widget busInfo(icon, title, value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),

        const SizedBox(height: 5),

        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),

        const SizedBox(height: 3),

        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class TestMapPage extends StatelessWidget {
  const TestMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OpenStreetMap Test")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(28.4089, 77.3178),
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.cbfpublicschool.apppro',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(28.4089, 77.3178),
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
