import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BusRoutineStop {
  final String stopId;
  final String stopName;
  final String time; // e.g., "07:30 AM"

  BusRoutineStop({
    required this.stopId,
    required this.stopName,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'stopId': stopId,
      'stopName': stopName,
      'time': time,
    };
  }

  factory BusRoutineStop.fromMap(Map<String, dynamic> map) {
    return BusRoutineStop(
      stopId: map['stopId'] ?? '',
      stopName: map['stopName'] ?? '',
      time: map['time'] ?? '',
    );
  }
}

class BusRoutine {
  final String id;
  final String driverId;
  final int tripNumber;
  final String type; // Arrival, Departure
  final List<BusRoutineStop> stops;

  BusRoutine({
    required this.id,
    required this.driverId,
    required this.tripNumber,
    required this.type,
    required this.stops,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'tripNumber': tripNumber,
      'type': type,
      'stops': stops.map((s) => s.toMap()).toList(),
    };
  }

  factory BusRoutine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusRoutine(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      tripNumber: data['tripNumber'] ?? 1,
      type: data['type'] ?? 'Arrival',
      stops: (data['stops'] as List? ?? [])
          .map((s) => BusRoutineStop.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BusRoutineService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<BusRoutine?> getRoutine(String driverId, int tripNumber, String type) {
    return _firestore
        .collection('bus_routines')
        .where('driverId', isEqualTo: driverId)
        .where('tripNumber', isEqualTo: tripNumber)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return BusRoutine.fromFirestore(snapshot.docs.first);
    });
  }

  Future<void> saveRoutine(String driverId, int tripNumber, String type, List<BusRoutineStop> stops) async {
    final query = await _firestore
        .collection('bus_routines')
        .where('driverId', isEqualTo: driverId)
        .where('tripNumber', isEqualTo: tripNumber)
        .where('type', isEqualTo: type)
        .get();

    final data = {
      'driverId': driverId,
      'tripNumber': tripNumber,
      'type': type,
      'stops': stops.map((s) => s.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (query.docs.isEmpty) {
      await _firestore.collection('bus_routines').add(data);
    } else {
      await _firestore.collection('bus_routines').doc(query.docs.first.id).update(data);
    }
    notifyListeners();
  }

  Future<void> deleteRoutine(String id) async {
    await _firestore.collection('bus_routines').doc(id).delete();
    notifyListeners();
  }
}
