import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/bus_destination.dart';

class BusService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Destinations ---

  Stream<List<BusDestination>> getDestinations() {
    return _firestore.collection('bus_destinations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BusDestination.fromFirestore(doc)).toList();
    });
  }

  Future<void> addDestination(String name, double lat, double lng, double fee) async {
    await _firestore.collection('bus_destinations').add({
      'name': name,
      'lat': lat,
      'lng': lng,
      'fee': fee,
    });
  }

  Future<void> updateDestination(String id, String name, double lat, double lng, double fee) async {
    await _firestore.collection('bus_destinations').doc(id).update({
      'name': name,
      'lat': lat,
      'lng': lng,
      'fee': fee,
    });
  }

  Future<void> deleteDestination(String id) async {
    await _firestore.collection('bus_destinations').doc(id).delete();
  }

  // --- Live Tracking ---

  // Update Driver's specific bus location
  Future<void> updateBusLocation(String driverId, double lat, double lng, int tripNumber, String status, List<String> destinationNames) async {
    try {
      await _firestore.collection('bus_tracking').doc(driverId).set({
        'driverId': driverId,
        'lat': lat,
        'lng': lng,
        'tripNumber': tripNumber,
        'status': status, // 'active', 'completed'
        'destinationNames': destinationNames,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print("Error updating bus location: $e");
    }
  }

  Future<void> endTrip(String driverId) async {
    try {
      await _firestore.collection('bus_tracking').doc(driverId).update({
        'status': 'completed',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print("Error ending trip: $e");
    }
  }
}
