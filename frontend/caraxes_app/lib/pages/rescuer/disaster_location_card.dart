import 'package:flutter/material.dart';

class DisasterLocationCard extends StatelessWidget {
  final Map<String, dynamic> detection;

  const DisasterLocationCard({super.key, required this.detection});

  @override
  Widget build(BuildContext context) {
    final String className = detection['class_name']?.toString() ?? 'Unknown';

    final double confidence =
        (detection['confidence'] as num?)?.toDouble() ?? 0;

    final boundingBox =
        detection['bounding_box'] as Map<String, dynamic>? ?? {};

    final severityEngine =
        detection['severity_engine'] as Map<String, dynamic>? ?? {};

    final String action = severityEngine['action']?.toString() ?? 'N/A';

    final int priority = (severityEngine['priority'] as num?)?.toInt() ?? 0;

    final int severityScore =
        (severityEngine['severity_score'] as num?)?.toInt() ?? 0;

    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 12),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              className.toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),

            const Divider(),

            const Text(
              'Bounding Box',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Text('X1: ${boundingBox['x1'] ?? 'N/A'}'),

            Text('X2: ${boundingBox['x2'] ?? 'N/A'}'),

            Text('Y1: ${boundingBox['y1'] ?? 'N/A'}'),

            Text('Y2: ${boundingBox['y2'] ?? 'N/A'}'),

            const Divider(),

            const Text(
              'Severity Analysis',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Text('Action: $action'),

            Text('Priority: $priority'),

            Text('Severity Score: $severityScore'),
          ],
        ),
      ),
    );
  }
}
