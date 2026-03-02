import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vps/data/models/bus_destination.dart';
import 'package:vps/data/services/auth_service.dart';
import 'package:vps/data/services/bus_service.dart';
import 'package:geolocator/geolocator.dart';
// import 'start_bus_screen.dart'; // Will navigate back or pop

class ActiveTripScreen extends StatefulWidget {
  final int tripNumber;
  final List<BusDestination> destinations;
  final String type; // Arrival, Departure

  const ActiveTripScreen({
    Key? key,
    required this.tripNumber,
    required this.destinations,
    required this.type,
  }) : super(key: key);

  @override
  _ActiveTripScreenState createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _timer;
  Duration _duration = Duration.zero;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat(reverse: true);
    
    _startTimer();
    _startTracking();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _duration += Duration(seconds: 1);
      });
    });
  }

  Future<void> _startTracking() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final driverId = Provider.of<AuthService>(context, listen: false).user!.uid;
    final busService = Provider.of<BusService>(context, listen: false);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      busService.updateBusLocation(
        driverId, 
        position.latitude, 
        position.longitude, 
        widget.tripNumber, 
        'active',
        widget.destinations.map((d) => d.name).toList(),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text("Trip #${widget.tripNumber} - Live"),
        backgroundColor: Colors.redAccent, 
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animation
            Center(
              child: ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)),
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(blurRadius: 20, color: Colors.red.withOpacity(0.3))]),
                  child: Icon(Icons.directions_bus, size: 64, color: Colors.redAccent),
                ),
              ),
            ),
            SizedBox(height: 32),
            
            // Info
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Current Trip Duration", style: TextStyle(color: Colors.grey)),
                    Text(_formatDuration(_duration), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Type: ${widget.type}", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${widget.destinations.length} Stops"),
                      ],
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.destinations.map((d) => Chip(label: Text(d.name, style: TextStyle(fontSize: 10)))).toList(),
                    )
                  ],
                ),
              ),
            ),
            Spacer(),
            
            // Buttons
            ElevatedButton.icon(
              icon: Icon(Icons.skip_next),
              label: Text("Next Trip (Complete Current)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                _endTrip();
                Navigator.pop(context, {'action': 'next', 'lastTrip': widget.tripNumber});
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.check_circle),
              label: Text("Complete Session (Stop Bus)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                 _endTrip();
                 Navigator.pop(context, {'action': 'complete'});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _endTrip() {
    final driverId = Provider.of<AuthService>(context, listen: false).user!.uid;
    Provider.of<BusService>(context, listen: false).endTrip(driverId);
  }
}
