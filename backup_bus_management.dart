import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../data/models/bus_destination.dart';
import '../../data/services/bus_service.dart';

class BusManagementScreen extends StatefulWidget {
  @override
  _BusManagementScreenState createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Trigger a UI rebuild if needed, though StreamBuilder handles data updates automatically.
              // This is just for user reassurance as requested.
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'List View', icon: Icon(Icons.list)),
              Tab(text: 'Map View', icon: Icon(Icons.map)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // List View Tab
                StreamBuilder<List<BusDestination>>(
                  stream: Provider.of<BusService>(context).getDestinations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("No destinations added yet."));
                    }

                    final destinations = snapshot.data!;
                    return ListView.builder(
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        final dest = destinations[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              dest.name,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Lat: \${dest.lat.toStringAsFixed(4)}, Lng: \${dest.lng.toStringAsFixed(4)}",
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Provider.of<BusService>(
                                  context,
                                  listen: false,
                                ).deleteDestination(dest.id);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                // Map View Tab
                DestinationsMapView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddDestinationScreen()),
        ),
        label: Text("Add Stop"),
        icon: Icon(Icons.add_location_alt),
      ),
    );
  }
}

class AddDestinationScreen extends StatefulWidget {
  @override
  _AddDestinationScreenState createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  final _nameController = TextEditingController();
  LatLng _selectedLocation = LatLng(
    20.5937,
    78.9629,
  ); // Default to India center
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _locationPermissionGranted = false;

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue accessing the position.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try requesting at a
        // higher level by providing rationale.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      return;
    }

    // When we reach here, permissions are granted and we can proceed.
    setState(() {
      _locationPermissionGranted = true;
    });

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _selectedLocation =
          _currentLocation!; // Also update the selected location
    });

    // Move the camera to the current location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation!, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Bus Stop')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 5,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (pos) {
                    setState(() => _selectedLocation = pos);
                  },
                  mapType: MapType.satellite,
                  markers: {
                    Marker(
                      markerId: MarkerId('selected'),
                      position: _selectedLocation,
                    ),
                    if (_currentLocation != null)
                      Marker(
                        markerId: MarkerId('current_location'),
                        position: _currentLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                      ),
                  },
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    onPressed: _getCurrentLocation,
                    child: Icon(Icons.my_location, color: Colors.blue),
                    tooltip: 'My Location',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Destination Name (e.g., School Gate)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isNotEmpty) {
                        Provider.of<BusService>(
                          context,
                          listen: false,
                        ).addDestination(
                          _nameController.text,
                          _selectedLocation.latitude,
                          _selectedLocation.longitude,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Save Destination'),
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
