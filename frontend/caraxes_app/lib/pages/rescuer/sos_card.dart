import 'package:flutter/material.dart';

class SosCard extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const SosCard({super.key, required this.documentId, required this.data});

  @override
  Widget build(BuildContext context) {
    final String userName = data['user_name']?.toString() ?? 'Unknown User';

    final String damageType = data['damage_type']?.toString() ?? 'Unknown';

    final String urgency = data['urgency']?.toString() ?? 'Unknown';

    final String status = data['status']?.toString() ?? 'Unknown';

    final int peopleAffected = (data['people_affected'] as num?)?.toInt() ?? 0;

    final double latitude = (data['latitude'] as num?)?.toDouble() ?? 0;

    final double longitude = (data['longitude'] as num?)?.toDouble() ?? 0;

    final String locationId = data['location_id']?.toString() ?? 'N/A';

    final String contactNumber = data['contact_number']?.toString() ?? 'N/A';

    final String notes =
        data['additional_notes']?.toString() ?? 'No additional notes';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getUrgencyColor(urgency),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        ),

        title: Text(
          damageType,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),

        subtitle: Text('$userName • $urgency'),

        trailing: Chip(
          label: Text(
            status.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          backgroundColor: _getStatusColor(status),
        ),

        children: [
          Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('SOS Details'),

                _buildInfoRow(Icons.person, 'User', userName),

                _buildInfoRow(Icons.phone, 'Contact', contactNumber),

                _buildInfoRow(Icons.warning, 'Urgency', urgency),

                _buildInfoRow(
                  Icons.people,
                  'People Affected',
                  peopleAffected.toString(),
                ),

                _buildInfoRow(Icons.location_on, 'Location ID', locationId),

                _buildInfoRow(
                  Icons.my_location,
                  'Latitude',
                  latitude.toString(),
                ),

                _buildInfoRow(
                  Icons.my_location,
                  'Longitude',
                  longitude.toString(),
                ),

                _buildInfoRow(Icons.info_outline, 'Status', status),

                const Divider(height: 30),

                _buildSectionTitle('Additional Notes'),

                const SizedBox(height: 8),

                Text(notes, style: const TextStyle(fontSize: 16)),

                const SizedBox(height: 20),

                Text(
                  'Document ID: $documentId',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red),

          const SizedBox(width: 12),

          SizedBox(
            width: 120,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red;

      case 'high':
        return Colors.orange;

      case 'medium':
        return Colors.amber;

      case 'low':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;

      case 'resolved':
        return Colors.green;

      case 'in progress':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }
}
