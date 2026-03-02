import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/data/models/bus_destination.dart';
import '../../data/services/bus_service.dart';
import 'active_trip_screen.dart';

class StartBusScreen extends StatefulWidget {
  const StartBusScreen({Key? key}) : super(key: key);

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
      body: Padding(
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
                    if (val != null) setState(() => _tripIndex = val);
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
                    if (val != null) setState(() => _type = val);
                  },
                ),
              ),
            ),

            const Spacer(),

            // Start Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _startTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Start", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
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

