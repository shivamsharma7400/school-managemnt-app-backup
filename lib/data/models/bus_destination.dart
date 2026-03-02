import 'package:cloud_firestore/cloud_firestore.dart';

class BusDestination {
  final String id;
  final String name;
  final double lat;
  final double lng;

  BusDestination({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory BusDestination.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BusDestination(
      id: doc.id,
      name: data['name'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
    };
  }
}
