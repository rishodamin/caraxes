import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LocationModel>> getLocations() async {
    try {
      final snapshot = await _firestore.collection('locations').get();
      return snapshot.docs
          .map((doc) => LocationModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch locations: $e');
    }
  }
}
