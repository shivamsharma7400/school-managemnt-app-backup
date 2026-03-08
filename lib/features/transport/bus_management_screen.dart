import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../data/models/bus_destination.dart';
import '../../data/services/bus_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/class_service.dart';
import '../../data/models/class_model.dart';
import '../../core/constants/app_constants.dart';

class BusManagementScreen extends StatefulWidget {
  @override
  _BusManagementScreenState createState() => _BusManagementScreenState();
}

class _BusManagementScreenState extends State<BusManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.dashboardBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.onBackground),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Bus Management',
            style: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined),
                    SizedBox(width: 8),
                    Text("Bus Stops", style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline),
                    SizedBox(width: 8),
                    Text("Students", style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BusStopsTab(),
            _StudentBusManagementTab(),
          ],
        ),
      ),
    );
  }
}

class _BusStopsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: StreamBuilder<List<BusDestination>>(
        stream: Provider.of<BusService>(context).getDestinations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No destinations added yet.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final destinations = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final dest = destinations[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dest.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "₹${dest.fee.toInt()}",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Icon(Icons.gps_fixed, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        "${dest.lat.toStringAsFixed(4)}, ${dest.lng.toStringAsFixed(4)}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.edit_outlined, color: AppColors.primary),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddDestinationScreen(destination: dest),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text("Delete Stop"),
                                content: Text("Are you sure you want to delete ${dest.name}?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
                                  TextButton(
                                    onPressed: () {
                                      Provider.of<BusService>(context, listen: false).deleteDestination(dest.id);
                                      Navigator.pop(ctx);
                                    },
                                    child: Text("Delete", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddDestinationScreen()),
        ),
        label: Text("Add New Stop", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add_location_alt),
        elevation: 4,
      ),
    );
  }
}

class AddDestinationScreen extends StatefulWidget {
  final BusDestination? destination;
  AddDestinationScreen({this.destination});

  @override
  _AddDestinationScreenState createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  late TextEditingController _nameController;
  late TextEditingController _feeController;
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _locationPermissionGranted = false;
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.destination?.name ?? '');
    _feeController = TextEditingController(text: widget.destination?.fee.toString() ?? '');
    _selectedLocation = widget.destination != null 
        ? LatLng(widget.destination!.lat, widget.destination!.lng)
        : LatLng(20.5937, 78.9629);
  }

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
      appBar: AppBar(title: Text(widget.destination == null ? 'Add Bus Stop' : 'Edit Bus Stop')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search location',
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
                TextField(
                  controller: _feeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monthly Bus Fee (₹)',
                    hintText: 'e.g. 500',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isNotEmpty) {
                        final fee = double.tryParse(_feeController.text) ?? 0.0;
                        if (widget.destination != null) {
                          await Provider.of<BusService>(context, listen: false)
                              .updateDestination(
                            widget.destination!.id,
                            _nameController.text,
                            _selectedLocation.latitude,
                            _selectedLocation.longitude,
                            fee,
                          );
                        } else {
                          await Provider.of<BusService>(context, listen: false)
                              .addDestination(
                            _nameController.text,
                            _selectedLocation.latitude,
                            _selectedLocation.longitude,
                            fee,
                          );
                        }
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.destination == null ? 'Save Destination' : 'Update Destination'),
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

class _StudentBusManagementTab extends StatefulWidget {
  @override
  State<_StudentBusManagementTab> createState() => _StudentBusManagementTabState();
}

class _StudentBusManagementTabState extends State<_StudentBusManagementTab> {
  final Map<String, String?> _selectedStops = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusDestination>>(
      stream: Provider.of<BusService>(context).getDestinations(),
      builder: (context, destSnapshot) {
        if (!destSnapshot.hasData) return Center(child: CircularProgressIndicator());
        final destinations = destSnapshot.data!;

        return StreamBuilder<List<ClassModel>>(
          stream: Provider.of<ClassService>(context).getAllClasses(),
          builder: (context, classSnapshot) {
            if (!classSnapshot.hasData) return Center(child: CircularProgressIndicator());
            final classes = classSnapshot.data!;

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: Provider.of<UserService>(context).getAllStudents(),
              builder: (context, studentSnapshot) {
                if (!studentSnapshot.hasData) return Center(child: CircularProgressIndicator());
                
                final allStudents = studentSnapshot.data!;
                final busStudents = allStudents.where((s) {
                  final feeConfig = s['feeConfig'] as Map<String, dynamic>? ?? {};
                  return feeConfig['Bus Fee'] != false;
                }).toList();

                if (busStudents.isEmpty) {
                  return Center(child: Text("No students using bus service."));
                }

                // Calculations for Summary
                int totalStudents = busStudents.length;
                double totalRevenue = 0;
                int unassignedCount = 0;

                for (var s in busStudents) {
                  final busStopId = s['busStopId']?.toString();
                  if (busStopId != null) {
                    final stop = destinations.firstWhere(
                      (d) => d.id == busStopId,
                      orElse: () => BusDestination(id: '', name: '', lat: 0, lng: 0, fee: 0),
                    );
                    totalRevenue += stop.fee;
                  } else {
                    unassignedCount++;
                    final classId = s['classId'];
                    final classModel = classes.firstWhere(
                      (c) => c.id == classId,
                      orElse: () => ClassModel(id: '', name: '', teacherId: ''),
                    );
                    totalRevenue += classModel.busFee;
                  }
                }

                final tabs = ["Undefined", ...destinations.map((d) => d.name)];

                return DefaultTabController(
                  length: tabs.length,
                  child: Column(
                    children: [
                      // Summary Dashboard
                      Container(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _buildSummaryCard("Total Students", totalStudents.toString(), Icons.people, Colors.blue),
                            SizedBox(width: 12),
                            _buildSummaryCard("Monthly Revenue", "₹${totalRevenue.toInt()}", Icons.account_balance_wallet, Colors.green),
                            SizedBox(width: 12),
                            _buildSummaryCard("Unassigned", unassignedCount.toString(), Icons.warning_amber_rounded, Colors.orange),
                          ],
                        ),
                      ),
                      
                      // Premium Capsule Styled TabBar (Centered)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.center,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          padding: EdgeInsets.zero,
                          labelPadding: EdgeInsets.symmetric(horizontal: 24),
                          tabs: tabs.map((t) {
                            final bool isUndefined = t == "Undefined";
                            return Tab(
                              height: 40,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUndefined ? Icons.help_outline : Icons.directions_bus_filled_outlined,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text(t),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      Expanded(
                        child: TabBarView(
                          children: tabs.map((tabName) {
                            final String? stopId = tabName == "Undefined" 
                                ? null 
                                : destinations.firstWhere((d) => d.name == tabName).id;

                            final filteredStudents = busStudents.where((s) => s['busStopId'] == stopId).toList();

                            return _buildStudentList(filteredStudents, classes, destinations);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onBackground),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Widget _buildStudentList(List<Map<String, dynamic>> students, List<ClassModel> classes, List<BusDestination> destinations) {
    final filteredBySearch = students.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final admNo = (s['admNo'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || admNo.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search by name or admission number...",
              prefixIcon: Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        
        Expanded(
          child: filteredBySearch.isEmpty 
            ? Center(child: Text("No students found."))
            : Container(
                margin: EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.05)),
                        headingRowHeight: 50,
                        dataRowMinHeight: 65,
                        dataRowMaxHeight: 65,
                        dividerThickness: 0.5,
                        columns: [
                          DataColumn(label: Text('Adm. No', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                          DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                          DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                          DataColumn(label: Text('Bus Fee', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                          DataColumn(label: Text('Stop Assignment', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                          DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                        ],
                        rows: filteredBySearch.map((s) {
                          final classId = s['classId']?.toString();
                          final studentId = (s['id'] ?? '').toString();
                          final classModel = classes.firstWhere(
                            (c) => c.id == classId,
                            orElse: () => ClassModel(id: '', name: 'Unknown', teacherId: '', coachingFee: 0, busFee: 0, hostelFee: 0, otherFees: {}),
                          );

                          final busStopId = s['busStopId']?.toString();
                          double displayFee = classModel.busFee;
                          
                          if (busStopId != null) {
                            final stop = destinations.firstWhere(
                              (d) => d.id == busStopId,
                              orElse: () => BusDestination(id: '', name: '', lat: 0, lng: 0, fee: 0),
                            );
                            displayFee = stop.fee;
                          }

                          return DataRow(cells: [
                            DataCell(Text(s['admNo']?.toString() ?? 'N/A', style: TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name']?.toString() ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(s['phone']?.toString() ?? '', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(classModel.name ?? 'Unknown', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            DataCell(
                              Text(
                                '₹${displayFee.toInt()}',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50]?.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: _selectedStops[studentId] ?? s['busStopId']?.toString(),
                                    style: TextStyle(fontSize: 13, color: Colors.black87),
                                    items: [
                                      DropdownMenuItem<String?>(value: null, child: Text("None (Undefined)")),
                                      ...destinations.map((d) => DropdownMenuItem<String?>(value: d.id, child: Text(d.name))),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedStops[studentId] = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: Icon(Icons.check_circle_outline, color: Colors.green[600]),
                                tooltip: "Save Assignment",
                                onPressed: () async {
                                  final selectedId = _selectedStops[studentId] ?? s['busStopId']?.toString();
                                  await Provider.of<UserService>(context, listen: false).updateStudentBusStop(studentId, selectedId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.green[600],
                                      content: Text("Bus stop updated for ${s['name']}"),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

