import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/data/models/bus_destination.dart';
import '../../data/services/bus_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/bus_routine_service.dart';
import '../../data/services/auth_service.dart';
import 'active_trip_screen.dart';

class StartBusScreen extends StatefulWidget {
  const StartBusScreen({super.key});

  @override
  _StartBusScreenState createState() => _StartBusScreenState();
}

class _StartBusScreenState extends State<StartBusScreen> {
  int? _tripIndex; // 0 for Trip 1, etc.
  List<BusDestination> _selectedDestinations = [];
  String _type = 'Arrival';
  final Set<int> _completedTrips = {}; // Track completed trips for this session

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Start Bus Workflow"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Select Trip Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Trip Dropdown
              const Text("Select Trip:"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _tripIndex,
                    hint: const Text("Choose Trip"),
                    isExpanded: true,
                    items: List.generate(5, (index) {
                      final int tripNum = index + 1;
                      final bool isCompleted = _completedTrips.contains(tripNum);
                      return DropdownMenuItem(
                        value: tripNum,
                        enabled: !isCompleted,
                        child: Row(
                          children: [
                            Text("Trip $tripNum"),
                            if (isCompleted) ...[
                              const Spacer(),
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            ]
                          ],
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _tripIndex = val);
                        _checkAndLoadRoutine();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Destination Multi-select
              const Text("Select Destinations:"),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showDestinationDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDestinations.isEmpty
                              ? "Tap to select destinations"
                              : _selectedDestinations.map((e) => e.name).join(", "),
                          style: TextStyle(
                            color: _selectedDestinations.isEmpty ? Colors.grey.shade600 : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Type Dropdown
              const Text("Type:"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _type,
                    isExpanded: true,
                    items: ["Arrival", "Departure"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _type = val);
                        _checkAndLoadRoutine();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
              if (_selectedDestinations.isNotEmpty) _buildStudentSummary(),
              const SizedBox(height: 30),

              // Start Button
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _startTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Start Trip", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkAndLoadRoutine() async {
    if (_tripIndex == null) return;
    
    final driverId = Provider.of<AuthService>(context, listen: false).user?.uid;
    if (driverId == null) return;

    final service = Provider.of<BusRoutineService>(context, listen: false);
    final routine = await service.getRoutine(driverId, _tripIndex!, _type).first;
    
    if (routine != null && routine.stops.isNotEmpty) {
      final busService = Provider.of<BusService>(context, listen: false);
      final allDestinations = await busService.getDestinations().first;
      
      List<BusDestination> selected = [];
      for (var rStop in routine.stops) {
        final match = allDestinations.where((d) => d.id == rStop.stopId).firstOrNull;
        if (match != null) {
          selected.add(match);
        }
      }

      if (mounted) {
        setState(() {
          _selectedDestinations = selected;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Routine loaded: ${selected.length} stops auto-selected"),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildStudentSummary() {
    final stopIds = _selectedDestinations.map((d) => d.id).toList();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<UserService>(context, listen: false).getStudentsByBusStops(stopIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final students = snapshot.data!;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Selected Passengers",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${students.length} Students",
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (students.isEmpty)
                const Center(child: Text("No students assigned to these stops", style: TextStyle(color: Colors.grey, fontSize: 13)))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(s['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text("Class ${s['classId'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Text(s['name']?[0] ?? 'S', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDestinationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<BusDestination>>(
          stream: Provider.of<BusService>(context).getDestinations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
            
            final availableDestinations = snapshot.data ?? [];
            
            return StatefulBuilder( // Use StatefulBuilder to update dialog state
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text("Select Destinations"),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: availableDestinations.isEmpty 
                      ? Text("No destinations found. management needs to add them.") 
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableDestinations.length,
                          itemBuilder: (context, index) {
                            final dest = availableDestinations[index];
                            final isSelected = _selectedDestinations.any((d) => d.id == dest.id);
                            return CheckboxListTile(
                              title: Text(dest.name),
                              value: isSelected,
                              onChanged: (val) {
                                setDialogState(() { // Update dialog UI
                                  if (val == true) {
                                    _selectedDestinations.add(dest);
                                  } else {
                                    _selectedDestinations.removeWhere((d) => d.id == dest.id);
                                  }
                                });
                                setState(() {}); // Update parent UI as well
                              },
                            );
                          },
                        ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Done")),
                  ],
                );
              }
            );
          },
        );
      },
    );
  }

  void _startTrip() async {
    if (_tripIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a trip")));
      return;
    }
    if (_selectedDestinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select at least one destination")));
      return;
    }

    // Navigate to Active Trip Screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveTripScreen(
          tripNumber: _tripIndex!,
          destinations: _selectedDestinations,
          type: _type,
        ),
      ),
    );

    // Handle return (Next Trip or Complete)
    if (result != null && result is Map) {
      if (result['action'] == 'next') {
        setState(() {
          _completedTrips.add(result['lastTrip']);
          _tripIndex = null; // Reset selection
          _selectedDestinations.clear();
          // Type remains same or reset? Keeping same type is usually better workflow
        });
      } else if (result['action'] == 'complete') {
        Navigator.pop(context); // Exit workflow
      }
    }
  }
}

