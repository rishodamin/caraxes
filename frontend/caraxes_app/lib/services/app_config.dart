import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfig {
  static String? backendIp;

  static Future<void> load() async {
    final doc = await FirebaseFirestore.instance
        .collection('app_data')
        .doc('main')
        .get();

    backendIp = doc.data()?['ip'];
  }

  static String get inferUrl {
    if (backendIp == null) {
      throw Exception('Backend IP not loaded');
    }

    return 'http://$backendIp:5000/infer';
  }
}
