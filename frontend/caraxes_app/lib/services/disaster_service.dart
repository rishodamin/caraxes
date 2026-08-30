import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/disaster_location_model.dart';

class DisasterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DisasterLocationModel>> getDisasterLocations() async {
    try {
      final snapshot = await _firestore.collection('disaster_locations').get();
      return snapshot.docs
          .map((doc) => DisasterLocationModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch disaster locations: $e');
    }
  }
}
