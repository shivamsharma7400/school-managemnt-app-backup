import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../data/models/bus_destination.dart';
import '../../data/services/bus_service.dart';
import '../../core/constants/app_constants.dart';

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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'List View', icon: Icon(Icons.list)),
            Tab(text: 'Map View', icon: Icon(Icons.map)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(), // Disable swipe to avoid conflict with map
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
                padding: EdgeInsets.only(bottom: 80), // Space for FAB
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
                        "Lat: ${dest.lat.toStringAsFixed(4)}, Lng: ${dest.lng.toStringAsFixed(4)}",
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
  MapType _currentMapType = MapType.normal;

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      return;
    }

    setState(() {
      _locationPermissionGranted = true;
    });

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _selectedLocation = _currentLocation!;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation!, 18),
    );
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Bus Stop')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search location (coming soon...)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.my_location, color: Colors.blue),
                  onPressed: _getCurrentLocation,
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 5,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_currentLocation != null) {
                       controller.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 15));
                    }
                  },
                  onTap: (pos) {
                    setState(() => _selectedLocation = pos);
                  },
                  mapType: _currentMapType,
                  markers: {
                    Marker(
                      markerId: MarkerId('selected'),
                      position: _selectedLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),
                 Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _onMapTypeButtonPressed,
                    backgroundColor: Colors.white,
                    child: Icon(
                      _currentMapType == MapType.normal
                          ? Icons.satellite_alt
                          : Icons.map,
                      color: AppColors.primary,
                    ),
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
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
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

class DestinationsMapView extends StatefulWidget {
  @override
  _DestinationsMapViewState createState() => _DestinationsMapViewState();
}

class _DestinationsMapViewState extends State<DestinationsMapView> {
  GoogleMapController? _mapController;
  bool _initialized = false;
  MapType _currentMapType = MapType.normal;

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.hybrid
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusDestination>>(
      stream: Provider.of<BusService>(context).getDestinations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_initialized) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final destinations = snapshot.data ?? [];
        final markers = destinations.map((dest) {
          return Marker(
            markerId: MarkerId('dest_${dest.id}'),
            position: LatLng(dest.lat, dest.lng),
            infoWindow: InfoWindow(
              title: dest.name,
              snippet: "Lat: ${dest.lat.toStringAsFixed(4)}, Lng: ${dest.lng.toStringAsFixed(4)}",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          );
        }).toSet();

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: destinations.isNotEmpty 
                    ? LatLng(destinations.first.lat, destinations.first.lng)
                    : const LatLng(20.5937, 78.9629),
                zoom: destinations.isNotEmpty ? 12 : 5,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (mounted) setState(() => _initialized = true);
              },
              mapType: _currentMapType,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              padding: EdgeInsets.only(bottom: 60), // Space for FAB
            ),
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'map_type_toggle_main', // Unique tag
                onPressed: _onMapTypeButtonPressed,
                backgroundColor: Colors.white,
                child: Icon(
                  _currentMapType == MapType.normal
                      ? Icons.satellite_alt
                      : Icons.map,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
