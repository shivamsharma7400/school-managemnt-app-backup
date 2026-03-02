import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../data/models/bus_destination.dart';
import '../../data/services/bus_service.dart';
import '../../core/constants/app_constants.dart';

class StudentBusTrackerScreen extends StatefulWidget {
  const StudentBusTrackerScreen({super.key});

  @override
  State<StudentBusTrackerScreen> createState() => _StudentBusTrackerScreenState();
}

class _StudentBusTrackerScreenState extends State<StudentBusTrackerScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  BusDestination? _selectedDestination;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  MapType _currentMapType = MapType.normal;
  late AnimationController _pulseController;
  List<LatLng> _polylineCoordinates = [];
  late PolylinePoints _polylinePoints;
  
  // Default location (India center)
  static const LatLng _center = LatLng(20.5937, 78.9629);

  // Cached values to prevent excessive API calls
  LatLng? _lastBusPos;
  LatLng? _lastDestPos;

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints(apiKey: AppConstants.googleMapsApiKey);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Fetch route between bus and destination
  Future<void> _updateRoute(LatLng busPos, LatLng destPos) async {
    // Only update if positions have changed significantly (e.g., > 10 meters)
    // For simplicity, we'll check simple equality or if it's the first run
    if (_lastBusPos == busPos && _lastDestPos == destPos && _polylineCoordinates.isNotEmpty) {
      return; 
    }

    _lastBusPos = busPos;
    _lastDestPos = destPos;

    try {
      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(busPos.latitude, busPos.longitude),
          destination: PointLatLng(destPos.latitude, destPos.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        setState(() {
          _polylineCoordinates = result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        });
      } else {
        debugPrint("Polyline Error: ${result.errorMessage}");
        // If there's an error message, we might want to show it once to the user
        if (result.errorMessage != null && mounted) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("Route Error: ${result.errorMessage}")),
             );
           });
        }
      }
    } catch (e) {
      debugPrint("Error fetching polyline: $e");
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Route Exception: ${e.toString()}")),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Live Bus Status", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient for AppBar area
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          _buildMap(),
          
          // Floating Destination Selector
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: _buildFloatingSelector(),
          ),

          // Map Type Switcher
          Positioned(
            top: 180,
            right: 15,
            child: _buildMapTypeSwitcher(),
          ),

          // Re-center Button
          Positioned(
            top: 360,
            right: 15,
            child: FloatingActionButton.small(
              heroTag: "recenter",
              backgroundColor: Colors.white,
              onPressed: _recenterMap,
              child: Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
          
          // Bottom Status Card
          _buildBottomStatusArea(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bus_tracking').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, snapshot) {
        Set<Marker> currentMarkers = Set.from(_markers);
        Set<Polyline> currentPolylines = {};
        
        if (snapshot.hasData && _selectedDestination != null) {
          final buses = snapshot.data!.docs;
          for (var doc in buses) {
            final data = doc.data() as Map<String, dynamic>;
            final destinations = List<String>.from(data['destinationNames'] ?? []);
            
            if (destinations.contains(_selectedDestination!.name)) {
              final busLat = (data['lat'] as num).toDouble();
              final busLng = (data['lng'] as num).toDouble();
              final busPos = LatLng(busLat, busLng);
              final destPos = LatLng(_selectedDestination!.lat, _selectedDestination!.lng);
              
              currentMarkers.add(
                Marker(
                  markerId: const MarkerId('live_bus'),
                  position: busPos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: InfoWindow(title: "Trip #${data['tripNumber']}"),
                ),
              );

              // Trigger route update
              // Note: We use a microtask or check explicitly to avoid setState during build
              // But for simplicity in this stream builder, we might just call it if we handle state carefully
              // A better way is to rely on the cached _polylineCoordinates
              
              if (_polylineCoordinates.isEmpty || _lastBusPos != busPos) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                   _updateRoute(busPos, destPos);
                 });
              }

              if (_polylineCoordinates.isNotEmpty) {
                currentPolylines.add(
                  Polyline(
                    polylineId: const PolylineId('bus_route'),
                    points: _polylineCoordinates,
                    color: Colors.yellow, // Yellow road line
                    width: 6,
                    jointType: JointType.round,
                  ),
                );
              } else {
                // Fallback to straight line if route not yet fetched
                currentPolylines.add(
                  Polyline(
                    polylineId: const PolylineId('bus_route_fallback'),
                    points: [busPos, destPos],
                    color: Colors.yellow.withOpacity(0.5),
                    width: 4,
                    patterns: [PatternItem.dash(10), PatternItem.gap(5)], // Dashed for fallback
                  ),
                );
              }

              break; 
            }
          }
        }

        return GoogleMap(
          initialCameraPosition: const CameraPosition(target: _center, zoom: 5),
          onMapCreated: (controller) => _mapController = controller,
          markers: currentMarkers,
          polylines: currentPolylines,
          mapType: _currentMapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          padding: const EdgeInsets.only(bottom: 150), // Ensure map elements aren't hidden by card
        );
      },
    );
  }

  Widget _buildFloatingSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: StreamBuilder<List<BusDestination>>(
        stream: Provider.of<BusService>(context).getDestinations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          
          final destinations = snapshot.data!;
          return DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedDestination?.id,
              isExpanded: true,
              hint: const Text("Select your Bus Stop"),
              decoration: const InputDecoration(
                icon: Icon(Icons.location_on, color: Colors.blue),
                border: InputBorder.none,
              ),
              items: destinations.map((d) {
                return DropdownMenuItem(
                  value: d.id,
                  child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final dest = destinations.firstWhere((d) => d.id == val);
                  setState(() {
                    _selectedDestination = dest;
                    _polylineCoordinates = []; // Reset route
                    _updateStaticMarkers();
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(LatLng(dest.lat, dest.lng), 15),
                    );
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapTypeSwitcher() {
    return Column(
      children: [
        _mapTypeFab(Icons.layers_outlined, MapType.normal),
        const SizedBox(height: 8),
        _mapTypeFab(Icons.satellite_alt_outlined, MapType.satellite),
        const SizedBox(height: 8),
        _mapTypeFab(Icons.terrain_outlined, MapType.terrain),
      ],
    );
  }

  Widget _mapTypeFab(IconData icon, MapType type) {
    bool isSelected = _currentMapType == type;
    return FloatingActionButton.small(
      heroTag: "map_type_$type",
      onPressed: () => setState(() => _currentMapType = type),
      backgroundColor: isSelected ? AppColors.primary : Colors.white,
      child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[700]),
    );
  }

  Widget _buildBottomStatusArea() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bus_tracking').where('status', isEqualTo: 'active').snapshots(),
        builder: (context, snapshot) {
          if (_selectedDestination == null) {
            return _buildInfoCard(
              "Select a stop to see bus status",
              Icons.info_outline,
              Colors.blue,
            );
          }

          Map<String, dynamic>? relevantBusData;
          bool busFound = false;

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final destinations = List<String>.from(data['destinationNames'] ?? []);
              if (destinations.contains(_selectedDestination!.name)) {
                relevantBusData = data;
                busFound = true;
                break;
              }
            }
          }

          if (busFound && relevantBusData != null) {
            return _buildLiveStatusCard(relevantBusData);
          } else {
            return _buildInfoCard(
              "Bus is not active or hasn't started yet for this route.",
              Icons.bus_alert,
              Colors.orange,
            );
          }
        },
      ),
    );
  }

  Widget _buildLiveStatusCard(Map<String, dynamic> data) {
    // Calculate distance if route is available
    String distanceDisplay = "Calculating...";
    if (_polylineCoordinates.isNotEmpty && _lastBusPos != null && _selectedDestination != null) {
       // Estimate based on road points
       // A simpler approach for rough estimate
       // But better: Use the total distance from the route result if possible, but package might not return it easily without full directions object
       // For now, we can sum the segments
       double totalDist = 0;
       for (int i = 0; i < _polylineCoordinates.length - 1; i++) {
         totalDist += _calculateDistance(
           _polylineCoordinates[i].latitude, _polylineCoordinates[i].longitude,
           _polylineCoordinates[i+1].latitude, _polylineCoordinates[i+1].longitude
         );
       }
       distanceDisplay = "${totalDist.toStringAsFixed(1)} km";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  FadeTransition(
                    opacity: _pulseController,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 20,
                    child: Icon(Icons.directions_bus, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "LIVE TRACKING",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      "Bus is on its way!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Trip #${data['tripNumber']}",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTripStat(Icons.timeline_outlined, "Distance", distanceDisplay),
              _buildTripStat(Icons.route_outlined, "Next Stop", data['currentDestination'] ?? "N/A"),
              _buildTripStat(Icons.speed, "Speed", "Normal"),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
  
// Haversine formula for updating distance calculation if needed locally
  double _calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = (a) => 0.5 - math.cos(a) / 2;
    return 12742 * math.asin(math.sqrt(c((lat2 - lat1) * p) + math.cos(lat1 * p) * math.cos(lat2 * p) * c((lon2 - lon1) * p)));
  }

  Widget _buildTripStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildInfoCard(String message, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _recenterMap() {
    if (_selectedDestination != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(_selectedDestination!.lat, _selectedDestination!.lng), 15),
      );
    }
  }

  void _updateStaticMarkers() {
    if (_selectedDestination == null) return;
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('my_stop'),
          position: LatLng(_selectedDestination!.lat, _selectedDestination!.lng),
          infoWindow: InfoWindow(title: "My Stop: ${_selectedDestination!.name}"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }
}

