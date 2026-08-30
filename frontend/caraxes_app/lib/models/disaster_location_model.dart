class DisasterDetection {
  final String className;
  final double confidence;
  final int severityScore;
  final int priority;

  DisasterDetection({
    required this.className,
    required this.confidence,
    required this.severityScore,
    required this.priority,
  });

  factory DisasterDetection.fromMap(Map<String, dynamic> map) {
    final severityEngine = map['severity_engine'] as Map<String, dynamic>? ?? {};
    return DisasterDetection(
      className: map['class_name'] ?? 'Unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      severityScore: (severityEngine['severity_score'] as num?)?.toInt() ?? 0,
      priority: (severityEngine['priority'] as num?)?.toInt() ?? 0,
    );
  }
}

class DisasterLocationModel {
  final String id;
  final double latitude;
  final double longitude;
  final List<DisasterDetection> detections;

  DisasterLocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.detections,
  });

  int get highestSeverityScore {
    if (detections.isEmpty) return 0;
    return detections.map((d) => d.severityScore).reduce((a, b) => a > b ? a : b);
  }

  DisasterDetection? get highestSeverityDetection {
    if (detections.isEmpty) return null;
    return detections.reduce((a, b) => a.severityScore > b.severityScore ? a : b);
  }

  factory DisasterLocationModel.fromMap(String id, Map<String, dynamic> map) {
    final locationMap = map['location'] as Map<String, dynamic>? ?? {};
    final detectionsList = map['detections'] as List<dynamic>? ?? [];

    return DisasterLocationModel(
      id: id,
      latitude: double.tryParse(locationMap['lat']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(locationMap['lon']?.toString() ?? '0.0') ?? 0.0,
      detections: detectionsList
          .map((d) => DisasterDetection.fromMap(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
